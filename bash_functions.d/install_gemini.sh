#!/bin/bash

################################################################################
# Gemini CLI Installation Script
#
# This script provides multiple methods to install Gemini CLI tool with robust
# error handling and environmental adaptation.
#
# Features:
# - Multiple installation methods (npm, Docker, source)
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
GEMINI_INSTALL_DIR="${HOME}/.gemini"
GEMINI_BIN_DIR="${HOME}/.local/bin"
LOG_FILE="${GEMINI_INSTALL_DIR}/install.log"
CONFIG_FILE="${GEMINI_INSTALL_DIR}/config.json"
DEFAULT_GEMINI_NPM="@google/gemini-cli"
DEFAULT_GEMINI_DOCKER="ghcr.io/google/gemini-cli"
BACKUP_GEMINI_URL="https://github.com/google/gemini-cli"

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
    echo "=== Gemini Installation Log - $(date) ===" >> "$LOG_FILE"
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

    # Remove temporary files
    if [ -f "${GEMINI_INSTALL_DIR}/gemini.tmp" ]; then
        rm -f "${GEMINI_INSTALL_DIR}/gemini.tmp"
        log_info "Removed temporary download file"
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
    echo "1) npm (default)"
    echo "2) Docker container"
    echo "3) Source build"

    read -p "Select installation method [1-3]: " install_method

    case $install_method in
        1|"")
            install_gemini_npm
            ;;
        2)
            install_gemini_docker
            ;;
        3)
            install_gemini_source
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
    echo "1. Install via npm: npm install -g @google/gemini-cli"
    echo "2. Verify installation: gemini --version"
    echo "3. For Docker: docker pull ghcr.io/google/gemini-cli"
    echo ""
    echo "For more information, visit: https://github.com/google/gemini-cli"
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

    # Check for npm (primary requirement)
    if ! command -v npm &> /dev/null; then
        log_warning "npm is not installed"
        missing_deps=$((missing_deps + 1))
    fi

    # Check for node
    if ! command -v node &> /dev/null; then
        log_warning "Node.js is not installed"
        missing_deps=$((missing_deps + 1))
    fi

    # Check for docker (optional)
    if ! command -v docker &> /dev/null; then
        log_info "Docker is not installed (optional for some methods)"
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

    # Install Node.js and npm
    case $PACKAGE_MANAGER in
        apt)
            log_info "Installing Node.js and npm via APT"
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        brew)
            log_info "Installing Node.js and npm via Homebrew"
            brew install node
            ;;
        *)
            log_error "Unsupported package manager for Node.js installation: $PACKAGE_MANAGER"
            log_info "Please install Node.js and npm manually from https://nodejs.org/"
            exit 1
            ;;
    esac

    # Verify installation
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        log_error "Failed to install Node.js dependencies"
        exit 1
    fi

    log_success "Dependencies installed successfully"
}

# Check if gemini is already installed
check_existing_installation() {
    if command -v gemini &> /dev/null; then
        local installed_version=$(gemini --version 2>/dev/null || echo "unknown")
        log_warning "Gemini CLI is already installed (version: $installed_version)"

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
install_gemini() {
    detect_system
    check_requirements
    check_existing_installation

    echo ""
    echo "Available Installation Methods:"
    echo "1) npm (Recommended) - Installs via Node.js package manager"
    echo "2) Docker - Runs Gemini CLI in Docker container"
    echo "3) Source Build - Build from source (advanced)"

    read -p "Select installation method [1-3]: " install_method

    case $install_method in
        1|"")
            install_gemini_npm
            ;;
        2)
            install_gemini_docker
            ;;
        3)
            install_gemini_source
            ;;
        *)
            log_error "Invalid selection"
            exit 1
            ;;
    esac
}

# Method 1: npm installation
install_gemini_npm() {
    log_info "Starting npm installation..."

    # Create installation directory
    mkdir -p "$GEMINI_INSTALL_DIR"
    mkdir -p "$GEMINI_BIN_DIR"

    # Add bin directory to PATH if not already there
    if [[ ":$PATH:" != *":${GEMINI_BIN_DIR}:"* ]]; then
        log_info "Adding ${GEMINI_BIN_DIR} to PATH"
        echo "export PATH=\"\$PATH:${GEMINI_BIN_DIR}\"" >> "$HOME/.bashrc"
        echo "export PATH=\"\$PATH:${GEMINI_BIN_DIR}\"" >> "$HOME/.zshrc"
        export PATH="$PATH:${GEMINI_BIN_DIR}"
    fi

    log_info "Installing Gemini CLI via npm..."
    if ! npm install -g "$DEFAULT_GEMINI_NPM"; then
        log_error "npm installation failed"
        return 1
    fi

    # Verify installation
    if command -v gemini &> /dev/null; then
        local version=$(gemini --version)
        log_success "Gemini CLI installed successfully! Version: $version"
        log_success "Installation location: $(command -v gemini)"
    else
        log_error "Installation verification failed"
        return 1
    fi

    # Cleanup
    cleanup_installation
}

