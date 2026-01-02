#!/usr/bin/env bash
# autocorrect_system.sh - autocorrect issues in bash_functions.d system
set -euo pipefail

BASEDIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && cd .. && pwd -P)"
echo "Autocorrecting bash_functions.d system in $BASEDIR"

# Create missing directories
echo "Ensuring directories exist..."
dirs=("core" "tools" "completions" "docs" "plugins" "tui")
for d in "${dirs[@]}"; do
  mkdir -p "$BASEDIR/$d"
done
echo "✓ Directories created"

# Fix executable permissions
echo "Fixing executable permissions..."
execs=(
  "core/load_ordered.sh"
  "tools/bf_docs.sh"
  "tools/deploy_to_github.sh"
  "tools/scan_secrets.sh"
  "tools/doc_verifier.sh"
  "tools/install_precommit_hook.sh"
  "tools/validate_system.sh"
  "tools/autocorrect_system.sh"
)
for e in "${execs[@]}"; do
  if [[ -f "$BASEDIR/$e" ]]; then
    chmod +x "$BASEDIR/$e"
  fi
done
echo "✓ Permissions fixed"

# Regenerate docs if missing
echo "Regenerating docs..."
"$BASEDIR/tools/generate_man_index.sh" >/dev/null 2>&1 || echo "Docs generation failed, but continuing"
echo "✓ Docs regenerated"

# Regenerate plugin env
echo "Regenerating plugin environment..."
if [[ -x "$BASEDIR/core/plugin_manager.sh" ]]; then
  "$BASEDIR/core/plugin_manager.sh" regen >/dev/null 2>&1 || echo "Plugin regen failed, but continuing"
fi
echo "✓ Plugin env regenerated"

# Handle specific tool reinstalls (e.g., OpenCode)
echo "Checking for missing AI agents/tools..."
# Check if OpenCode is missing or broken
if ! command -v opencode >/dev/null 2>&1; then
  echo "OpenCode not found, attempting local install with npx..."
  if command -v npx >/dev/null 2>&1; then
    # Install locally in a node_modules or specific dir
    mkdir -p "$BASEDIR/tools/node_modules"
    cd "$BASEDIR/tools"
    if npx @open-code/opencode --version >/dev/null 2>&1; then
      echo "✓ OpenCode installed locally"
      # Add to PATH if needed
      if [[ -x "$BASEDIR/core/path_manager.sh" ]]; then
        "$BASEDIR/core/path_manager.sh" add "$BASEDIR/tools/node_modules/.bin" >/dev/null 2>&1 || true
      fi
    else
      echo "WARNING: OpenCode install failed, may need manual intervention"
    fi
  else
    echo "WARNING: npx not available, cannot install OpenCode"
  fi
else
  echo "✓ OpenCode already available"
fi

# Check other common tools (add more as needed)
# Example: check for bw (Bitwarden CLI)
if ! command -v bw >/dev/null 2>&1; then
  echo "Bitwarden CLI not found, attempting install..."
  # Assume package manager available
  if command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y bw || echo "bw install failed"
  elif command -v brew >/dev/null 2>&1; then
    brew install bitwarden-cli || echo "bw install failed"
  else
    echo "WARNING: No supported package manager for bw"
  fi
fi

# Re-run validation
echo "Re-running validation..."
if "$BASEDIR/tools/validate_system.sh" >/dev/null 2>&1; then
  echo "✓ Autocorrect successful: System validated"
else
  echo "WARNING: Some issues remain after autocorrect"
fi

