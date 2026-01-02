#!/usr/bin/env bash
# Small linux utilities: process, ports, services wrappers

set -euo pipefail

_lu_log() { printf '[linux_utils] %s\n' "$*" >&2; }

list_open_ports() {
  if command -v ss >/dev/null 2>&1; then
    ss -tuln
  else
    netstat -tuln 2>/dev/null || lsof -i -P -n
  fi
}

kill_by_name() {
  local name
  name="$1"
  pgrep -f "$name" | xargs -r -n1 kill -9
}

svc_restart() {
  local svc
  svc="$1"
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart "$svc"
  else
    _lu_log "systemctl not available"
    return 2
  fi
}

check_port() {
  local port
  port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn 'sport = :"$port"'
  else
    lsof -iTCP -sTCP:LISTEN -P -n | grep ":$port\b" || true
  fi
}

