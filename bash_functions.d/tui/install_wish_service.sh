#!/usr/bin/env bash
# Install the wish-server systemd unit from the sample and enable/start it.
# Safe installer: verifies inputs, backs up existing unit, and uses sudo for privileged steps.
set -euo pipefail

# Defaults
SAMPLE_UNIT_DEFAULT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/wish-server.service.sample"
UNIT_DST_DEFAULT="/etc/systemd/system/wish-server.service"
BIN_DEFAULT="$(pwd)/wish-server"
USER_DEFAULT="$USER"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--sample SAMPLE] [--unit DST] [--binary BIN] [--host-key PATH] [--allowlist PATH] [--user USER] [--preview-out PATH]

Installs a systemd unit for the wish-server (sample unit is used as source).
If options are omitted the script will try sensible defaults and prompt before making changes.

Options:
  --sample PATH    Path to sample unit file (default: $SAMPLE_UNIT_DEFAULT)
  --unit PATH      Destination unit path (default: $UNIT_DST_DEFAULT)
  --binary PATH    Path to the wish-server binary to reference in the unit (default: $BIN_DEFAULT)
  --host-key PATH  Path to host key (optional; sample unit may already reference it)
  --allowlist PATH Path to allowlist JSON (optional)
  --user USER      Service user (default: $USER_DEFAULT)
  --preview-out PATH  Write the patched unit to PATH and exit (no install)
  -h, --help       Show this help
EOF
}

# parse flags
SAMPLE_UNIT="$SAMPLE_UNIT_DEFAULT"
UNIT_DST="$UNIT_DST_DEFAULT"
BIN_PATH="$BIN_DEFAULT"
HOST_KEY=""
ALLOW_PATH=""
SERVICE_USER="$USER_DEFAULT"
PREVIEW_OUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sample) SAMPLE_UNIT="$2"; shift 2;;
    --unit) UNIT_DST="$2"; shift 2;;
    --binary) BIN_PATH="$2"; shift 2;;
    --host-key) HOST_KEY="$2"; shift 2;;
    --allowlist) ALLOW_PATH="$2"; shift 2;;
    --user) SERVICE_USER="$2"; shift 2;;
    --preview-out) PREVIEW_OUT="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

# sanity checks
if [[ ! -f "$SAMPLE_UNIT" ]]; then
  echo "Sample unit not found: $SAMPLE_UNIT" >&2
  exit 2
fi

if [[ ! -f "$BIN_PATH" ]]; then
  echo "Warning: wish-server binary not found at $BIN_PATH" >&2
  read -r -p "Continue anyway? [y/N] " cont
  if [[ "${cont,,}" != "y" ]]; then
    echo "Place the compiled 'wish-server' binary at $BIN_PATH or pass --binary" >&2
    exit 3
  fi
fi

if [[ -n "$HOST_KEY" && ! -f "$HOST_KEY" ]]; then
  echo "Warning: host key not found at $HOST_KEY" >&2
  read -r -p "Continue anyway? [y/N] " cont
  if [[ "${cont,,}" != "y" ]]; then
    exit 4
  fi
fi

if [[ -n "$ALLOW_PATH" && ! -f "$ALLOW_PATH" ]]; then
  echo "Warning: allowlist not found at $ALLOW_PATH" >&2
  read -r -p "Continue anyway? [y/N] " cont
  if [[ "${cont,,}" != "y" ]]; then
    exit 5
  fi
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl not available on this host; cannot install systemd unit" >&2
  exit 6
fi

echo "About to install wish-server service with these values:"
echo "  sample unit: $SAMPLE_UNIT"
echo "  unit dst:    $UNIT_DST"
echo "  binary:      $BIN_PATH"
echo "  host key:    ${HOST_KEY:-<not-specified>}"
echo "  allowlist:   ${ALLOW_PATH:-<not-specified>}"
echo "  service user:${SERVICE_USER}"

# If preview-only requested, we still create and write patched unit then exit

# Create a patched temporary unit file (locally) with placeholder replacements
TMP_UNIT_LOCAL=""
if [[ -n "$PREVIEW_OUT" ]]; then
  TMP_UNIT_LOCAL="$PREVIEW_OUT"
  cp "$SAMPLE_UNIT" "$TMP_UNIT_LOCAL"
else
  TMP_UNIT_LOCAL=$(mktemp)
  cp "$SAMPLE_UNIT" "$TMP_UNIT_LOCAL"
fi

# Replace placeholders only if values provided
if [[ -n "$BIN_PATH" ]]; then
  sed -i "s|__WISH_BIN__|$BIN_PATH|g" "$TMP_UNIT_LOCAL"
fi
if [[ -n "$HOST_KEY" ]]; then
  sed -i "s|__HOST_KEY__|$HOST_KEY|g" "$TMP_UNIT_LOCAL"
fi
if [[ -n "$ALLOW_PATH" ]]; then
  sed -i "s|__ALLOWLIST__|$ALLOW_PATH|g" "$TMP_UNIT_LOCAL"
fi

# Show preview
echo "---- Preview of patched unit file (local temp): ----"
cat "$TMP_UNIT_LOCAL"
echo "---- End preview ----"

# If preview-out was requested, exit now with path
if [[ -n "$PREVIEW_OUT" ]]; then
  echo "Wrote patched unit to: $TMP_UNIT_LOCAL"
  echo "You can review and then move it with: sudo mv '$TMP_UNIT_LOCAL' '$UNIT_DST' && sudo systemctl daemon-reload && sudo systemctl enable --now $(basename $UNIT_DST)"
  exit 0
fi

read -r -p "Proceed and install service? [y/N] " ans
if [[ "${ans,,}" != "y" ]]; then
  echo "Aborting; temporary unit retained at: $TMP_UNIT_LOCAL"
  exit 0
fi

# backup existing unit if present
if [[ -f "$UNIT_DST" ]]; then
  ts=$(date -u +%Y%m%dT%H%M%SZ)
  backup="${UNIT_DST}.bak.$ts"
  echo "Backing up existing unit to $backup"
  sudo cp -v "$UNIT_DST" "$backup"
fi

# Move local temp into place with sudo
sudo mv "$TMP_UNIT_LOCAL" "$UNIT_DST"
sudo chmod 644 "$UNIT_DST"

# Reload and enable/start the service
sudo systemctl daemon-reload
sudo systemctl enable --now wish-server.service

echo "wish-server.service installed and started."
echo "Next steps:"
echo "  - Check status: sudo systemctl status wish-server.service"
echo "  - View logs: journalctl -u wish-server.service -f"
echo "  - Adjust firewall: sudo ufw allow 8022/tcp"
echo "  - Configure domain and SSL: see documentation"
