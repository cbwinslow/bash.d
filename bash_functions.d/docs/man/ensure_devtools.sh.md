---
title: ensure_devtools.sh
---
Ensure requested dev CLIs are installed and on PATH with idempotent behavior.
Targets (best-effort due to naming ambiguity):
 - opencode
 - codex
 - qwen-coder
 - forgecode
 - kilocode (aka "kilo code")
 - cline
 - roocode (aka "roo code")
 - gemini-cli

Strategy:
 - If command exists, skip.
 - Otherwise try (in order): npm -g, pipx, brew (if available), apt (Debian/Ubuntu).
 - Adjust npm global prefix to $HOME/.npm-global when appropriate.
 - Add $HOME/.local/bin and $HOME/.npm-global/bin to PATH for this run.
 - Clean broken symlinks in common user bin dirs.
