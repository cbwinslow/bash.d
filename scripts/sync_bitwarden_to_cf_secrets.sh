#!/usr/bin/env bash
# Sync Bitwarden fields into Cloudflare Secrets Store or Worker secrets.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BW_AGENT="${ROOT}/bash_functions.d/tools/bw_agent.sh"

MODE="secrets-store" # secrets-store | worker
ENV_FILE="${HOME}/.env"
CONFIG_FILE="${ROOT}/configs/bitwarden/cloudflare_secrets_sync.json"
STORE_NAME="default_secrets_store"
STORE_ID=""
SCOPES="workers"
WORKER_CWD="${ROOT}/mirror/openai_compat"
DRY_RUN=0
ALLOW_PLAIN=0
FIELD_REGEX=""
ITEM_REGEX=".*"
STORE_NAME_SET=0
SCOPES_SET=0

usage() {
  cat <<'EOF'
Sync Bitwarden fields into Cloudflare secrets.

Usage:
  scripts/sync_bitwarden_to_cf_secrets.sh [options]

Options:
  --mode <secrets-store|worker>   Target secrets store or worker secrets (default: secrets-store)
  --env-file <path>               Source environment file for Bitwarden/OpenRouter (default: ~/.env)
  --config <path>                 JSON config file with explicit secret mappings
  --regex <pattern>               Field-name regex for auto-discovery
  --item-regex <pattern>          Item-name regex for auto-discovery (default: .*)
  --store-id <id>                 Cloudflare Secrets Store id
  --store-name <name>             Cloudflare Secrets Store name (default: default_secrets_store)
  --scopes <csv>                  Secrets Store scopes (default: workers)
  --worker-cwd <path>             Wrangler project directory for worker secrets
  --allow-plain                   Allow passing secret values via --value (Secrets Store only)
  --dry-run                       Show what would happen without changes
  -h, --help                      Show this help

Notes:
  - Secrets Store create/update uses --value (plain-text in process args).
    Use --allow-plain to accept this risk.
  - Worker secrets are set via stdin and do not expose values.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"; shift 2 ;;
    --env-file)
      ENV_FILE="$2"; shift 2 ;;
    --config)
      CONFIG_FILE="$2"; shift 2 ;;
    --regex)
      FIELD_REGEX="$2"; shift 2 ;;
    --item-regex)
      ITEM_REGEX="$2"; shift 2 ;;
    --store-id)
      STORE_ID="$2"; shift 2 ;;
    --store-name)
      STORE_NAME="$2"; STORE_NAME_SET=1; shift 2 ;;
    --scopes)
      SCOPES="$2"; SCOPES_SET=1; shift 2 ;;
    --worker-cwd)
      WORKER_CWD="$2"; shift 2 ;;
    --allow-plain)
      ALLOW_PLAIN=1; shift ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage; exit 1 ;;
  esac
done

