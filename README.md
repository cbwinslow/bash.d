# bash.d

An advanced, modular Bash profile with optional Oh My Bash, AI assistants powered by OpenRouter, and self-healing behaviors.

## Layout
- `bashrc` – entry point sourced by `~/.bashrc`; sets up directories and loads modules.
- `bash_aliases.d/` – alias bundles.
- `bash_functions.d/` – core helpers and AI wrappers.
- `bash_env.d/` – environment adjustments (PATH, history paths, etc.).
- `bash_prompt.d/` – prompt customization when Oh My Bash is absent.
- `bash_completions.d/` – drop-in completion scripts.
- `bash_secrets.d/` – user-specific secrets (gitignored).
- `bash_history.d/` – isolated history storage (gitignored).
- `ai/` – OpenRouter-powered agent CLI with local memory and GitHub publishing helper.
- `bin/` – executable helpers (e.g., `bashd-ai`).

## Bootstrap
```bash
./bootstrap.sh
```
This copies the repo into `~/.bash.d` (or `$BASHD_HOME`) and ensures `~/.bashrc` sources `bashrc`.

To install Oh My Bash later, run:
```bash
bashd_install_oh_my_bash
```

## AI agents
Prerequisites:
- `OPENROUTER_API_KEY` environment variable.
- `python3` and `requests` available.

Examples:
```bash
bashd_ai_chat "How do I tail logs efficiently?"
bashd_ai_debug "Command not found: foo"
bashd_ai_tldr "tar"
bashd_ai_publish_function my_helper_function
```

The `ai/agent.py` script maintains short- and long-term memory under `$BASHD_STATE_DIR`, logs interactions, and can clone/update `cbwinslow/bashrc` to stage new functions with automatic placement and documentation prompts.
