# bash.d Quick Start Guide

Get up and running with bash.d in 5 minutes!

## 1. Choose Your Installation Method

### Option A: Standalone (Recommended for New Users)

```bash
# Clone to your home directory
git clone https://github.com/cbwinslow/bash.d.git ~/.bash.d

# Run installer
cd ~/.bash.d
./install.sh

# Reload shell
source ~/.bashrc
```

### Option B: With bash-it Integration

```bash
# Install bash-it first (if not installed)
git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
~/.bash_it/install.sh

# Clone bash.d
git clone https://github.com/cbwinslow/bash.d.git ~/.bash.d

# Run bash-it integration
cd ~/.bash.d
./install-bash-it.sh

# Reload shell
source ~/.bashrc
```

## 2. Verify Installation

```bash
# Check if bash.d loaded
bashd-list

# Should show available modules like:
# [aliases]
# ----------------
#   [ ] git.aliases
#   [ ] docker.aliases
#   [ ] general.aliases
```

## 3. Enable Your First Modules

```bash
# Enable git aliases (50+ shortcuts)
bashd-enable aliases git

# Enable docker aliases  
bashd-enable aliases docker

# Enable core plugin (navigation shortcuts)
bashd-enable plugins bashd-core
```

## 4. Try Some Commands

### Git Shortcuts

```bash
gs              # git status
ga file.txt     # git add
gcm "message"   # git commit -m
gp              # git push
gpl             # git pull
gl              # git log --oneline --graph
gco branch      # git checkout
```

### Docker Shortcuts

```bash
d ps            # docker ps
dps             # docker ps
dcu             # docker-compose up
dcud            # docker-compose up -d (detached)
dlogs           # docker logs
dstop all       # stop all containers
```

### bash.d Commands

```bash
cdbd            # cd to bash.d directory
bashd-reload    # reload configuration
bashd-search    # search for modules
func_search     # search for functions
```

## 5. Discover More Features

```bash
# List all available modules
bashd-list

# Search for specific functionality
bashd-search network
bashd-search git
bashd-search docker

# Get info about a module
bashd-info aliases git

# Update module index
bashd_index_update
bashd_index_stats
```

## 6. Customize Your Setup

### Add Custom Aliases

```bash
# Create custom alias file
cat > ~/.bash.d/bash_aliases.d/my-aliases.sh << 'EOF'
# My custom aliases
alias work='cd ~/projects && ls'
alias today='date +"%Y-%m-%d"'
EOF

# Reload
bashd-reload
```

### Add Custom Functions

```bash
# Create custom function
cat > ~/.bash.d/bash_functions.d/custom/my-func.sh << 'EOF'
#!/bin/bash
# My custom function

my_hello() {
    echo "Hello, $1!"
}

export -f my_hello
EOF

# Reload
bashd-reload

# Use it
my_hello World
```

### Add Environment Variables

```bash
# Create env file
cat > ~/.bash.d/bash_env.d/my-env.sh << 'EOF'
# My environment variables
export PROJECT_DIR="$HOME/projects"
export EDITOR="vim"
EOF

# Reload
bashd-reload
```

## 7. Common Tasks

### Managing Modules

```bash
# Enable a module
bashd-enable aliases git

# Disable a module
bashd-disable aliases docker

# List enabled modules
bashd-list all enabled

# List disabled modules
bashd-list all disabled
```

### Finding Functions

```bash
# Search all functions
func_search docker

# View function source
func_recall docker_cleanup

# Get function info
func_info network_scan

# See recently used
func_recent
```

### Navigation

```bash
cdbd            # Go to bash.d directory
cdbdf           # Go to functions directory
cdbdp           # Go to plugins directory
cdbda           # Go to aliases directory
```

## 8. Integration with bash-it (Optional)

If you use bash-it, bash.d works seamlessly alongside:

```bash
# Use bash-it commands
bash-it show plugins
bash-it enable plugin git
bash-it show aliases

# Use bash.d commands
bashd-list
bashd-enable aliases docker
bashd-search network

# Both work together!
```

## 9. Troubleshooting

### Module not loading?

```bash
# Check if module exists
bashd-list aliases

# Enable it explicitly
bashd-enable aliases git

# Reload shell
bashd-reload
```

### Command not found?

```bash
# Source bashrc again
source ~/.bashrc

# Or open new terminal
```

### Need to reset?

```bash
# Disable all custom modules
cd ~/.bash.d/enabled
rm -f *

# Reload
bashd-reload
```

## 10. Next Steps

- **Read full docs**: `cat ~/.bash.d/README.md`
- **Explore functions**: `func_list`
- **Check examples**: `ls ~/.bash.d/examples/`
- **Contribute**: Read `~/.bash.d/CONTRIBUTING.md`

## Command Reference Card

```bash
# Module Management
bashd-list [type]           List modules
bashd-enable <type> <name>  Enable module
bashd-disable <type> <name> Disable module
bashd-search <query>        Search modules
bashd-info <type> <name>    Show module info

# Function Discovery
func_list                   List all functions
func_search <term>          Search functions
func_recall <name>          View function source
func_info <name>            Show function info
func_recent [n]             Show recent usage

# System
bashd-reload                Reload configuration
bashd-status                Show system status
bashd-edit <file>           Edit configuration
cdbd                        Go to bash.d

# Indexing
bashd_index_update          Update module index
bashd_index_stats           Show index statistics
bashd_index_search <query>  Search index
```

## Tips & Tricks

1. **Tab Completion**: Use TAB to complete bash.d commands
   ```bash
   bashd-enable <TAB>        # Shows: aliases plugins completions functions
   ```

2. **Alias Shortcuts**: Many aliases work intuitively
   ```bash
   g <TAB>                   # Shows git aliases
   d <TAB>                   # Shows docker aliases
   ```

3. **Quick Help**: Most commands have `--help`
   ```bash
   bashd-list --help
   ```

4. **History Search**: Use reverse search with bash.d commands
   ```bash
   Ctrl+R                    # Then type: bashd
   ```

5. **Chaining**: Combine commands with aliases
   ```bash
   gs && ga . && gcm "update" && gp
   ```

## Getting Help

- **Issues**: https://github.com/cbwinslow/bash.d/issues
- **Docs**: `cat ~/.bash.d/README.md`
- **Contributing**: `cat ~/.bash.d/CONTRIBUTING.md`
- **Tests**: `~/.bash.d/test_modular_system.sh`

---

**You're Ready!** 🚀

Start exploring bash.d and customize it to your workflow.

*Happy bashing!*
