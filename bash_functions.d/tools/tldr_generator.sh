#!/usr/bin/env bash
# tldr_generator.sh - generate a short TLDR summary (first paragraph) for each script's header

set -euo pipefail
ROOT=${1:-$HOME/.bash_functions.d}
OUTDIR=${2:-$ROOT/docs/tldr}
mkdir -p "$OUTDIR"

while IFS= read -r -d '' f; do
  rel=${f#"$ROOT"/}
  out="$OUTDIR/$rel.tldr"
  mkdir -p "$(dirname "$out")"
  tldr=$(awk 'NR==1{if($0~/^#!/){next}} { if($0 ~ /^#/ || $0 ~ /^\/\//) { gsub(/^# ?|^\/\//, ""); print } else { if(NR>1) exit}}' "$f" | sed -n '1,40p' | awk 'BEGIN{RS=""} {gsub("\n"," "); print; exit}')
  printf "%s\n" "$tldr" > "$out"
done < <(find "$ROOT" -type f -name "*.sh" -print0)

echo "Wrote TLDR files to $OUTDIR"
