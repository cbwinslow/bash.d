# Continue.dev + OpenRouter (free) Toolkit Pack

This pack gives you:
- A **robust `config.yaml`** for Continue (global) using **OpenRouter**
- A **workspace `.continue/` layout** (models / rules / prompts / MCP servers)
- A **model-sync script** that discovers OpenRouter **free** models and generates a ready-to-import model list
- Security hardening notes for MCP + API keys

> Docs used to match current Continue YAML config + OpenRouter provider syntax and MCP server layout.

---

## 0) Folder layout

```
~/.continue/
  config.yaml

<your-repo>/.continue/
  models/
    openrouter-free.generated.yaml
  rules/
    cbw-rules.md
    project-rules.md
  prompts/
    dev-prompts.md
  mcpServers/
    continue-docs-mcp.yaml
    filesystem-mcp.yaml
    postgres-mcp.yaml
    playwright-mcp.yaml

scripts/
  sync_openrouter_free_models.py
  continue_doctor.sh

.env.example
README_CONTINUE_TOOLKIT.md
```

---

## 1) Global Continue config (`~/.continue/config.yaml`)

This is your “daily driver” config. It:
- Uses OpenRouter for **chat/edit/apply/summarize**
- Uses the same (or another) model for **autocomplete** (you can swap later)
- Sets safe defaults (token limits, temperature)
- Adds core context providers
- Enables MCP servers (workspace-local `.continue/mcpServers/*.yaml` are auto-picked up by Continue)

```yaml
%YAML 1.1
---
name: CBW Continue Global
version: 1.0.0
schema: v1

# Shared defaults for OpenRouter models
openrouter_defaults: &openrouter_defaults
  provider: openrouter
  apiBase: https://openrouter.ai/api/v1
  # Keep your key OUT of this file. Prefer Continue secrets.
  # Option A (recommended): set OPENROUTER_API_KEY in Continue secrets UI and reference it here
  apiKey: ${{ secrets.OPENROUTER_API_KEY }}
  requestOptions:
    # OpenRouter optional tuning. Disables prompt transforms/compression if you prefer.
    extraBodyProperties:
      transforms: []
    # Optional headers OpenRouter supports (nice-to-have)
    headers:
      HTTP-Referer: "https://cloudcurio.cc"
      X-Title: "CBW-Continue"

models:
  # --- MAIN: Coding + chat + agent mode ---
  - name: OpenRouter Free (General)
    <<: *openrouter_defaults
    # Pick a stable free model ID you like; the sync script will help you choose.
    # Example IDs often look like: "google/gemini-...:free" or "qwen/...:free"
    model: "google/gemini-exp-1121:free"
    roles: [chat, edit, apply, summarize]
    defaultCompletionOptions:
      temperature: 0.3
      maxTokens: 4096

  # --- AUTOCOMPLETE: prioritize speed ---
  - name: OpenRouter Free (Autocomplete)
    <<: *openrouter_defaults
    model: "qwen/qwen-2.5-coder-7b-instruct:free"
    roles: [autocomplete]
    autocompleteOptions:
      debounceDelay: 250
      maxPromptTokens: 1024
      onlyMyCode: true
    defaultCompletionOptions:
      temperature: 0.2
      maxTokens: 512
      stop:
        - "\n"

# Rules apply to Chat/Edit/Agent tool use. Keep these concise and high-signal.
rules:
  - uses: file://~/.continue/rules/cbw-rules.md

# Optional: add project prompts you can call with /command
prompts:
  - uses: file://~/.continue/prompts/dev-prompts.md

# Context providers let you use @ to pull in context
context:
  - provider: diff
  - provider: file
  - provider: code
  - provider: docs

# MCP servers can be declared here, but I recommend workspace-local YAML files in .continue/mcpServers/
# so each repo can opt-in to specific tools.
# (Continue will auto-load those local MCP server files.)
```

---

## 2) Workspace rules (`<repo>/.continue/rules/cbw-rules.md`)

```md
---
name: CBW Engineering Rules
---

You are an expert software engineer working in a homelab + DevOps + data systems environment.

### Reliability rules
- Prefer correctness and robustness over cleverness.
- Validate inputs and fail safely; never assume.
- Add structured logging and error handling.
- Avoid destructive operations unless explicitly requested.

### Security rules
- Do not print secrets.
- Prefer environment variables / secret stores.
- For file tools, restrict operations to the project workspace.
- For database tools, prefer read-only queries unless explicitly asked.

### Coding style
- Produce reusable, modular solutions.
- Use clear naming, constants, and configuration.
- Include tests when feasible.

### Output rules
- When writing scripts, include: header, usage, flags, examples.
- Provide 3+ suggested next steps/improvements.
```

> If you want repo-specific rules, add a `project-rules.md` and reference it from your repo config.

