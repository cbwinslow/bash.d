#!/usr/bin/env bash
# Install the sample allowlist into the user's home bash_functions.d location
set -euo pipefail

SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/sample_allowlist.json"
DST="$HOME/.bash_functions.d/tui/wish_allowlist.json"

mkdir -p "$(dirname "$DST")"
if [[ ! -f "$SRC" ]]; then
  echo "sample_allowlist.json not found at $SRC" >&2
  exit 2
fi
cp -v "$SRC" "$DST"
chmod 600 "$DST"
chown "$USER":"$USER" "$DST" 2>/dev/null || true

echo "Installed allowlist to $DST (permissions 600). Edit it to add your public keys."
