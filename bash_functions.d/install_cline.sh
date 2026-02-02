#!/bin/bash

################################################################################
# Cline Installation Script
#
# This script provides multiple methods to install Cline CLI tool with robust
# error handling and environmental adaptation.
#
# Features:
# - Multiple installation methods (direct download, package manager, AI agent)
# - Comprehensive error handling
# - Environmental detection and adaptation
# - Logging and debugging capabilities
# - User feedback and confirmation prompts
#
# Usage: source this script or run directly
################################################################################

# Script version
SCRIPT_VERSION="1.0.0"

# Global variables
CLINE_INSTALL_DIR="${HOME}/.cline"
CLINE_BIN_DIR="${HOME}/.local/bin"
LOG_FILE="${CLINE_INSTALL_DIR}/install.log"
CONFIG_FILE="${CLINE_INSTALL_DIR}/config.json"
DEFAULT_CLINE_URL="https://github.com/cline/cli/releases/latest/download/cline"
BACKUP_CLINE_URL="https://raw.githubusercontent.com/cline/cli/main/install.sh"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Logging Functions
################################################################################

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    echo "=== Cline Installation Log - $(date) ===" >> "$LOG_FILE"
    log_message "Script version: $SCRIPT_VERSION"
    log_message "Starting installation process"
}

# Log messages to file
log_message() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Log and print error messages
log_error() {
    local message="$1"
    log_message "ERROR: $message"
    echo -e "${RED}[ERROR]${NC} $message" >&2
}

# Log and print success messages
log_success() {
    local message="$1"
    log_message "SUCCESS: $message"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
}

# Log and print info messages
log_info() {
    local message="$1"
    log_message "INFO: $message"
    echo -e "${BLUE}[INFO]${NC} $message"
}

# Log and print warning messages
log_warning() {
    local message="$1"
    log_message "WARNING: $message"
    echo -e "${YELLOW}[WARNING]${NC} $message"
}

################################################################################
# Error Handling Functions
################################################################################

# Global error handler
handle_error() {
    local exit_code=$1
    local line_number=$2
    local command=$3

    if [ $exit_code -ne 0 ]; then
        log_error "Command failed: '$command' (Exit code: $exit_code, Line: $line_number)"
        log_error "Check $LOG_FILE for details"

        # Cleanup on error
        cleanup_on_error

        # Offer recovery options
        offer_recovery_options

        exit $exit_code
    fi
}

# Trap errors and call error handler
trap 'handle_error $? $LINENO "$BASH_COMMAND"' ERR

# Cleanup resources on error
cleanup_on_error() {
    log_info "Performing cleanup after error..."

    # Remove partially downloaded files
    if [ -f "${CLINE_INSTALL_DIR}/cline.tmp" ]; then
        rm -f "${CLINE_INSTALL_DIR}/cline.tmp"
        log_info "Removed temporary download file"
    fi

    # Remove incomplete installation
    if [ -f "${CLINE_BIN_DIR}/cline" ] && [ ! -x "${CLINE_BIN_DIR}/cline" ]; then
        rm -f "${CLINE_BIN_DIR}/cline"
        log_info "Removed incomplete cline binary"
    fi
}

# Offer recovery options to user
offer_recovery_options() {
    echo ""
    echo "Recovery Options:"
    echo "1) Retry installation with different method"
    echo "2) Manual installation instructions"
    echo "3) View detailed logs"
    echo "4) Exit"

    read -p "Select an option [1-4]: " recovery_option

    case $recovery_option in
        1)
            retry_installation
            ;;
        2)
            show_manual_instructions
            ;;
        3)
            show_logs
            ;;
        *)
            log_info "Exiting installation script"
            exit 1
            ;;
    esac
}

# Retry installation with different method
retry_installation() {
    echo ""
    echo "Available installation methods:"
    echo "1) Direct download (default)"
    echo "2) Package manager (if available)"
    echo "3) AI agent installation (experimental)"
    echo "4) Docker container"

    read -p "Select installation method [1-4]: " install_method

    case $install_method in
        1)
            install_cline_direct
            ;;
        2)
            install_cline_package_manager
            ;;
        3)
            install_cline_ai_agent
            ;;
        4)
            install_cline_docker
            ;;
        *)
            log_error "Invalid selection"
            exit 1
            ;;
    esac
}

