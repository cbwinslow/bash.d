#!/bin/bash
# bash-it integration installer for bash.d
# This script sets up bash.d as a bash-it plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASH_IT_DIR="${BASH_IT:-$HOME/.bash_it}"
BASHD_REPO="${BASHD_REPO:-$SCRIPT_DIR}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         bash.d Integration with bash-it                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_bash_it() {
    if [[ ! -d "$BASH_IT_DIR" ]]; then
        error "bash-it not found at $BASH_IT_DIR"
        echo ""
        echo "Please install bash-it first:"
        echo "  git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it"
        echo "  ~/.bash_it/install.sh"
        echo ""
        exit 1
    fi
    success "bash-it found at $BASH_IT_DIR"
}

install_as_plugin() {
    info "Installing bash.d as bash-it plugin..."
    
    local custom_dir="$BASH_IT_DIR/custom"
    mkdir -p "$custom_dir"
    
    # Create bash.d custom directory
    mkdir -p "$custom_dir/bash.d"
    
    # Link the plugin file
    local plugin_link="$custom_dir/bash.d.plugin.bash"
    if [[ -L "$plugin_link" ]]; then
        warning "Plugin link already exists, removing old link"
        rm -f "$plugin_link"
    fi
    
    ln -sf "$BASHD_REPO/lib/bash-it-plugin.bash" "$plugin_link"
    success "Created plugin link: $plugin_link"
}

configure_bashrc() {
    info "Checking ~/.bashrc configuration..."
    
    local bashrc="$HOME/.bashrc"
    local needs_update=false
    
    # Check if BASH_D_REPO is set
    if ! grep -q "BASH_D_REPO" "$bashrc" 2>/dev/null; then
        needs_update=true
    fi
    
    if [[ "$needs_update" == true ]]; then
        info "Adding bash.d configuration to ~/.bashrc"
        
        cat >> "$bashrc" << EOF

# bash.d configuration
export BASH_D_REPO="$BASHD_REPO"
export BASHD_REPO_ROOT="$BASHD_REPO"
EOF
        success "Updated ~/.bashrc with bash.d configuration"
    else
        success "~/.bashrc already configured"
    fi
}

enable_plugin() {
    info "The bash.d plugin has been installed in bash-it custom directory"
    echo ""
    echo "The plugin will be automatically loaded on next shell startup."
    echo ""
    echo "To manually load it now, run:"
    echo "  source ~/.bashrc"
}

verify_installation() {
    echo ""
    info "Verifying installation..."
    echo ""
    
    # Check plugin link
    if [[ -L "$BASH_IT_DIR/custom/bash.d.plugin.bash" ]]; then
        success "Plugin link exists"
    else
        error "Plugin link not found"
        return 1
    fi
    
    # Check bash.d repo
    if [[ -d "$BASHD_REPO" ]]; then
        success "bash.d repository found at $BASHD_REPO"
    else
        error "bash.d repository not found"
        return 1
    fi
    
    # Check lib files
    if [[ -f "$BASHD_REPO/lib/bash-it-plugin.bash" ]]; then
        success "bash-it plugin file exists"
    else
        error "bash-it plugin file not found"
        return 1
    fi
    
    echo ""
    success "Installation verification complete!"
}

show_usage() {
    echo ""
    echo "Once you reload your shell, you can use bash.d with bash-it:"
    echo ""
    echo "  # List bash.d modules"
    echo "  bashd-list"
    echo ""
    echo "  # Enable bash.d modules"
    echo "  bashd-enable plugins bashd-core"
    echo "  bashd-enable aliases git"
    echo ""
    echo "  # Use bash-it normally"
    echo "  bash-it show plugins"
    echo "  bash-it enable plugin git"
    echo ""
    echo "  # Search for functions"
    echo "  func_search docker"
    echo ""
    echo "  # Quick navigation"
    echo "  cdbd          # cd to bash.d repo"
    echo ""
}

main() {
    print_header
    
    info "Starting bash-it integration..."
    echo ""
    
    check_bash_it
    echo ""
    
    install_as_plugin
    echo ""
    
    configure_bashrc
    echo ""
    
    enable_plugin
    
    verify_installation
    
    show_usage
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "To apply changes, run:"
    echo "  source ~/.bashrc"
    echo ""
}

main "$@"
