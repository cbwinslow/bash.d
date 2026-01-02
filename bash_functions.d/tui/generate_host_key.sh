#!/usr/bin/env bash
# Generate an SSH host key for the Wish server (ed25519 recommended)
set -euo pipefail

OUT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
OUT="$OUT_DIR/host_key"

if [[ -f "$OUT" ]]; then
  echo "Host key already exists at $OUT"
  exit 0
fi

ssh-keygen -t ed25519 -f "$OUT" -N "" -C "wish-host-key" || {
  echo "ssh-keygen failed" >&2; exit 2
}

chmod 600 "$OUT"
chmod 600 "$OUT.pub"

echo "Generated host key: $OUT"
