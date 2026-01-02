#!/usr/bin/env bash
# bf_docs.sh - lookup and show docs for bash_functions.d scripts
# Usage:
#   bf_docs.sh index          # generate docs index from script header comments
#   bf_docs.sh lookup <term>  # fuzzy search scripts and show matches
#   bf_docs.sh tldr <script>  # show short summary (first paragraph of header)
#   bf_docs.sh man <script>   # show full header doc (man page if generated)

set -euo pipefail
BASEDIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
MAN_DIR="$BASEDIR/docs/man"
GENERATOR="$BASEDIR/generate_man_index.sh"

usage() {
  cat <<EOF
bf_docs.sh - docs lookup for bash_functions.d

Commands:
  index           generate the docs index from file headers (writes to $MAN_DIR)
  lookup <term>   fuzzy search across script names and header summaries
  tldr <script>   show first paragraph of header comment for <script>
  man <script>    show full header comment or generated man page for <script>
  help            show this help
EOF
}

extract_header() {
  # read top comment block (skip shebang)
  local file="$1"
  awk 'BEGIN{skip_shebang=1} NR==1{if($0~/^#!/) {skip_shebang=0; next}} { if($0 ~ /^#/ || $0 ~ /^\/\//) { gsub(/^# ?|^\/\//, ""); print; } else { if(NR>1) exit } }' "$file"
}

cmd=${1:-help}; shift || true
case "$cmd" in
  index)
    if [[ ! -x "$GENERATOR" ]]; then
      echo "Generator not found or not executable: $GENERATOR" >&2
      echo "Make sure generate_man_index.sh exists in $BASEDIR and is executable." >&2
      exit 2
    fi
    "$GENERATOR"
    ;;
  lookup)
    if [[ $# -lt 1 ]]; then echo "usage: bf_docs.sh lookup <term>"; exit 2; fi
    term="$*"
    # search man dir first
    if [[ -d "$MAN_DIR" ]]; then
      grep -Ri --line-number --exclude-dir=.git --exclude=*.png -e "$term" "$MAN_DIR" 2>/dev/null || true
    fi
    # fallback: search script headers
    grep -Ri --line-number --exclude-dir=docs -e "$term" "$BASEDIR" 2>/dev/null | sed -n '1,200p' || true
    ;;
  tldr)
    if [[ $# -lt 1 ]]; then echo "usage: bf_docs.sh tldr <script>"; exit 2; fi
    s="$1"
    # try man file
    manfile="$MAN_DIR/$s.md"
    if [[ -f "$manfile" ]]; then
      awk 'NR==1{print;next} /^$/ {exit} {print}' "$manfile"
      exit 0
    fi
    # else search for script path
    file=$(grep -R --exclude-dir=docs -l "$(basename $s)" "$BASEDIR" 2>/dev/null | head -n1 || true)
    if [[ -z "$file" ]]; then echo "Script not found: $s"; exit 2; fi
    extract_header "$file" | awk 'NR==1{print;next} /^$/ {exit} {print}'
    ;;
  man)
    if [[ $# -lt 1 ]]; then echo "usage: bf_docs.sh man <script>"; exit 2; fi
    s="$1"
    manfile="$MAN_DIR/$s.md"
    if [[ -f "$manfile" ]]; then
      cat "$manfile"
      exit 0
    fi
    file=$(grep -R --exclude-dir=docs -l "$(basename $s)" "$BASEDIR" 2>/dev/null | head -n1 || true)
    if [[ -z "$file" ]]; then echo "Script not found: $s"; exit 2; fi
    echo "File: $file"
    echo "---- header ----"
    extract_header "$file"
    echo "---- body (first 200 lines) ----"
    sed -n '1,200p' "$file"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo "Unknown command: $cmd"; usage; exit 2
    ;;
esac

