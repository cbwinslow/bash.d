# System Organization & Architecture Diagram

## 📁 File System Hierarchy

```
bash_functions.d/
│
├── 🚀 BOOTSTRAP LAYER
│   ├── setup.sh                          # Initial system setup
│   ├── load_ordered.sh                   # Main loading orchestrator
│   └── source_all.sh                     # Legacy compatibility loader
│
├── 🔧 CORE SYSTEM
│   ├── aliases.sh                        # Core shell aliases
│   ├── functions.sh                      # Core utility functions
│   ├── debug_decorators.sh               # Testing and debugging decorators
│   ├── exports.sh                        # Environment variable exports
│   ├── paths.sh                          # PATH configuration
│   ├── path_manager.sh                   # Dynamic PATH management
│   ├── plugin_manager.sh                 # Plugin system orchestration
│   ├── load_core.sh                      # Core system loader
│   ├── help.sh                           # Built-in help system
│   │
│   ├── agents/                           # AI Agent Management
│   │   ├── agent_runner.sh               # Agent execution engine
│   │   └── manifest.json                 # Agent configuration
│   │
│   ├── environment/                      # Environment Management
│   │   ├── paths.sh                      # PATH management
│   │   ├── exports.sh                    # Environment exports
│   │   └── variables.sh                  # Shell variables
│   │
│   ├── aliases/                          # Alias Organization
│   │   ├── 10-core.sh                    # Core aliases
│   │   ├── 20-git.sh                     # Git-related aliases
│   │   ├── 30-dev.sh                     # Development aliases
│   │   └── 40-system.sh                  # System administration aliases
│   │
│   ├── functions/                        # Function Organization
│   │   ├── 10-fileops.sh                 # File operations
│   │   ├── 20-gitops.sh                  # Git operations
│   │   ├── 30-netops.sh                  # Network operations
│   │   └── 40-devops.sh                  # Development operations
│   │
│   ├── utilities/                        # Utility Functions
│   │   ├── help.sh                       # Help system
│   │   ├── debug.sh                      # Debug utilities
│   │   └── completion.sh                 # Completion helpers
│   │
│   └── plugin_system/                    # Plugin Architecture
│       ├── plugin_manager.sh             # Plugin management
│       ├── manifest.sh                   # Plugin manifests
│       └── registry.sh                   # Plugin registry
│
├── 🛠️ TOOLS ECOSYSTEM
│   ├── automation/                       # Automation Tools
│   │   ├── deployment/                   # CI/CD utilities
│   │   ├── monitoring/                   # System monitoring
│   │   └── maintenance/                  # System maintenance
│   │
│   ├── development/                      # Development Tools
│   │   ├── ai_tools/                     # AI coding assistants
│   │   │   ├── ai_tools_install.sh       # Master installer
│   │   │   ├── forgecode_latest.sh       # Forgecode installer
│   │   │   ├── qwen_code_latest.sh       # Qwen Code installer
│   │   │   ├── cline_latest.sh           # Cline installer
│   │   │   └── setup_direnv_nvm.sh       # Environment setup
│   │   ├── git_tools/                    # Git enhancements
│   │   ├── editor_tools/                 # Editor integration
│   │   └── testing/                      # Testing frameworks
│   │
│   ├── system/                           # System Administration
│   │   ├── admin_tools/                  # System administration
│   │   ├── network_tools/                # Network utilities
│   │   ├── file_tools/                   # File management
│   │   └── security_tools/               # Security utilities
│   │
│   └── integration/                      # External Integrations
│       ├── github_api.sh                 # GitHub API wrapper
│       ├── gitlab_api.sh                 # GitLab API wrapper
│       └── webhooks/                     # Webhook handlers
│
├── 🤖 AI CODING TOOLS ECOSYSTEM
│   ├── .envrc                            # Direnv configuration
│   ├── README.md                         # AI tools documentation
│   ├── ai_tools_install.sh               # Master installer
│   ├── setup_direnv_nvm.sh              # Direnv + NVM setup
│   ├── forgecode_latest.sh              # Forgecode installation
│   ├── qwen_code_latest.sh              # Qwen Code installation
│   ├── cline_latest.sh                  # Cline installation
│   ├── continue_latest.sh               # Continue installation
│   ├── roo_code_latest.sh               # Roo Code installation
│   ├── kilo_code_latest.sh              # Kilo Code installation
│   ├── gemini_cli_latest.sh             # Gemini CLI installation
│   └── codex_latest.sh                  # Codex CLI installation
│
├── 🔌 PLUGIN SYSTEM
│   ├── enabled_env.sh                   # Auto-generated plugin environment
│   ├── ai-tools/                        # AI Tools Plugin
│   │   ├── init.sh                      # Plugin initialization
│   │   └── bin/                         # Executables
│   ├── auto-tasks/                      # Auto Tasks Plugin
│   ├── rag-tools/                       # RAG Implementation
│   ├── vector-db/                       # Vector Database Tools
│   └── self-heal/                       # Self-healing System
│
├── 📚 DOCUMENTATION SYSTEM
│   ├── CONVENTIONS.md                   # Coding conventions
│   ├── ENCRYPTION.md                    # Encryption documentation
│   ├── WORKFLOW_ANALYSIS.md             # This workflow analysis
│   ├── SYSTEM_ORGANIZATION.md           # System organization
│   ├── INVENTORY_ANALYSIS.md            # Inventory analysis
│   ├── ORGANIZATION_PLAN.md             # Organization improvement plan
│   │
│   └── man/                             # Generated man pages
│       ├── 00-aliases.sh.md             # Aliases documentation
│       ├── 00-help.sh.md                # Help documentation
│       ├── 10-exports.sh.md             # Exports documentation
│       └── [other script documentation]
│
├── 🧪 TESTING FRAMEWORK
│   ├── test_suite.sh                    # Main test suite
│   ├── ai_agent_verification.sh         # AI agent verification
│   ├── validate_env.sh                  # Environment validation
│   ├── test_install_preview.sh          # Installation preview
│   ├── test_requests_flow.sh            # Request flow testing
│   └── test_service_check.sh            # Service health checks
│
├── 🎯 TERMINAL UI & CLI
│   ├── README.md                        # TUI documentation
│   ├── approve_request.sh               # Request approval CLI
│   ├── install_allowlist.sh             # Allowlist installer
│   ├── install_wish_service.sh          # Service installer
│   ├── generate_host_key.sh             # Host key generation
│   │
│   ├── cmd/                             # Go Commands
│   │   ├── wish-server/                 # SSH server
│   │   ├── term/                        # Terminal interface
│   │   └── sshserver/                   # SSH server implementation
│   │
│   ├── TESTING.md                       # Testing procedures
│   ├── sample_allowlist.json            # Allowlist example
│   └── wish-server.service.sample       # Systemd service template
│
├── 🎨 BASH FUNCTIONS (Top Level)
│   ├── ai_tools_functions.sh            # AI tools wrapper functions
│   ├── ai_tools_loader.sh               # AI tools loader
│   ├── aliases_tools.sh                 # Alias management tools
│   ├── backup.sh                        # Backup utilities
│   ├── bw_fuzzy.sh                      # Bitwarden fuzzy search
│   ├── bw_helpers.sh                    # Bitwarden helpers
│   ├── check_port.sh                    # Port checking utilities
│   ├── dfh.sh                           # Disk usage helpers
│   ├── docker_clean.sh                  # Docker cleanup
│   ├── dsize.sh                         # Directory size analysis
│   ├── ensure_devtools.sh               # Development tools installer
│   ├── extract.sh                       # Archive extraction
│   ├── findreplace.sh                   # Find and replace utilities
│   ├── fstr.sh                          # Fuzzy search tools
│   ├── fuzzy_search.sh                  # Advanced fuzzy search
│   ├── gather_scripts.sh                # Script collection
│   ├── gh_gl_helpers.sh                 # GitHub/GitLab helpers
│   ├── gh_helpers.sh                    # GitHub helpers
│   ├── git_status_all.sh                # Git status across repos
│   ├── install_add_to_bashrc.sh         # Bashrc installer
│   ├── install_precommit_hook.sh        # Pre-commit hook installer
│   ├── killp.sh                         # Process killing utilities
│   ├── largest.sh                       # Largest files finder
│   ├── linux_utils.sh                   # Linux utilities
│   ├── mcp-github-check.sh              # MCP GitHub checker
│   ├── mcp-github-reload.sh             # MCP GitHub reloader
│   ├── mcp-github-start.sh              # MCP GitHub starter
│   ├── mkd.sh                           # Directory creation
│   ├── mkdg.sh                          # Directory creation with git
│   ├── parse_conda_env.sh               # Conda environment parser
│   ├── parse_git_branch.sh              # Git branch parser
│   ├── parse_kube_context.sh            # Kubernetes context parser
│   ├── parse_venv.sh                    # Virtual environment parser
│   ├── pstree.sh                        # Process tree display
│   ├── recent.sh                        # Recent files finder
│   ├── scan_network.sh                  # Network scanning
│   ├── setup.sh                         # System setup
│   ├── sync_secrets.sh                  # Secrets synchronization
│   └── weather.sh                       # Weather utility
│
├── ⚡ COMPLETIONS
│   ├── completion_helpers.sh            # Completion generation helpers
│   ├── completions.sh                   # General completions
│   ├── agent_completion.sh              # Agent-specific completions
│   └── generate_agent_completion.sh     # Agent completion generator
│
└── 📊 ANALYSIS & MONITORING
    ├── script_inventory.sh              # Script inventory generator
    ├── validate_system.sh               # System validation
    ├── autocorrect_system.sh            # System autocorrection
    ├── generate_man_index.sh            # Documentation index generator
    └── tldr_generator.sh                # TLDR summary generator
```

