# Agent Definitions (OpenAI-Compatible)

This folder mirrors agent definitions from `configs/agents/` into a simpler,
OpenAI-compatible shape for use with the Cloudflare proxy.

## Conventions

- `model` should use OpenRouter free-tier defaults when possible.
- `system_prompt` should stay short and point to repo-local tooling.
- Tooling should reference safe functions only unless supervision is required.

## Sync Guidance

Sync the mirror from `configs/agents/`:

```bash
python3 scripts/sync_agent_configs.py --clean
```
