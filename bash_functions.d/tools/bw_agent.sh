#!/usr/bin/env bash
# bw_agent.sh - Bitwarden agent-friendly wrapper for non-interactive access
# Usage: bw_agent.sh <command> [args]

set -euo pipefail

DEFAULT_ENV_FILE="$HOME/.bash_secrets.d/bitwarden/bw_agent.env"
DEFAULT_SESSION_FILE="$HOME/.cache/bw-agent/bw_session"

log() { printf '[bw_agent] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

env_file() {
  echo "${BW_AGENT_ENV:-$DEFAULT_ENV_FILE}"
}

session_file() {
  echo "${BW_AGENT_SESSION_FILE:-$DEFAULT_SESSION_FILE}"
}

load_env() {
  local file
  file="$(env_file)"
  if [[ -f "$file" ]]; then
    # shellcheck disable=SC1090
    set -a
    source "$file"
    set +a
  fi
  if [[ -z "${BW_CLIENTID:-}" && -n "${BW_USER_ID:-}" ]]; then
    export BW_CLIENTID="$BW_USER_ID"
  fi
  if [[ -z "${BW_CLIENTSECRET:-}" && -n "${BW_USER_SECRET:-}" ]]; then
    export BW_CLIENTSECRET="$BW_USER_SECRET"
  fi
}

ensure_deps() {
  command -v bw >/dev/null 2>&1 || die "bw CLI not found"
  command -v jq >/dev/null 2>&1 || die "jq not found"
}

load_session() {
  local file
  file="$(session_file)"
  if [[ -z "${BW_SESSION:-}" && -f "$file" ]]; then
    BW_SESSION=$(cat "$file")
    export BW_SESSION
  fi
}

save_session() {
  local token="$1"
  local file dir old_umask
  file="$(session_file)"
  dir="$(dirname "$file")"
  mkdir -p "$dir"
  chmod 700 "$dir" 2>/dev/null || true
  old_umask=$(umask)
  umask 077
  printf '%s' "$token" > "$file"
  umask "$old_umask"
  chmod 600 "$file" 2>/dev/null || true
}

clear_session() {
  local file
  file="$(session_file)"
  rm -f "$file"
  unset BW_SESSION || true
}

bw_cmd() {
  if [[ -n "${BW_SESSION:-}" ]]; then
    bw --session "$BW_SESSION" "$@"
  else
    bw "$@"
  fi
}

bw_status_json() {
  bw status 2>/dev/null || true
}

bw_agent_login() {
  if [[ -n "${BW_SERVER:-}" ]]; then
    bw config server "$BW_SERVER" >/dev/null
  fi
  if [[ -z "${BW_CLIENTID:-}" || -z "${BW_CLIENTSECRET:-}" ]]; then
    die "Missing BW_CLIENTID/BW_CLIENTSECRET (or BW_USER_ID/BW_USER_SECRET)"
  fi
  bw login --apikey >/dev/null
}

bw_agent_unlock() {
  local pass_env=""
  if [[ -n "${BW_PASSWORD:-}" ]]; then
    pass_env="BW_PASSWORD"
  elif [[ -n "${BW_MASTER_PASSWORD:-}" ]]; then
    pass_env="BW_MASTER_PASSWORD"
  elif [[ -n "${BW_AGENT_PASSWORD_ENV:-}" ]]; then
    pass_env="$BW_AGENT_PASSWORD_ENV"
  fi
  if [[ -z "$pass_env" ]]; then
    die "Missing unlock password. Set BW_PASSWORD or BW_MASTER_PASSWORD or BW_AGENT_PASSWORD_ENV"
  fi
  local token
  token=$(bw unlock --raw --passwordenv "$pass_env")
  export BW_SESSION="$token"
  if [[ "${BW_AGENT_NO_SESSION_CACHE:-0}" != "1" ]]; then
    save_session "$token"
  fi
}

bw_agent_ensure_session() {
  load_env
  ensure_deps
  load_session
  local status_json status
  status_json=$(bw_status_json)
  status=$(echo "$status_json" | jq -r '.status // empty')
  case "$status" in
    unlocked)
      return 0
      ;;
    locked)
      bw_agent_unlock
      ;;
    unauthenticated|"")
      bw_agent_login
      bw_agent_unlock
      ;;
    *)
      die "Unknown bw status: $status"
      ;;
  esac
}

