#!/usr/bin/env bash
set -euo pipefail

# Run the installer in preview mode to produce /tmp/wish-server.service.preview
BIN=${1:-/bin/true}
ALLOW=${2:-$(pwd)/sample_allowlist.json}

bash ./install_wish_service.sh --binary "$BIN" --allowlist "$ALLOW" --preview-out /tmp/wish-server.service.preview

echo "Preview written to /tmp/wish-server.service.preview"
ls -la /tmp/wish-server.service.preview
sed -n '1,240p' /tmp/wish-server.service.preview || true

