#!/usr/bin/env bash
# Aliases and completion hooks for bw and gh helpers

set -euo pipefail

# ...existing code...

alias bwenv='bw_build_env'
alias aisecret='python3 ~/bash_functions.d/scripts/ai_replace.py'
alias ghadd='gh_add_and_commit'

# Completion for bw_build_env: suggest patterns based on bw item names
_bf_bw_patterns() {
  # call bw list items and output names
  bw list items 2>/dev/null | jq -r '.[].name' 2>/dev/null || true
}

_bw_build_env_completion() {
  local IFS=$'\n'
  local words
  mapfile -t words < <(_bf_bw_patterns)
  COMPREPLY=( $(compgen -W "${words[*]}" -- "${COMP_WORDS[COMP_CWORD]}") )
}
complete -F _bw_build_env_completion bw_build_env bwenv

# simple completion for gh_add_and_commit path
_gh_path_completion() {
  local cur
  cur="${COMP_WORDS[COMP_CWORD]}"
  local IFS=$'\n'
  local dirs
  mapfile -t dirs < <(compgen -d -- "$cur")
  COMPREPLY=("${dirs[@]}")
}
complete -F _gh_path_completion gh_add_and_commit ghadd

# ...existing code...