# Show manual installation instructions
show_manual_instructions() {
    echo ""
    echo "Manual Installation Instructions:"
    echo "1. Download the latest release from: $DEFAULT_CLINE_URL"
    echo "2. Make it executable: chmod +x cline"
    echo "3. Move to your PATH: mv cline ${CLINE_BIN_DIR}/"
    echo "4. Verify installation: cline --version"
    echo ""
    echo "For more information, visit: https://github.com/cline/cli"
}

# Show detailed logs
show_logs() {
    echo ""
    echo "=== Installation Logs ==="
    cat "$LOG_FILE"
    echo "=== End of Logs ==="
}

################################################################################
# System Detection and Environment Functions
################################################################################

# Detect system information
detect_system() {
    log_info "Detecting system information..."

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi

    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            ;;
        *)
            ARCH="unknown"
            ;;
    esac

    # Detect shell
    SHELL_NAME=$(basename "$SHELL")

    # Detect package manager
    if command -v apt-get &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
    elif command -v brew &> /dev/null; then
        PACKAGE_MANAGER="brew"
    elif command -v pacman &> /dev/null; then
        PACKAGE_MANAGER="pacman"
    else
        PACKAGE_MANAGER="none"
    fi

    # Detect if running in Docker
    if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        IN_DOCKER="true"
    else
        IN_DOCKER="false"
    fi

    log_info "Detected System: OS=$OS, ARCH=$ARCH, SHELL=$SHELL_NAME"
    log_info "Package Manager: $PACKAGE_MANAGER"
    log_info "Running in Docker: $IN_DOCKER"

    # Export for use in other functions
    export OS ARCH SHELL_NAME PACKAGE_MANAGER IN_DOCKER
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."

    local missing_deps=0

    # Check for curl
    if ! command -v curl &> /dev/null; then
        log_warning "curl is not installed"
        missing_deps=$((missing_deps + 1))
    fi

    # Check for wget
    if ! command -v wget &> /dev/null; then
        log_warning "wget is not installed"
        missing_deps=$((missing_deps + 1))
    fi

    # Check for git
    if ! command -v git &> /dev/null; then
        log_warning "git is not installed"
        missing_deps=$((missing_deps + 1))
    fi

    # Check for jq (for JSON processing)
    if ! command -v jq &> /dev/null; then
        log_warning "jq is not installed (optional for some features)"
    fi

    if [ $missing_deps -gt 0 ]; then
        log_warning "Missing $missing_deps required dependencies"
        read -p "Attempt to install missing dependencies? [y/N]: " install_deps

        if [[ "$install_deps" =~ ^[Yy]$ ]]; then
            install_missing_dependencies
        else
            log_error "Cannot proceed without required dependencies"
            exit 1
        fi
    else
        log_success "All requirements met"
    fi
}

# Install missing dependencies
install_missing_dependencies() {
    log_info "Installing missing dependencies..."

    case $PACKAGE_MANAGER in
        apt)
            sudo apt-get update
            sudo apt-get install -y curl wget git jq
            ;;
        yum|dnf)
            sudo $PACKAGE_MANAGER install -y curl wget git jq
            ;;
        brew)
            brew install curl wget git jq
            ;;
        pacman)
            sudo pacman -S --noconfirm curl wget git jq
            ;;
        *)
            log_error "Unsupported package manager: $PACKAGE_MANAGER"
            log_info "Please install curl, wget, and git manually"
            exit 1
            ;;
    esac

    # Verify installation
    if ! command -v curl &> /dev/null || ! command -v wget &> /dev/null || ! command -v git &> /dev/null; then
        log_error "Failed to install dependencies"
        exit 1
    fi

    log_success "Dependencies installed successfully"
}

# Check if cline is already installed
check_existing_installation() {
    if command -v cline &> /dev/null; then
        local installed_version=$(cline --version 2>/dev/null || echo "unknown")
        log_warning "Cline is already installed (version: $installed_version)"

        read -p "Do you want to reinstall/upgrade? [y/N]: " reinstall

        if [[ "$reinstall" =~ ^[Yy]$ ]]; then
            log_info "Proceeding with reinstallation"
            return 0
        else
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi
}

