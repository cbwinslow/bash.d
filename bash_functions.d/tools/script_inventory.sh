#!/usr/bin/env bash
# script_inventory.sh - build an inventory of scripts under bash_functions.d
# outputs JSON with path, description (first header paragraph), executable flag

set -euo pipefail
ROOT=${1:-$HOME/.bash_functions.d}
OUT=${2:-$ROOT/script_inventory.json}
TMP=${TMPDIR:-/tmp}/bashd-script-inventory.$$.
items_tmp="${TMP}items.jsonl"

rm -f "$items_tmp"
mkdir -p "$(dirname "$OUT")"

while IFS= read -r -d '' f; do
  rel=${f#${ROOT}/}
  exe=false
  [[ -x "$f" ]] && exe=true
  # extract header comment paragraph
  header=$(awk 'NR==1{if($0~/^#!/){next}} { if($0 ~ /^#/ || $0 ~ /^\/\//) { gsub(/^# ?|^\/\//, ""); print } else { if(NR>1) exit } }' "$f" | sed -n '1,40p' | awk 'BEGIN{ORS="\\n"} NR==1{print $0; next} {print $0} ' | sed '/^$/q')
  jq -n --arg path "$rel" --argjson executable "$exe" --arg desc "$header" \
    '{path:$path,executable:$executable,description:$desc}' >> "$items_tmp"
done < <(find "$ROOT" -type f -name "*.sh" -print0)

# combine into JSON array
jq -s '{scripts: .}' "$items_tmp" > "$OUT"
rm -f "$items_tmp"

echo "Wrote inventory to $OUT"
