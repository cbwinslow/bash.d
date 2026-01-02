#!/usr/bin/env bash
# Basic environment exports and PATH adjustments for bash functions
set -euo pipefail

# Add local bin to PATH if present
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# default editor
export EDITOR="${EDITOR:-vim}"

# safe umask for created files
umask 077

