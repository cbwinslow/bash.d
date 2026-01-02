# bash completion for bf_agent_run
_manifest_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)/40-agents"
_manifest="$_manifest_dir/manifest.json"

_bf_agent_run_completion() {
  local cur
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    if [[ -f "$_manifest" ]]; then
      local list arr arr2
      # read agent and crew names into array
      list=$(jq -r '.agents[]?.name, .crews[]?.name' "$_manifest" 2>/dev/null | tr '\n' ' ')
      IFS=' ' read -r -a arr <<< "$list"
      # filter by current word
      mapfile -t arr2 < <(compgen -W "${arr[*]}" -- "$cur")
      COMPREPLY=("${arr2[@]}")
    fi
    return 0
  fi
}
complete -F _bf_agent_run_completion bf_agent_run bfagent
