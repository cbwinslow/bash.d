#!/usr/bin/env bash
# Generate bash completion for bf_agent_run listing agents from manifest
set -euo pipefail

_manifest="$(dirname -- "${BASH_SOURCE[0]}")/../40-agents/manifest.json"
_out="$(dirname -- "${BASH_SOURCE[0]}")/agent_completion.sh"

mkdir -p "$(dirname -- "${_out}")"

cat >"${_out}" <<'BASH'
# bash completion for bf_agent_run
_bf_agent_run_completion() {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "__AGENT_LIST__" -- "$cur") )
    return 0
  fi
}
complete -F _bf_agent_run_completion bf_agent_run bfagent
BASH

# build agent list
_agents=$(jq -r '.agents[]?.name, .crews[]?.name' "$_manifest" 2>/dev/null | tr '\n' ' ')
# replace placeholder
sed -i "s/__AGENT_LIST__/${_agents}/g" "${_out}"

echo "Wrote ${_out}"

