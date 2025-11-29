#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET="${BASHD_HOME:-$HOME/.bash.d}"
mkdir -p "$TARGET"

rsync -av --exclude '.git' --exclude '.gitignore' --exclude 'README.md' "$REPO_ROOT/" "$TARGET/"

if ! grep -q "bashd_home" "$HOME/.bashrc" 2>/dev/null; then
  cat <<'RC' >> "$HOME/.bashrc"
# bash.d bootstrap
if [[ -f "$HOME/.bash.d/bashrc" ]]; then
  source "$HOME/.bash.d/bashrc"
fi
RC
fi

echo "bash.d installed to $TARGET"
echo "Open a new shell to load the profile."
