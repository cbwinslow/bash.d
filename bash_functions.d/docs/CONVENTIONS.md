Conventions for bash_functions.d

File layout and naming
- Directories are loaded in a deterministic order by `load_ordered.sh`.
- Use numeric-prefix directories (e.g., `00-env`, `10-paths`, `20-core`, `30-plugins`, `40-agents`, `50-completions`, `60-aliases`, `70-dotfiles`, `80-tui`, `90-local`).
- Within each dir, files are sourced in lexical order. Use numeric prefixes on filenames if you need stricter ordering (e.g., `10-init.sh`, `20-vars.sh`).

Symbol rules
- Exported/Stable functions should be named with a `bf_` or `bw_` prefix for clarity (e.g., `bf_help`, `bw_build_env`).
- Private helpers: prefix with underscore, e.g., `_bf_log`, `_bw_internal`.
- Avoid exporting secrets or raw tokens. Prefer explicit getter functions.

Security
- Temporary files must be created with `mktemp` and set to `chmod 600`.
- Never send secrets (values) to external AI services. Only send metadata (names/descriptions) for ranking.

Agents and tools
- Agents should be declared in `agents/manifest.json` describing required tools and allowed actions.
- An agent-runner should enforce an execution policy and log actions without leaking secrets.

Dotfiles
- Use `dotfiles/secrets/*.age` for encrypted secrets (age recommended). Provide `dotman` helper for encryption/decryption.

