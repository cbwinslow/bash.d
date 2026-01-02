#!/usr/bin/env bash
# Bitwarden helpers for bw CLI: session handling, fuzzy find, field access, .env builder
# Safe by default: temp files are 600 perms and secrets are not printed unless requested

set -euo pipefail

# ...existing code...

_bw_log() { printf '[bw_helpers] %s\n' "$*" >&2; }

bw_ensure_session() {
  # Ensure BW_SESSION env var is set; if not, try to unlock interactively
  if [[ -n "${BW_SESSION:-}" ]]; then
    _bw_log "BW_SESSION already set"
    return 0
  fi
  if ! command -v bw >/dev/null 2>&1; then
    _bw_log "bw CLI not found; please install Bitwarden CLI"
    return 1
  fi
  _bw_log "Attempting to unlock Bitwarden (interactive)..."
  # Try to unlock; user will be prompted for master password
  # We export raw token for current shell
  local token
  if token=$(bw unlock --raw 2>/dev/null); then
    export BW_SESSION="$token"
    _bw_log "BW_SESSION exported"
    return 0
  fi
  _bw_log "bw unlock failed; try 'bw login' or set BW_SESSION manually"
  return 2
}

bw_find_item() {
  # bw_find_item <query> - prints JSON array of matching items (id,name)
  local query
  query="$*"
  if [[ -z "$query" ]]; then
    echo "[]"
    return 0
  fi
  bw_ensure_session || return 1
  # Use bw list items --search for fast direct matches, fallback to list and grep
  if bw list items --search "$query" >/dev/null 2>&1; then
    bw list items --search "$query" | jq -c '.[] | {id: .id, name: .name, notes: .notes, fields: .fields}'
  else
    bw list items | jq -c --arg q "$query" '.[] | select(.name | test($q; "i")) | {id: .id, name: .name, notes: .notes, fields: .fields}'
  fi
}

bw_get_field() {
  # bw_get_field <item-id> <field-name>
  local id field
  id="$1"; field="$2"
  bw_ensure_session || return 1
  # Query item and extract field
  bw get item "$id" | jq -r --arg f "$field" '.fields[]? | select(.name == $f) | .value' 2>/dev/null || true
}

bw_get_password() {
  # bw_get_password <item-id>
  local id
  id="$1"
  bw_ensure_session || return 1
  bw get password "$id" 2>/dev/null || true
}

bw_build_env() {
  # bw_build_env --pattern PATTERN --out FILE
  local pattern="" out="" interactive=0
  while (("$#")); do
    case "$1" in
      --pattern) pattern="$2"; shift 2;;
      --out) out="$2"; shift 2;;
      --interactive) interactive=1; shift;;
      --help) echo "Usage: bw_build_env --pattern PATTERN --out FILE [--interactive]"; return 0;;
      *) pattern="$1"; shift;;
    esac
  done
  if [[ -z "$pattern" || -z "$out" ]]; then
    _bw_log "pattern and out required"; return 2
  fi
  bw_ensure_session || return 1
  local tmp
  tmp=$(mktemp)
  chmod 600 "$tmp"
  # Find candidate items whose name or fields match the pattern
  local matches
  matches=$(bw list items | jq -r --arg p "$pattern" '.[] | select((.name | test($p; "i")) or (.fields[]?.name? | test($p; "i")) ) | @base64')
  if [[ -z "$matches" ]]; then
    _bw_log "No items matched pattern $pattern"
    return 0
  fi
  # For each matched item, try to extract conventional env fields
  while IFS= read -r m; do
    local id name
    id=$(echo "$m" | base64 --decode | jq -r '.id')
    name=$(echo "$m" | base64 --decode | jq -r '.name')
    # common env field names
    local keys=("PASSWORD" "API_KEY" "TOKEN" "USERNAME" "HOST" "URL" "DB" "DATABASE" "PORT")
    for k in "${keys[@]}"; do
      local v
      v=$(bw_get_field "$id" "$k" || true)
      if [[ -n "$v" && "$v" != "null" ]]; then
        echo "${name}_${k}=$v" >>"$tmp"
      fi
    done
    # fallback: try password endpoint
    local pw
    pw=$(bw_get_password "$id" || true)
    if [[ -n "$pw" && "$pw" != "null" ]]; then
      echo "${name}_PASSWORD=$pw" >>"$tmp"
    fi
  done <<<"$matches"
  # Move temp to out atomically
  mv "$tmp" "$out"
  chmod 600 "$out"
  _bw_log "Wrote env to $out (600)"
  if [[ $interactive -eq 1 ]]; then
    _bw_log "Contents:"; sed -n '1,200p' "$out"
  fi
}

# ...existing code...

