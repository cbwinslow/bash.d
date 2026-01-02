# OpenAI-Compatible Mirror (OpenRouter + Cloudflare)

This mirror provides an OpenAI-compatible API surface for bash.d agents and tools.
It is designed to run on Cloudflare Workers and forward `/v1/*` requests to OpenRouter.
Only free-tier models are allowed; requests are clamped to the free-model allowlist.

## Layout

- `mirror/openai_compat/src/index.js` - Cloudflare Worker proxy (`/v1/chat/completions`, `/v1/models`)
- `mirror/openai_compat/wrangler.toml` - Worker config
- `mirror/openai_compat/agents/` - Mirror agent definitions (OpenAI-compatible)

## Quick Start

```bash
cd mirror/openai_compat
wrangler login
wrangler secret put OPENROUTER_API_KEY
wrangler deploy
```

## Create Cloudflare API Token (Script)

```bash
scripts/create_cloudflare_api_token.sh --env-file ~/.env --account-id <ACCOUNT_ID>
```

## Sync Bitwarden → Cloudflare Secrets Store

```bash
# Edit the mapping file first:
cat configs/bitwarden/cloudflare_secrets_sync.json

# Sync to the default secrets store (uses --value, so opt-in):
scripts/sync_bitwarden_to_cf_secrets.sh --allow-plain
```

Regex mode example:

```bash
scripts/sync_bitwarden_to_cf_secrets.sh --allow-plain --regex '(api[_-]?key|token)' --item-regex 'cloudflare|openrouter'
```

## Sync Agent Definitions

```bash
python3 scripts/sync_agent_configs.py --clean
```

## Usage (OpenAI-Compatible Client)

Set your base URL to the Worker:

```
https://<your-worker-subdomain>.workers.dev/v1
```

Example environment:

```
OPENAI_BASE_URL=https://<your-worker-subdomain>.workers.dev/v1
OPENAI_API_KEY=anything
```

The Worker injects `OPENROUTER_API_KEY` and forwards to OpenRouter.

## Notes

- Free-tier model defaults and allowlist are defined in `mirror/openai_compat/src/index.js`.
- Secrets should live in `~/.bash_secrets.d/openrouter/token.age` and be loaded into Wrangler secrets.
- This mirror keeps agent definitions in sync with `configs/agents/` by manual or scripted conversion.
