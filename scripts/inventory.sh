#!/usr/bin/env bash

# Inventory System - Create comprehensive inventory of all packages, repos, scripts
# Part of bash.d - Master system inventory for backup/restore

set -euo pipefail

BASHD_HOME="${BASHD_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
INVENTORY_DIR="$BASHD_HOME/inventory"
TIMESTAMP="$(date +%Y%m%d_%H%M%S | tr -d ':')"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Ensure inventory directory exists
mkdir -p "$INVENTORY_DIR"

# ============================================
# 1. Package Manager Inventory
# ============================================

inventory_packages() {
    log_info "Collecting package inventories..."
    
    # npm packages (global)
    if command -v npm &> /dev/null; then
        npm list -g --depth=0 --json > "$INVENTORY_DIR/npm_global_$TIMESTAMP.json" 2>/dev/null || echo '{}' > "$INVENTORY_DIR/npm_global_$TIMESTAMP.json"
        npm list -g --depth=0 2>/dev/null | grep -v '^$' | tail -n +2 > "$INVENTORY_DIR/npm_global_$TIMESTAMP.txt" || true
        log_info "  ✓ npm packages inventoried"
    fi
    
    # yarn packages (global)
    if command -v yarn &> /dev/null; then
        yarn global list --json > "$INVENTORY_DIR/yarn_global_$TIMESTAMP.json" 2>/dev/null || echo '[]' > "$INVENTORY_DIR/yarn_global_$TIMESTAMP.json"
        log_info "  ✓ yarn packages inventoried"
    fi
    
    # pip packages
    if command -v pip &> /dev/null; then
        pip list --format=json > "$INVENTORY_DIR/pip_$TIMESTAMP.json" 2>/dev/null || echo '[]' > "$INVENTORY_DIR/pip_$TIMESTAMP.json"
        pip freeze > "$INVENTORY_DIR/pip_$TIMESTAMP.txt" 2>/dev/null || true
        log_info "  ✓ pip packages inventoried"
    fi
    
    # pipx packages
    if command -v pipx &> /dev/null; then
        pipx list > "$INVENTORY_DIR/pipx_$TIMESTAMP.txt" 2>/dev/null || true
        log_info "  ✓ pipx packages inventoried"
    fi
    
    # Homebrew packages
    if command -v brew &> /dev/null; then
        brew list --json > "$INVENTORY_DIR/brew_$TIMESTAMP.json" 2>/dev/null || echo '{}' > "$INVENTORY_DIR/brew_$TIMESTAMP.json"
        brew list > "$INVENTORY_DIR/brew_$TIMESTAMP.txt" 2>/dev/null || true
        log_info "  ✓ Homebrew packages inventoried"
    fi
    
    # apt packages
    if command -v dpkg &> /dev/null; then
        dpkg -l > "$INVENTORY_DIR/apt_$TIMESTAMP.txt" 2>/dev/null || true
        log_info "  ✓ apt packages inventoried"
    fi
    
    # Go packages
    if command -v go &> /dev/null; then
        go list -m all > "$INVENTORY_DIR/go_$TIMESTAMP.txt" 2>/dev/null || true
        log_info "  ✓ Go packages inventoried"
    fi
    
    # cargo/Rust
    if command -v cargo &> /dev/null; then
        cargo install --list > "$INVENTORY_DIR/cargo_$TIMESTAMP.txt" 2>/dev/null || true
        log_info "  ✓ Cargo packages inventoried"
    fi
    
    # Ruby gems
    if command -v gem &> /dev/null; then
        gem list --local > "$INVENTORY_DIR/gem_$TIMESTAMP.txt" 2>/dev/null || true
        log_info "  ✓ Ruby gems inventoried"
    fi
    
    # Composer (PHP)
    if command -v composer &> /dev/null; then
        composer global show --no-interaction > "$INVENTORY_DIR/composer_$TIMESTAMP.txt" 2>/dev/null || true
        log_info "  ✓ Composer packages inventoried"
    fi
    
    # Snap packages
    if command -v snap &> /dev/null; then
        snap list > "$INVENTORY_DIR/snap_$TIMESTAMP.txt" 2>/dev/null || true
        log_info "  ✓ Snap packages inventoried"
    fi
}

