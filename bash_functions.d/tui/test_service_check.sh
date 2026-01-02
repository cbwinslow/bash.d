#!/usr/bin/env bash
set -euo pipefail

UNIT=${1:-wish-server.service}

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl not available on this host; cannot check service"
  exit 2
fi

echo "Checking status of $UNIT"
sudo systemctl status "$UNIT" --no-pager || true
sudo journalctl -u "$UNIT" -n 50 --no-pager || true

