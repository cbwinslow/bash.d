#!/usr/bin/env bash
# approve_request.sh - CLI helper to list/approve/deny requests in the TUI request queue
# Usage examples:
#  approve_request.sh --list
#  approve_request.sh --approve req-1
#  approve_request.sh --deny req-1
#  approve_request.sh --approve --run req-1

set -euo pipefail

PROGNAME="$(basename "$0")"

# defaults (support both dot and underscore dirs for compatibility)
HOME_DIR="${HOME:-/root}"
REQUESTS_PATHS=("$HOME_DIR/.bash_functions_d/tui/requests.json" "$HOME_DIR/.bash_functions.d/tui/requests.json")
AUDIT_PATHS=("$HOME_DIR/.bash_functions_d/tui/agent_audit.log" "$HOME_DIR/.bash_functions.d/tui/agent_audit.log")
ALLOWLIST_DEFAULTS=("$HOME_DIR/.bash_functions.d/tui/wish_allowlist.json" "$HOME_DIR/.bash_functions_d/tui/wish_allowlist.json")
AGENT_RUNNER_PATHS=("$HOME_DIR/bash_functions.d/40-agents/agent_runner.sh" "$HOME_DIR/.bash_functions.d/40-agents/agent_runner.sh")

# CLI params
ACTION=""
REQUEST_ID=""
RUN_AFTER_APPROVE=0
FORCE=0
ALLOWLIST=""
REQUESTS_PATH=""
AUDIT_PATH=""
AGENT_RUNNER=""
DRY_RUN=0

usage() {
  cat <<EOF
$PROGNAME [--list] [--approve ID] [--deny ID] [--approve --run ID] [--allowlist PATH] [--requests PATH] [--audit PATH] [--agent-runner PATH] [--force] [--dry-run]

Examples:
  $PROGNAME --list
  $PROGNAME --approve req-1
  $PROGNAME --approve --run req-1
  $PROGNAME --deny req-1

This will modify requests file and write audit entries. Defaults try typical locations.
EOF
}

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) ACTION=list; shift;;
    --approve) ACTION=approve; REQUEST_ID="${2:-}"; shift 2;;
    --deny) ACTION=deny; REQUEST_ID="${2:-}"; shift 2;;
    --run) RUN_AFTER_APPROVE=1; shift;;
    --approve-and-run) ACTION=approve; RUN_AFTER_APPROVE=1; REQUEST_ID="${2:-}"; shift 2;;
    --allowlist) ALLOWLIST="$2"; shift 2;;
    --requests) REQUESTS_PATH="$2"; shift 2;;
    --audit) AUDIT_PATH="$2"; shift 2;;
    --agent-runner) AGENT_RUNNER="$2"; shift 2;;
    --force) FORCE=1; shift;;
    --dry-run) DRY_RUN=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

# helper: find first existing path from list
find_first() {
  for p in "$@"; do
    [[ -f "$p" ]] && { echo "$p"; return 0; }
  done
  return 1
}

# choose defaults if not provided
if [[ -z "$REQUESTS_PATH" ]]; then
  REQUESTS_PATH="$(find_first "${REQUESTS_PATHS[@]}" 2>/dev/null || echo "$HOME_DIR/.bash_functions_d/tui/requests.json")"
fi
if [[ -z "$AUDIT_PATH" ]]; then
  AUDIT_PATH="$(find_first "${AUDIT_PATHS[@]}" 2>/dev/null || echo "$HOME_DIR/.bash_functions_d/tui/agent_audit.log")"
fi
if [[ -z "$ALLOWLIST" ]]; then
  ALLOWLIST="$(find_first "${ALLOWLIST_DEFAULTS[@]}" 2>/dev/null || echo "")"
fi
if [[ -z "$AGENT_RUNNER" ]]; then
  AGENT_RUNNER="$(find_first "${AGENT_RUNNER_PATHS[@]}" 2>/dev/null || echo "")"
fi

LOCKDIR="$HOME_DIR/.bash_functions_d/locks"
mkdir -p "$LOCKDIR"
LOCKFILE="$LOCKDIR/requests.lock"

# read JSON helpers
read_requests() {
  if [[ ! -f "$REQUESTS_PATH" ]]; then
    echo "[]"
    return 0
  fi
  cat "$REQUESTS_PATH"
}

write_requests() {
  local tmp
  tmp=$(mktemp)
  printf '%s' "$1" > "$tmp"
  mv "$tmp" "$REQUESTS_PATH"
}

