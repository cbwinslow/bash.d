Testing and QA for the Wish TUI and service

Overview

This document describes how to build, preview, install, and test the Wish-based TUI server and the request approval workflow. The scripts in this folder are idempotent and safe: most tests run in preview mode or create temporary data under ~/.bash_functions_d/tui.

Prerequisites
- Go (only required to build the TUI and wish-server if you plan to build them locally)
- ssh client (to connect to the wish server)
- jq (used by the helper scripts)
- systemd if you plan to install the service

Files added for testing
- install_wish_service.sh - installer (interactive); supports --preview-out
- approve_request.sh - CLI helper (list/approve/deny requests)
- test_install_preview.sh - creates a previewed systemd unit at /tmp/wish-server.service.preview
- test_requests_flow.sh - creates sample requests, dummy agent runner, and exercises approve_request.sh (list/approve/deny)
- test_service_check.sh - basic check for systemd service status (non-destructive)

Quick test: request workflow (local)

1) Run the requests workflow test (this will create sample requests and a dummy agent runner, run list, approve and deny, then show audit and remaining requests):

```bash
bash ~/bash_functions.d/tui/go-term/test_requests_flow.sh
```

2) Inspect results manually:

```bash
cat ~/.bash_functions_d/tui/agent_audit.log
cat ~/.bash_functions_d/tui/requests.json
```

Previewing the systemd unit (safe)

To preview the unit that will be installed (no changes to systemd):

```bash
bash ~/bash_functions.d/tui/go-term/test_install_preview.sh --binary /bin/true --allowlist ~/bash_functions.d/tui/go-term/sample_allowlist.json
# This writes /tmp/wish-server.service.preview and prints it
```

Installing the unit

After previewing, you can install the unit manually with the preview file (the installer can also apply it interactively):

```bash
sudo mv /tmp/wish-server.service.preview /etc/systemd/system/wish-server.service
sudo chmod 644 /etc/systemd/system/wish-server.service
sudo systemctl daemon-reload
sudo systemctl enable --now wish-server.service
sudo systemctl status wish-server.service
```

Service status check

Run the status check script (safe) to see whether the wish-server unit is active (no changes):

```bash
bash ~/bash_functions.d/tui/go-term/test_service_check.sh
```

Notes
- The tests are intentionally simple and avoid network exposure: the preview uses /bin/true as the binary in examples, and the requests test uses a dummy agent runner.
- For production you should build `wish-server` with `go build -tags wish ./cmd/wish-server`, deploy host keys and allowlist entries, and run the provided installer interactively.