################################################################################
# Installation Methods
################################################################################

# Main installation function
install_cline() {
    detect_system
    check_requirements
    check_existing_installation

    echo ""
    echo "Available Installation Methods:"
    echo "1) Direct Download (Recommended) - Downloads binary directly"
    echo "2) Package Manager - Uses system package manager if available"
    echo "3) AI Agent Installation - Uses AI agent to install (experimental)"
    echo "4) Docker - Runs Cline in Docker container"
    echo "5) Source Build - Build from source (advanced)"

    read -p "Select installation method [1-5]: " install_method

    case $install_method in
        1|"")
            install_cline_direct
            ;;
        2)
            install_cline_package_manager
            ;;
        3)
            install_cline_ai_agent
            ;;
        4)
            install_cline_docker
            ;;
        5)
            install_cline_source
            ;;
        *)
            log_error "Invalid selection"
            exit 1
            ;;
    esac
}

# Method 1: Direct download installation
install_cline_direct() {
    log_info "Starting direct download installation..."

    # Create installation directory
    mkdir -p "$CLINE_INSTALL_DIR"
    mkdir -p "$CLINE_BIN_DIR"

    # Add bin directory to PATH if not already there
    if [[ ":$PATH:" != *":${CLINE_BIN_DIR}:"* ]]; then
        log_info "Adding ${CLINE_BIN_DIR} to PATH"
        echo "export PATH=\"\$PATH:${CLINE_BIN_DIR}\"" >> "$HOME/.bashrc"
        echo "export PATH=\"\$PATH:${CLINE_BIN_DIR}\"" >> "$HOME/.zshrc"
        export PATH="$PATH:${CLINE_BIN_DIR}"
    fi

    # Determine download URL based on system
    local download_url="$DEFAULT_CLINE_URL"
    local temp_file="${CLINE_INSTALL_DIR}/cline.tmp"
    local final_file="${CLINE_BIN_DIR}/cline"

    log_info "Downloading Cline from: $download_url"

    # Try curl first, fall back to wget
    if command -v curl &> /dev/null; then
        if ! curl -L -o "$temp_file" "$download_url"; then
            log_warning "curl download failed, trying wget..."
            if ! wget -O "$temp_file" "$download_url"; then
                log_error "Both curl and wget failed to download Cline"
                return 1
            fi
        fi
    elif command -v wget &> /dev/null; then
        if ! wget -O "$temp_file" "$download_url"; then
            log_error "wget failed to download Cline"
            return 1
        fi
    else
        log_error "Neither curl nor wget available for download"
        return 1
    fi

    # Verify download
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        log_error "Download failed - file not found or empty"
        return 1
    fi

    # Make executable and move to final location
    chmod +x "$temp_file"
    mv "$temp_file" "$final_file"

    # Verify installation
    if command -v cline &> /dev/null; then
        local version=$(cline --version)
        log_success "Cline installed successfully! Version: $version"
        log_success "Installation location: $final_file"
    else
        log_error "Installation verification failed"
        return 1
    fi

    # Cleanup
    cleanup_installation
}

# Method 2: Package manager installation
install_cline_package_manager() {
    log_info "Attempting package manager installation..."

    case $PACKAGE_MANAGER in
        apt)
            log_info "Using APT package manager"
            # Check if cline package exists
            if apt-cache show cline &> /dev/null; then
                log_info "Installing cline via APT"
                sudo apt-get update
                sudo apt-get install -y cline
            else
                log_warning "Cline package not found in APT repositories"
                log_info "Falling back to direct download method"
                install_cline_direct
                return $?
            fi
            ;;
        brew)
            log_info "Using Homebrew package manager"
            # Check if cline formula exists
            if brew search cline &> /dev/null; then
                log_info "Installing cline via Homebrew"
                brew install cline
            else
                log_warning "Cline formula not found in Homebrew"
                log_info "Falling back to direct download method"
                install_cline_direct
                return $?
            fi
            ;;
        *)
            log_warning "Package manager $PACKAGE_MANAGER not supported for direct installation"
            log_info "Falling back to direct download method"
            install_cline_direct
            return $?
            ;;
    esac

    # Verify installation
    if command -v cline &> /dev/null; then
        local version=$(cline --version)
        log_success "Cline installed successfully via package manager! Version: $version"
    else
        log_error "Package manager installation failed"
        return 1
    fi
}

