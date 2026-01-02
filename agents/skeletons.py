"""Skeleton agent loader and Pydantic mapping for per-agent YAML configs.

This module provides a lightweight AgentSpec model that mirrors configs/agents/*.yaml
and utilities to load those configs and produce BaseAgent objects accordingly.
"""
from __future__ import annotations

from pathlib import Path
from typing import List, Optional
try:
    import yaml
    HAS_YAML = True
except Exception:
    yaml = None
    HAS_YAML = False
from pydantic import BaseModel, Field

from .base import BaseAgent, AgentConfig, AgentType


class AgentSpec(BaseModel):
    id: str
    name: str
    category: str
    description: Optional[str] = None
    capabilities: Optional[List[str]] = Field(default_factory=list)
    default_model: Optional[str] = "meta-llama/llama-3.2-3b-instruct:free"
    model_provider: Optional[str] = "openrouter"
    temperature: Optional[float] = 0.2
    max_tokens: Optional[int] = 4096
    system_prompt: Optional[str] = None
    user_prompt: Optional[str] = None
    allowed_tools: Optional[List[str]] = Field(default_factory=list)
    output_format: Optional[str] = "markdown"
    safety: Optional[str] = None


def _category_to_agent_type(cat: str) -> AgentType:
    # Map loose category to AgentType enum
    mapping = {
        "programming": AgentType.PROGRAMMING,
        "devops": AgentType.DEVOPS,
        "documentation": AgentType.DOCUMENTATION,
        "testing": AgentType.TESTING,
        "security": AgentType.SECURITY,
        "data": AgentType.DATA,
        "design": AgentType.DESIGN,
        "communication": AgentType.COMMUNICATION,
        "monitoring": AgentType.MONITORING,
        "automation": AgentType.AUTOMATION,
        "general": AgentType.GENERAL,
        "special": AgentType.GENERAL,
    }
    return mapping.get(cat.lower(), AgentType.GENERAL)


def load_agent_specs(directory: Path) -> List[AgentSpec]:
    specs: List[AgentSpec] = []
    import re

    def _simple_parse(text: str) -> dict:
        # Extract a small set of top-level fields from the YAML-like text.
        out = {}
        # capture single-line key: value
        for key in [
            "id", "name", "category", "description", "default_model",
            "model_provider", "temperature", "max_tokens"
        ]:
            m = re.search(rf"^\s*{re.escape(key)}\s*:\s*(.+)$", text, re.MULTILINE)
            if m:
                out[key] = m.group(1).strip().strip('"')

        return out


    for p in sorted(directory.glob("*.yaml")):
        try:
            content = p.read_text()
            if HAS_YAML:
                data = yaml.safe_load(content) or {}
            else:
                data = _simple_parse(content) or {}
            # if the file contains a top-level 'agents' list, take first item
            if isinstance(data, dict) and "agents" in data:
                # our generator wrote single-agent YAMLs; handle both cases
                items = data.get("agents") or [data]
            else:
                items = [data]

            for item in items:
                if not item:
                    continue
                # item might be a dict or string-object mapping when parsed simply
                try:
                    spec = AgentSpec(**item)
                except Exception:
                    # Attempt to coerce minimal fields when full parsing is not available
                    minimal = {
                        'id': item.get('id') if isinstance(item, dict) else None,
                        'name': item.get('name') if isinstance(item, dict) else item.get('id'),
                        'category': item.get('category') if isinstance(item, dict) else 'general',
                        'description': item.get('description') if isinstance(item, dict) else None,
                        'default_model': item.get('default_model') if isinstance(item, dict) else None,
                        'model_provider': item.get('model_provider') if isinstance(item, dict) else None,
                    }
                    # If keys are missing attempt to fill from the simple parser result
                    if isinstance(item, dict) and '_raw' in item:
                        parsed = _simple_parse(item['_raw'])
                        minimal.update(parsed)
                    spec = AgentSpec(**{k: v for k, v in minimal.items() if v is not None})
                specs.append(spec)
        except Exception as e:
            # ignore invalid YAML files
            print(f"Failed to load {p}: {e}")
    return specs


def spec_to_agent(spec: AgentSpec) -> BaseAgent:
    cfg = AgentConfig(
        model_provider=spec.model_provider or "openrouter",
        model_name=spec.default_model or "meta-llama/llama-3.2-3b-instruct:free",
        temperature=spec.temperature or 0.2,
        max_tokens=spec.max_tokens or 4096,
    )

    agent = BaseAgent(
        name=spec.name,
        type=_category_to_agent_type(spec.category),
        description=spec.description or "",
        config=cfg,
    )

    # Add capabilities as simple AgentCapability objects if needed elsewhere.
    # Keep BaseAgent.capabilities empty by default to avoid heavy objects.

    return agent


def load_agents_from_configs(configs_dir: str | Path) -> List[BaseAgent]:
    p = Path(configs_dir)
    specs = load_agent_specs(p)
    return [spec_to_agent(s) for s in specs]


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("configs_dir", nargs="?", default="configs/agents")
    args = parser.parse_args()

    agents = load_agents_from_configs(args.configs_dir)
    print(f"Loaded {len(agents)} agent skeletons")
    for a in agents[:10]:
        print(a)
