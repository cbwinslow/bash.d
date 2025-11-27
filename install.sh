#!/bin/bash
#===============================================================================
#
#          FILE:  install.sh
#
#         USAGE:  ./install.sh [options]
#
#   DESCRIPTION:  Installation script for bash.d configuration
#                 Sets up bash_functions.d and configures bashrc
#
#       OPTIONS:  -h, --help      Show help
#                 -f, --force     Overwrite existing files
#                 -b, --backup    Create backups before overwriting
#                 --no-omb        Skip oh-my-bash installation
#  REQUIREMENTS:  bash, git
#         NOTES:  Run this script from the repository root
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

set -e

#===============================================================================
# CONFIGURATION
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Options
FORCE=false
CREATE_BACKUP=true
INSTALL_OMB=true

#===============================================================================
# FUNCTIONS
#===============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                   bash.d Installation Script                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Install bash.d configuration and bash_functions.d.

OPTIONS:
    -h, --help      Show this help message
    -f, --force     Overwrite existing files without prompting
    -b, --backup    Create backups before overwriting (default)
    --no-backup     Don't create backups
    --no-omb        Skip oh-my-bash installation

EXAMPLES:
    $(basename "$0")                 # Interactive installation
    $(basename "$0") -f              # Force installation
    $(basename "$0") --no-omb        # Skip oh-my-bash

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -b|--backup)
                CREATE_BACKUP=true
                shift
                ;;
            --no-backup)
                CREATE_BACKUP=false
                shift
                ;;
            --no-omb)
                INSTALL_OMB=false
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

backup_file() {
    local file="$1"
    if [[ -e "$file" && "$CREATE_BACKUP" == true ]]; then
        cp "$file" "${file}${BACKUP_SUFFIX}"
        info "Backed up: $file -> ${file}${BACKUP_SUFFIX}"
    fi
}

install_symlink() {
    local source="$1"
    local target="$2"
    
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ "$FORCE" == true ]]; then
            backup_file "$target"
            rm -rf "$target"
        else
            warning "$target already exists."
            echo -n "Overwrite? (y/n) "
            read -r response
            if [[ "$response" =~ ^[Yy] ]]; then
                backup_file "$target"
                rm -rf "$target"
            else
                info "Skipping: $target"
                return 0
            fi
        fi
    fi
    
    ln -sf "$source" "$target"
    success "Created symlink: $target -> $source"
}

copy_file() {
    local source="$1"
    local target="$2"
    
    if [[ -e "$target" ]]; then
        if [[ "$FORCE" == true ]]; then
            backup_file "$target"
        else
            warning "$target already exists."
            echo -n "Overwrite? (y/n) "
            read -r response
            if [[ ! "$response" =~ ^[Yy] ]]; then
                info "Skipping: $target"
                return 0
            fi
            backup_file "$target"
        fi
    fi
    
    cp -r "$source" "$target"
    success "Copied: $target"
}

install_oh_my_bash() {
    if [[ "$INSTALL_OMB" != true ]]; then
        info "Skipping oh-my-bash installation."
        return 0
    fi
    
    if [[ -d "${HOME}/.oh-my-bash" ]]; then
        warning "oh-my-bash is already installed."
        return 0
    fi
    
    info "Installing oh-my-bash..."
    
    # Clone oh-my-bash
    if command -v git >/dev/null 2>&1; then
        git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git "${HOME}/.oh-my-bash" 2>/dev/null
        success "oh-my-bash installed successfully!"
    else
        error "git is required to install oh-my-bash."
        return 1
    fi
}

install_dependencies() {
    info "Checking for optional dependencies..."
    
    local missing=""
    
    # Check for useful tools
    command -v fzf >/dev/null 2>&1 || missing="$missing fzf"
    command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1 || missing="$missing bat"
    command -v tldr >/dev/null 2>&1 || missing="$missing tldr"
    
    if [[ -n "$missing" ]]; then
        warning "Optional tools not installed:$missing"
        echo ""
        echo "To install these tools (recommended):"
        
        if command -v apt-get >/dev/null 2>&1; then
            echo "  sudo apt-get install fzf bat"
            echo "  pip install tldr"
        elif command -v brew >/dev/null 2>&1; then
            echo "  brew install fzf bat tldr"
        elif command -v dnf >/dev/null 2>&1; then
            echo "  sudo dnf install fzf bat"
            echo "  pip install tldr"
        fi
        echo ""
    else
        success "All recommended tools are installed!"
    fi
}

install_bash_functions() {
    info "Installing bash_functions.d..."
    
    local target_dir="${HOME}/.bash_functions.d"
    
    if [[ -e "$target_dir" ]]; then
        if [[ "$FORCE" == true ]]; then
            backup_file "$target_dir"
            rm -rf "$target_dir"
        else
            warning "$target_dir already exists."
            echo -n "Overwrite? (y/n) "
            read -r response
            if [[ "$response" =~ ^[Yy] ]]; then
                backup_file "$target_dir"
                rm -rf "$target_dir"
            else
                info "Skipping bash_functions.d installation."
                return 0
            fi
        fi
    fi
    
    # Option 1: Symlink to repo (for development)
    # ln -sf "${SCRIPT_DIR}/bash_functions.d" "$target_dir"
    
    # Option 2: Copy files (for production)
    cp -r "${SCRIPT_DIR}/bash_functions.d" "$target_dir"
    
    success "bash_functions.d installed to: $target_dir"
}

