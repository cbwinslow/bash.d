# scripts directory

This folder holds helper scripts for bootstrapping, installing, and maintaining tooling in the bash.d workspace.

- `unified_install.sh` – runs the opinionated installer described in the project README.
- `setup.sh` – establishes dotfiles, packages, and baseline configuration for new machines.
- `install_ai_tools.sh` – installs the AI/LLM toolset, as referenced from the developer guide.
- `system/toolchain-maintenance.sh` – installs/updates Node.js, pnpm, npm, bun, and Homebrew via Volta/Homebrew, keeps their bin directories on `PATH`, and validates each installation.
- `logger/` – conversation logging helpers: `log.sh` for CLI ingestion, `append-entry.mjs` for Node-based persistence, `daemon.mjs` for HTTP intake, `labeler.sh` for annotations, and `sync.sh` for git commits. Use `agent-hook.sh` to standardize agent calls and `install-systemd.sh` to generate automation units; consult `docs/logger-workflow` for workflow details.

Run `bash scripts/system/toolchain-maintenance.sh` whenever you need to refresh the core toolchain; it also rewrites the shell profiles listed in `PROFILE_TARGETS` so the environment stays consistent. When you need to capture conversations, point agents at `scripts/logger/log.sh` or the daemon and keep the logs backed up with `scripts/logger/sync.sh`.
