#!/usr/bin/env bash
# completion_helpers.sh - helper functions to generate basic bash completion stubs for scripts

# Generate a completion function for a command that uses a simple subcommand list
# Usage: generate_completion mycmd sub1 sub2 sub3 > /etc/bash_completion.d/mycmd

generate_completion() {
  cmd="$1"; shift
  subs=("$@")
  cat <<'EOF'
# bash completion for ${cmd}
_${cmd}_completions()
{
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  opts="${subs}"
  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  return 0
}
complete -F _${cmd}_completions ${cmd}
EOF
}