# Method 3: AI Agent installation (experimental)
install_cline_ai_agent() {
    log_info "Starting AI agent installation (experimental)..."

    # Check for AI agent tools
    if command -v ollama &> /dev/null; then
        log_info "Detected Ollama AI agent"
        install_cline_ollama
    elif command -v docker &> /dev/null && docker ps &> /dev/null; then
        log_info "Detected Docker (can run AI containers)"
        install_cline_ai_docker
    else
        log_warning "No AI agent tools detected"
        read -p "Install Ollama for AI agent installation? [y/N]: " install_ollama

        if [[ "$install_ollama" =~ ^[Yy]$ ]]; then
            install_ollama_agent
            install_cline_ollama
        else
            log_info "Falling back to direct download method"
            install_cline_direct
        fi
    fi
}

# Install Ollama agent
install_ollama_agent() {
    log_info "Installing Ollama AI agent..."

    if command -v curl &> /dev/null; then
        curl -fsSL https://ollama.com/install.sh | sh
    elif command -v wget &> /dev/null; then
        wget -q -O - https://ollama.com/install.sh | sh
    else
        log_error "Cannot install Ollama - neither curl nor wget available"
        return 1
    fi

    if ! command -v ollama &> /dev/null; then
        log_error "Ollama installation failed"
        return 1
    fi

    log_success "Ollama installed successfully"
}

# Install Cline using Ollama
install_cline_ollama() {
    log_info "Using Ollama to install Cline..."

    # Check if cline model is available
    if ! ollama list | grep -q "cline"; then
        log_info "Pulling cline model..."
        ollama pull cline
    fi

    # Run installation through Ollama
    log_info "Running Cline installation via Ollama..."
    ollama run cline "install cline"

    # Verify installation
    if command -v cline &> /dev/null; then
        local version=$(cline --version)
        log_success "Cline installed successfully via AI agent! Version: $version"
    else
        log_error "AI agent installation failed"
        return 1
    fi
}

# Install Cline using AI in Docker
install_cline_ai_docker() {
    log_info "Using Docker AI container to install Cline..."

    # Run AI installation container
    docker run -it --rm \
        -v "$HOME/.cline:/root/.cline" \
        -v "$CLINE_BIN_DIR:/usr/local/bin" \
        -e HOME=/root \
        ghcr.io/cline/ai-installer:latest

    # Verify installation
    if command -v cline &> /dev/null; then
        local version=$(cline --version)
        log_success "Cline installed successfully via AI Docker! Version: $version"
    else
        log_error "AI Docker installation failed"
        return 1
    fi
}

# Method 4: Docker installation
install_cline_docker() {
    log_info "Setting up Cline Docker container..."

    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        read -p "Install Docker now? [y/N]: " install_docker

        if [[ "$install_docker" =~ ^[Yy]$ ]]; then
            install_docker_engine
        else
            log_info "Falling back to direct download method"
            install_cline_direct
            return $?
        fi
    fi

    # Pull Cline Docker image
    log_info "Pulling Cline Docker image..."
    docker pull ghcr.io/cline/cli:latest

    # Create alias for easy access
    echo "alias cline='docker run -it --rm ghcr.io/cline/cli:latest'" >> "$HOME/.bashrc"
    echo "alias cline='docker run -it --rm ghcr.io/cline/cli:latest'" >> "$HOME/.zshrc"

    log_success "Cline Docker setup complete!"
    log_info "Usage: cline [command]"
    log_info "Or run directly: docker run -it --rm ghcr.io/cline/cli:latest [command]"
}

# Install Docker engine
install_docker_engine() {
    log_info "Installing Docker engine..."

    case $PACKAGE_MANAGER in
        apt)
            # Install Docker on Ubuntu/Debian
            sudo apt-get update
            sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release

            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

            # Add user to docker group
            sudo usermod -aG docker "$USER"
            log_info "You may need to log out and back in for Docker to work properly"
            ;;
        brew)
            # Install Docker on macOS
            brew install --cask docker
            ;;
        *)
            log_error "Unsupported package manager for Docker installation: $PACKAGE_MANAGER"
            return 1
            ;;
    esac

    if ! command -v docker &> /dev/null; then
        log_error "Docker installation failed"
        return 1
    fi

    log_success "Docker installed successfully"
}

