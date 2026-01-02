Bash utilities: Bitwarden helpers, AI-assisted env replacement, GitHub helpers, fuzzy search, and Linux utilities

Quick start:
- Source functions: source /home/cbwinslow/bash_functions.d/load_ordered.sh
- Ensure BW session: bw login; export BW_SESSION=$(bw unlock --raw)
- Agent-friendly BW access: /home/cbwinslow/bash_functions.d/tools/bw_agent.sh ensure
- Build env: bw_build_env --pattern DB_* --out /tmp/dev.env
- AI replace: python3 /home/cbwinslow/bash_functions.d/scripts/ai_replace.py --in template.env --out .env --dry-run

Script gathering and repo ops:
- Gather scripts: gather_scripts_copy --from ~/bin --to /tmp/gathered --rename --organize
- Move scripts: gather_scripts_move --from ~/Downloads --to /tmp/gathered --rename --organize
- Upload gathered into repo: upload_gathered --src /tmp/gathered --repo-path extras/scripts --msg "import scripts"
- Set tokens: gh_token_set <GH_PAT>; gl_token_set <GL_PAT> [--host gitlab.example.com]
- Mirror GH->GL: mirror_github_to_gitlab my-gh-org my-gl-group
- Mirror GL->GH: mirror_gitlab_to_github my-gl-group my-gh-org
- Mass op across repos: gh_for_each_repo my-gh-org -- run 'rg -n TODO || true'

Security:
- Secrets are never sent to AI. Temporary files are chmod 600.
- gh_add_and_commit refuses to commit files with likely secrets unless --force is used.

Dependencies:
- bw, jq, git, gh (optional), rg, fzf, python3, curl, jq, openrouter (optional)

Layout & loader:
- Prefer using `load_ordered.sh` which loads directories in this order: 00-env, 10-paths, 20-core, 30-plugins, 40-agents, 50-completions, 60-aliases, 70-dotfiles, 80-tui, 90-local.
- Conventions are in `CONVENTIONS.md`.