## 🔄 Loading Sequence Diagram

```
┌─────────────────┐
│  User Shell     │
│  Initialization │
└─────────┬───────┘
          │
          ▼
┌─────────────────────────┐
│  ~/.bashrc              │
│  source load_ordered.sh │
└─────────┬───────────────┘
          │
          ▼
┌─────────────────────────┐
│  Bootstrap Process      │
│  - Setup BASEDIR        │
│  - Define load order    │
└─────────┬───────────────┘
          │
          ▼
    ┌─────────────┐
    │ Load Core   │
    │ System      │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │ Load        │
    │ Tools       │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │ Load        │
    │ Completions │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │ Load TUI    │
    │ Components  │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │ Load        │
    │ Plugins     │
    └──────┬──────┘
           │
           ▼
    ┌─────────────────────────┐
    │  System Ready           │
    │  - Functions available  │
    │  - Aliases active       │
    │  - Tools loaded         │
    └─────────────────────────┘
```

## 🤖 AI Tools Workflow

```
┌─────────────────────┐
│ Enter AI Tools      │
│ Directory           │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Direnv Auto-Load    │
│ Environment (.envrc)│
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ NVM Setup           │
│ Node.js Management  │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Check Tool          │
│ Availability        │
└─────────┬───────────┘
          │
          ▼
    ┌─────────────┐
    │ Tool        │
    │ Installed?  │
    └───┬────────┘
        │ Yes
        ▼
    ┌─────────────┐
    │ Use Tool    │
    └─────────────┘
        │
        │ No
        ▼
    ┌─────────────┐
    │ Install     │
    │ Tool        │
    └─────────────┘
        │
        ▼
    ┌─────────────┐
    │ Verify      │
    │ Install     │
    └─────────────┘
```

