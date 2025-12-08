#!/bin/bash
# Package Collector Script
# Collects information about installed packages from various package managers
# Outputs JSON format for AI agent consumption

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Collect APT packages (Debian/Ubuntu)
collect_apt_packages() {
    if command_exists apt; then
        log_info "Collecting APT packages..."
        local packages
        packages=$(dpkg --get-selections | grep -v deinstall | awk '{print $1}' | sort)
        local manually_installed
        manually_installed=$(apt-mark showmanual | sort)
        
        echo "{
            \"manager\": \"apt\",
            \"all_packages\": $(echo "$packages" | jq -R -s -c 'split("\n")[:-1]'),
            \"manually_installed\": $(echo "$manually_installed" | jq -R -s -c 'split("\n")[:-1]')
        }"
    fi
}

# Collect YUM/DNF packages (RedHat/Fedora/CentOS)
collect_yum_packages() {
    if command_exists yum || command_exists dnf; then
        log_info "Collecting YUM/DNF packages..."
        local cmd="yum"
        command_exists dnf && cmd="dnf"
        
        local packages
        packages=$($cmd list installed 2>/dev/null | tail -n +2 | awk '{print $1}' | sed 's/\.[^.]*$//' | sort)
        
        echo "{
            \"manager\": \"$cmd\",
            \"packages\": $(echo "$packages" | jq -R -s -c 'split("\n")[:-1]')
        }"
    fi
}

# Collect Pacman packages (Arch Linux)
collect_pacman_packages() {
    if command_exists pacman; then
        log_info "Collecting Pacman packages..."
        local packages
        packages=$(pacman -Q | awk '{print $1}' | sort)
        local explicit
        explicit=$(pacman -Qe | awk '{print $1}' | sort)
        
        echo "{
            \"manager\": \"pacman\",
            \"all_packages\": $(echo "$packages" | jq -R -s -c 'split("\n")[:-1]'),
            \"explicitly_installed\": $(echo "$explicit" | jq -R -s -c 'split("\n")[:-1]')
        }"
    fi
}

# Collect Homebrew packages (macOS/Linux)
collect_brew_packages() {
    if command_exists brew; then
        log_info "Collecting Homebrew packages..."
        local packages
        packages=$(brew list --formula -1 2>/dev/null | sort)
        local casks
        casks=$(brew list --cask -1 2>/dev/null | sort)
        local taps
        taps=$(brew tap 2>/dev/null | sort)
        
        echo "{
            \"manager\": \"brew\",
            \"formulae\": $(echo "$packages" | jq -R -s -c 'split("\n")[:-1]'),
            \"casks\": $(echo "$casks" | jq -R -s -c 'split("\n")[:-1]'),
            \"taps\": $(echo "$taps" | jq -R -s -c 'split("\n")[:-1]')
        }"
    fi
}

# Collect Python packages (pip)
collect_pip_packages() {
    local pip_commands=("pip" "pip3")
    local results=()
    
    for pip_cmd in "${pip_commands[@]}"; do
        if command_exists "$pip_cmd"; then
            log_info "Collecting $pip_cmd packages..."
            local packages
            packages=$($pip_cmd list --format=json 2>/dev/null || echo "[]")
            
            if [[ "$packages" != "[]" ]]; then
                results+=("{
                    \"manager\": \"$pip_cmd\",
                    \"packages\": $packages
                }")
            fi
        fi
    done
    
    if [ ${#results[@]} -gt 0 ]; then
        printf '%s\n' "${results[@]}"
    fi
}

# Collect Node.js packages (npm)
collect_npm_packages() {
    if command_exists npm; then
        log_info "Collecting NPM global packages..."
        local packages
        packages=$(npm list -g --depth=0 --json 2>/dev/null | jq -c '.dependencies // {}')
        
        echo "{
            \"manager\": \"npm\",
            \"global_packages\": $packages
        }"
    fi
}

# Collect Ruby gems
collect_gem_packages() {
    if command_exists gem; then
        log_info "Collecting Ruby gems..."
        local packages
        packages=$(gem list --local --no-versions | sort)
        
        echo "{
            \"manager\": \"gem\",
            \"packages\": $(echo "$packages" | jq -R -s -c 'split("\n")[:-1]')
        }"
    fi
}