install_bashrc() {
    info "Installing .bashrc configuration..."
    
    # Check if current bashrc should be preserved
    if [[ -f "${HOME}/.bashrc" ]]; then
        warning "Existing .bashrc found."
        echo ""
        echo "Options:"
        echo "  1) Replace with bash.d .bashrc (backup existing)"
        echo "  2) Merge (append source line to existing)"
        echo "  3) Skip"
        echo ""
        echo -n "Choose option (1/2/3): "
        read -r choice
        
        case "$choice" in
            1)
                backup_file "${HOME}/.bashrc"
                cp "${SCRIPT_DIR}/.bashrc" "${HOME}/.bashrc"
                success "Replaced .bashrc"
                ;;
            2)
                # Append source line
                if ! grep -q "bash_functions.d" "${HOME}/.bashrc" 2>/dev/null; then
                    cat >> "${HOME}/.bashrc" << 'EOF'

# Source bash.d functions
export BASH_FUNCTIONS_D="${HOME}/.bash_functions.d"
if [[ -d "$BASH_FUNCTIONS_D" ]]; then
    for func_file in $(find "$BASH_FUNCTIONS_D" -type f -name "*.sh" 2>/dev/null); do
        source "$func_file"
    done
fi
EOF
                    success "Added bash_functions.d source to .bashrc"
                else
                    info "bash_functions.d already sourced in .bashrc"
                fi
                ;;
            3)
                info "Skipping .bashrc installation."
                ;;
            *)
                error "Invalid choice. Skipping."
                ;;
        esac
    else
        cp "${SCRIPT_DIR}/.bashrc" "${HOME}/.bashrc"
        success "Installed .bashrc"
    fi
}

set_bash_d_repo() {
    # Set BASH_D_REPO environment variable
    local repo_path
    repo_path=$(cd "$SCRIPT_DIR" && pwd)
    
    if ! grep -q "BASH_D_REPO" "${HOME}/.bashrc" 2>/dev/null; then
        echo "" >> "${HOME}/.bashrc"
        echo "# bash.d repository location" >> "${HOME}/.bashrc"
        echo "export BASH_D_REPO=\"${repo_path}\"" >> "${HOME}/.bashrc"
        success "Set BASH_D_REPO to: $repo_path"
    fi
}

verify_installation() {
    echo ""
    info "Verifying installation..."
    echo ""
    
    local issues=0
    
    # Check bash_functions.d
    if [[ -d "${HOME}/.bash_functions.d" ]]; then
        success "bash_functions.d directory exists"
        local func_count
        func_count=$(find "${HOME}/.bash_functions.d" -name "*.sh" -type f 2>/dev/null | wc -l)
        info "  Found $func_count function files"
    else
        error "bash_functions.d directory not found"
        ((issues++))
    fi
    
    # Check .bashrc
    if [[ -f "${HOME}/.bashrc" ]]; then
        success ".bashrc exists"
    else
        error ".bashrc not found"
        ((issues++))
    fi
    
    # Check oh-my-bash
    if [[ -d "${HOME}/.oh-my-bash" ]]; then
        success "oh-my-bash is installed"
    else
        warning "oh-my-bash is not installed (optional)"
    fi
    
    echo ""
    if [[ $issues -eq 0 ]]; then
        success "Installation verified successfully!"
    else
        error "Installation completed with $issues issue(s)"
    fi
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    parse_args "$@"
    print_header
    
    info "Starting installation..."
    echo ""
    
    # Check prerequisites
    if [[ ! -d "${SCRIPT_DIR}/bash_functions.d" ]]; then
        error "bash_functions.d not found in script directory."
        error "Please run this script from the repository root."
        exit 1
    fi
    
    # Install components
    install_oh_my_bash
    echo ""
    
    install_bash_functions
    echo ""
    
    install_bashrc
    echo ""
    
    set_bash_d_repo
    echo ""
    
    install_dependencies
    echo ""
    
    verify_installation
    echo ""
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "To apply changes, either:"
    echo "  1. Run: source ~/.bashrc"
    echo "  2. Open a new terminal"
    echo ""
    echo "Available commands:"
    echo "  func_list      - List available functions"
    echo "  func_add       - Add new function"
    echo "  func_recall    - Search and recall functions"
    echo "  help_me        - Get help for commands"
    echo "  galiases       - Show git shortcuts"
    echo "  daliases       - Show docker shortcuts"
    echo "  netaliases     - Show network shortcuts"
    echo ""
}

main "$@"
