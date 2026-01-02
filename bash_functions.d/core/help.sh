#!/usr/bin/env bash
# bf_help: list available functions and agents
set -euo pipefail

bf_help() {
  echo "Available bash functions (brief):"
  # list functions that start with bf_ or bw_
  declare -F | awk '{print $3}' | grep -E '^(bf_|bw_|gh_|fsearch|list_open_ports|kill_by_name|svc_restart)' || true
  echo "\nAgents (manifest):"
  if [[ -f "${BASH_SOURCE%/*}/../agents/manifest.json" ]]; then
    jq -r '.agents[]?.name' "${BASH_SOURCE%/*}/../agents/manifest.json" 2>/dev/null || true
  fi
}

