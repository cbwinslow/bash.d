# Project Structure

This document describes the organized directory structure of the bash.d project following industry-standard conventions.

## Root Directory

```
bash.d/
├── .bashrc                    # Main bash configuration (kept for user convenience)
├── .gitignore                 # Git ignore rules
├── bashrc                     # Symlink to config/bashrc-variants/bashrc.main
├── bootstrap.sh               # Quick bootstrap script
├── install.sh                 # Main installation script
├── requirements.txt           # Python dependencies
├── README.md                  # Main project documentation
├── CONTRIBUTING.md            # Contribution guidelines
├── QUICKSTART.md              # Quick start guide
├── MASTER_INDEX.md            # Master index of features
└── [directories below...]
```

## Core Directories

### `/agents/`
Python-based AI agent system for autonomous development.

```
agents/
├── algorithms/        # Algorithm-focused agents
├── automation/        # Task automation agents
├── devops/           # DevOps and infrastructure agents
├── documentation/    # Documentation generation agents
├── programming/      # Language-specific programming agents
├── security/         # Security and vulnerability agents
└── testing/          # Testing and QA agents
```

### `/bash_functions.d/`
Modular bash functions organized by category.

```
bash_functions.d/
├── core/             # Core system functions (loading, indexing, search)
├── utils/            # Utility functions (git, docker, network, parsing)
├── ai/               # AI integration functions
├── ai_coding_tools/  # IDE integration (Cline, Roo-Code, Continue)
├── plugins/          # Plugin system (self-heal, auto-tasks, RAG)
├── tools/            # System tools and helpers
├── 40-agents/        # Agent helper functions
├── 60-aliases/       # Alias definitions
├── 90-security/      # Security functions
└── [other modules]
```

### `/scripts/`
Organized executable scripts by purpose.

```
scripts/
├── setup/            # Installation and setup scripts
│   ├── install-bash-it.sh
│   ├── setup-agent-zero-cloudflare.sh
│   ├── setup-cloudflare-agents.sh
│   ├── setup-cloudflare-features.sh
│   ├── setup-monitor.sh
│   └── setup-tools.sh
├── security/         # Security-related scripts
│   ├── iptables-anonymity.sh
│   ├── iptables-cheat-sheet.sh
│   ├── port-scan-detector.sh
│   ├── security-dashboard-launcher.sh
│   └── security-toolkit-summary.sh
├── network/          # Network monitoring and tools
│   ├── network-security-monitor.sh
│   └── network-security-monitoring.sh
├── monitoring/       # System monitoring scripts
│   ├── alert-daemon.py
│   ├── system-health.sh
│   └── system-monitor.py
├── test/             # Testing scripts
│   ├── test-bashrc.sh
│   ├── test-ai-integration.sh
│   ├── test-modular-system.sh
│   ├── shell-debug-analyzer.sh
│   └── validate-master-agent.py
└── tools/            # Utility tools
    ├── demo-autonomous-builder.py
    ├── function-catalog-analysis.sh
    └── [other tools]
```

### `/docs/`
All project documentation organized by category.

```
docs/
├── implementation/   # Implementation and integration docs
│   ├── AI_INTEGRATION_SUMMARY.md
│   ├── INTEGRATION_GUIDE.md
│   ├── SECURITY_INTEGRATION_COMPLETE.md
│   └── [other implementation docs]
├── guides/           # User guides and how-tos
│   ├── AUTONOMOUS_APP_BUILDER.md
│   ├── MASTER_AGENT_GUIDE.md
│   ├── MULTIAGENT_README.md
│   └── [other guides]
├── reports/          # Status reports and analysis
│   ├── COMPREHENSIVE_FUNCTION_ANALYSIS_REPORT.md
│   ├── VALIDATION_REPORT.md
│   └── [other reports]
├── architecture/     # Architecture documentation
│   ├── agent-zero-cloudflare-plan.md
│   ├── agent_config_tools_manager_architecture.md
│   └── [other architecture docs]
├── agents/           # Agent-specific documentation
├── TOOLS_OVERVIEW.md
├── TOOLS_README.md
└── tasks.md
```

### `/config/`
Configuration files and templates.

