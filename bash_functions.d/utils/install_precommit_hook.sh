HOOK
#!/usr/bin/env bash
# pre-commit hook: verify docs and scan staged files for secrets
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel)
BFD="$HOME/.bash_functions.d"
REPORT="$BFD/deploy_scan_report.txt"

# Run doc verifier if available (full repo check)
if [[ -x "$BFD/tools/doc_verifier.sh" ]]; then
  echo "Running documentation verifier..."
  "$BFD/tools/doc_verifier.sh" || { echo "Documentation verifier failed"; exit 1; }
fi

# Gather staged files (only name-only) and scan them if any
STAGED=$(git diff --name-only --cached --diff-filter=ACM)
if [[ -n "$STAGED" ]]; then
  echo "Scanning staged files for secrets..."
  # send list to scanner via stdin
  printf "%s\n" $STAGED | "$BFD/tools/scan_secrets.sh" - "$REPORT" || { echo "Secrets scan found issues; see $REPORT"; exit 2; }
else
  echo "No staged files to scan for secrets"
fi

exit 0
HOOK
