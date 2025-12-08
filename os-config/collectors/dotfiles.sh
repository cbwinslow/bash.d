#!/bin/bash
# Dotfiles and Configuration Collector Script
# Backs up important dotfiles and configuration directories
# Outputs to a tarball and JSON manifest

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

command_exists() {
    command -v "$1" &> /dev/null
}

# Common dotfiles to backup
DOTFILES=(
    ".bashrc"
    ".bash_profile"
    ".bash_aliases"
    ".bash_logout"
    ".zshrc"
    ".zsh_profile"
    ".profile"
    ".vimrc"
    ".vim"
    ".nvim"
    ".gitconfig"
    ".gitignore_global"
    ".ssh/config"
    ".ssh/known_hosts"
    ".tmux.conf"
    ".screenrc"
    ".inputrc"
    ".editorconfig"
    ".curlrc"
    ".wgetrc"
)

# Configuration directories to backup
CONFIG_DIRS=(
    ".config/nvim"
    ".config/fish"
    ".config/git"
    ".config/code-server"
    ".config/terminator"
    ".config/alacritty"
    ".config/kitty"
    ".config/i3"
    ".config/sway"
    ".config/awesome"
)

# Application config files
APP_CONFIGS=(
    ".vscode/settings.json"
    ".vscode/keybindings.json"
    ".vscode/extensions.txt"
)

# Collect dotfiles
collect_dotfiles() {
    local home="$HOME"
    local collected=()
    
    log_info "Collecting dotfiles from $home..."
    
    for dotfile in "${DOTFILES[@]}"; do
        local fullpath="$home/$dotfile"
        if [ -e "$fullpath" ]; then
            local size=$(du -sh "$fullpath" 2>/dev/null | awk '{print $1}')
            local type="file"
            [ -d "$fullpath" ] && type="directory"
            [ -L "$fullpath" ] && type="symlink"
            
            collected+=("{\"path\":\"$dotfile\",\"type\":\"$type\",\"size\":\"$size\"}")
            log_info "Found: $dotfile ($type, $size)"
        fi
    done
    
    echo "${collected[@]}"
}

# Collect config directories
collect_config_dirs() {
    local home="$HOME"
    local collected=()
    
    log_info "Collecting configuration directories..."
    
    for config_dir in "${CONFIG_DIRS[@]}"; do
        local fullpath="$home/$config_dir"
        if [ -d "$fullpath" ]; then
            local size=$(du -sh "$fullpath" 2>/dev/null | awk '{print $1}')
            collected+=("{\"path\":\"$config_dir\",\"type\":\"directory\",\"size\":\"$size\"}")
            log_info "Found: $config_dir ($size)"
        fi
    done
    
    echo "${collected[@]}"
}

# Collect application configs
collect_app_configs() {
    local home="$HOME"
    local collected=()
    
    log_info "Collecting application configurations..."
    
    # VSCode extensions list
    if command_exists code; then
        local extensions_file="$home/.vscode/extensions.txt"
        mkdir -p "$home/.vscode"
        code --list-extensions > "$extensions_file" 2>/dev/null || true
        if [ -f "$extensions_file" ]; then
            collected+=("{\"path\":\".vscode/extensions.txt\",\"type\":\"generated\",\"size\":\"$(du -sh $extensions_file | awk '{print $1}')\"}")
        fi
    fi
    
    for config in "${APP_CONFIGS[@]}"; do
        local fullpath="$home/$config"
        if [ -f "$fullpath" ]; then
            local size=$(du -sh "$fullpath" 2>/dev/null | awk '{print $1}')
            collected+=("{\"path\":\"$config\",\"type\":\"file\",\"size\":\"$size\"}")
            log_info "Found: $config ($size)"
        fi
    done
    
    echo "${collected[@]}"
}

# Create backup tarball
create_backup_tarball() {
    local output_dir="${1:-.}"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local tarball="$output_dir/dotfiles-$timestamp.tar.gz"
    local home="$HOME"
    
    log_info "Creating backup tarball: $tarball"
    
    # Create temporary list of files to backup
    local temp_list=$(mktemp)
    
    # Add dotfiles that exist
    for dotfile in "${DOTFILES[@]}"; do
        if [ -e "$home/$dotfile" ]; then
            echo "$dotfile" >> "$temp_list"
        fi
    done
    
    # Add config directories that exist
    for config_dir in "${CONFIG_DIRS[@]}"; do
        if [ -d "$home/$config_dir" ]; then
            echo "$config_dir" >> "$temp_list"
        fi
    done
    
    # Add app configs that exist
    for config in "${APP_CONFIGS[@]}"; do
        if [ -e "$home/$config" ]; then
            echo "$config" >> "$temp_list"
        fi
    done
    
    # Create tarball
    if [ -s "$temp_list" ]; then
        cd "$home"
        tar czf "$tarball" -T "$temp_list" 2>/dev/null || log_warn "Some files could not be backed up"
        cd - > /dev/null
        log_info "Backup created: $tarball ($(du -sh $tarball | awk '{print $1}'))"
        echo "$tarball"
    else
        log_warn "No files to backup"
        echo ""
    fi
    
    rm -f "$temp_list"
}

# Generate JSON manifest
generate_manifest() {
    local dotfiles_array=($(collect_dotfiles))
    local configs_array=($(collect_config_dirs))
    local apps_array=($(collect_app_configs))
    
    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "home": "$HOME",
    "dotfiles": [$(IFS=,; echo "${dotfiles_array[*]}")],
    "config_dirs": [$(IFS=,; echo "${configs_array[*]}")],
    "app_configs": [$(IFS=,; echo "${apps_array[*]}")],
    "shell": {
        "current": "$SHELL",
        "bash_version": "$(bash --version 2>/dev/null | head -1 || echo 'not available')",
        "zsh_version": "$(zsh --version 2>/dev/null || echo 'not available')"
    }
}
EOF
}

# Main function
main() {
    local output_dir="${1:-.}"
    local mode="${2:-json}"
    
    log_info "Starting dotfiles collection..."
    
    case "$mode" in
        "json")
            generate_manifest
            ;;
        "backup")
            mkdir -p "$output_dir"
            local tarball=$(create_backup_tarball "$output_dir")
            generate_manifest > "$output_dir/dotfiles-manifest.json"
            if [ -n "$tarball" ]; then
                echo "{\"success\": true, \"tarball\": \"$tarball\", \"manifest\": \"$output_dir/dotfiles-manifest.json\"}"
            else
                echo "{\"success\": false, \"error\": \"No files to backup\"}"
            fi
            ;;
        *)
            log_warn "Unknown mode: $mode. Use 'json' or 'backup'"
            exit 1
            ;;
    esac
    
    log_info "Dotfiles collection complete!"
}

main "$@"