if [[ -n "$ENV_FILE" && -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

if [[ -z "${BW_CLIENTSECRET:-}" && -n "${BW_SECRETID:-}" ]]; then
  export BW_CLIENTSECRET="${BW_SECRETID}"
fi
if [[ -z "${BW_PASSWORD:-}" && -n "${BWPASSWORD:-}" ]]; then
  export BW_PASSWORD="${BWPASSWORD}"
fi

if [[ ! -x "$BW_AGENT" ]]; then
  echo "bw_agent.sh not found at $BW_AGENT" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

if [[ "$MODE" == "secrets-store" && "$ALLOW_PLAIN" -ne 1 && "$DRY_RUN" -ne 1 ]]; then
  echo "Refusing to run Secrets Store sync without --allow-plain" >&2
  exit 1
fi

if [[ -z "$FIELD_REGEX" && ! -f "$CONFIG_FILE" ]]; then
  echo "Provide --regex or a config file with secret mappings." >&2
  exit 1
fi

"$BW_AGENT" ensure >/dev/null

trim() {
  local val="$1"
  val="${val#"${val%%[![:space:]]*}"}"
  val="${val%"${val##*[![:space:]]}"}"
  printf "%s" "$val"
}

get_store_id() {
  local name="$1"
  local output line store_name store_id
  output=$(wrangler secrets-store store list --remote)
  while IFS= read -r line; do
    [[ "$line" != *"│"* ]] && continue
    store_name="$(trim "$(echo "$line" | awk -F '│' '{print $2}')")"
    store_id="$(trim "$(echo "$line" | awk -F '│' '{print $3}')")"
    if [[ "$store_name" == "$name" && -n "$store_id" && "$store_id" != "ID" ]]; then
      echo "$store_id"
      return 0
    fi
  done <<< "$output"
  return 1
}

declare -A EXISTING_SECRET_IDS=()
load_existing_secrets() {
  local output line name id
  output=$(wrangler secrets-store secret list "$STORE_ID" --remote --per-page 100)
  while IFS= read -r line; do
    [[ "$line" != *"│"* ]] && continue
    name="$(trim "$(echo "$line" | awk -F '│' '{print $2}')")"
    id="$(trim "$(echo "$line" | awk -F '│' '{print $3}')")"
    if [[ -n "$name" && -n "$id" && "$name" != "Name" && "$id" != "ID" ]]; then
      EXISTING_SECRET_IDS["$name"]="$id"
    fi
  done <<< "$output"
}

declare -a MAPPINGS=()
if [[ -n "$FIELD_REGEX" ]]; then
  items_json=$("$BW_AGENT" list)
  while IFS=$'\t' read -r item field; do
    [[ -z "$item" || -z "$field" ]] && continue
    MAPPINGS+=("${item}"$'\t'"${field}"$'\t'"${field}"$'\t'"${SCOPES}"$'\t'""")
  done < <(echo "$items_json" | jq -r --arg re "$FIELD_REGEX" --arg item_re "$ITEM_REGEX" '
    .[] | select(.name | test($item_re; "i"))
    | . as $item
    | ($item.fields // [])[]? | select(test($re; "i"))
    | [$item.name, .] | @tsv
  ')
else
  if [[ -f "$CONFIG_FILE" ]]; then
    if [[ "$STORE_NAME_SET" -eq 0 ]]; then
      config_store_name=$(jq -r '.store_name // empty' "$CONFIG_FILE")
      if [[ -n "$config_store_name" ]]; then
        STORE_NAME="$config_store_name"
      fi
    fi
    if [[ "$SCOPES_SET" -eq 0 ]]; then
      config_scopes=$(jq -r '.scopes // [] | join(",")' "$CONFIG_FILE")
      if [[ -n "$config_scopes" ]]; then
        SCOPES="$config_scopes"
      fi
    fi
  fi
  while IFS=$'\t' read -r item field name scopes comment; do
    [[ -z "$item" || -z "$field" ]] && continue
    name="${name:-$field}"
    scopes="${scopes:-$SCOPES}"
    MAPPINGS+=("${item}"$'\t'"${field}"$'\t'"${name}"$'\t'"${scopes}"$'\t'"${comment}")
  done < <(jq -r '.secrets[] | [.item, .field, (.name // .field), ((.scopes // []) | join(",")), (.comment // "")] | @tsv' "$CONFIG_FILE")
fi

if [[ "${#MAPPINGS[@]}" -eq 0 ]]; then
  echo "No matching Bitwarden fields found." >&2
  exit 1
fi

if [[ "$MODE" == "secrets-store" ]]; then
  if [[ -z "$STORE_ID" ]]; then
    STORE_ID="$(get_store_id "$STORE_NAME" || true)"
  fi
  if [[ -z "$STORE_ID" ]]; then
    echo "Secrets Store id not found. Use --store-id or create a store." >&2
    exit 1
  fi
  load_existing_secrets
fi

apply_secret() {
  local name="$1"
  local value="$2"
  local scopes="$3"
  local comment="$4"

  if [[ "$MODE" == "worker" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[dry-run] worker secret put ${name}"
      return 0
    fi
    printf "%s" "$value" | wrangler secret put "$name" --cwd "$WORKER_CWD" >/dev/null
    echo "worker: updated ${name}"
    return 0
  fi

  local secret_id="${EXISTING_SECRET_IDS[$name]:-}"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ -n "$secret_id" ]]; then
      echo "[dry-run] secrets-store update ${name}"
    else
      echo "[dry-run] secrets-store create ${name}"
    fi
    return 0
  fi

  if [[ -n "$secret_id" ]]; then
    wrangler secrets-store secret update "$STORE_ID" \
      --secret-id "$secret_id" \
      --value "$value" \
      --scopes "$scopes" \
      --comment "$comment" \
      --remote >/dev/null
    echo "secrets-store: updated ${name}"
  else
    wrangler secrets-store secret create "$STORE_ID" \
      --name "$name" \
      --value "$value" \
      --scopes "$scopes" \
      --comment "$comment" \
      --remote >/dev/null
    echo "secrets-store: created ${name}"
  fi
}

if [[ "$ALLOW_PLAIN" -eq 1 ]]; then
  set +o history 2>/dev/null || true
fi

for entry in "${MAPPINGS[@]}"; do
  IFS=$'\t' read -r item field name scopes comment <<< "$entry"
  value="$("$BW_AGENT" get-field "$item" "$field" || true)"
  if [[ -z "$value" ]]; then
    echo "skip: ${item} :: ${field} (empty)"
    continue
  fi
  apply_secret "$name" "$value" "$scopes" "$comment"
done

echo "Sync complete."