```
config/
├── bashrc-variants/  # Various bashrc configurations
│   ├── .bashrc.backup
│   ├── .bashrc.minimal
│   └── bashrc.main
├── .env.example      # Environment variable template
├── docker-compose.yml
├── Dockerfile
├── mcp_server_config.json
├── SYSTEM_INDEX.json
├── bitlocker-mount.service
├── bitlocker-mount-prompt.service
└── proton.hatchet
```

### `/tools/`
Python tool modules and utilities.

```
tools/
├── __init__.py
├── registry.py          # Tool registry
├── base.py             # Base tool classes
├── api_http_tools.py   # HTTP/API tools
├── bitwarden_tools.py  # Bitwarden integration
├── docker_tools.py     # Docker utilities
├── filesystem_tools.py # File system operations
├── git_tools.py        # Git operations
├── system_tools.py     # System utilities
└── security/           # Security tools
```

### `/lib/`
Core library functions for bash.d framework.

```
lib/
├── bash-it-integration.sh  # bash-it framework integration
├── bash-it-compat.sh       # Compatibility layer
├── bash-it-plugin.bash     # Plugin interface
├── module-manager.sh       # Module management
└── indexer.sh              # Function indexing system
```

## Supporting Directories

### `/aliases/`
Alias definitions organized by category.
- `git.aliases.bash` - Git shortcuts
- `docker.aliases.bash` - Docker shortcuts
- `general.aliases.bash` - General aliases

### `/completions/`
Bash completion scripts.

### `/bin/`
Binary wrappers and executables.
- `bashd-ai` - AI CLI wrapper

### `/configs/`
Additional configuration directories.
- `agents/` - Agent configurations
- `bash/` - Bash-specific configs
- `bitwarden/` - Bitwarden configs

### `/external/`
External dependencies and third-party tools.
```
external/
├── 4nonimizer/       # Anonymization tool
├── bitlocker/        # Bitlocker utilities
├── kali-anonymous/   # Kali anonymity tools
├── mirror/           # OpenAI mirror/proxy
└── tldr/             # TLDR pages
```

### `/packages/`
Binary packages and installers.
- `protonvpn-stable-release_1.0.8_all.deb`

## Bash.d Module Directories

The following directories are part of the modular bash configuration system:

- `/bash_aliases.d/` - Additional alias files
- `/bash_env.d/` - Environment variable definitions
- `/bash_history.d/` - History configuration
- `/bash_prompt.d/` - Prompt customization
- `/bash_secrets.d/` - Secrets (git-ignored)
- `/plugins/` - Plugin implementations
- `/examples/` - Example configurations
- `/tests/` - Test files

## Other Directories

- `/ai/` - AI integration files
- `/crewai_config/` - CrewAI configuration
- `/multi-agent-collaboration-system/` - Multi-agent system
- `/os-config/` - OS-specific configurations
- `/web/` - Web interface files

## Naming Conventions

### Scripts
- Use **kebab-case** for all script files
- Format: `verb-noun-modifier.sh` or `noun-action.py`
- Examples: `setup-tools.sh`, `test-bashrc.sh`, `system-monitor.py`

### Directories
- Use **lowercase** with underscores or hyphens
- Be descriptive and singular/plural as appropriate
- Examples: `bash_functions.d`, `scripts/setup`, `docs/guides`

### Documentation
- Use **UPPERCASE** for major documents in root
- Use **descriptive names** with underscores for clarity
- Examples: `README.md`, `CONTRIBUTING.md`, `AI_INTEGRATION_SUMMARY.md`

## File Organization Principles

1. **Separation of Concerns**: Code, docs, configs, and scripts are in separate directories
2. **Clear Hierarchy**: Subdirectories organize files by function/purpose
3. **Discoverability**: Logical structure makes files easy to find
4. **Maintainability**: Related files are grouped together
5. **Backward Compatibility**: Symlinks preserve existing workflows

## Migration Notes

The following files have been reorganized:

- Documentation moved from root to `/docs/` subdirectories
- Scripts moved from root to `/scripts/` subdirectories
- Config files moved to `/config/`
- External tools moved to `/external/`
- All scripts renamed to kebab-case convention
- Symlink `bashrc` created for backward compatibility

## See Also

- [README.md](../README.md) - Main project documentation
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide
