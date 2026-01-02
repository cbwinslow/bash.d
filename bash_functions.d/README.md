bash_functions.d - organized shell functions, aliases, and tools

Layout

- core/                     - core loaders, aliases, functions, path/plugin management
  - aliases.sh              - top-level alias definitions
  - functions.sh            - top-level function helpers
  - source_all.sh           - legacy loader (maintained)
  - load_ordered.sh         - deterministic loader sourcing core/, tools/, completions/, tui/
  - path_manager.sh         - manage PATH entries
  - plugin_manager.sh       - oh-my-bash-like plugin manager
  - debug_decorators.sh     - debug and testing decorators
  - exports.sh              - environment exports
  - paths.sh                - path configurations
  - help.sh                 - help functions
  - agents/                 - AI agent management
    - agent_runner.sh       - agent execution script
    - manifest.json         - agent manifest
- tools/                    - specific tools and utilities
  - secrets_tool.sh         - Bitwarden-based secrets helper
  - bw_agent.sh             - Bitwarden agent-friendly wrapper for non-interactive access
  - deploy_to_github.sh     - package & push to GitHub with secrets scan
  - scan_secrets.sh         - secrets scanner for pre-commit/CI
  - script_inventory.sh     - build JSON inventory of scripts
  - tldr_generator.sh       - generate TLDR summaries
  - doc_verifier.sh         - verify scripts have header docs
  - install_precommit_hook.sh - install git pre-commit hook
  - bf_docs.sh              - docs lookup CLI
  - generate_man_index.sh   - generate man pages from headers
  - validate_system.sh      - validate system setup
  - autocorrect_system.sh   - autocorrect system issues (e.g., reinstall tools)
  - github_api.sh           - GitHub API wrapper functions
  - gitlab_api.sh           - GitLab API wrapper functions
  - setup_secrets.sh        - setup bash_secrets.d with tokens
- completions/              - bash completion helpers
  - completion_helpers.sh   - helpers to generate completions
  - completions.sh          - example completions
  - agent_completion.sh     - agent-specific completions
  - generate_agent_completion.sh - generate agent completions
- docs/                     - generated documentation
  - man/                    - man pages from script headers
  - tldr/                   - TLDR summaries
  - ENCRYPTION.md           - encryption system documentation
  - CONVENTIONS.md          - coding conventions
- plugins/                  - plugin management
  - enabled_env.sh          - auto-generated plugin environment
  - ai-tools/               - AI query tools using OpenRouter
  - rag-tools/              - RAG implementation with local knowledge
  - vector-db/              - Vector database tools
  - docker-tools/           - Docker management utilities
  - self-heal/              - Self-healing system analysis
  - auto-tasks/             - Auto task finding and solving
- tui/                      - TUI tools and go-term
  - cmd/                    - Go commands
    - term/                 - TUI terminal
    - wish-server/          - SSH server
  - approve_request.sh      - request approval CLI
  - install_allowlist.sh    - allowlist installer
  - install_wish_service.sh - service installer

Quick start

1) Source helpers in your ~/.bashrc (recommended ordered loader):

```bash
source ~/bash_functions.d/core/load_ordered.sh
```

2) Enable debugging and testing:

```bash
export DEBUG_BASH=1  # Enable debug logging
export TEST_MODE=1   # Enable test mode
```

3) Validate and autocorrect the system:

```bash
# Validate setup
~/bash_functions.d/tools/validate_system.sh

# Autocorrect issues (e.g., reinstall missing tools like OpenCode)
~/bash_functions.d/tools/autocorrect_system.sh
```

4) Use aliases & functions

- `bfdocs` - docs lookup
- `bfdeploy` - deploy script (dry-run)
- `bf_find <pattern>` - fuzzy search
- `secrets_tool.sh lookup <name>` - Bitwarden lookup
- `secrets_tool.sh fill-template template.env.tpl .env` - fill .env values from Bitwarden

5) Debug and test functions:

```bash
# Use decorators
time_decorator my_function arg1 arg2
error_decorator my_function arg1 arg2

# Run delegate actions
run_delegate debug my_function arg1
run_delegate test my_function arg1
run_delegate document my_function arg1

# Run test suites
run_tests test_func1 test_func2
```

### Secrets Management: `~/.bash_secrets.d/`
**Recommendation**: Folder structure for better organization and security.
- `~/.bash_secrets.d/github/token.age` - Encrypted GitHub Personal Access Token
- `~/.bash_secrets.d/gitlab/token.age` - Encrypted GitLab Personal Access Token
- `~/.bash_secrets.d/openrouter/token.age` - Encrypted OpenRouter API Key
- `~/.bash_secrets.d/age_key.txt` - Age private key for decryption
- Uses `age` (Go-based encryption tool) for secure storage
- Tokens are automatically decrypted when needed by scripts
- See `docs/ENCRYPTION.md` for full documentation
