#!/usr/bin/env bash
# Install loader into user's ~/.bashrc if not present
set -euo pipefail

if grep -F "load_ordered.sh" ~/.bashrc >/dev/null 2>&1; then
  echo "load_ordered.sh already referenced in ~/.bashrc"
  exit 0
fi
{
  echo "# Auto-load personal bash functions"
  echo "if [ -f \"$HOME/bash_functions.d/load_ordered.sh\" ]; then"
  echo "  source \"$HOME/bash_functions.d/load_ordered.sh\""
  echo "fi"
} >>~/.bashrc

echo "Appended loader to ~/.bashrc"