resolve_item_id() {
  local query="$1"
  if [[ "$query" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    echo "$query"
    return 0
  fi
  local items count
  items=$(bw_cmd list items --search "$query")
  count=$(echo "$items" | jq 'length')
  if [[ "$count" -eq 0 ]]; then
    die "No items matched '$query'"
  fi
  if [[ "$count" -gt 1 ]]; then
    log "Multiple items matched '$query'; use an item id"
    echo "$items" | jq -r '.[] | "\(.id)  \(.name)"' >&2
    exit 2
  fi
  echo "$items" | jq -r '.[0].id'
}

print_env_example() {
  cat <<'EOF'
# Bitwarden agent env file (do not commit)
# Save to: ~/.bash_secrets.d/bitwarden/bw_agent.env
BW_CLIENTID=your_client_id_here
BW_CLIENTSECRET=your_client_secret_here
BW_PASSWORD=your_master_password_here
# BW_SERVER=https://vault.bitwarden.com
# BW_AGENT_ALLOW_PASSWORD=1
# BW_AGENT_ALLOW_RAW=1
EOF
}

print_usage() {
  cat <<'EOF'
bw_agent.sh - Bitwarden agent-friendly wrapper for non-interactive access

Usage:
  bw_agent.sh env-example
  bw_agent.sh env-check
  bw_agent.sh ensure
  bw_agent.sh status
  bw_agent.sh search <query>
  bw_agent.sh list
  bw_agent.sh get-item <query> [--raw]
  bw_agent.sh get-field <query> <field>
  bw_agent.sh get-password <query>
  bw_agent.sh logout

Env:
  BW_AGENT_ENV                 Optional env file (default: ~/.bash_secrets.d/bitwarden/bw_agent.env)
  BW_AGENT_SESSION_FILE        Optional session cache path
  BW_AGENT_NO_SESSION_CACHE=1  Disable session caching
  BW_AGENT_ALLOW_PASSWORD=1    Allow get-password
  BW_AGENT_ALLOW_RAW=1         Allow get-item --raw
  BW_CLIENTID/BW_CLIENTSECRET  Bitwarden API key
  BW_PASSWORD or BW_MASTER_PASSWORD  Vault unlock password
  BW_USER_ID/BW_USER_SECRET    Aliases for BW_CLIENTID/BW_CLIENTSECRET
  BW_SERVER                    Optional server URL
  BW_AGENT_PASSWORD_ENV        Name of env var holding the password
EOF
}

env_check() {
  load_env
  local file
  file="$(env_file)"
  echo "env_file: $file"
  echo "session_file: $(session_file)"
  echo "BW_CLIENTID set: ${BW_CLIENTID:+yes}"
  echo "BW_CLIENTSECRET set: ${BW_CLIENTSECRET:+yes}"
  echo "BW_PASSWORD set: ${BW_PASSWORD:+yes}"
  echo "BW_MASTER_PASSWORD set: ${BW_MASTER_PASSWORD:+yes}"
  echo "BW_SERVER set: ${BW_SERVER:+yes}"
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  env-example)
    print_env_example
    ;;
  env-check)
    env_check
    ;;
  ensure)
    bw_agent_ensure_session
    bw status
    ;;
  status)
    bw status
    ;;
  search)
    bw_agent_ensure_session
    query="${1:-}"
    [[ -n "$query" ]] || die "search requires a query"
    bw_cmd list items --search "$query" | jq -c '[.[] | {id, name, login: {username: .login.username?}, fields: ([.fields[]?.name] // []), has_notes: ((.notes // "") | length > 0)}]'
    ;;
  list)
    bw_agent_ensure_session
    bw_cmd list items | jq -c '[.[] | {id, name, login: {username: .login.username?}, fields: ([.fields[]?.name] // []), has_notes: ((.notes // "") | length > 0)}]'
    ;;
  get-item)
    bw_agent_ensure_session
    query="${1:-}"
    shift || true
    [[ -n "$query" ]] || die "get-item requires a query or item id"
    raw=0
    if [[ "${1:-}" == "--raw" ]]; then
      raw=1
    fi
    if [[ "$raw" -eq 1 && "${BW_AGENT_ALLOW_RAW:-0}" != "1" ]]; then
      die "Set BW_AGENT_ALLOW_RAW=1 to allow raw item output"
    fi
    id=$(resolve_item_id "$query")
    if [[ "$raw" -eq 1 ]]; then
      bw_cmd get item "$id"
    else
      bw_cmd get item "$id" | jq -c '{id, name, type, login: {username: .login.username?}, fields: ([.fields[]?.name] // []), has_notes: ((.notes // "") | length > 0)}'
    fi
    ;;
  get-field)
    bw_agent_ensure_session
    query="${1:-}"
    field="${2:-}"
    [[ -n "$query" && -n "$field" ]] || die "get-field requires <query> <field>"
    id=$(resolve_item_id "$query")
    bw_cmd get item "$id" | jq -r --arg f "$field" '.fields[]? | select(.name == $f) | .value' || true
    ;;
  get-password)
    bw_agent_ensure_session
    query="${1:-}"
    [[ -n "$query" ]] || die "get-password requires a query or item id"
    if [[ "${BW_AGENT_ALLOW_PASSWORD:-0}" != "1" ]]; then
      die "Set BW_AGENT_ALLOW_PASSWORD=1 to allow password access"
    fi
    id=$(resolve_item_id "$query")
    bw_cmd get password "$id"
    ;;
  logout)
    bw logout || true
    clear_session
    ;;
  help|--help|-h)
    print_usage
    ;;
  *)
    print_usage
    die "Unknown command: $cmd"
    ;;
esac
