# bash.d

An advanced, modular bash shell configuration with oh-my-bash integration, comprehensive utility functions, intelligent autocomplete, and syntax highlighting.

## Features

- **Modular Function Organization**: Functions organized in `bash_functions.d/` by category
- **Oh-My-Bash Integration**: Full integration with oh-my-bash for themes and plugins
- **Function Management**: Utilities to add, recall, search, and edit bash functions
- **Intelligent Autocomplete**: History-based completion, FZF integration, and custom completions
- **Syntax Highlighting**: Colored output for commands, man pages, and file viewers
- **Comprehensive Utilities**: Git, Docker, Network, and System utility functions
- **Help System**: Unified help with man pages, tldr, cheatsheets, and quick references

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/bash.d.git ~/bash.d

# Run the installer
cd ~/bash.d
./install.sh
```

### Manual Installation

If you prefer manual setup:

```bash
# Copy bash_functions.d to home directory
cp -r bash_functions.d ~/.bash_functions.d

# Backup and copy .bashrc
cp ~/.bashrc ~/.bashrc.backup
cp .bashrc ~/.bashrc

# Set environment variable
echo 'export BASH_D_REPO="$HOME/bash.d"' >> ~/.bashrc

# Apply changes
source ~/.bashrc
```

## Directory Structure

```
bash.d/
├── .bashrc                    # Main bash configuration
├── install.sh                 # Installation script
├── README.md                  # This file
└── bash_functions.d/          # Modular function directory
    ├── utilities/             # General utility functions
    │   ├── func_add.sh        # Add/manage functions
    │   ├── func_recall.sh     # Search/recall functions
    │   └── syntax_highlighting.sh
    ├── help/                  # Help system functions
    │   └── func_help.sh       # man/tldr/help integration
    ├── autocomplete/          # Autocomplete enhancements
    │   └── autocomplete.sh    # History-based completion
    ├── system/                # System utilities
    │   └── system_utils.sh    # File, process, system functions
    ├── git/                   # Git utilities
    │   └── git_utils.sh       # Git workflow shortcuts
    ├── docker/                # Docker utilities
    │   └── docker_utils.sh    # Docker/compose shortcuts
    └── network/               # Network utilities
        └── network_utils.sh   # DNS, SSL, connectivity tools
