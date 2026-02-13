# Developer Guide — bash.d

This guide helps developers get productive with the project quickly.

## Local setup
1. Clone the repo
2. Run `./scripts/unified_install.sh` to install recommended tooling
3. Use the integrated CLI `./bashd` to interact with the platform

## Toolchain maintenance
- Run `scripts/system/toolchain-maintenance.sh` to refresh Node.js, npm, pnpm, bun, and Homebrew. Each function in that script keeps the necessary bin directories on `PATH`, validates that binaries live under the preferred manager, and prints their versions so you can confirm that updates succeeded.

## Conversation logging
- Consult `docs/logger-workflow/INSTRUCTIONS.md` for the schema, CLI, daemon, labeler, and sync automation that powers the universal logger.
- Use `scripts/logger/log.sh` or the HTTP daemon (`scripts/logger/daemon.mjs`) to record every agent turn; keep the data in `~/bash.d/conversation-logs` and let `scripts/logger/sync.sh` push new files.
- When you add new agent wrappers (Codex, Gemini, etc.), call `scripts/logger/log.sh` or hit the daemon so `task_label`, `role`, `tokens`, and `metadata` stay structured for downstream training.
- Prefer `scripts/logger/agent-hook.sh` (or `bash_functions.d/logger.sh`) as the consistent entrypoint for every agent; it will route turns through the daemon when reachable or fall back to the CLI.
- Run `scripts/logger/install-systemd.sh` (or the cron snippets from `docs/logger-workflow/AUTOMATION.md`) so the daemon, sync, and labeler run automatically on your workstation or server.

## Testing
- Unit tests: use the `tests/` folder and run locally
- Add tests with clear inputs and expected results
- Integrations should run in a containerized or sandbox environment

## Contributing
- See `CONTRIBUTING.md` for workflow details
- Keep PRs small and testable
- Update docs for any behavior changes

## Helpful tips
- Use shellcheck and linting for scripts
- Keep shared logic in `src/` and document it
- Use feature branches for all work
