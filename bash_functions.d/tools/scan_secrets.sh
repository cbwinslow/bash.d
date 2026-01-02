#!/usr/bin/env bash
# scan_secrets.sh - reusable secrets scanner for pre-commit or CI
set -euo pipefail
ROOT=${1:-$PWD}
OUT=${2:-$HOME/.bash_functions.d/deploy_scan_report.txt}

echo "Running secrets scan on $ROOT -> $OUT"
rm -f "$OUT"

# patterns (simpler tokens for file-scoped scanning)
patterns=(
  "AKIA[0-9A-Z]{16}"
  "ASIA[0-9A-Z]{16}"
  "A3T[A-Z0-9]{16}"
  "AIza[0-9A-Za-z_-]{35}"
  "aws_secret_access_key"
  "secret[_-]?(key|token|access|)"
  "-----BEGIN (RSA |OPENSSH |)PRIVATE KEY-----"
  "password\s*[:=]"
  "api[_-]?key\s*[:=]"
  "client_secret"
  "oauth[_-]?token"
)

found=0

# helper to scan a single file
scan_file() {
  local f="$1"
  # skip binary files
  if file --brief --mime-type "$f" 2>/dev/null | grep -q 'binary'; then
    return 0
  fi
  for pat in "${patterns[@]}"; do
    # use grep -n to show matches; use -E for ERE
    if grep -En --binary-files=without-match -e "$pat" "$f" >/dev/null 2>&1; then
      echo "Potential secrets in $f for pattern: $pat" >> "$OUT"
      grep -En --binary-files=without-match -e "$pat" "$f" >> "$OUT" 2>/dev/null || true
      found=1
    fi
  done
}

if [[ "$ROOT" == "-" ]]; then
  # read file paths from stdin
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    if [[ -f "$file" ]]; then
      scan_file "$file"
    fi
  done
else
  # scan whole directory recursively
  if [[ ! -d "$ROOT" ]]; then
    echo "Path not found: $ROOT" >&2
    exit 2
  fi
  # find text files and scan
  while IFS= read -r -d '' f; do
    scan_file "$f"
  done < <(find "$ROOT" -type f \( -iname "*.sh" -o -iname "*.env*" -o -iname "*.yaml" -o -iname "*.yml" -o -iname "*.json" -o -iname "*.py" -o -iname "*.go" -o -iname "*.rb" -o -iname "*.js" -o -iname "*.ts" \) -print0)
fi

if [[ -s "$OUT" ]]; then
  echo "Potential secrets found; report written to $OUT"
  exit 1
else
  echo "No obvious secrets found"
  rm -f "$OUT" || true
  exit 0
fi
