#!/usr/bin/env bash
# Create a Cloudflare API token with Workers deploy permissions.
# Requires an existing auth method that can create tokens (API Tokens:Edit or Global API Key).

set -euo pipefail

NAME="bashd-workers-token"
ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-${CF_ACCOUNT_ID:-}}"
OUTPUT="${HOME}/.bash_secrets.d/cloudflare/api_token.txt"
PRINT_TOKEN=0
ENV_FILE=""
declare -a PERMISSIONS
PERMISSIONS=(
  "Account:Read"
  "Workers Scripts:Edit"
)

usage() {
  cat <<'EOF'
Usage: scripts/create_cloudflare_api_token.sh [options]

Options:
  --name <name>              Token name (default: bashd-workers-token)
  --account-id <id>          Restrict to a Cloudflare account id
  --output <path>            File path to write token (default: ~/.bash_secrets.d/cloudflare/api_token.txt)
  --print                    Print the token to stdout (unsafe)
  --env-file <path>          Source env vars from file (e.g., ~/.env)
  --with-kv                  Add Workers KV Storage:Edit permission
  --with-tail                Add Workers Tail:Read permission
  --permission <name>        Add an extra permission group (repeatable)
  -h, --help                 Show this help

Auth (required):
  - CLOUDFLARE_API_TOKEN or CF_API_TOKEN
  - OR CLOUDFLARE_API_KEY/CF_API_KEY + CLOUDFLARE_EMAIL/CF_EMAIL
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      NAME="$2"
      shift 2
      ;;
    --account-id)
      ACCOUNT_ID="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --print)
      PRINT_TOKEN=1
      shift
      ;;
    --env-file)
      ENV_FILE="$2"
      shift 2
      ;;
    --with-kv)
      PERMISSIONS+=("Workers KV Storage:Edit")
      shift
      ;;
    --with-tail)
      PERMISSIONS+=("Workers Tail:Read")
      shift
      ;;
    --permission)
      PERMISSIONS+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -n "$ENV_FILE" ]]; then
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Env file not found: $ENV_FILE" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

AUTH_HEADERS=()
if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  AUTH_HEADERS+=("-H" "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}")
elif [[ -n "${CF_API_TOKEN:-}" ]]; then
  AUTH_HEADERS+=("-H" "Authorization: Bearer ${CF_API_TOKEN}")
elif [[ -n "${CLOUDFLARE_API_KEY:-}" && -n "${CLOUDFLARE_EMAIL:-}" ]]; then
  AUTH_HEADERS+=("-H" "X-Auth-Key: ${CLOUDFLARE_API_KEY}")
  AUTH_HEADERS+=("-H" "X-Auth-Email: ${CLOUDFLARE_EMAIL}")
elif [[ -n "${CF_API_KEY:-}" && -n "${CF_EMAIL:-}" ]]; then
  AUTH_HEADERS+=("-H" "X-Auth-Key: ${CF_API_KEY}")
  AUTH_HEADERS+=("-H" "X-Auth-Email: ${CF_EMAIL}")
else
  echo "Missing Cloudflare auth env vars (API token or global API key)." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

perm_json=$(curl -sS -X GET "https://api.cloudflare.com/client/v4/user/tokens/permission_groups" \
  -H "content-type: application/json" \
  "${AUTH_HEADERS[@]}")

if [[ "$(echo "$perm_json" | jq -r '.success')" != "true" ]]; then
  echo "Failed to list permission groups." >&2
  echo "$perm_json" | jq -r '.errors[]?.message' >&2 || true
  exit 1
fi

perm_ids=()
missing=()
for perm in "${PERMISSIONS[@]}"; do
  id=$(echo "$perm_json" | jq -r --arg name "$perm" '.result[] | select(.name == $name) | .id' | head -n 1)
  if [[ -z "$id" || "$id" == "null" ]]; then
    missing+=("$perm")
  else
    perm_ids+=("$id")
  fi
done

if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "Missing permission group(s): ${missing[*]}" >&2
  exit 1
fi

resources_json='{"com.cloudflare.api.account.*":"*"}'
if [[ -n "$ACCOUNT_ID" ]]; then
  resources_json=$(jq -cn --arg id "$ACCOUNT_ID" '{"com.cloudflare.api.account."+ $id : "*"}')
fi

payload=$(jq -cn \
  --arg name "$NAME" \
  --argjson resources "$resources_json" \
  --argjson perms "$(printf '%s\n' "${perm_ids[@]}" | jq -R . | jq -s 'map({id: .})')" \
  '{
    name: $name,
    policies: [
      {
        permission_groups: $perms,
        resources: $resources
      }
    ],
    condition: {}
  }')

resp=$(curl -sS -X POST "https://api.cloudflare.com/client/v4/user/tokens" \
  -H "content-type: application/json" \
  "${AUTH_HEADERS[@]}" \
  --data "$payload")

if [[ "$(echo "$resp" | jq -r '.success')" != "true" ]]; then
  echo "Token creation failed." >&2
  echo "$resp" | jq -r '.errors[]?.message' >&2 || true
  exit 1
fi

token_value=$(echo "$resp" | jq -r '.result.value')
token_id=$(echo "$resp" | jq -r '.result.id')

if [[ -z "$token_value" || "$token_value" == "null" ]]; then
  echo "Token created but no value returned. It may have already been displayed once." >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"
umask 077
printf "%s" "$token_value" > "$OUTPUT"
chmod 600 "$OUTPUT" 2>/dev/null || true

if [[ "$PRINT_TOKEN" -eq 1 ]]; then
  printf "%s\n" "$token_value"
else
  echo "Token saved to $OUTPUT"
  echo "Token id: $token_id"
  echo "Token name: $NAME"
fi
