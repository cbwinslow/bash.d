# bash.d - Modular Bash Configuration Framework

A comprehensive, modular bash configuration system that serves as a single source of truth for your bash profile across all machines. Compatible with bash-it, oh-my-bash, and standalone usage.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📋 Project Status & Roadmap

**🎯 [View Master Task List](MASTER_TASK_LIST.md)** - Complete roadmap with 500+ measurable microtasks  
**📅 [Current Sprint](docs/TASK_TRACKING.md)** - Active development and task coordination  
**🤖 [AI Agent Tasks](docs/tasks.md)** - Multi-agent system development  
**📖 [Quick Reference](docs/QUICK_REFERENCE.md)** - Navigate the project easily

## 🌟 Features

- **🔌 Modular Architecture**: Organized into plugins, aliases, completions, functions, and themes
- **🤝 Framework Integration**: Native support for bash-it and oh-my-bash
- **📦 Module Management**: Enable/disable modules like bash-it (list, enable, disable)
- **🔍 Advanced Search & Index System**: Fast indexing and multiple search methods (unified, fuzzy, pattern, content)
- **📊 Smart Organization**: Sort, categorize, and navigate functions with ease
- **🎨 Customizable**: Easy to extend with your own functions and configurations
- **📚 Well-Documented**: Comprehensive documentation and inline help
- **🔒 Secure**: Separate directories for secrets with automatic .gitignore
- **🚀 AI Integration**: Built-in AI agent system for autonomous development
- **🐳 Docker Ready**: Includes Docker and container management utilities
- **🔐 Bitwarden Integration**: Secret management with Bitwarden CLI

## 🤖 OpenAI-Compatible Proxy (Free Models Only)

The Cloudflare Worker proxy enforces OpenRouter free-tier models only.

