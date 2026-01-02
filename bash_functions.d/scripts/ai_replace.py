#!/usr/bin/env python3
"""AI-assisted secret replacement tool.
Given an .env file with placeholders like {{DB_PASSWORD}}, map placeholders to Bitwarden items
using fuzzy matching and optional AI ranking via OpenRouter.

Safety: secret VALUES are never sent to the AI service. Only placeholder names and candidate ITEM NAMES
and non-sensitive metadata are sent for ranking.

Usage: ai_replace.py --in env.template --out .env [--dry-run] [--interactive]

Requires: BW_SESSION (or unlocked bw). OPENROUTER_API_KEY optional for better ranking.
"""

import argparse
import os
import re
import subprocess
import sys
import json
import tempfile
from typing import Dict, List, Tuple

PLACEHOLDER_RE = re.compile(r"\{\{\s*([A-Za-z0-9_\-]+)\s*\}\}")


def run_cmd(cmd: List[str]) -> Tuple[int, str]:
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True)
        return 0, out
    except subprocess.CalledProcessError as e:
        return e.returncode, e.output or ""


def parse_placeholders(s: str) -> List[str]:
    return list(dict.fromkeys(PLACEHOLDER_RE.findall(s)))


def bw_list_items() -> List[Dict]:
    rc, out = run_cmd(["bw", "list", "items"])
    if rc != 0:
        return []
    return json.loads(out)


def find_candidates_for(name: str, items: List[Dict]) -> List[Tuple[str, str, float]]:
    # simple name similarity: lowercase substring and ratio
    import difflib

    candidates = []
    for it in items:
        nm = it.get("name", "")
        score = difflib.SequenceMatcher(None, name.lower(), nm.lower()).ratio()
        candidates.append((it.get("id"), nm, score))
    candidates.sort(key=lambda x: -x[2])
    return candidates


def rank_with_ai(placeholder: str, candidates: List[Tuple[str, str, float]]) -> List[Tuple[str, str, float]]:
    """If OPENROUTER_API_KEY is present, call OpenRouter to rank candidate names.
    Only send placeholder and candidate NAMES (no secret values). Return reordered candidates.
    If API is not available or call fails, return candidates unchanged.
    """
    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        return candidates
    try:
        import requests
    except Exception:
        return candidates
    # Build a simple prompt asking the model to rank candidates by likely match to placeholder name.
    prompt = (
        "You are a harmless assistant that ranks secret item NAMES against a placeholder name.\n"
        "Do NOT request or accept secret values. You will be given a placeholder name and a numbered list of candidate item names.\n"
        "Return a JSON array of indices (0-based) in order of most likely match to least.\n"
        "Placeholder: \"%s\"\nCandidates:\n" % placeholder
    )
    for i, (_, nm, score) in enumerate(candidates[:10]):
        prompt += f"{i}: {nm}\n"
    prompt += "\nRespond with a JSON array of indices, e.g. [0,2,1]. If uncertain, prefer earlier items."

    body = {
        "model": "meta-llama/llama-3.2-3b-instruct:free",
        "messages": [
            {"role": "system", "content": "You rank candidate NAMES for a placeholder. NEVER request secret values."},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.0,
        "max_tokens": 256,
    }
    try:
        headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
        resp = requests.post("https://api.openrouter.ai/v1/chat/completions", headers=headers, json=body, timeout=10)
        if resp.status_code != 200:
            return candidates
        data = resp.json()
        # Extract text from assistant
        text = ""
        if isinstance(data, dict):
            # support standard OpenRouter chat response shape
            choices = data.get("choices") or []
            if choices:
                text = choices[0].get("message", {}).get("content", "")
        if not text:
            return candidates
        # parse JSON array from text
        import re
        m = re.search(r"\[.*\]", text)
        order = None
        if m:
            order = json.loads(m.group(0))
        else:
            # fallback: extract integers
            nums = [int(s) for s in re.findall(r"\\d+", text)]
            order = nums if nums else None
        if not order:
            return candidates
        # remap candidates
        ordered = []
        for idx in order:
            if 0 <= idx < len(candidates):
                ordered.append(candidates[idx])
        # append any missing candidates at end
        for c in candidates:
            if c not in ordered:
                ordered.append(c)
        return ordered
    except Exception:
        return candidates


def get_secret_for_item(item_id: str) -> str:
    rc, out = run_cmd(["bw", "get", "password", item_id])
    if rc == 0 and out:
        return out.strip()
    # try fields
    rc, out = run_cmd(["bw", "get", "item", item_id])
    if rc != 0:
        return ""
    item = json.loads(out)
    for f in item.get("fields", []) or []:
        if f.get("purpose") in ("PASSWORD",) or f.get("name", "").lower() in ("password", "token", "api_key", "secret"):
            return f.get("value", "")
    return ""


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--in", dest="infile", required=True)
    p.add_argument("--out", dest="outfile", required=True)
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--interactive", action="store_true")
    args = p.parse_args()

    if not os.path.isfile(args.infile):
        print("Input file not found", file=sys.stderr)
        sys.exit(2)

    with open(args.infile) as f:
        content = f.read()

    placeholders = parse_placeholders(content)
    if not placeholders:
        print("No placeholders found; copying file.")
        if not args.dry_run:
            with open(args.outfile, "w") as o:
                o.write(content)
        sys.exit(0)

    items = bw_list_items()

    mapping = {}

    for ph in placeholders:
        candidates = find_candidates_for(ph, items)
        if not candidates:
            print(f"No candidates found for {ph}")
            continue
        # attempt AI ranking if available
        ranked = rank_with_ai(ph, candidates)
        if args.interactive:
            print(f"Placeholder: {ph}")
            for idx, (cid, cname, score) in enumerate(ranked[:7]):
                print(f"  [{idx}] {cname} (score={score:.3f})")
            choice = input(f"Choose index for {ph} [0] or enter to skip: ")
            if choice.strip() == "":
                chosen = (ranked[0][0], ranked[0][1])
            else:
                try:
                    i = int(choice.strip())
                    chosen = (ranked[i][0], ranked[i][1])
                except Exception:
                    chosen = (ranked[0][0], ranked[0][1])
        else:
            chosen = (ranked[0][0], ranked[0][1])
        mapping[ph] = chosen

    # dry-run: print mapping
    if args.dry_run:
        for k, (iid, nm) in mapping.items():
            print(f"{k} -> {nm} ({iid})")
        sys.exit(0)

    # Replace placeholders by fetching secrets locally
    out_content = content
    for ph, (iid, nm) in mapping.items():
        secret = get_secret_for_item(iid)
        if not secret:
            print(f"Warning: no secret value for {ph} from {nm}", file=sys.stderr)
            continue
        out_content = re.sub(r"\{\{\s*" + re.escape(ph) + r"\s*\}\}", secret, out_content)

    with open(args.outfile, "w") as o:
        o.write(out_content)
    os.chmod(args.outfile, 0o600)
    print(f"Wrote {args.outfile} (600)")


if __name__ == "__main__":
    main()
