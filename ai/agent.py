#!/usr/bin/env python3
"""AI agent utilities for bash.d.

Features:
- Chat, debugging, TLDR, code completion via OpenRouter.
- Function publishing helper that can classify and stage functions into a target repo.
- Simple memory and reinforcement signals stored locally under $BASHD_STATE_DIR.
"""

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import subprocess
import sys
from typing import Dict, List

import requests

DEFAULT_MODEL = os.environ.get("BASHD_AI_MODEL", "meta-llama/llama-3.2-3b-instruct:free")
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
BASHD_STATE_DIR = Path(os.environ.get("BASHD_STATE_DIR", Path.home() / ".bash.d" / "state"))
MEMORY_FILE = BASHD_STATE_DIR / "memory.json"
LOG_DIR = BASHD_STATE_DIR / "logs"
REPO_CACHE = BASHD_STATE_DIR / "repos"


def ensure_state() -> None:
  BASHD_STATE_DIR.mkdir(parents=True, exist_ok=True)
  LOG_DIR.mkdir(parents=True, exist_ok=True)
  REPO_CACHE.mkdir(parents=True, exist_ok=True)


def load_memory() -> Dict[str, List[str]]:
  ensure_state()
  if not MEMORY_FILE.exists():
    return {"short_term": [], "long_term": []}
  with open(MEMORY_FILE, "r", encoding="utf-8") as fh:
    return json.load(fh)


def save_memory(memory: Dict[str, List[str]]) -> None:
  ensure_state()
  with open(MEMORY_FILE, "w", encoding="utf-8") as fh:
    json.dump(memory, fh, indent=2)


def append_memory(kind: str, entry: str) -> None:
  memory = load_memory()
  memory.setdefault(kind, []).append(entry)
  memory[kind] = memory[kind][-50:]
  save_memory(memory)


def openrouter_request(prompt: str, system_prompt: str = "", model: str = DEFAULT_MODEL) -> str:
  api_key = os.environ.get("OPENROUTER_API_KEY")
  if not api_key:
    raise RuntimeError(
        "OPENROUTER_API_KEY is required for AI interactions. "
        "Set the OPENROUTER_API_KEY environment variable (get your key at https://openrouter.ai/keys)."
    )
  payload = {
    "model": model,
    "messages": [
      {"role": "system", "content": system_prompt or "You are a bash-oriented assistant."},
      {"role": "user", "content": prompt},
    ],
  }
  headers = {"Authorization": f"Bearer {api_key}"}
  response = requests.post(OPENROUTER_URL, json=payload, headers=headers, timeout=60)
  response.raise_for_status()
  data = response.json()
  message = data["choices"][0]["message"]["content"]
  return message


def log_interaction(mode: str, prompt: str, response: str) -> None:
  ensure_state()
  stamp = dt.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
  log_file = LOG_DIR / f"ai-{mode}-{stamp}.md"
  with open(log_file, "w", encoding="utf-8") as fh:
    fh.write(f"# {mode}\n\n## Prompt\n{prompt}\n\n## Response\n{response}\n")


def chat(prompt: str, mode: str) -> str:
  system_prompt = "High-signal, shell-savvy assistant with concise but actionable output."
  if mode == "debug":
    system_prompt = "Assist with debugging shell sessions; prefer minimal, testable steps."
  elif mode == "tldr":
    system_prompt = "Summarize command usage with short examples."
  reply = openrouter_request(prompt, system_prompt=system_prompt)
  append_memory("short_term", f"{mode}:{prompt} -> {reply}")
  log_interaction(mode, prompt, reply)
  return reply