# ============================================
# 2. Repository Inventory
# ============================================

inventory_repos() {
    log_info "Collecting repository inventories..."
    
    # GitHub repositories (using gh CLI)
    if command -v gh &> /dev/null; then
        gh repo list "$USER" --limit 100 --json name,url,description,visibility > "$INVENTORY_DIR/github_repos_$TIMESTAMP.json" 2>/dev/null || echo '[]' > "$INVENTORY_DIR/github_repos_$TIMESTAMP.json"
        log_info "  ✓ GitHub repos inventoried"
    fi
    
    # GitLab repositories (if configured)
    if command -v glab &> /dev/null; then
        glab repo list --owned --json > "$INVENTORY_DIR/gitlab_repos_$TIMESTAMP.json" 2>/dev/null || echo '[]' > "$INVENTORY_DIR/gitlab_repos_$TIMESTAMP.json"
        log_info "  ✓ GitLab repos inventoried"
    fi
    
    # Local git repos
    {
        echo "# Local Git Repositories"
        echo "# Generated: $(date)"
        echo ""
        find ~ -maxdepth 4 -type d -name '.git' 2>/dev/null | while read -r repo; do
            dir=$(dirname "$repo")
            echo "  $dir"
        done
    } > "$INVENTORY_DIR/local_repos_$TIMESTAMP.txt"
    log_info "  ✓ Local git repos inventoried"
}

# ============================================
# 3. Script Inventory
# ============================================

inventory_scripts() {
    log_info "Collecting script inventories..."
    
    # All bash scripts in bash.d
    {
        echo "# bash.d Script Inventory"
        echo "# Generated: $(date)"
        echo ""
        find "$BASHD_HOME" -name "*.sh" -type f 2>/dev/null | while read -r script; do
            size=$(stat -c%s "$script" 2>/dev/null || echo "0")
            echo "$(basename "$script")|$script|$size"
        done
    } > "$INVENTORY_DIR/scripts_$TIMESTAMP.csv"
    
    # Count scripts by directory
    {
        echo "# Script Count by Directory"
        echo "# Generated: $(date)"
        echo ""
        find "$BASHD_HOME" -name "*.sh" -type f 2>/dev/null | xargs dirname 2>/dev/null | sort | uniq -c | sort -rn
    } > "$INVENTORY_DIR/scripts_by_dir_$TIMESTAMP.txt"
    
    log_info "  ✓ Scripts inventoried"
}

# ============================================
# 4. Configuration Inventory
# ============================================

inventory_configs() {
    log_info "Collecting configuration inventories..."
    
    # Dotfiles
    {
        echo "# Dotfiles Inventory"
        echo "# Generated: $(date)"
        echo ""
        find "$BASHD_HOME/dotfiles" -type f 2>/dev/null | while read -r file; do
            echo "$(basename "$file")|$file"
        done
    } > "$INVENTORY_DIR/dotfiles_$TIMESTAMP.txt"
    
    # YAML configs
    find "$BASHD_HOME" -name "*.yaml" -o -name "*.yml" 2>/dev/null | while read -r config; do
        echo "$config"
    done > "$INVENTORY_DIR/configs_yaml_$TIMESTAMP.txt"
    
    # JSON configs
    find "$BASHD_HOME" -name "*.json" 2>/dev/null | grep -v node_modules | while read -r config; do
        echo "$config"
    done > "$INVENTORY_DIR/configs_json_$TIMESTAMP.txt"
    
    log_info "  ✓ Configurations inventoried"
}

# ============================================
# 5. Docker Inventory
# ============================================