- Base URL: `https://bashd.cloudcurio.workers.dev/v1`
- Default model: `meta-llama/llama-3.2-3b-instruct:free`
- Allowed models:
  - `meta-llama/llama-3.2-3b-instruct:free`
  - `google/gemma-2-9b-it:free`
  - `mistralai/mistral-7b-instruct:free`
  - `google/gemini-2.0-flash-lite-preview-02-05:free`

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
  - [Standalone Installation](#standalone-installation)
  - [bash-it Integration](#bash-it-integration)
  - [oh-my-bash Integration](#oh-my-bash-integration)
- [Directory Structure](#directory-structure)
- [Usage](#usage)
  - [Module Management](#module-management)
  - [Functions](#functions)
  - [Aliases](#aliases)
  - [Completions](#completions)
- [Configuration](#configuration)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/cbwinslow/bash.d.git ~/.bash.d

# Run the installer
cd ~/.bash.d
./install.sh

# Reload your shell
source ~/.bashrc
```

## 📦 Installation

### Standalone Installation

The standalone installation creates a complete bash configuration in `~/.bash.d`:

```bash
# Clone the repository
git clone https://github.com/cbwinslow/bash.d.git
cd bash.d

# Run installation script
./install.sh

# Reload shell
source ~/.bashrc
```

#### Installation Options

```bash
./install.sh --help          # Show help
./install.sh -f              # Force installation (overwrite existing)
./install.sh --no-omb        # Skip oh-my-bash installation
./install.sh -b              # Create backups (default)
```

### bash-it Integration

bash.d can be integrated as a bash-it plugin, leveraging bash-it's powerful framework:

#### Prerequisites

```bash
# Install bash-it first
git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
~/.bash_it/install.sh
```

#### Install bash.d as bash-it Plugin

```bash
# Clone bash.d to your preferred location
git clone https://github.com/cbwinslow/bash.d.git ~/.bash.d

# Create bash-it custom plugin link
mkdir -p ~/.bash_it/custom
ln -sf ~/.bash.d/lib/bash-it-plugin.bash ~/.bash_it/custom/bash.d.plugin.bash

# Enable the plugin
bash-it enable plugin bash.d

# Reload shell
source ~/.bashrc
```

#### Using bash.d with bash-it

Once installed, bash.d works seamlessly with bash-it:

```bash
# List bash.d modules
bashd-list

# Enable specific bash.d modules
bashd-enable plugins bashd-core
bashd-enable aliases git

# Use bash-it commands normally
bash-it show plugins
bash-it enable plugin git
```

### oh-my-bash Integration

bash.d includes built-in support for oh-my-bash:

```bash
# Install bash.d
git clone https://github.com/cbwinslow/bash.d.git ~/.bash.d
cd ~/.bash.d
./install.sh

# Install oh-my-bash (if not already installed)
bashd-install-omb

# Configure oh-my-bash theme (optional)
export OSH_THEME="font"  # Add to ~/.bashrc

# Reload shell
source ~/.bashrc
```

## 📁 Directory Structure

The project follows industry-standard organization with clear separation of concerns:

```
bash.d/
├── agents/                       # AI agent system
├── bash_functions.d/             # Modular bash functions
├── scripts/                      # Organized scripts
│   ├── setup/                    # Installation scripts
│   ├── security/                 # Security tools
│   ├── network/                  # Network utilities
│   ├── monitoring/               # System monitoring
│   ├── test/                     # Test scripts
│   └── tools/                    # Development tools
├── docs/                         # Documentation
│   ├── implementation/           # Implementation docs
│   ├── guides/                   # User guides
│   ├── reports/                  # Status reports
│   └── architecture/             # Architecture docs
├── config/                       # Configuration files
│   ├── bashrc-variants/          # Bashrc configurations
│   └── [other configs]
├── lib/                          # Core libraries
├── tools/                        # Python tools
├── aliases/                      # Alias definitions
├── completions/                  # Bash completions
├── external/                     # External dependencies
├── packages/                     # Binary packages
├── install.sh                    # Installation script
├── bootstrap.sh                  # Quick bootstrap
└── README.md                     # This file
```

📖 **See [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) for complete structure documentation**

## 🎯 Usage

### Module Management

bash.d provides a powerful module management system similar to bash-it:

#### List Modules

```bash
# List all modules
bashd-list

# List specific type
bashd-list aliases
bashd-list plugins
bashd-list completions
bashd-list functions

# List only enabled modules
bashd_module_list all enabled

# List only disabled modules
bashd_module_list all disabled
```

#### Enable/Disable Modules

```bash
# Enable a module
bashd-enable aliases git
bashd-enable plugins bashd-core
bashd-enable completions bashd

# Disable a module
bashd-disable aliases docker
bashd-disable plugins bashd-core

# Using full function names
bashd_module_enable aliases git
bashd_module_disable aliases git
```

#### Search Modules

```bash
# Search for modules by name or content
bashd-search docker
bashd-search completion
bashd-search network

# Using full function name
bashd_module_search git
```

#### Module Information

```bash
# Get detailed information about a module
bashd-info aliases git
bashd-info plugins bashd-core
bashd-info functions docker_utils

# Using full function name
bashd_module_info aliases git
```

### Functions

bash.d includes a comprehensive function library organized by category with a powerful search and index system.

#### Search & Index System

The bash.d search system provides fast indexing and multiple search methods:

```bash
# Build the search index (first time)
bashd_index_build

# Search for functions, aliases, or scripts
bashd_search docker        # Search for docker-related items
bashd_search ai functions  # Search only in functions

# Quick locate by exact name
bashd_locate ai_agent_system

# Interactive fuzzy search (requires fzf)
bashd_fuzzy network

# Pattern-based file search
bashd_find "docker*"

# Content search with context
bashd_grep "TODO" 3

# View index statistics
bashd_index_stats

# Get help
bashd_help               # General help
bashd_help search        # Help for specific command
```

**Short aliases available:**
- `bds` → bashd_search
- `bdf` → bashd_find
- `bdl` → bashd_locate
- `bdz` → bashd_fuzzy
- `bdi` → bashd_index_build

See [SEARCH_SYSTEM.md](docs/SEARCH_SYSTEM.md) for complete documentation.

#### Function Discovery (Legacy)

```bash
# List all available functions
func_list

# Search for functions
func_search docker
func_search network
func_recall git

# Get function information
func_info docker_cleanup
func_info network_scan

# View recently used functions
func_recent
func_recent 20  # Show top 20
```

#### AI Integration Functions

```bash
# AI agent system
bashd_ai_healthcheck              # Check AI system status
bashd_ai_chat "query"             # Chat with AI assistant

# Use the autonomous agent system
python -m agents.main interactive  # Interactive mode
python -m agents.main create      # Create a project
```

#### Docker Functions

Located in `bash_functions.d/docker/`:

```bash
# Docker utilities (available after enabling docker functions)
docker_cleanup                    # Clean up Docker resources
docker_stats                      # Show Docker statistics
docker_logs_all                   # View logs from all containers
```

#### Git Functions

Located in `bash_functions.d/git/`:

```bash
# Git utilities
git_status_all                    # Status of all git repos in directory
git_branch_cleanup               # Clean up merged branches
git_recent_branches              # Show recently used branches
```

#### Network Functions

Located in `bash_functions.d/network/`:

```bash
# Network utilities
network_scan                      # Scan local network
check_port                        # Check if port is open
get_public_ip                     # Get public IP address
```

### Aliases

#### Git Aliases

```bash
# Basic git commands
g            # git
gs           # git status
ga           # git add
gc           # git commit
gp           # git push
gpl          # git pull
gd           # git diff

# Advanced operations
galiases     # Show all git aliases
```

See all git aliases: [aliases/git.aliases.bash](aliases/git.aliases.bash)

#### Docker Aliases

```bash
# Basic docker commands
d            # docker
dc           # docker-compose
dps          # docker ps
di           # docker images
dexec        # docker exec -it

# Cleanup
dprune       # docker system prune
dstopall     # stop all containers

daliases     # Show all docker aliases
```

See all docker aliases: [aliases/docker.aliases.bash](aliases/docker.aliases.bash)

#### General Aliases

```bash
# Navigation
..           # cd ..
...          # cd ../..
~            # cd ~

# Listing
ll           # ls -lh
la           # ls -lAh
lt           # ls -lhtr (sorted by time)

# System
myip         # Get public IP
localip      # Get local IP
path         # Show PATH entries
```

See all general aliases: [aliases/general.aliases.bash](aliases/general.aliases.bash)

### Completions

bash.d provides intelligent tab completions for all commands:

```bash
# Tab completion for bash.d commands
bashd-enable <TAB>               # Shows: aliases plugins completions functions
bashd-enable aliases <TAB>       # Shows available alias modules
bashd-disable plugins <TAB>      # Shows available plugins

# Function completion
func_recall <TAB>                # Shows available functions
func_info <TAB>                  # Shows available functions
```

## ⚙️ Configuration

### Environment Variables

Configure bash.d behavior with these environment variables:

```bash
# Core paths
export BASHD_HOME="$HOME/.bash.d"              # Installation directory
export BASHD_REPO_ROOT="$HOME/bash.d"          # Repository location
export BASHD_STATE_DIR="$BASHD_HOME/state"     # State and logs directory

# bash-it integration
export BASH_IT="$HOME/.bash_it"                # bash-it location
export BASH_IT_THEME="bobby"                   # bash-it theme

# oh-my-bash integration
export OMB_DIR="$HOME/.oh-my-bash"             # oh-my-bash location
export OSH_THEME="font"                        # oh-my-bash theme

# AI configuration
export OPENROUTER_API_KEY="your-key"           # AI API key
export BASHD_AI_MODEL="anthropic/claude-3"     # AI model

# Editor
export EDITOR="vim"                            # Default editor
```

### Custom Configuration

Add your own configurations in the appropriate directories:

```bash
# Custom aliases
echo "alias myalias='command'" > ~/.bash.d/bash_aliases.d/custom.sh

# Custom environment variables
echo "export MY_VAR='value'" > ~/.bash.d/bash_env.d/custom.sh

# Custom functions
cat > ~/.bash.d/bash_functions.d/custom/my_function.sh << 'EOF'
#!/bin/bash
my_function() {
    echo "My custom function"
}
export -f my_function
EOF

# Reload shell
bashd-reload
```

### Secrets Management

Store sensitive data in `bash_secrets.d/` (automatically gitignored):

```bash
# API keys and tokens
echo "export GITHUB_TOKEN='your-token'" > ~/.bash.d/bash_secrets.d/github.sh
echo "export AWS_ACCESS_KEY='your-key'" > ~/.bash.d/bash_secrets.d/aws.env

# Reload to apply
bashd-reload
```

## 🛠️ Development

### Adding New Modules

#### Create a Plugin

```bash
cat > plugins/myplugin.plugin.bash << 'EOF'
#!/bin/bash
# My custom plugin

cite about-plugin
about-plugin 'Description of my plugin'

# Plugin code here
my_plugin_function() {
    echo "Hello from my plugin"
}

export -f my_plugin_function
EOF

# Enable it
bashd-enable plugins myplugin
```

#### Create Aliases

```bash
cat > aliases/myaliases.aliases.bash << 'EOF'
#!/bin/bash
# My custom aliases

cite about-alias
about-alias 'My custom aliases'

alias myalias='echo "Hello"'
alias another='ls -la'
EOF

# Enable it
bashd-enable aliases myaliases
```

#### Create Completions

```bash
cat > completions/mycommand.completion.bash << 'EOF'
#!/bin/bash
# Completions for mycommand

_mycommand_complete() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    COMPREPLY=($(compgen -W "option1 option2 option3" -- "${cur}"))
}

complete -F _mycommand_complete mycommand
EOF

# Enable it
bashd-enable completions mycommand
```

### Testing

```bash
# Run tests
./scripts/test/test-bashrc.sh

# Test AI integration
./scripts/test/test-ai-integration.sh

# Manual testing
bash --norc --noprofile -c "source ./config/bashrc-variants/bashrc.main && bashd_module_list"
```

### Code Style

bash.d follows industry best practices:

- **Shellcheck compliance**: All scripts pass shellcheck
- **Function naming**: Use `bashd_` prefix for bash.d functions
- **Documentation**: Include header comments in all files
- **Modularity**: One module per file, organized by category
- **Safety**: Use `set -euo pipefail` for scripts
- **Quoting**: Always quote variables: `"$var"`

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Areas for Contribution

- New plugins and functions
- Additional aliases and completions
- Documentation improvements
- Bug fixes and optimizations
- Integration with other frameworks
- Test coverage improvements

### Development Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following code style guidelines
4. Test your changes
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📚 Documentation

- **[Master Agent Guide](MASTER_AGENT_GUIDE.md)** - AI agent system documentation
- **[Integration Guide](INTEGRATION_GUIDE.md)** - Framework integration details
- **[Quick Start Guide](QUICKSTART.md)** - Get up and running quickly
- **[API Documentation](docs/)** - Detailed API reference

## 🙏 Acknowledgments

bash.d draws inspiration from and is compatible with:

- **[bash-it](https://github.com/Bash-it/bash-it)** - Community bash framework
- **[oh-my-bash](https://github.com/ohmybash/oh-my-bash)** - Bash configuration framework
- **[oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)** - The inspiration for bash frameworks

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 💡 Quick Tips

```bash
# Quickly navigate to bash.d
cdbd

# Edit bash.d configuration
bashd-edit ~/.bash.d/bashrc

# Reload configuration without restarting shell
bashd-reload

# Check bash.d status
bashd-status

# Search for a specific function
func_search network

# View function source with syntax highlighting
func_recall docker_cleanup

# Get help on any command
help_me command_name
```

## 🔗 Links

- **Repository**: https://github.com/cbwinslow/bash.d
- **Issues**: https://github.com/cbwinslow/bash.d/issues
- **Discussions**: https://github.com/cbwinslow/bash.d/discussions

## 📞 Support

- Create an [issue](https://github.com/cbwinslow/bash.d/issues) for bugs
- Start a [discussion](https://github.com/cbwinslow/bash.d/discussions) for questions
- Check [documentation](docs/) for detailed guides

---

**Made with ❤️ by the bash.d community**

*Transform your bash experience - one module at a time*
