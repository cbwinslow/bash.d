#!/usr/bin/env bash
# agent helper functions to call agent_runner
set -euo pipefail

_agent_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# bf_agent_run <agent-name> [--exec] [args...]
bf_agent_run() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: bf_agent_run <agent-name> [--exec] [args...]" >&2; return 2
  fi
  local agent="$1"; shift
  "$_agent_dir/agent_runner.sh" "$agent" "$@"
}

# bf_agent_list - list agents from manifest
bf_agent_list() {
  jq -r '.agents[]?.name + " - " + (.agents[]?.desc // "")' "$_agent_dir/manifest.json" 2>/dev/null || jq -r '.agents[]?.name' "$_agent_dir/manifest.json" 2>/dev/null || true
}