## 🔌 Plugin System Architecture

```
┌─────────────────────────────┐
│ Plugin Manager              │
│ (plugin_manager.sh)         │
└─────────────┬───────────────┘
              │
    ┌─────────┼─────────┐
    │         │         │
    ▼         ▼         ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Install │ │ Enable  │ │ Disable │
│ Plugin  │ │ Plugin  │ │ Plugin  │
└─────────┘ └─────────┘ └─────────┘
    │         │         │
    ▼         ▼         ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Clone   │ │Symlink  │ │Remove   │
│ from    │ │to       │ │Symlink  │
│ URL     │ │enabled/ │ │and      │
└─────────┘ │register │ │unregister│
            │bin PATH │ │bin PATH  │
            └─────────┘ └─────────┘
                  │
                  ▼
            ┌─────────────┐
            │ Regenerate  │
            │enabled_env.sh│
            └─────────────┘
                  │
                  ▼
            ┌─────────────┐
            │ Source      │
            │ enabled_env │
            │ on startup  │
            └─────────────┘
```

## 🧪 Testing & Validation Flow

```
┌─────────────────────┐
│ System Startup      │
│ Validation          │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Check Required      │
│ Files               │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Check Required      │
│ Tools               │
└─────────┬───────────┘
          │
          ▼
    ┌─────────────┐
    │ All Checks  │
    │ Pass?       │
    └───┬────────┘
        │ Yes
        ▼
    ┌─────────────┐
    │ System      │
    │ Ready       │
    └─────────────┘
        │
        │ No
        ▼
    ┌─────────────┐
    │ Run         │
    │ Autocorrect │
    └─────────────┘
        │
        ▼
    ┌─────────────┐
    │ Fix Issues  │
    └─────────────┘
```

