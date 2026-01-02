#!/usr/bin/env bash
# path_manager.sh - manage PATH entries for bash_functions.d
# Usage:
#   path_manager.sh add <dir>
#   path_manager.sh remove <dir>
#   path_manager.sh list

set -euo pipefail
cmd=${1:-help}; shift || true
BASE="$HOME/.bash_functions.d/bin"
mkdir -p "$BASE"

usage(){
  cat <<EOF
path_manager.sh - manage PATH entries for bash functions

Commands:
  add <dir>     add directory to PATH (in ~/.bash_functions.d/path.env)
  remove <dir>  remove directory from PATH
  list          list current managed PATH entries
  help
EOF
}

PATH_FILE="$HOME/.bash_functions.d/path.env"

read_list(){
  [[ -f "$PATH_FILE" ]] || { echo ""; return 0; }
  cat "$PATH_FILE"
}

write_list(){
  printf "%s\n" "$@" > "$PATH_FILE"
}

case "$cmd" in
  add)
    d="$1"
    if [[ -z "$d" ]]; then echo "dir required"; exit 2; fi
    cur=$(read_list)
    if echo "$cur" | grep -Fxq "$d"; then echo "already present"; exit 0; fi
    write_list $(echo -e "$cur\n$d" | sed '/^$/d')
    echo "Added $d"
    ;;
  remove)
    d="$1"
    if [[ -z "$d" ]]; then echo "dir required"; exit 2; fi
    cur=$(read_list)
    new=$(echo "$cur" | awk -v rm="$d" '$0!=rm')
    printf "%s\n" "$new" > "$PATH_FILE"
    echo "Removed $d"
    ;;
  list)
    read_list
    ;;
  *) usage; exit 0;;
esac