inventory_docker() {
    log_info "Collecting Docker inventories..."
    
    # Running containers
    if command -v docker &> /dev/null; then
        docker ps -a --format "{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}" > "$INVENTORY_DIR/docker_containers_$TIMESTAMP.txt" 2>/dev/null || true
        docker images --format "{{.Repository}}:{{.Tag}}|{{.Size}}|{{.CreatedAt}}" > "$INVENTORY_DIR/docker_images_$TIMESTAMP.txt" 2>/dev/null || true
        docker volume ls --format "{{.Name}}" > "$INVENTORY_DIR/docker_volumes_$TIMESTAMP.txt" 2>/dev/null || true
        log_info "  ✓ Docker containers/images inventoried"
    fi
    
    # Podman if available
    if command -v podman &> /dev/null; then
        podman ps -a --format "{{.Names}}|{{.Image}}|{{.Status}}" > "$INVENTORY_DIR/podman_containers_$TIMESTAMP.txt" 2>/dev/null || true
        log_info "  ✓ Podman containers inventoried"
    fi
}

# ============================================
# 6. System Information
# ============================================

inventory_system() {
    log_info "Collecting system information..."
    
    {
        echo "bash.d System Inventory"
        echo "======================"
        echo "Generated: $(date)"
        echo ""
        
        echo "## OS Information"
        uname -a
        echo ""
        
        echo "## Shell"
        echo "BASH_VERSION: $BASH_VERSION"
        echo "SHELL: $SHELL"
        echo ""
        
        echo "## Package Managers Available"
        for pm in npm yarn pip pipx brew apt go cargo gem composer snap; do
            if command -v "$pm" &> /dev/null; then
                echo "  ✓ $pm"
            else
                echo "  ✗ $pm"
            fi
        done
        echo ""
        
        echo "## Development Tools"
        for tool in docker podman gh git curl wget jq; do
            if command -v "$tool" &> /dev/null; then
                version=$($tool --version 2>/dev/null | head -1 || echo "installed")
                echo "  ✓ $tool: $version"
            else
                echo "  ✗ $tool"
            fi
        done
        echo ""
        
        echo "## AI Tools"
        for tool in ollama Claude cursor code; do
            if command -v "$tool" &> /dev/null; then
                version=$($tool --version 2>/dev/null | head -1 || echo "installed")
                echo "  ✓ $tool: $version"
            else
                echo "  ✗ $tool"
            fi
        done
    } > "$INVENTORY_DIR/system_$TIMESTAMP.txt"
    
    log_info "  ✓ System information inventoried"
}

# ============================================
# 7. Generate Install Script
# ============================================

generate_install_script() {
    log_info "Generating installation script..."
    
    cat > "$INVENTORY_DIR/install_all_$TIMESTAMP.sh" << 'INSTALL_EOF'
#!/usr/bin/env bash
# Auto-generated installation script from bash.d inventory
# Run this on a new system to install all your packages

set -euo pipefail

echo "Installing packages from inventory..."

# Install npm global packages
if command -v npm &> /dev/null && [ -f "${BASH_SOURCE%/*}/npm_global_*.txt" ]; then
    echo "Installing npm packages..."
    # Extract package names and install
fi

# Install pip packages
if command -v pip &> /dev/null && [ -f "${BASH_SOURCE%/*}/pip_*.txt" ]; then
    echo "Installing pip packages..."
    pip install -r "${BASH_SOURCE%/*}/pip_*.txt" 2>/dev/null || true
fi

# Install Homebrew packages
if command -v brew &> /dev/null && [ -f "${BASH_SOURCE%/*}/brew_*.txt" ]; then
    echo "Installing Homebrew packages..."
    while read -r pkg; do
        brew install "$pkg" 2>/dev/null || true
    done < "${BASH_SOURCE%/*}/brew_*.txt"
fi

echo "Installation complete!"
INSTALL_EOF
    
    chmod +x "$INVENTORY_DIR/install_all_$TIMESTAMP.sh"
    log_info "  ✓ Installation script generated"
}

# ============================================
# 8. Create Master Summary
# ============================================

