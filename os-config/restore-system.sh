#!/bin/bash
# System Restoration Script
# Restores system configuration from a backup bundle
# Usage: ./restore-system.sh <bundle-directory> [--dry-run]

set -euo pipefail

BUNDLE_DIR="${1:-.}"
DRY_RUN=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $*"
}

# Parse arguments
if [ $# -eq 0 ]; then
    log_error "Usage: $0 <bundle-directory> [--dry-run]"
    exit 1
fi

if [ "$#" -gt 1 ] && [ "$2" = "--dry-run" ]; then
    DRY_RUN=true
    log_info "Running in dry-run mode"
fi

# Validate bundle directory
if [ ! -d "$BUNDLE_DIR" ]; then
    log_error "Bundle directory not found: $BUNDLE_DIR"
    exit 1
fi

if [ ! -f "$BUNDLE_DIR/metadata.json" ]; then
    log_error "Invalid bundle: metadata.json not found"
    exit 1
fi

# Show bundle information
show_bundle_info() {
    log_step "Bundle Information:"
    
    if command -v jq &> /dev/null && [ -f "$BUNDLE_DIR/metadata.json" ]; then
        local backup_name=$(jq -r '.backup_name' "$BUNDLE_DIR/metadata.json")
        local timestamp=$(jq -r '.timestamp' "$BUNDLE_DIR/metadata.json")
        local hostname=$(jq -r '.hostname' "$BUNDLE_DIR/metadata.json")
        
        echo "  Backup Name: $backup_name"
        echo "  Created:     $timestamp"
        echo "  From Host:   $hostname"
        echo ""
    fi
}

# Restore APT packages
restore_apt_packages() {
    if [ ! -f "$BUNDLE_DIR/packages.json" ]; then
        log_warn "packages.json not found, skipping package restoration"
        return
    fi
    
    log_step "Restoring APT packages..."
    
    if ! command -v jq &> /dev/null; then
        log_error "jq is required for restoration"
        exit 1
    fi
    
    local packages=$(jq -r '.package_managers[] | select(.manager == "apt") | .manually_installed[]?' "$BUNDLE_DIR/packages.json" 2>/dev/null)
    
    if [ -z "$packages" ]; then
        log_info "No APT packages to restore"
        return
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would install packages:"
        echo "$packages" | head -20
        return
    fi
    
    log_info "Installing packages (this may take a while)..."
    # Install packages individually to avoid command injection
    while IFS= read -r pkg; do
        if [ -n "$pkg" ]; then
            sudo apt-get install -y "$pkg" 2>&1 | tee -a /tmp/apt-restore.log
        fi
    done <<< "$packages"
    log_info "✓ APT packages installed"
}

# Restore Python packages
restore_pip_packages() {
    if [ ! -f "$BUNDLE_DIR/packages.json" ]; then
        return
    fi
    
    log_step "Restoring Python packages..."
    
    local packages=$(jq -r '.package_managers[] | select(.manager == "pip3") | .packages[].name' "$BUNDLE_DIR/packages.json" 2>/dev/null)
    
    if [ -z "$packages" ]; then
        log_info "No Python packages to restore"
        return
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would install pip packages:"
        echo "$packages" | head -20
        return
    fi
    
    log_info "Installing Python packages..."
    # Install packages individually to avoid command injection
    while IFS= read -r pkg; do
        if [ -n "$pkg" ]; then
            pip3 install "$pkg" 2>&1 | tee -a /tmp/pip-restore.log
        fi
    done <<< "$packages"
    log_info "✓ Python packages installed"
}

# Restore NPM packages
restore_npm_packages() {
    if [ ! -f "$BUNDLE_DIR/packages.json" ]; then
        return
    fi
    
    if ! command -v npm &> /dev/null; then
        log_warn "npm not installed, skipping NPM package restoration"
        return
    fi
    
    log_step "Restoring NPM packages..."
    
    local packages=$(jq -r '.package_managers[] | select(.manager == "npm") | .global_packages | keys[]' "$BUNDLE_DIR/packages.json" 2>/dev/null)
    
    if [ -z "$packages" ]; then
        log_info "No NPM packages to restore"
        return
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would install npm packages:"
        echo "$packages"
        return
    fi
    
    log_info "Installing NPM packages..."
    # Install packages individually to avoid command injection
    while IFS= read -r pkg; do
        if [ -n "$pkg" ]; then
            npm install -g "$pkg" 2>&1 | tee -a /tmp/npm-restore.log
        fi
    done <<< "$packages"
    log_info "✓ NPM packages installed"
}

# Show manual steps
show_manual_steps() {
    log_step "Manual Steps Required:"
    
    echo ""
    echo "The following items need manual attention:"
    echo ""
    echo "1. Review and restore dotfiles:"
    echo "   cat $BUNDLE_DIR/dotfiles.json"
    echo ""
    echo "2. Configure databases:"
    echo "   cat $BUNDLE_DIR/databases.json"
    echo ""
    echo "3. Restore Docker containers:"
    echo "   cat $BUNDLE_DIR/containers.json"
    echo ""
    echo "4. Clone Git repositories:"
    echo "   cat $BUNDLE_DIR/repositories.json"
    echo ""
    echo "5. Configure system services:"
    echo "   cat $BUNDLE_DIR/system.json"
    echo ""
    echo "6. Full setup guide:"
    echo "   cat $BUNDLE_DIR/SETUP_GUIDE.md"
    echo ""
}

# Main restoration
main() {
    echo "========================================"
    echo "  System Configuration Restoration"
    echo "========================================"
    echo ""
    
    show_bundle_info
    
    log_warn "This script will install packages and modify your system."
    log_warn "Make sure you have reviewed the bundle contents first."
    echo ""
    
    if [ "$DRY_RUN" = false ]; then
        read -p "Continue with restoration? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            log_info "Restoration cancelled"
            exit 0
        fi
    fi
    
    # Restore packages
    restore_apt_packages
    restore_pip_packages
    restore_npm_packages
    
    # Show what needs manual work
    show_manual_steps
    
    echo ""
    echo "========================================"
    echo "  Restoration Summary"
    echo "========================================"
    echo ""
    log_info "Automated restoration complete!"
    log_info "Please review the manual steps above."
    echo ""
}

main
