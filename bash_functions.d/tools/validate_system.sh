#!/usr/bin/env bash
# validate_system.sh - validate the bash_functions.d system setup
set -euo pipefail

BASEDIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && cd .. && pwd -P)"
echo "Validating bash_functions.d system in $BASEDIR"

# Check directory structure
echo "Checking directory structure..."
dirs=("core" "tools" "completions" "docs" "plugins" "tui")
for d in "${dirs[@]}"; do
  if [[ ! -d "$BASEDIR/$d" ]]; then
    echo "ERROR: Missing directory $d"
    exit 1
  fi
done
echo "✓ Directory structure OK"

# Check key files
echo "Checking key files..."
files=(
  "core/load_ordered.sh"
  "core/aliases.sh"
  "core/functions.sh"
  "tools/bf_docs.sh"
  "tools/deploy_to_github.sh"
  "tools/scan_secrets.sh"
  "tools/doc_verifier.sh"
  "completions/completion_helpers.sh"
  "tui/go-term/cmd/term/main.go"
)
for f in "${files[@]}"; do
  if [[ ! -f "$BASEDIR/$f" ]]; then
    echo "ERROR: Missing file $f"
    exit 1
  fi
done
echo "✓ Key files present"

# Check executables
echo "Checking executable permissions..."
execs=(
  "core/load_ordered.sh"
  "tools/bf_docs.sh"
  "tools/deploy_to_github.sh"
  "tools/scan_secrets.sh"
  "tools/doc_verifier.sh"
  "tools/install_precommit_hook.sh"
)
for e in "${execs[@]}"; do
  if [[ ! -x "$BASEDIR/$e" ]]; then
    echo "ERROR: $e is not executable"
    exit 1
  fi
done
echo "✓ Executables OK"

# Check if loaders can source without error
echo "Testing loaders..."
if ! bash -c "source '$BASEDIR/core/load_ordered.sh' 2>/dev/null"; then
  echo "ERROR: load_ordered.sh failed to source"
  exit 1
fi
echo "✓ Loaders OK"

# Check docs generation
echo "Testing docs generation..."
if ! "$BASEDIR/tools/generate_man_index.sh" >/dev/null 2>&1; then
  echo "ERROR: Docs generation failed"
  exit 1
fi
echo "✓ Docs generation OK"

# Check plugin env
echo "Checking plugin environment..."
if [[ -f "$BASEDIR/plugins/enabled_env.sh" ]]; then
  if ! bash -c "source '$BASEDIR/plugins/enabled_env.sh' 2>/dev/null"; then
    echo "ERROR: enabled_env.sh failed to source"
    exit 1
  fi
  echo "✓ Plugin environment OK"
else
  echo "✓ No plugin environment (none enabled)"
fi

echo "Validation complete: All checks passed!"