# Method 5: Build from source
install_cline_source() {
    log_info "Building Cline from source..."

    # Check for build tools
    if ! command -v git &> /dev/null; then
        log_error "Git is required for source installation"
        return 1
    fi

    if ! command -v make &> /dev/null; then
        log_error "make is required for source installation"
        return 1
    fi

    if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
        log_error "C compiler (gcc or clang) is required for source installation"
        return 1
    fi

    # Clone repository
    local repo_url="https://github.com/cline/cli.git"
    local temp_dir=$(mktemp -d)

    log_info "Cloning Cline repository..."
    if ! git clone "$repo_url" "$temp_dir"; then
        log_error "Failed to clone Cline repository"
        rm -rf "$temp_dir"
        return 1
    fi

    # Build from source
    log_info "Building Cline from source..."
    cd "$temp_dir" || return 1

    if ! make build; then
        log_error "Build failed"
        cd - || return 1
        rm -rf "$temp_dir"
        return 1
    fi

    # Install binary
    mkdir -p "$CLINE_BIN_DIR"
    if ! cp cline "$CLINE_BIN_DIR/"; then
        log_error "Failed to copy binary to installation directory"
        cd - || return 1
        rm -rf "$temp_dir"
        return 1
    fi

    # Cleanup
    cd - || return 1
    rm -rf "$temp_dir"

    # Verify installation
    if command -v cline &> /dev/null; then
        local version=$(cline --version)
        log_success "Cline built and installed successfully! Version: $version"
    else
        log_error "Source installation failed"
        return 1
    fi
}

################################################################################
# Post-Installation Functions
################################################################################

# Cleanup after installation
cleanup_installation() {
    log_info "Cleaning up installation files..."

    # Remove temporary files
    rm -f "${CLINE_INSTALL_DIR}/cline.tmp"

    # Remove old backups
    rm -f "${CLINE_BIN_DIR}/cline.bak"

    log_success "Cleanup complete"
}

# Configure Cline
configure_cline() {
    log_info "Configuring Cline..."

    # Create config directory
    mkdir -p "$CLINE_INSTALL_DIR"

    # Create default config if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" <<EOF
{
    "version": "1.0",
    "installation": {
        "method": "direct",
        "date": "$(date)",
        "version": "$(cline --version 2>/dev/null || echo 'unknown')"
    },
    "settings": {
        "auto_update": true,
        "telemetry": false,
        "log_level": "info"
    }
}
EOF
        log_info "Created default configuration file"
    fi

    log_success "Configuration complete"
}

# Verify installation
verify_installation() {
    log_info "Verifying Cline installation..."

    if ! command -v cline &> /dev/null; then
        log_error "Cline command not found in PATH"
        return 1
    fi

    local version=$(cline --version 2>/dev/null)
    if [ -z "$version" ]; then
        log_error "Cline version check failed"
        return 1
    fi

    log_success "Installation verified successfully"
    log_success "Cline version: $version"
    log_success "Installation path: $(command -v cline)"

    # Show basic usage
    echo ""
    echo "Basic Usage:"
    echo "  cline --help          Show help"
    echo "  cline --version       Show version"
    echo "  cline update          Update to latest version"
    echo "  cline config          Configure settings"
}

################################################################################
# Main Execution
################################################################################

# Main function
main() {
    # Initialize
    init_logging

    # Welcome message
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        Cline Installation Script v${SCRIPT_VERSION}                   ║"
    echo "║        Robust installation with multiple methods                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Start installation
    install_cline

    # Post-installation steps
    if [ $? -eq 0 ]; then
        configure_cline
        verify_installation
        cleanup_installation

        echo -e "${GREEN}"
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║                    Installation Complete!                      ║"
        echo "║                                                                ║"
        echo "║  Cline has been successfully installed.                       ║"
        echo "║  You can now use: cline [command]                            ║"
        echo "║                                                                ║"
        echo "║  Logs saved to: $LOG_FILE                                  ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
    fi
}

# Execute main function
main "$@"