---

## 3) Prompts (`<repo>/.continue/prompts/dev-prompts.md`)

```md
---
name: Dev Prompts
---

---
name: Write tests
invokable: true
---
Write a complete test suite for the selected code. Use the repo's existing test framework.
Include edge cases and failure modes.

---
name: Security review
invokable: true
---
Perform a security review of the selected code. Identify risks and propose remediations.
Provide concrete patches.

---
name: Refactor for reuse
invokable: true
---
Refactor the selected code for modularity and reuse. Add input validation and logging.
```

---

## 4) MCP servers (workspace-local)

### 4.1 Continue docs MCP (`.continue/mcpServers/continue-docs-mcp.yaml`)

```yaml
name: Continue Documentation MCP
version: 0.0.1
schema: v1
mcpServers:
  - uses: continuedev/continue-docs-mcp
```

### 4.2 Filesystem MCP (`.continue/mcpServers/filesystem-mcp.yaml`)

**Important:** restrict the allowed directories to your repo(s). Don’t give it your whole home folder.

```yaml
name: Filesystem MCP (Scoped)
version: 0.0.1
schema: v1
mcpServers:
  - name: Filesystem (project)
    type: stdio
    command: npx
    args:
      - "-y"
      - "@modelcontextprotocol/server-filesystem@latest"
      # Restrict access to your workspace root (edit this)
      - "--root"
      - "."
```

### 4.3 Postgres MCP (`.continue/mcpServers/postgres-mcp.yaml`)

**Default is read-only** (good). You’ll pass `POSTGRES_URL` as an env var.

```yaml
name: Postgres MCP (Read-only)
version: 0.0.1
schema: v1
mcpServers:
  - name: Postgres
    type: stdio
    command: npx
    args:
      - "-y"
      - "@modelcontextprotocol/server-postgres@latest"
    env:
      POSTGRES_URL: ${{ secrets.POSTGRES_URL }}
```

### 4.4 Playwright MCP (`.continue/mcpServers/playwright-mcp.yaml`)

```yaml
name: Playwright MCP
version: 0.0.1
schema: v1
mcpServers:
  - name: Browser search
    command: npx
    args:
      - "@playwright/mcp@latest"
```

---

## 5) OpenRouter free-model sync script (`scripts/sync_openrouter_free_models.py`)

This script:
- Calls `GET https://openrouter.ai/api/v1/models`
- Filters “free” models by either:
  - model id containing `:free`, OR
  - pricing prompt+completion == 0 (best-effort)
- Writes a generated Continue model list at:
  - `.continue/models/openrouter-free.generated.yaml`

