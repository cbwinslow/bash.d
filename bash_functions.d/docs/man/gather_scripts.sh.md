---
title: gather_scripts.sh
---
Gather scripts from the filesystem, optionally rename (AI/heuristic), organize,
and add them to a target repo folder. Supports copy or move.

Key functions:
  gather_scripts_copy --from <PATH> [--to <DIR>] [--pattern "*.sh"] [--ai] [--rename] [--organize]
  gather_scripts_move --from <PATH> [--to <DIR>] [--pattern "*.sh"] [--ai] [--rename] [--organize]
  organize_scripts_ai <DIR>
  ai_suggest_name <FILE>
  upload_gathered --src <DIR> --repo-path <SUBDIR> --msg "commit message" [--force]

Notes:
- AI rename uses OpenRouter if OPENROUTER_API_KEY is present. Falls back to heuristic.
- Secrets are not sent: only file basename and a short summary (first lines sans content-like strings).
- Uses gh_add_and_commit (from gh_helpers.sh) when available.