```

## Function Categories

### Function Management (`func_*`)

| Command | Description |
|---------|-------------|
| `func_add <name> [category]` | Create a new function with template |
| `func_list [category]` | List all available functions |
| `func_edit <name>` | Edit an existing function |
| `func_recall [search]` | Search and recall functions (with FZF) |
| `func_search <term>` | Search function names and content |
| `func_info <name>` | Show function metadata |
| `func_remove <name>` | Remove a function |

### Help System (`help_*`)

| Command | Description |
|---------|-------------|
| `help_me <cmd> [source]` | Unified help viewer (man/tldr/help) |
| `quickref <cmd>` | Quick reference for common commands |
| `explain <command>` | Break down complex commands |

Sources: `man`, `tldr`, `help`, `cheat`, `func`, `all`

### Git Utilities (`g*`)

| Command | Description |
|---------|-------------|
| `gs` | Enhanced git status |
| `glog [n]` | Git log with graph |
| `gco [branch]` | Checkout branch (FZF selector) |
| `gnew <name>` | Create and checkout new branch |
| `gcm <msg>` | Commit with message |
| `gac <msg>` | Add all and commit |
| `gacp <msg>` | Add, commit, and push |
| `gpull` | Pull with rebase |
| `gpush` | Push current branch |
| `gstash [msg]` | Quick stash |
| `gundo` | Undo last commit (keep changes) |
| `galiases` | Show all git aliases |

### Docker Utilities (`d*`)

| Command | Description |
|---------|-------------|
| `dps` | List running containers |
| `dpsa` | List all containers |
| `dexec [name]` | Exec into container (FZF) |
| `dlogs [name]` | View container logs (FZF) |
| `dimages` | List images |
| `dcleanall` | Full Docker cleanup |
| `dcup` | docker-compose up -d |
| `dcdown` | docker-compose down |
| `dstats` | Container resource stats |
| `daliases` | Show all docker aliases |

### Network Utilities

| Command | Description |
|---------|-------------|
| `dnslookup <domain>` | DNS lookup (all record types) |
| `httptest <url>` | Test HTTP endpoint |
| `testport <host> <port>` | Test port connectivity |
| `portscan <host>` | Scan common ports |
| `sslcheck <host>` | Check SSL certificate |
| `sslexpiry <host>` | Get certificate expiry |
| `netinfo` | Show network interfaces |
| `netaliases` | Show all network aliases |

### System Utilities

| Command | Description |
|---------|-------------|
| `mkcd <dir>` | Create directory and cd into it |
| `extract <file>` | Extract any archive format |
| `backup <file>` | Create timestamped backup |
| `ff <name>` | Find files by name |
| `ftext <text>` | Find files containing text |
| `psg <name>` | Find process by name |
| `sysinfo` | System overview |
| `myip` | Show public and local IPs |
| `serve [port]` | Start HTTP server |
| `calc <expr>` | Calculator |
| `timer <sec>` | Countdown timer |

### Colored Output Functions

| Command | Description |
|---------|-------------|
| `success <msg>` | Print green success message |
| `error <msg>` | Print red error message |
| `warning <msg>` | Print yellow warning message |
| `info <msg>` | Print cyan info message |
| `cecho <color> <msg>` | Print in specified color |

## Autocomplete Features

### Key Bindings

| Key | Action |
|-----|--------|
| `Ctrl+R` | FZF history search (or reverse search) |
| `Up/Down` | History search based on current input |
| `Alt+.` | Insert last argument from previous command |
| `Tab` | Intelligent completion |

### FZF Integration (if installed)

- `fzf_history` - Enhanced history search
- `fzf_file` - File search with preview
- `fzf_dir` - Directory navigation
- `fzf_git_branch` - Git branch selector
- `fzf_kill` - Interactive process killer

## Oh-My-Bash

This configuration integrates with [oh-my-bash](https://github.com/ohmybash/oh-my-bash).

### Included Completions
- git, ssh, docker, kubectl, npm, pip

### Included Aliases
- general, chmod, docker, docker-compose, git, kubectl

### Included Plugins
- git, bashmarks, progress, sudo

### Theme
Default theme: `powerline`

## Adding Your Own Functions

### Using func_add

```bash
# Create a new function
func_add myfunction utilities

# This creates: ~/.bash_functions.d/utilities/myfunction.sh
# with a template and opens it in your editor
```

### Manual Creation

Create a `.sh` file in the appropriate category folder:

```bash
#!/bin/bash
# My custom function

myfunction() {
    echo "Hello from myfunction!"
}

export -f myfunction 2>/dev/null
```

## Requirements

### Required
- Bash 4.0+
- Git (for installation and git functions)

### Recommended
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [bat](https://github.com/sharkdp/bat) - Better cat
- [eza](https://github.com/eza-community/eza) - Better ls
- [tldr](https://tldr.sh/) - Simplified man pages
- [grc](https://github.com/garabik/grc) - Generic colorizer

### Install Recommendations

```bash
# Ubuntu/Debian
sudo apt-get install fzf bat grc

# macOS
brew install fzf bat eza grc tldr

# Install tldr (any platform)
pip install tldr
# or
npm install -g tldr
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BASH_FUNCTIONS_D` | `~/.bash_functions.d` | Functions directory |
| `BASH_D_REPO` | `~/bash.d` | Repository location |
| `EDITOR` | `vim` | Default editor |

### Customization

Create `~/.bashrc.local` for local customizations that won't be overwritten:

```bash
# ~/.bashrc.local
export MY_VAR="value"
alias my_alias='command'
```

## Troubleshooting

### Functions not loading
```bash
# Manually source functions
source ~/.bashrc

# Check if functions directory exists
ls -la ~/.bash_functions.d/
```

### oh-my-bash not working
```bash
# Check if installed
ls -la ~/.oh-my-bash/

# Reinstall
rm -rf ~/.oh-my-bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
```

### Completions not working
```bash
# Check bash version
bash --version

# Ensure readline is configured
bind -p | grep completion
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add your functions to the appropriate category
4. Test your changes
5. Submit a pull request

## License

MIT License - feel free to use, modify, and distribute.

## Credits

- [oh-my-bash](https://github.com/ohmybash/oh-my-bash) - Bash framework
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [tldr](https://tldr.sh/) - Simplified man pages
