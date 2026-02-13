# Bash.d AI Agents

**AI agent ecosystem for shell automation and development**

## Standard Layout

- Code: `agents/`
- Config: `configs/agents/`
- Docs: `docs/agents/` (catalog in `docs/agents/agents_catalog.md`)
- Index + change log: `agents.md` (this file)
- Template loader: `configs/bash/secrets/00-bashd-env.bash`

## Secrets & Env Policy

- Single source of truth: `~/.bash_secrets.d/env/root.env`
- Repo path `bash_secrets.d/env/root.env` is a symlink to the canonical file and is git-ignored
- Loader: `~/.config/bash/secrets/00-bashd-env.bash`
- Do not commit secrets or `.env` files

## Local Integrations

- Bitwarden Secrets Access — `bash_functions.d/tools/bw_agent.sh` (see `docs/agents/agents_catalog.md`)

## Agent Registry (Core)

- **AI Assistant** - General purpose AI assistant for shell tasks
- **Tool Manager** - Shell tool discovery and management

## Quick Start

```bash
# Load all agents
source bash_functions.d/core/agents/load_agents.sh
```

## Change Log

- 2025-12-30: Standardized secrets sourcing and single-source symlink for `root.env`
- 2025-12-30: Documented Bitwarden wrapper + repo loader template
- 2025-12-30: Added template install README for secrets loader
