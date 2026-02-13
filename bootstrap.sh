#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET="${BASHD_HOME:-$HOME/.bash.d}"
mkdir -p "$TARGET"

rsync -av --exclude '.git' --exclude '.gitignore' --exclude 'README.md' "$REPO_ROOT/" "$TARGET/"


  cat <<'RC' >> "$HOME/.bashrc"
# bashd_home bootstrap
if [[ -f "$HOME/.bash.d/config/bashrc-variants/bashrc.main" ]]; then
  source "$HOME/.bash.d/config/bashrc-variants/bashrc.main"
fi
RC
fi

echo "bash.d installed to $TARGET"
echo "Open a new shell to load the profile."
