#!/usr/bin/env bash
# Fuzzy helpers used by bw helpers - uses python fallback for fuzzy scoring

set -euo pipefail

# Score candidates using difflib SequenceMatcher via python to avoid external deps
fuzzy_rank() {
  # fuzzy_rank <needle> <candidates-file> - prints top matches (score TAB candidate)
  local needle file
  needle="$1"; file="$2"
  python3 - "$needle" "$file" <<'PY'
import sys,difflib
needle=sys.argv[1]
file=sys.argv[2]
with open(file) as f:
    cand=[l.strip() for l in f if l.strip()]
scores=[(difflib.SequenceMatcher(None, needle.lower(), c.lower()).ratio(), c) for c in cand]
for s,c in sorted(scores, key=lambda x:-x[0])[:20]:
    print(f"{s:.4f}\t{c}")
PY
}
