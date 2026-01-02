#!/usr/bin/env bash
# secrets_tool.sh - small wrapper to lookup secrets via Bitwarden and populate .env templates
# Usage:
#  secrets_tool.sh lookup <name>
#  secrets_tool.sh fill-template template.env.envtpl output.env

set -euo pipefail

cmd=${1:-help}; shift || true

usage() {
  cat <<EOF
secrets_tool.sh - Bitwarden-based secrets mapper

Commands:
  lookup <name>      lookup an entry by name (fuzzy)
  fill-template tpl out  replace placeholders like {{SECRET_NAME}} in tpl with bw values and write to out

EOF
}

bw_lookup() {
  local name="$1"
  if ! command -v bw >/dev/null 2>&1; then echo "bw CLI not installed"; return 2; fi
  if [[ -z "${BW_SESSION:-}" ]]; then echo "No BW_SESSION; attempting interactive unlock"; BW_SESSION=$(bw unlock --raw); export BW_SESSION; fi
  bw list items --search "$name" | jq -r '.[0].name' 2>/dev/null || true
}

fill_template() {
  local tpl="$1"; local out="$2"
  if [[ ! -f "$tpl" ]]; then echo "template not found: $tpl"; return 2; fi
  local content; content=$(cat "$tpl")
  # Find placeholders like {{NAME}} and attempt to replace by lookup
  echo "$content" | sed -E "s/\{\{([A-Za-z0-9_\-]+)\}\}/\\nPLACEHOLDER:\1\\n/g" | while IFS= read -r line; do
    if [[ "$line" =~ ^PLACEHOLDER:(.*) ]]; then
      key=${BASH_REMATCH[1]}
      val=$(bw get password "$key" 2>/dev/null || bw get item "$key" 2>/dev/null || echo "")
      if [[ -n "$val" ]]; then
        content=$(echo "$content" | sed "s/{{${key}}}/$val/g")
      fi
    fi
  done
  printf "%s" "$content" > "$out"
  echo "Wrote $out"
}

case "$cmd" in
  lookup)
    bw_lookup "$1"
    ;;
  fill-template)
    fill_template "$1" "$2"
    ;;
  *)
    usage
    ;;
esac