## 📊 Dependencies Graph

```
                    ┌─────────────────┐
                    │  ~/.bashrc      │
                    │  (entry point)  │
                    └─────────┬───────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ load_ordered.sh │
                    │ (main loader)   │
                    └─────────┬───────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│ Core System │      │ Tools       │      │ Completions │
│             │      │             │      │             │
├── aliases.sh│      ├── git_tools │      ├── agent_    │
├── functions │      ├── sys_tools │      │ completions │
├── exports   │      ├── net_tools │      └── general   │
└── plugins   │      └── sec_tools │          completions
        │             │                      │
        │             ▼                      ▼
        │      ┌─────────────┐      ┌─────────────┐
        │      │ AI Tools    │      │ Function    │
        │      │ System      │      │ Completions │
        │      │             │      │             │
        │      ├── install   │      └───bf_*      │
        │      ├── setup     │             functions│
        │      └── direnv    │                      │
        │             │             │                │
        ▼             ▼             ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Plugin System                           │
│                                                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │ ai-tools    │  │ auto-tasks  │  │ rag-tools   │       │
│  │             │  │             │  │             │       │
│  ├── init.sh   │  ├── init.sh   │  ├── init.sh   │       │
│  └── bin/      │  └── bin/      │  └── bin/      │       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │ vector-db   │  │ self-heal   │  │ ...         │       │
│  │             │  │             │  │             │       │
│  ├── init.sh   │  ├── init.sh   │  ├── init.sh   │       │
│  └── bin/      │  └── bin/      │  └── bin/      │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
│                           │                                │
│                           ▼                                │
│                  ┌─────────────────┐                       │
│                  │ enabled_env.sh  │                       │
│                  │ (auto-generated)│                       │
│                  └─────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Configuration Flow

```
┌─────────────────────┐
│ Environment         │
│ Detection           │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Load Profile        │
│ (development/       │
│  production/        │
│  testing)           │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Apply Environment   │
│ Variables           │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Setup Paths         │
│ - Core bin/         │
│ - Plugin bins/      │
│ - Tool bins/        │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Initialize          │
│ Subsystems          │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Load User           │
│ Customizations      │
└─────────────────────┘
```

This comprehensive organization diagram shows the logical structure, dependencies, and workflows within the bash_functions.d system. Each component has clear responsibilities and interfaces with other components through well-defined mechanisms.