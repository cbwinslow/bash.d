#!/usr/bin/env bash
set -euo pipefail

echo "Running requests workflow test (creates sample requests and dummy agent runner)"

HOME_DIR="$HOME"
REQ_DIR="$HOME_DIR/.bash_functions_d/tui"
mkdir -p "$REQ_DIR"
cat > "$REQ_DIR/requests.json" <<'JSON'
[
  {"id":"req-1","agent":"ai_secret_mapper","user":"guest","time":"2025-11-27T12:00:00Z","notes":"Please map DB keys for dev"},
  {"id":"req-2","agent":"env_build_crew","user":"guest","time":"2025-11-27T12:05:00Z","notes":"Build .env for project X"}
]
JSON
chmod 600 "$REQ_DIR/requests.json"

# create dummy agent runner
mkdir -p "$HOME_DIR/bash_functions.d/40-agents"
cat > "$HOME_DIR/bash_functions.d/40-agents/agent_runner.sh" <<'SH'
#!/usr/bin/env bash
printf 'DUMMY RUNNER: %s\n' "$@"
exit 0
SH
chmod +x "$HOME_DIR/bash_functions.d/40-agents/agent_runner.sh"

# copy the approve helper to temp and run tests
cp "$(pwd)/approve_request.sh" /tmp/approve_request_test.sh
chmod +x /tmp/approve_request_test.sh

echo "-- list requests --"
/tmp/approve_request_test.sh --list || true

echo "-- approve req-1 (force) --"
/tmp/approve_request_test.sh --approve req-1 --force || true

echo "-- audit log --"
cat "$HOME_DIR/.bash_functions_d/tui/agent_audit.log" || true

echo "-- requests after approve --"
cat "$HOME_DIR/.bash_functions_d/tui/requests.json" || true

echo "-- deny req-2 --"
/tmp/approve_request_test.sh --deny req-2 --force || true

echo "-- audit log after deny --"
cat "$HOME_DIR/.bash_functions_d/tui/agent_audit.log" || true

echo "-- requests after deny --"
cat "$HOME_DIR/.bash_functions_d/tui/requests.json" || true

echo "Requests workflow test complete"

