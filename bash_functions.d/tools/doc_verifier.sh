#!/usr/bin/env bash
# doc_verifier.sh - verify that each script has a top-of-file documentation header

set -euo pipefail
ROOT=${1:-$HOME/.bash_functions.d}
MISS=()

while IFS= read -r -d '' f; do
  header=$(awk 'NR==1{if($0~/^#!/){next}} { if($0 ~ /^#/ || $0 ~ /^\/\//) { print; } else { if(NR>1) exit}}' "$f" | sed -n '1,20p')
  if [[ -z "$header" ]]; then
    MISS+=("$f")
  fi
done < <(find "$ROOT" -type f -name "*.sh" -print0)

if [[ ${#MISS[@]} -gt 0 ]]; then
  echo "Scripts missing header documentation:";
  for m in "${MISS[@]}"; do echo " - $m"; done
  exit 1
else
  echo "All scripts have header docs."
fi