# load allowlist and find permissions for current user
get_user_perms() {
  local user cur allowed execs is_admin
  user="$(id -un)"
  cur=""
  [[ -n "$ALLOWLIST" && -f "$ALLOWLIST" ]] || { echo ""; return 0; }
  # look for entry by user
  cur=$(jq -r --arg u "$user" '.[] | select(.user==$u) | @base64' "$ALLOWLIST" 2>/dev/null || echo "")
  if [[ -z "$cur" ]]; then
    echo ""
    return 0
  fi
  echo "$cur"
}

# helper to decode base64 jq result into fields
decode_entry() {
  echo "$1" | base64 --decode | jq -r "$2"
}

# append audit
append_audit() {
  local line="$1"
  mkdir -p "$(dirname "$AUDIT_PATH")"
  printf "%s\n" "$line" >> "$AUDIT_PATH"
}

# list requests
list_requests() {
  local json
  json=$(read_requests)
  echo "$json" | jq -r '.[] | "id: \(.id)  agent: \(.agent)  user: \(.user)  time: \(.time) \n  notes: \(.notes)\n"' || echo "(no requests)"
}

# approve logic (with locking and dry-run)
approve_request_locked() {
  local id="$1"
  local dry="$2"
  # Acquire lock
  exec 9>"$LOCKFILE"
  if ! flock -n 9; then
    echo "Could not acquire lock on requests; try again later" >&2
    return 10
  fi

  local json req agent requester rc=0
  json=$(read_requests)
  req=$(echo "$json" | jq -r --arg id "$id" '.[] | select(.id==$id) | @base64' )
  if [[ -z "$req" ]]; then
    echo "Request not found: $id" >&2; rc=2; flock -u 9; return $rc
  fi
  agent=$(echo "$req" | base64 --decode | jq -r '.agent')
  requester=$(echo "$req" | base64 --decode | jq -r '.user')

  # permission check
  if [[ $FORCE -ne 1 ]]; then
    entry=$(get_user_perms)
    if [[ -z "$entry" ]]; then
      echo "You are not listed in allowlist; cannot approve unless --force used" >&2; rc=3; flock -u 9; return $rc
    fi
    is_admin=$(decode_entry "$entry" '.is_admin')
    if [[ "$is_admin" != "true" && "$is_admin" != "1" ]]; then
      contains=$(decode_entry "$entry" '.allowed_exec[]? | select(.=="'"$agent"'")' 2>/dev/null || true)
      if [[ -z "$contains" ]]; then
        echo "You are not permitted to approve this agent ($agent)." >&2; rc=4; flock -u 9; return $rc
      fi
    fi
  fi

  if [[ $dry -eq 1 ]]; then
    echo "Dry-run: would approve $id (agent=$agent)"
    flock -u 9
    return 0
  fi

  if [[ -z "$AGENT_RUNNER" || ! -x "$AGENT_RUNNER" ]]; then
    echo "Agent runner not found or not executable: $AGENT_RUNNER" >&2
    rc=5
    flock -u 9
    return $rc
  fi

  out=$("$AGENT_RUNNER" "$agent" --exec 2>&1) || rc=$?
  rc=${rc:-0}
  echo "Agent output:\n$out"
  append_audit "$(date -u +%Y-%m-%dT%H:%M:%SZ)\tagent=$agent\treq=$id\trequester=$requester\tapproved_by=$(id -un)\texit=$rc"

  # remove request
  newjson=$(echo "$json" | jq --arg id "$id" '[.[] | select(.id != $id)]')
  printf "%s" "$newjson" > "$REQUESTS_PATH"

  flock -u 9
  return $rc
}

# deny logic (with lock)
deny_request_locked() {
  local id="$1"
  exec 9>"$LOCKFILE"
  if ! flock -n 9; then echo "Could not acquire lock" >&2; return 10; fi
  local json req
  json=$(read_requests)
  req=$(echo "$json" | jq -r --arg id "$id" '.[] | select(.id==$id) | @base64' )
  if [[ -z "$req" ]]; then echo "Request not found: $id" >&2; flock -u 9; return 2; fi
  requester=$(echo "$req" | base64 --decode | jq -r '.user')
  append_audit "$(date -u +%Y-%m-%dT%H:%M:%SZ)\treq=$id\trequester=$requester\tdenied_by=$(id -un)"
  newjson=$(echo "$json" | jq --arg id "$id" '[.[] | select(.id != $id)]')
  printf "%s" "$newjson" > "$REQUESTS_PATH"
  flock -u 9
}

# main dispatch
case "$ACTION" in
  list)
    list_requests
    ;;
  approve)
    approve_request_locked "$REQUEST_ID" "$DRY_RUN"
    ;;
  deny)
    deny_request_locked "$REQUEST_ID"
    ;;
  "")
    echo "No action specified."; usage; exit 2
    ;;
  *)
    echo "Unknown action: $ACTION"; usage; exit 2
    ;;
esac