# Collect Rust packages (cargo)
collect_cargo_packages() {
    if command_exists cargo; then
        log_info "Collecting Cargo packages..."
        local packages
        packages=$(cargo install --list 2>/dev/null | grep -E '^\w+' | awk '{print $1}' | sort)
        
        echo "{
            \"manager\": \"cargo\",
            \"packages\": $(echo "$packages" | jq -R -s -c 'split("\n")[:-1]')
        }"
    fi
}

# Collect Go packages
collect_go_packages() {
    if command_exists go; then
        log_info "Collecting Go packages..."
        local go_path="${GOPATH:-$HOME/go}"
        local packages=()
        
        if [ -d "$go_path/bin" ]; then
            packages=$(ls -1 "$go_path/bin" 2>/dev/null | sort)
        fi
        
        echo "{
            \"manager\": \"go\",
            \"binaries\": $(echo "$packages" | jq -R -s -c 'split("\n")[:-1]'),
            \"go_version\": \"$(go version 2>/dev/null || echo 'unknown')\"
        }"
    fi
}

# Collect Snap packages (Ubuntu)
collect_snap_packages() {
    if command_exists snap; then
        log_info "Collecting Snap packages..."
        local packages
        packages=$(snap list 2>/dev/null | tail -n +2 | awk '{print $1}' | sort)
        
        echo "{
            \"manager\": \"snap\",
            \"packages\": $(echo "$packages" | jq -R -s -c 'split("\n")[:-1]')
        }"
    fi
}

# Collect Flatpak packages
collect_flatpak_packages() {
    if command_exists flatpak; then
        log_info "Collecting Flatpak packages..."
        local packages
        packages=$(flatpak list --app --columns=application 2>/dev/null | sort)
        
        echo "{
            \"manager\": \"flatpak\",
            \"packages\": $(echo "$packages" | jq -R -s -c 'split("\n")[:-1]')
        }"
    fi
}

# Main function
main() {
    log_info "Starting package collection..."
    
    # Check for jq (required for JSON processing)
    if ! command_exists jq; then
        log_error "jq is required but not installed. Please install it first."
        exit 1
    fi
    
    # Start JSON output
    echo "{"
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"hostname\": \"$(hostname)\","
    echo "  \"os\": \"$(uname -s)\","
    echo "  \"package_managers\": ["
    
    # Collect from all available package managers
    local collectors=()
    
    local apt_result=$(collect_apt_packages)
    [ -n "$apt_result" ] && collectors+=("$apt_result")
    
    local yum_result=$(collect_yum_packages)
    [ -n "$yum_result" ] && collectors+=("$yum_result")
    
    local pacman_result=$(collect_pacman_packages)
    [ -n "$pacman_result" ] && collectors+=("$pacman_result")
    
    local brew_result=$(collect_brew_packages)
    [ -n "$brew_result" ] && collectors+=("$brew_result")
    
    # Python packages
    local pip_results=($(collect_pip_packages))
    for result in "${pip_results[@]}"; do
        [ -n "$result" ] && collectors+=("$result")
    done
    
    local npm_result=$(collect_npm_packages)
    [ -n "$npm_result" ] && collectors+=("$npm_result")
    
    local gem_result=$(collect_gem_packages)
    [ -n "$gem_result" ] && collectors+=("$gem_result")
    
    local cargo_result=$(collect_cargo_packages)
    [ -n "$cargo_result" ] && collectors+=("$cargo_result")
    
    local go_result=$(collect_go_packages)
    [ -n "$go_result" ] && collectors+=("$go_result")
    
    local snap_result=$(collect_snap_packages)
    [ -n "$snap_result" ] && collectors+=("$snap_result")
    
    local flatpak_result=$(collect_flatpak_packages)
    [ -n "$flatpak_result" ] && collectors+=("$flatpak_result")
    
    # Output collected data
    local first=true
    for collector in "${collectors[@]}"; do
        if [ -n "$collector" ]; then
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            echo "    $collector"
        fi
    done
    
    echo "  ]"
    echo "}"
    
    log_info "Package collection complete!"
}

# Run main function
main "$@"
