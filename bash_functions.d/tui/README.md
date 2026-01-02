Go TUI and SSH server

Build:

```bash
cd ~/bash_functions.d/tui/go-term
# build the TUI
go build ./cmd/term
# build the lightweight SSH server
go build ./cmd/sshserver
```

This produces the `term` TUI binary and the `sshserver` binary.

Run TUI locally:

```bash
./term
```

Run lightweight SSH server (will spawn `./term` for each incoming session):

```bash
# run server (listens on 8022 by default)
./sshserver --port 8022
# then connect from another machine:
ssh -p 8022 user@yourhost
```

Wish (preferred for production)

To build and run a Wish-based SSH server (recommended for middleware, logging, and auth), build with the `wish` build tag:

```bash
# build Wish-based server (this fetches wish as a dependency)
go build -tags wish ./cmd/wish-server
# run (use a host key and an allowlist JSON for public-key auth)
./wish-server --port 8022 --host-key /path/to/host_key --allowlist /path/to/wish_allowlist.json
```

Allowlist format

The Wish server supports a JSON allowlist of users and their authorized public keys. Example (`sample_allowlist.json` provided in repo):

```json
[
  {
    "user": "cbwinslow",
    "pubkey": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePublicKey user@example.com"
  }
]
```

Notes:
- The Wish-based server enforces public-key-only authentication against the allowlist by default; do not enable the lightweight server on public-facing hosts.
- Ensure `term` binary is in the same directory as `wish-server` or adjust the handler to run a different binary.
