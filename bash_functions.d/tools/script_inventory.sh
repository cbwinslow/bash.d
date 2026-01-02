#!/usr/bin/env bash
# script_inventory.sh - build an inventory of scripts under bash_functions.d
# outputs JSON with path, description (first header paragraph), executable flag

set -euo pipefail
ROOT=${1:-$HOME/.bash_functions.d}
OUT=${2:-$ROOT/script_inventory.json}

jq_init='{}'

items=()

while IFS= read -r -d '' f; do
  rel=${f#${ROOT}/}
  exe=0
  [[ -x "$f" ]] && exe=1
  # extract header comment paragraph
  header=$(awk 'NR==1{if($0~/^#!/){next}} { if($0 ~ /^#/ || $0 ~ /^\/\//) { gsub(/^# ?|^\/\//, ""); print } else { if(NR>1) exit } }' "$f" | sed -n '1,40p' | awk 'BEGIN{ORS="\\n"} NR==1{print $0; next} {print $0} ' | sed '/^$/q')
  items+=("$(jq -n --arg path "$rel" --arg exe "$exe" --arg desc "$header" '{path:$path,executable:($exe|test("1")),description:$desc}')")
done < <(find "$ROOT" -type f -name "*.sh" -print0)

# combine into JSON array
jq -n --argjson items "[${items[*]}]" '{scripts:$items}' > "$OUT" || true

echo "Wrote inventory to $OUT"

