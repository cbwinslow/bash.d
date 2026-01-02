#!/usr/bin/env bash
# Quick validation script to check CLI deps and env vars
set -euo pipefail

_check() { command -v "$1" >/dev/null 2>&1 || { echo "$1 not found"; exit 2; } }

_check bw
_check jq
_check git

if [[ -z "${BW_SESSION:-}" ]]; then
  echo "Warning: BW_SESSION not set. Run: bw unlock --raw and export BW_SESSION"
fi

if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
  echo "OPENROUTER_API_KEY not set; AI ranking will be unavailable"
fi

echo "Validation OK (basic checks)"