# Method 2: Docker installation
install_gemini_docker() {
    log_info "Setting up Gemini CLI Docker container..."

    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        read -p "Install Docker now? [y/N]: " install_docker

        if [[ "$install_docker" =~ ^[Yy]$ ]]; then
            install_docker_engine
        else
            log_info "Falling back to npm method"
            install_gemini_npm
            return $?
        fi
    fi

    # Pull Gemini Docker image
    log_info "Pulling Gemini Docker image..."
    if ! docker pull "$DEFAULT_GEMINI_DOCKER"; then
        log_error "Failed to pull Gemini Docker image"
        return 1
    fi

    # Create alias for easy access
    echo "alias gemini='docker run -it --rm $DEFAULT_GEMINI_DOCKER'" >> "$HOME/.bashrc"
    echo "alias gemini='docker run -it --rm $DEFAULT_GEMINI_DOCKER'" >> "$HOME/.zshrc"

    log_success "Gemini Docker setup complete!"
    log_info "Usage: gemini [command]"
    log_info "Or run directly: docker run -it --rm $DEFAULT_GEMINI_DOCKER [command]"
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

# Method 3: Build from source
install_gemini_source() {
    log_info "Building Gemini from source..."

    # Check for build tools
    if ! command -v git &> /dev/null; then
        log_error "Git is required for source installation"
        return 1
    fi

    if ! command -v npm &> /dev/null; then
        log_error "npm is required for source installation"
        return 1
    fi

    # Clone repository
    local repo_url="https://github.com/google/gemini-cli.git"
    local temp_dir=$(mktemp -d)

    log_info "Cloning Gemini repository..."
    if ! git clone "$repo_url" "$temp_dir"; then
        log_error "Failed to clone Gemini repository"
        rm -rf "$temp_dir"
        return 1
    fi

    # Build from source
    log_info "Building Gemini from source..."
    cd "$temp_dir" || return 1

    if ! npm install && npm run build; then
        log_error "Build failed"
        cd - || return 1
        rm -rf "$temp_dir"
        return 1
    fi

    # Install globally
    if ! npm install -g; then
        log_error "Global installation failed"
        cd - || return 1
        rm -rf "$temp_dir"
        return 1
    fi

    # Cleanup
    cd - || return 1
    rm -rf "$temp_dir"

    # Verify installation
    if command -v gemini &> /dev/null; then
        local version=$(gemini --version)
        log_success "Gemini built and installed successfully! Version: $version"
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
    rm -f "${GEMINI_INSTALL_DIR}/gemini.tmp"

    log_success "Cleanup complete"
}

# Configure Gemini
configure_gemini() {
    log_info "Configuring Gemini..."

    # Create config directory
    mkdir -p "$GEMINI_INSTALL_DIR"

    # Create default config if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" <<EOF
{
    "version": "1.0",
    "installation": {
        "method": "npm",
        "date": "$(date)",
        "version": "$(gemini --version 2>/dev/null || echo 'unknown')"
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
    log_info "Verifying Gemini installation..."

    if ! command -v gemini &> /dev/null; then
        log_error "Gemini command not found in PATH"
        return 1
    fi

    local version=$(gemini --version 2>/dev/null)
    if [ -z "$version" ]; then
        log_error "Gemini version check failed"
        return 1
    fi

    log_success "Installation verified successfully"
    log_success "Gemini version: $version"
    log_success "Installation path: $(command -v gemini)"

    # Show basic usage
    echo ""
    echo "Basic Usage:"
    echo "  gemini --help          Show help"
    echo "  gemini --version       Show version"
    echo "  gemini auth login      Authenticate with Google"
    echo "  gemini chat            Start interactive chat"
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
    echo "║        Gemini CLI Installation Script v${SCRIPT_VERSION}              ║"
    echo "║        Robust installation with multiple methods                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Start installation
    install_gemini

    # Post-installation steps
    if [ $? -eq 0 ]; then
        configure_gemini
        verify_installation
        cleanup_installation

        echo -e "${GREEN}"
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║                    Installation Complete!                      ║"
        echo "║                                                                ║"
        echo "║  Gemini CLI has been successfully installed.               ║"
        echo "║  You can now use: gemini [command]                          ║"
        echo "║                                                                ║"
        echo "║  Logs saved to: $LOG_FILE                                  ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
    fi
}

# Execute main function
main "$@"
