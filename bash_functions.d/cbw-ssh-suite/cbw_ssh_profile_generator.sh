#!/usr/bin/env bash
# cbw_ssh_profile_generator.sh
# Author: cbwinslow + ChatGPT
# Date: 2025-11-22
# Summary:
#   Generates a full SSH connection profile for a single machine using:
#     - Existing SSH config & keys
#     - ZeroTier CLI (if installed)
#     - NetBird CLI (if installed)
#   Builds:
#     - Private/Public keypair
#     - authorized_keys (with local pubkey)
#     - ssh config file with overlay-aware hosts
#     - metadata.json
#   Designed so user can copy the generated folder to ~/.ssh on any machine.
#
# Usage:
#   ./cbw_ssh_profile_generator.sh --host cbwdellr720 --user cbwinslow
#   Outputs folder: ./output/<host>-ssh-profile/
#
set -euo pipefail
LOG_FILE="/tmp/CBW-ssh-profile.log"
DRY_RUN=false

log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
run(){ if [ "$DRY_RUN" = true ]; then log "DRY-RUN: $*"; else log "RUN: $*"; eval "$*"; fi; }

check_bin(){ if ! command -v "$1" &>/dev/null; then return 1; else return 0; fi; }

HOSTNAME=""
USERNAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOSTNAME="$2"; shift 2;;
    --user) USERNAME="$2"; shift 2;;
    --dry-run) DRY_RUN=true; shift;;
    *) log "Unknown arg: $1"; exit 1;;
  esac
done

if [ -z "$HOSTNAME" ] || [ -z "$USERNAME" ]; then
  log "ERROR: --host and --user required"; exit 1
fi

OUTDIR="output/${HOSTNAME}-ssh-profile"
run "mkdir -p '$OUTDIR'"

KEYFILE="$OUTDIR/${HOSTNAME}_ed25519"
if [ ! -f "$KEYFILE" ]; then
  run "ssh-keygen -t ed25519 -C '${USERNAME}@${HOSTNAME}' -f '$KEYFILE' -N ''"
else
  log "Keypair exists; reusing $KEYFILE"
fi
PUBKEY="${KEYFILE}.pub"

ZT_IPS=()
if check_bin zerotier-cli; then
  ZT_IDS=$(zerotier-cli listnetworks | awk '{print $3}' | tail -n +2 || true)
  for ZID in $ZT_IDS; do
    ZT_IP=$(zerotier-cli get "$ZID" ip4 || true)
    if [[ "$ZT_IP" != "" ]]; then ZT_IPS+=("$ZT_IP"); fi
  done
fi

NB_IPS=()
if check_bin netbird; then
  NB_JSON=$(netbird status show --json || true)
  NB_IP=$(echo "$NB_JSON" | grep -Eo '"IP":"[0-9./]+"' | cut -d '"' -f4 || true)
  if [[ "$NB_IP" != "" ]]; then NB_IPS+=("$NB_IP"); fi
fi

AUTHFILE="$OUTDIR/authorized_keys"
run "cp '$PUBKEY' '$AUTHFILE'"
log "authorized_keys created with local pubkey"

CONFIGFILE="$OUTDIR/config"
{
  echo "Host $HOSTNAME"
  echo "    HostName $HOSTNAME"
  echo "    User $USERNAME"
  echo "    IdentityFile ~/.ssh/${HOSTNAME}_ed25519"
  echo "    IdentitiesOnly yes"
  echo ""
  for IP in "${ZT_IPS[@]}"; do
    echo "Host ${HOSTNAME}-zt"
    echo "    HostName $IP"
    echo "    User $USERNAME"
    echo "    IdentityFile ~/.ssh/${HOSTNAME}_ed25519"
    echo "    IdentitiesOnly yes"
    echo ""
  done
  for IP in "${NB_IPS[@]}"; do
    echo "Host ${HOSTNAME}-netbird"
    echo "    HostName $IP"
    echo "    User $USERNAME"
    echo "    IdentityFile ~/.ssh/${HOSTNAME}_ed25519"
    echo "    IdentitiesOnly yes"
    echo ""
  done
} > "$CONFIGFILE"
log "ssh config generated at $CONFIGFILE"

META="$OUTDIR/metadata.json"
{
  echo "{"
  echo "  \"host\": \"$HOSTNAME\","
  echo "  \"user\": \"$USERNAME\","
  echo "  \"zerotier_ips\": ["
  for IP in "${ZT_IPS[@]}"; do echo "    \"$IP\","; done
  echo "  ],"
  echo "  \"netbird_ips\": ["
  for IP in "${NB_IPS[@]}"; do echo "    \"$IP\","; done
  echo "  ]"
  echo "}"
} > "$META"

log "metadata.json written to $META"
log "SSH profile ready in: $OUTDIR"

exit 0
