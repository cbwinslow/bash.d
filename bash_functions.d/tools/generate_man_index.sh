#!/usr/bin/env bash
# generate_man_index.sh - scan bash_functions.d and generate docs/man/*.md files from top-of-file comments
set -euo pipefail
BASEDIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
OUTDIR="$BASEDIR/docs/man"
mkdir -p "$OUTDIR"

# Find scripts (shell scripts and .sh) under basedir (exclude docs dir)
find "$BASEDIR" -maxdepth 3 -type f \( -name "*.sh" -o -perm /u=x -o -name "*" \) -print0 | while IFS= read -r -d '' f; do
  # skip within docs
  case "$f" in
    */docs/*) continue;;
  esac
  # only consider files that look like scripts (shebang or .sh)
  if ! grep -qE "^#!" "$f" 2>/dev/null && [[ "${f##*.}" != "sh" ]]; then
    continue
  fi
  name="$(basename "$f")"
  out="$OUTDIR/${name}.md"
  echo "Generating doc for $f -> $out"
  # extract header comment block
  awk 'NR==1{if($0~/^#!/){next}} { if($0 ~ /^#/ || $0 ~ /^\/\//) { gsub(/^# ?|^\/\//, ""); print; } else { if(NR>1) exit } }' "$f" > "$out"
  # add metadata header
  title="${name}"
  tmp=$(mktemp)
  echo "---" > "$tmp"
  echo "title: $title" >> "$tmp"
  echo "---" >> "$tmp"
  cat "$out" >> "$tmp"
  mv "$tmp" "$out"
done
