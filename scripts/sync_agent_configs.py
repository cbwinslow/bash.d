#!/usr/bin/env python3
"""
Sync configs/agents/*.yaml into mirror/openai_compat/agents/*.json.

Defaults to OpenRouter free-tier models and Cloudflare provider metadata.
"""
from __future__ import annotations

import argparse
import ast
import json
import os
import sys

try:
    import yaml
    HAS_YAML = True
except Exception:
    yaml = None
    HAS_YAML = False

ROOT = os.path.dirname(os.path.dirname(__file__))
SRC_DIR = os.path.join(ROOT, "configs", "agents")
OUT_DIR = os.path.join(ROOT, "mirror", "openai_compat", "agents")

DEFAULT_OWNER = "cbwinslow"
DEFAULT_EMAIL = "blaine.winslow@gmail.com"
DEFAULT_MODEL = "meta-llama/llama-3.2-3b-instruct:free"
DEFAULT_PROVIDER = "openrouter"
DEFAULT_FALLBACK_MODELS = [
    "meta-llama/llama-3.2-3b-instruct:free",
    "google/gemma-2-9b-it:free",
    "mistralai/mistral-7b-instruct:free",
    "google/gemini-2.0-flash-lite-preview-02-05:free",
]


def normalize_yaml(raw: str) -> str:
    lines = raw.splitlines()
    nonempty = [
        ln for ln in lines if ln.strip() and not ln.lstrip().startswith("#")
    ]
    if not nonempty:
        return raw

    first = nonempty[0]
    indented = sum(1 for ln in nonempty[1:] if ln.startswith("    "))
    if first.startswith("id:") and indented >= max(1, int(len(nonempty[1:]) * 0.6)):
        fixed = []
        for ln in lines:
            fixed.append(ln[4:] if ln.startswith("    ") else ln)
        return "\n".join(fixed) + ("\n" if raw.endswith("\n") else "")
    return raw


def simple_parse_value(value: str):
    value = value.strip()
    if not value:
        return ""
    if value in ("true", "false"):
        return value == "true"
    if value.isdigit():
        return int(value)
    try:
        return float(value)
    except ValueError:
        pass
    if value.startswith("[") or value.startswith("{"):
        try:
            return json.loads(value.replace("'", "\""))
        except Exception:
            try:
                return ast.literal_eval(value)
            except Exception:
                return value
    return value.strip("\"'")


def simple_parse_yaml(raw: str) -> dict:
    data: dict = {}
    lines = raw.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip() or line.lstrip().startswith("#"):
            i += 1
            continue
        if ":" not in line:
            i += 1
            continue
        key, rest = line.split(":", 1)
        key = key.strip()
        value = rest.strip()
        if value == "|":
            i += 1
            block_lines = []
            while i < len(lines):
                block = lines[i]
                if block.startswith("  ") or block.startswith("\t"):
                    block_lines.append(block.strip())
                    i += 1
                else:
                    break
            data[key] = "\n".join(block_lines).strip()
            continue
        data[key] = simple_parse_value(value)
        i += 1
    return data


def coerce_float(value, default: float):
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value)
        except ValueError:
            return default
    return default


def coerce_int(value, default: int):
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        try:
            return int(value)
        except ValueError:
            return default
    return default


def load_agent(path: str) -> dict:
    with open(path, "r") as fh:
        raw = fh.read()
    normalized = normalize_yaml(raw)
    if HAS_YAML:
        try:
            return yaml.safe_load(normalized) or {}
        except Exception:
            return simple_parse_yaml(normalized)
    return simple_parse_yaml(normalized)


def ensure_list(value):
    if value is None:
        return []
    if isinstance(value, list):
        return value
    if isinstance(value, str):
        parsed = simple_parse_value(value)
        return parsed if isinstance(parsed, list) else [value]
    return [value]


def to_openai(agent: dict, args, source_path: str) -> dict:
    agent_id = agent.get("id")
    if not agent_id:
        return {}

    model = args.force_model or agent.get("default_model") or DEFAULT_MODEL
    provider = args.force_provider or agent.get("model_provider") or DEFAULT_PROVIDER

    metadata = agent.get("metadata") if isinstance(agent.get("metadata"), dict) else {}
    metadata = dict(metadata)
    metadata.update(
        {
            "provider": "cloudflare",
            "source": os.path.relpath(source_path, ROOT),
            "fallback_models": args.fallback_models or DEFAULT_FALLBACK_MODELS,
        }
    )

    return {
        "id": agent_id,
        "name": agent.get("name", agent_id),
        "owner": args.owner,
        "email": args.email,
        "description": agent.get("description", ""),
        "category": agent.get("category", ""),
        "capabilities": ensure_list(agent.get("capabilities")),
        "model": model,
        "model_provider": provider,
        "temperature": coerce_float(agent.get("temperature"), 0.2),
        "max_tokens": coerce_int(agent.get("max_tokens"), 2048),
        "system_prompt": agent.get("system_prompt", ""),
        "user_prompt": agent.get("user_prompt", ""),
        "allowed_tools": ensure_list(agent.get("allowed_tools")),
        "output_format": agent.get("output_format", "markdown"),
        "safety": agent.get("safety", ""),
        "metadata": metadata,
    }


def sync_agents(args) -> list[str]:
    os.makedirs(OUT_DIR, exist_ok=True)
    if args.clean:
        for name in os.listdir(OUT_DIR):
            if name.endswith(".json"):
                os.remove(os.path.join(OUT_DIR, name))

    written = []
    for name in sorted(os.listdir(SRC_DIR)):
        if not name.endswith(".yaml"):
            continue
        source_path = os.path.join(SRC_DIR, name)
        agent = load_agent(source_path)
        output = to_openai(agent, args, source_path)
        if not output.get("id"):
            continue
        out_path = os.path.join(OUT_DIR, f"{output['id']}.json")
        with open(out_path, "w") as fh:
            json.dump(output, fh, indent=2, sort_keys=False)
            fh.write("\n")
        written.append(out_path)
    return written


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--owner", default=DEFAULT_OWNER)
    parser.add_argument("--email", default=DEFAULT_EMAIL)
    parser.add_argument("--force-model", default=DEFAULT_MODEL)
    parser.add_argument("--force-provider", default=DEFAULT_PROVIDER)
    parser.add_argument(
        "--fallback-model",
        dest="fallback_models",
        action="append",
        default=[],
        help="Repeatable fallback model list entries",
    )
    parser.add_argument("--clean", action="store_true")
    return parser.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    written = sync_agents(args)
    print(f"Wrote {len(written)} agent files to {OUT_DIR}")


if __name__ == "__main__":
    main(sys.argv[1:])