def classify_function(name: str, body: str) -> Dict[str, str]:
  prompt = (
    "Given a bash function and its body, decide the best relative path inside a modular "
    "bash.d layout (candidates: bash_functions.d, bash_aliases.d, bash_completions.d, "
    "bash_prompt.d). Return JSON with fields file, rationale, documentation."
  )
  user = f"Function name: {name}\n\nBody:\n{body}"
  system_prompt = "You are a repo curator. Choose deterministic, minimal file names like core.sh."
  reply = openrouter_request(f"{prompt}\n\n{user}", system_prompt=system_prompt)
  try:
    return json.loads(reply)
  except json.JSONDecodeError:
    return {"file": "bash_functions.d/generated.sh", "rationale": reply, "documentation": ""}


def ensure_repo(repo_slug: str) -> Path:
  ensure_state()
  target = REPO_CACHE / repo_slug.replace("/", "__")
  if target.exists():
    try:
      subprocess.run(["git", "-C", str(target), "pull", "--rebase"], check=True)
    except subprocess.CalledProcessError as e:
      print(f"Error: git pull failed for {repo_slug} at {target}: {e}", file=sys.stderr)
      raise
    return target
  try:
    subprocess.run(["git", "clone", f"https://github.com/{repo_slug}.git", str(target)], check=True)
  except subprocess.CalledProcessError as e:
    print(f"Error: git clone failed for {repo_slug} at {target}: {e}", file=sys.stderr)
    raise
  return target


def publish_function(name: str, body: str, repo_slug: str) -> str:
  classification = classify_function(name, body)
  repo_path = ensure_repo(repo_slug)
  relative_file = classification.get("file", "bash_functions.d/generated.sh")
  destination = repo_path / relative_file
  destination.parent.mkdir(parents=True, exist_ok=True)
  with open(destination, "a", encoding="utf-8") as fh:
    fh.write(f"\n# Added by AI agent on {dt.datetime.utcnow().isoformat()}Z\n")
    if classification.get("documentation"):
      fh.write(f"# {classification['documentation']}\n")
    fh.write(body)
    fh.write("\n")
  add_result = subprocess.run(
    ["git", "-C", str(repo_path), "add", relative_file],
    capture_output=True, text=True
  )
  if add_result.returncode != 0:
    error_msg = f"Failed to add file to git: {add_result.stderr.strip()}"
    append_memory("short_term", f"error:{error_msg}")
    return error_msg
  commit_message = f"Add function {name} via AI agent"
  commit_result = subprocess.run(
    ["git", "-C", str(repo_path), "commit", "-m", commit_message],
    capture_output=True, text=True
  )
  if commit_result.returncode != 0:
    error_msg = f"Failed to commit changes: {commit_result.stderr.strip()}"
    append_memory("short_term", f"error:{error_msg}")
    return error_msg
  append_memory("long_term", f"Published {name} to {repo_slug}:{relative_file}")
  return f"Staged {name} into {repo_path} at {relative_file}. Review and push when ready."


def main(argv: List[str]) -> int:
  parser = argparse.ArgumentParser(description="AI agents for bash.d")
  sub = parser.add_subparsers(dest="command", required=True)

  chat_parser = sub.add_parser("chat", help="General chat")
  chat_parser.add_argument("prompt", nargs='+')
  chat_parser.add_argument("--mode", choices=["chat", "debug", "tldr", "code"], default="chat")

  publish_parser = sub.add_parser("publish-function", help="Send a function to a repo")
  publish_parser.add_argument("name")
  publish_parser.add_argument("body")
  publish_parser.add_argument("--repo", default="cbwinslow/bashrc")

  args = parser.parse_args(argv)
  try:
    if args.command == "chat":
      print(chat(" ".join(args.prompt), args.mode))
    elif args.command == "publish-function":
      print(publish_function(args.name, args.body, args.repo))
  except (RuntimeError, requests.exceptions.RequestException, subprocess.CalledProcessError) as exc:
    append_memory("short_term", f"error:{exc}")
    sys.stderr.write(f"Error: {exc}\n")
    raise
  return 0


if __name__ == "__main__":
  raise SystemExit(main(sys.argv[1:]))