create_summary() {
    log_info "Creating master summary..."
    
    {
        echo "bash.d Master Inventory Summary"
        echo "================================"
        echo "Generated: $(date)"
        echo "Timestamp: $TIMESTAMP"
        echo ""
        
        echo "## Package Counts"
        [ -f "$INVENTORY_DIR/npm_global_$TIMESTAMP.txt" ] && echo "  npm (global): $(grep -c '^' "$INVENTORY_DIR/npm_global_$TIMESTAMP.txt" 2>/dev/null || echo 0)"
        [ -f "$INVENTORY_DIR/pip_$TIMESTAMP.txt" ] && echo "  pip: $(grep -c '^' "$INVENTORY_DIR/pip_$TIMESTAMP.txt" 2>/dev/null || echo 0)"
        [ -f "$INVENTORY_DIR/brew_$TIMESTAMP.txt" ] && echo "  brew: $(grep -c '^' "$INVENTORY_DIR/brew_$TIMESTAMP.txt" 2>/dev/null || echo 0)"
        [ -f "$INVENTORY_DIR/apt_$TIMESTAMP.txt" ] && echo "  apt: $(grep -c '^ii' "$INVENTORY_DIR/apt_$TIMESTAMP.txt" 2>/dev/null || echo 0)"
        [ -f "$INVENTORY_DIR/go_$TIMESTAMP.txt" ] && echo "  go: $(grep -c '^' "$INVENTORY_DIR/go_$TIMESTAMP.txt" 2>/dev/null || echo 0)"
        echo ""
        
        echo "## Repository Counts"
        [ -f "$INVENTORY_DIR/github_repos_$TIMESTAMP.json" ] && echo "  GitHub: $(grep -o '"name"' "$INVENTORY_DIR/github_repos_$TIMESTAMP.json" 2>/dev/null | wc -l || echo 0)"
        [ -f "$INVENTORY_DIR/local_repos_$TIMESTAMP.txt" ] && echo "  Local: $(grep -c '^/' "$INVENTORY_DIR/local_repos_$TIMESTAMP.txt" 2>/dev/null || echo 0)"
        echo ""
        
        echo "## Script Counts"
        [ -f "$INVENTORY_DIR/scripts_$TIMESTAMP.csv" ] && echo "  Total scripts: $(grep -c '^' "$INVENTORY_DIR/scripts_$TIMESTAMP.csv" 2>/dev/null || echo 0)"
        echo ""
        
        echo "## Docker"
        [ -f "$INVENTORY_DIR/docker_containers_$TIMESTAMP.txt" ] && echo "  Containers: $(grep -c '^' "$INVENTORY_DIR/docker_containers_$TIMESTAMP.txt" 2>/dev/null || echo 0)"
        [ -f "$INVENTORY_DIR/docker_images_$TIMESTAMP.txt" ] && echo "  Images: $(grep -c '^' "$INVENTORY_DIR/docker_images_$TIMESTAMP.txt" 2>/dev/null || echo 0)"
        echo ""
        
        echo "## Files Generated"
        ls -1 "$INVENTORY_DIR"/*"$TIMESTAMP"* 2>/dev/null | wc -l | xargs echo "  Total inventory files:"
    } > "$INVENTORY_DIR/summary_$TIMESTAMP.txt"
    
    log_info "  ✓ Summary created"
}

# ============================================
# Main Function
# ============================================

main() {
    local mode="${1:-all}"
    
    echo "========================================"
    echo "  bash.d Inventory System"
    echo "  Timestamp: $TIMESTAMP"
    echo "========================================"
    echo ""
    
    case "$mode" in
        "packages")
            inventory_packages
            ;;
        "repos")
            inventory_repos
            ;;
        "scripts")
            inventory_scripts
            ;;
        "configs")
            inventory_configs
            ;;
        "docker")
            inventory_docker
            ;;
        "system")
            inventory_system
            ;;
        "all")
            inventory_packages
            inventory_repos
            inventory_scripts
            inventory_configs
            inventory_docker
            inventory_system
            generate_install_script
            create_summary
            ;;
        *)
            echo "Usage: $0 {packages|repos|scripts|configs|docker|system|all}"
            exit 1
            ;;
    esac
    
    echo ""
    echo "========================================"
    log_info "Inventory complete!"
    log_info "Files saved to: $INVENTORY_DIR"
    echo "========================================"
}

main "$@"