```python
#!/usr/bin/env python3
"""sync_openrouter_free_models.py

Date: 2026-01-02
Author: CBW Toolkit Generator (ChatGPT)

Summary:
    Fetches the full OpenRouter model catalog and generates a Continue.dev
    YAML snippet containing *free* models suitable for import.

Inputs:
    - OPENROUTER_API_KEY (env var): Optional. Some OpenRouter endpoints may work without it,
      but authenticated requests are safer and less rate-limited.
    - OUTPUT_PATH (env var or CLI): Where to write the generated YAML.

Outputs:
    - A YAML file containing a list of Continue model entries.

Usage:
    python3 scripts/sync_openrouter_free_models.py \
      --out .continue/models/openrouter-free.generated.yaml \
      --max 30

Modification Log:
    - 2026-01-02: Initial version.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

import urllib.request


OPENROUTER_MODELS_URL = "https://openrouter.ai/api/v1/models"
DEFAULT_API_BASE = "https://openrouter.ai/api/v1"
DEFAULT_OUT = ".continue/models/openrouter-free.generated.yaml"


@dataclass(frozen=True)
class ORModel:
    """Represents the subset of OpenRouter model fields we care about."""

    id: str
    name: str
    context_length: Optional[int]
    pricing_prompt: Optional[float]
    pricing_completion: Optional[float]
    supports_tools: Optional[bool]


def _safe_float(x: Any) -> Optional[float]:
    try:
        if x is None:
            return None
        return float(x)
    except Exception:
        return None


def _is_free_model(m: ORModel) -> bool:
    """Heuristic filter for 'free' models.

    OpenRouter commonly uses ':free' suffix in the model id.
    Some models also expose pricing fields; if both prompt+completion are 0, treat as free.
    """

    if ":free" in m.id:
        return True

    # Best-effort pricing check
    if m.pricing_prompt is not None and m.pricing_completion is not None:
        if m.pricing_prompt == 0.0 and m.pricing_completion == 0.0:
            return True

    return False


def fetch_models(api_key: Optional[str], timeout_s: int = 30) -> List[ORModel]:
    """Fetch model list from OpenRouter."""

    headers = {
        "Accept": "application/json",
        # Optional: identify your app
        "HTTP-Referer": "https://cloudcurio.cc",
        "X-Title": "CBW-Continue-Model-Sync",
    }

    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"

    req = urllib.request.Request(OPENROUTER_MODELS_URL, headers=headers)

    try:
        with urllib.request.urlopen(req, timeout=timeout_s) as resp:
            raw = resp.read().decode("utf-8")
    except Exception as e:
        raise RuntimeError(f"Failed to fetch models from OpenRouter: {e}")

    try:
        payload = json.loads(raw)
    except Exception as e:
        raise RuntimeError(f"OpenRouter returned non-JSON response: {e}")

    data = payload.get("data")
    if not isinstance(data, list):
        raise RuntimeError("Unexpected OpenRouter models payload: missing 'data' list")

    models: List[ORModel] = []

    for item in data:
        if not isinstance(item, dict):
            continue

        mid = str(item.get("id", "")).strip()
        name = str(item.get("name", mid)).strip() or mid

        # context_length is sometimes on 'context_length'
        context_length = item.get("context_length")
        try:
            context_length = int(context_length) if context_length is not None else None
        except Exception:
            context_length = None

        pricing = item.get("pricing") or {}
        if not isinstance(pricing, dict):
            pricing = {}

        pricing_prompt = _safe_float(pricing.get("prompt"))
        pricing_completion = _safe_float(pricing.get("completion"))

        # Some models expose supported_parameters / architecture; tools support is not standardized.
        # We'll keep a placeholder boolean if present.
        supports_tools = None
        sp = item.get("supported_parameters")
        if isinstance(sp, list):
            supports_tools = "tools" in sp or "tool_use" in sp

        if mid:
            models.append(
                ORModel(
                    id=mid,
                    name=name,
                    context_length=context_length,
                    pricing_prompt=pricing_prompt,
                    pricing_completion=pricing_completion,
                    supports_tools=supports_tools,
                )
            )

    return models


def rank_models(models: List[ORModel]) -> List[ORModel]:
    """Sort free models roughly by context length desc, then name."""

    def key(m: ORModel) -> Tuple[int, str]:
        cl = m.context_length or 0
        return (cl, m.name.lower())

    return sorted(models, key=key, reverse=True)


def ensure_parent_dir(path: str) -> None:
    parent = os.path.dirname(os.path.abspath(path))
    if parent and not os.path.isdir(parent):
        os.makedirs(parent, exist_ok=True)


def render_continue_yaml(models: List[ORModel], api_key_secret: str = "OPENROUTER_API_KEY") -> str:
    """Render a Continue-compatible YAML snippet."""

    lines: List[str] = []
    lines.append("%YAML 1.1")
    lines.append("---")
    lines.append("name: OpenRouter Free Models (generated)")
    lines.append("version: 0.1.0")
    lines.append("schema: v1")
    lines.append("")
    lines.append("openrouter_defaults: &openrouter_defaults")
    lines.append("  provider: openrouter")
    lines.append(f"  apiKey: ${{{{ secrets.{api_key_secret} }}}}")
    lines.append(f"  apiBase: {DEFAULT_API_BASE}")
    lines.append("  requestOptions:")
    lines.append("    extraBodyProperties:")
    lines.append("      transforms: []")
    lines.append("")
    lines.append("models:")

    for m in models:
        safe_name = m.name.replace("\"", "'")
        # A concise label that still disambiguates
        title = f"{safe_name}"
        lines.append(f"  - name: \"{title}\"")
        lines.append("    <<: *openrouter_defaults")
        lines.append(f"    model: \"{m.id}\"")
        # Assign roles broadly; you can prune later
        lines.append("    roles: [chat, edit, apply, summarize]")
        if m.supports_tools:
            lines.append("    capabilities:")
            lines.append("      - tool_use")
        # Light defaults; tune per model if you want
        lines.append("    defaultCompletionOptions:")
        lines.append("      temperature: 0.3")
        lines.append("      maxTokens: 4096")

    lines.append("")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate Continue YAML for OpenRouter free models")
    ap.add_argument("--out", default=os.environ.get("OUTPUT_PATH", DEFAULT_OUT), help="Output YAML path")
    ap.add_argument("--max", type=int, default=40, help="Max models to include")
    ap.add_argument("--timeout", type=int, default=30, help="HTTP timeout seconds")
    ap.add_argument(
        "--require-key",
        action="store_true",
        help="Fail if OPENROUTER_API_KEY is not set",
    )
    args = ap.parse_args()

    api_key = os.environ.get("OPENROUTER_API_KEY")
    if args.require_key and not api_key:
        print("ERROR: OPENROUTER_API_KEY is required but not set", file=sys.stderr)
        return 2

    try:
        all_models = fetch_models(api_key=api_key, timeout_s=args.timeout)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    free_models = [m for m in all_models if _is_free_model(m)]
    free_models = rank_models(free_models)

    if args.max > 0:
        free_models = free_models[: args.max]

    ensure_parent_dir(args.out)

    yaml_text = render_continue_yaml(free_models)

    try:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(yaml_text)
    except Exception as e:
        print(f"ERROR: Failed writing {args.out}: {e}", file=sys.stderr)
        return 1

    print(f"Wrote {len(free_models)} free models to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

---

## 6) Continue “doctor” script (`scripts/continue_doctor.sh`)

Quick health check: confirms Node, npx, Continue config locations, and whether required env vars exist.

```bash
#!/usr/bin/env bash
# continue_doctor.sh
# Date: 2026-01-02
# Author: CBW Toolkit Generator (ChatGPT)
# Summary: Quick diagnostics for Continue + MCP + OpenRouter

