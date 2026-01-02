#!/usr/bin/env bash
# cbw_ssh_suite_runner.sh
# Author: cbwinslow + ChatGPT (GPT-5.1 Thinking)
# Date: 2025-11-22
#
# Summary:
#   Orchestrator script for the CBW SSH Suite.
#   Uses the Python topology builder to generate per-machine SSH profiles
#   (keys, authorized_keys, config, known_hosts) from a YAML topology file.
#
#   This is the high-level "one command" entrypoint:
#     - Validates environment (python3, PyYAML, ssh-keygen)
#     - Runs cbw_ssh_profile_builder.py
#     - Optionally zips the generated profiles for transfer
#
# Usage examples:
#   ./cbw_ssh_suite_runner.sh \
#       --topology ssh_topology.yaml \
#       --output-dir ssh_profiles
#
#   ./cbw_ssh_suite_runner.sh \
#       --topology ssh_topology.yaml \
#       --output-dir ssh_profiles \
#       --zip-out cbw-ssh-profiles.zip
#
# Parameters:
#   --topology PATH   : YAML topology file (required)
#   --output-dir PATH : Directory for generated profiles (default: ./ssh_profiles)
#   --zip-out PATH    : Optional zip file to create from output-dir
#   --force           : Force regeneration of keys/config
#   --no-scan         : Skip ssh-keyscan (no known_hosts)
#   --dry-run         : Compute but don't write/execute destructive commands
#   --verbose         : Verbose logging
#
# Notes:
#   - Exits non-zero on failure; logs to /tmp/CBW-ssh-suite-runner.log
#   - Designed to be safe and idempotent where possible.
#
set -euo pipefail

LOG_FILE="/tmp/CBW-ssh-suite-runner.log"
: >"$LOG_FILE"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

TOPOLOGY=""
OUTPUT_DIR="ssh_profiles"
ZIP_OUT=""
FORCE=false
NO_SCAN=false
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --topology)
      TOPOLOGY="$2"; shift 2;;
    --output-dir)
      OUTPUT_DIR="$2"; shift 2;;
    --zip-out)
      ZIP_OUT="$2"; shift 2;;
    --force)
      FORCE=true; shift;;
    --no-scan)
      NO_SCAN=true; shift;;
    --dry-run)
      DRY_RUN=true; shift;;
    --verbose)
      VERBOSE=true; shift;;
    -h|--help)
      cat <<EOF
cbw_ssh_suite_runner.sh - CBW SSH Profile Suite Orchestrator

Usage:
  ./cbw_ssh_suite_runner.sh --topology ssh_topology.yaml [options]

Options:
  --topology PATH   YAML topology file (required)
  --output-dir PATH Output directory for generated profiles (default: ssh_profiles)
  --zip-out PATH    Optional zip archive to create from output-dir
  --force           Force regeneration of keys/config files
  --no-scan         Skip ssh-keyscan for known_hosts
  --dry-run         Compute but do not write or execute key/scan commands
  --verbose         Enable verbose logging
  -h, --help        Show this help and exit
EOF
      exit 0;;
    *)
      log "ERROR: Unknown argument: $1"
      exit 1;;
  esac
done

if [[ -z "$TOPOLOGY" ]]; then
  log "ERROR: --topology is required"
  exit 1
fi

TOPOLOGY=$(realpath "$TOPOLOGY")
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")

log "Topology file : $TOPOLOGY"
log "Output dir    : $OUTPUT_DIR"
[[ -n "$ZIP_OUT" ]] && log "Zip output    : $ZIP_OUT"

if [[ ! -f "$TOPOLOGY" ]]; then
  log "ERROR: Topology file not found: $TOPOLOGY"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  log "ERROR: python3 not found in PATH"
  exit 1
fi

if ! command -v ssh-keygen &>/dev/null; then
  log "ERROR: ssh-keygen not found in PATH"
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PY_BUILDER="$SCRIPT_DIR/cbw_ssh_profile_builder.py"

if [[ ! -f "$PY_BUILDER" ]]; then
  log "ERROR: cbw_ssh_profile_builder.py not found next to this script: $PY_BUILDER"
  log "       Make sure the CBW SSH Suite files are together in one directory."
  exit 1
fi

if ! python3 -c "import yaml" &>/dev/null; then
  log "WARNING: PyYAML not available in python3 environment. Attempting to install via pip..."
  if ! python3 -m pip install --user pyyaml &>>"$LOG_FILE"; then
    log "ERROR: Failed to install PyYAML; please install it manually (pip install pyyaml)."
    exit 1
  fi
  log "PyYAML installed successfully."
fi

PY_ARGS=("--topology" "$TOPOLOGY" "--output-dir" "$OUTPUT_DIR")
$FORCE    && PY_ARGS+=("--force")
$NO_SCAN  && PY_ARGS+=("--no-scan")
$DRY_RUN  && PY_ARGS+=("--dry-run")
$VERBOSE  && PY_ARGS+=("--verbose")

log "Running cbw_ssh_profile_builder.py with: ${PY_ARGS[*]}"
if ! python3 "$PY_BUILDER" "${PY_ARGS[@]}"; then
  log "ERROR: cbw_ssh_profile_builder.py failed"
  exit 1
fi

log "SSH profiles generated under: $OUTPUT_DIR"

if [[ -n "$ZIP_OUT" ]]; then
  if $DRY_RUN; then
    log "DRY-RUN: Would zip $OUTPUT_DIR into $ZIP_OUT"
  else
    ZIP_ABS=$(realpath "$ZIP_OUT")
    log "Creating zip archive: $ZIP_ABS"
    (cd "$OUTPUT_DIR" && zip -r "$ZIP_ABS" .) &>>"$LOG_FILE" || {
      log "ERROR: Failed to create zip archive $ZIP_ABS"
      exit 1
    }
    log "Zip archive created: $ZIP_ABS"
  fi
fi

log "cbw_ssh_suite_runner.sh completed successfully."
exit 0
