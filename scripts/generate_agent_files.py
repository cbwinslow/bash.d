#!/usr/bin/env python3
"""Generate per-agent YAML files from the consolidated agents_catalog_configs.yaml

Usage: python scripts/generate_agent_files.py
"""
import os
try:
    import yaml
    HAS_YAML = True
except Exception:
    yaml = None
    HAS_YAML = False

ROOT = os.path.dirname(os.path.dirname(__file__))
SOURCE = os.path.join(ROOT, "configs", "agents_catalog_configs.yaml")
OUT_DIR = os.path.join(ROOT, "configs", "agents")

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(SOURCE, "r") as fh:
        raw = fh.read()

    agents = []
    if HAS_YAML:
        data = yaml.safe_load(raw)
        agents = data.get("agents", [])
    else:
        # Simple fallback splitter for environments without PyYAML.
        # Assumes the consolidated YAML uses top-level 'agents:' and each agent begins
        # with a line indented two spaces then '- id:'. We'll split on '\n  - ' and
        # then prepend the leading '- ' to reconstruct a YAML block per agent.
        parts = raw.split('\n  - ')
        # first part is 'agents:' header; remaining are agent blocks
        header = parts[0]
        for block in parts[1:]:
            # reconstruct the block so it can be parsed by a limited YAML loader
            text = block
            # Make it a valid YAML mapping: ensure top-level 'id:' present
            # Prepend 'id: ' if the split removed the leading '- '
            # We'll do a best-effort conversion: attach '-' lines to produce a YAML fragment
            # Write out the fragment as is (it remains YAML-like), store as text
            # For safe operation, attempt minimal parsing: extract id: line
            lines = text.splitlines()
            # find id line
            id_line = None
            for ln in lines:
                if ln.strip().startswith('id:'):
                    id_line = ln.strip().split(':', 1)[1].strip()
                    break
            agent = {}
            if id_line:
                agent['id'] = id_line
            # store raw text as fallback
            agent['_raw'] = text
            agents.append(agent)
    for agent in agents:
        agent_id = agent.get("id")
        if not agent_id:
            print("Skipping agent without id", agent)
            continue
        out_path = os.path.join(OUT_DIR, f"{agent_id}.yaml")
        with open(out_path, "w") as fh:
            if HAS_YAML and isinstance(agent, dict):
                yaml.safe_dump(agent, fh, sort_keys=False)
            else:
                # write raw fallback text if YAML loader isn't present
                if isinstance(agent, dict) and '_raw' in agent:
                    fh.write(agent['_raw'])
                else:
                    # attempt a basic dump
                    fh.write(str(agent))
        print("Wrote", out_path)

if __name__ == "__main__":
    main()