set -euo pipefail

log() { printf "[continue-doctor] %s\n" "$*"; }
warn() { printf "[continue-doctor][WARN] %s\n" "$*"; }
err() { printf "[continue-doctor][ERROR] %s\n" "$*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Missing required command: $1"; return 1; }
}

main() {
  log "Checking basic tools..."
  need_cmd node
  need_cmd npm
  need_cmd npx
  need_cmd python3

  log "Node version: $(node -v)"
  log "npm version:  $(npm -v)"

  local global_cfg="$HOME/.continue/config.yaml"
  if [[ -f "$global_cfg" ]]; then
    log "Found global Continue config: $global_cfg"
  else
    warn "Global Continue config not found at $global_cfg"
  fi

  if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
    log "OPENROUTER_API_KEY is set (good)"
  else
    warn "OPENROUTER_API_KEY is NOT set in this shell. If you use Continue secrets UI, that's OK."
  fi

  if [[ -n "${POSTGRES_URL:-}" ]]; then
    log "POSTGRES_URL is set (optional)"
  else
    warn "POSTGRES_URL not set (only needed if using Postgres MCP)"
  fi

  log "Done. If MCP servers fail to start, try using absolute paths for node/npx, or install MCP servers globally."
}

main "$@"
```

---

## 7) `.env.example`

```env
# Continue/OpenRouter
OPENROUTER_API_KEY=put_your_openrouter_key_here

# Optional (if using Postgres MCP)
POSTGRES_URL=postgresql://user:pass@host:5432/dbname
```

---

## 8) README (`README_CONTINUE_TOOLKIT.md`)

```md
# Continue.dev + OpenRouter Toolkit (CBW)

## Setup
1) Put global config in: `~/.continue/config.yaml`
2) Put rules/prompt files in: `~/.continue/rules/` and `~/.continue/prompts/`
3) In each repo, create `.continue/mcpServers/` and drop in whichever MCP YAML files you want.
4) Add secrets in Continue:
   - `OPENROUTER_API_KEY`
   - `POSTGRES_URL` (optional)

## Generate a fresh free-model list
```bash
python3 scripts/sync_openrouter_free_models.py --out .continue/models/openrouter-free.generated.yaml --max 40
```

## Using the generated models
- Open the generated YAML and copy/paste model blocks into your global `~/.continue/config.yaml`, or
- Convert the generated file into a Hub-style `uses: file://...` import (Continue supports file imports).

## Safety notes for MCP
- Prefer official servers and pin versions.
- Restrict filesystem roots to the current repo.
- Avoid giving MCP servers access to email or broad credential stores.
```

---

## 9) Practical guidance: getting the most out of Continue + OpenRouter (free)

1) **Pick a “fast” and a “smart” model**
   - Fast: autocomplete + quick edits
   - Smart: agent mode + multi-step refactors
   Use the sync script to find which free models have large context.

2) **Use agent mode only when tools are needed**
   MCP servers only run in agent mode.

3) **Keep MCP scoped**
   File tools should be restricted to a repo root. DB tools should start read-only.

4) **Disable OpenRouter prompt transforms if you care about exact input**
   The `transforms: []` setting helps avoid surprise compression.

---

## 10) Next steps / upgrades (pick any 3, we can ship immediately)

1) **Auto-pick best free models**: extend the sync script to score models by context length, “tool_use” support, and latency hints.
2) **Workspace override system**: add a `.continue/config.yaml` per repo that merges with global and selects repo-specific tools.
3) **Add a “Repo RAG” MCP server**: index your codebase/docs and expose semantic search via MCP.
4) **Key hygiene**: integrate Bitwarden CLI to inject `OPENROUTER_API_KEY` into your environment securely.
5) **Model fallbacks**: create multiple “profiles” (fast/smart/offline) you can switch between from Continue’s config dropdown.

