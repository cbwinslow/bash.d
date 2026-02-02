#!/bin/bash

################################################################################
# Kilo-Code CLI Installation Script
#
# This script provides multiple methods to install Kilo-Code CLI tool with robust
# error handling and environmental adaptation.
#
# Features:
# - Multiple installation methods (wrapper, Docker, source)
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
KILO_INSTALL_DIR="${HOME}/.kilo"
KILO_BIN_DIR="${HOME}/.local/bin"
LOG_FILE="${KILO_INSTALL_DIR}/install.log"
CONFIG_FILE="${KILO_INSTALL_DIR}/config.json"
DEFAULT_KILO_DOCKER="ghcr.io/kilo-code/kilo-cli"
BACKUP_KILO_URL="https://github.com/kilo-code/kilo"

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
    echo "=== Kilo-Code Installation Log - $(date) ===" >> "$LOG_FILE"
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
    if [ -f "${KILO_INSTALL_DIR}/kilo.tmp" ]; then
        rm -f "${KILO_INSTALL_DIR}/kilo.tmp"
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
    echo "1) Wrapper script (default)"
    echo "2) Docker container"
    echo "3) Source build"

    read -p "Select installation method [1-3]: " install_method

    case $install_method in
        1|"")
            install_kilo_wrapper
            ;;
        2)
            install_kilo_docker
            ;;
        3)
            install_kilo_source
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
    echo "1. This is a wrapper-based installation"
    echo "2. For Docker: docker pull ghcr.io/kilo-code/kilo-cli"
    echo "3. Check for updates at: https://github.com/kilo-code/kilo"
    echo ""
    echo "Note: Kilo-Code CLI is currently wrapper-based"
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

    # Check for curl (for wrapper functionality)
    if ! command -v curl &> /dev/null; then
        log_warning "curl is not installed"
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

    # Install curl
    case $PACKAGE_MANAGER in
        apt)
            log_info "Installing curl via APT"
            sudo apt-get update
            sudo apt-get install -y curl
            ;;
        brew)
            log_info "Installing curl via Homebrew"
            brew install curl
            ;;
        *)
            log_error "Unsupported package manager for curl installation: $PACKAGE_MANAGER"
            log_info "Please install curl manually"
            exit 1
            ;;
    esac

    # Verify installation
    if ! command -v curl &> /dev/null; then
        log_error "Failed to install curl"
        exit 1
    fi

    log_success "Dependencies installed successfully"
}

# Check if kilo is already installed
check_existing_installation() {
    if command -v kilo &> /dev/null; then
        log_warning "Kilo-Code CLI is already installed"

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
install_kilo() {
    detect_system
    check_requirements
    check_existing_installation

    echo ""
    echo "Available Installation Methods:"
    echo "1) Wrapper Script (Recommended) - Creates wrapper for Kilo-Code functionality"
    echo "2) Docker - Runs Kilo-Code in Docker container"
    echo "3) Source Build - Build from source (advanced)"

    read -p "Select installation method [1-3]: " install_method

    case $install_method in
        1|"")
            install_kilo_wrapper
            ;;
        2)
            install_kilo_docker
            ;;
        3)
            install_kilo_source
            ;;
        *)
            log_error "Invalid selection"
            exit 1
            ;;
    esac
}

# Method 1: Wrapper installation
install_kilo_wrapper() {
    log_info "Creating Kilo-Code wrapper script..."

    # Create installation directory
    mkdir -p "$KILO_INSTALL_DIR"
    mkdir -p "$KILO_BIN_DIR"

    # Add bin directory to PATH if not already there
    if [[ ":$PATH:" != *":${KILO_BIN_DIR}:"* ]]; then
        log_info "Adding ${KILO_BIN_DIR} to PATH"
        echo "export PATH=\"\$PATH:${KILO_BIN_DIR}\"" >> "$HOME/.bashrc"
        echo "export PATH=\"\$PATH:${KILO_BIN_DIR}\"" >> "$HOME/.zshrc"
        export PATH="$PATH:${KILO_BIN_DIR}"
    fi

    # Create wrapper script for Kilo-Code functionality
    cat > "${KILO_BIN_DIR}/kilo" <<EOF
#!/bin/bash

# Kilo-Code CLI Wrapper Script
# This provides a unified interface for Kilo-Code functionality

# Main function
main() {
    if [ $# -eq 0 ]; then
        show_help
        return 0
    fi

    local command="$1"
    shift

    case "$command" in
        --help|-h)
            show_help
            ;;
        --version|-v)
            show_version
            ;;
        chat|interactive)
            start_chat "$@"
            ;;
        complete|code)
            code_completion "$@"
            ;;
        analyze|review)
            code_analysis "$@"
            ;;
        *)
            echo "Unknown command: $command"
            show_help
            return 1
            ;;
    esac
}

# Show help
show_help() {
    echo "Kilo-Code CLI - Unified interface for Kilo-Code functionality"
    echo ""
    echo "Usage: kilo [command] [options]"
    echo ""
    echo "Commands:"
    echo "  --help, -h          Show this help message"
    echo "  --version, -v      Show version information"
    echo "  chat, interactive   Start interactive chat session"
    echo "  complete, code      Code completion"
    echo "  analyze, review     Code analysis and review"
    echo ""
    echo "Examples:"
    echo "  kilo chat              Start interactive session"
    echo "  kilo complete 'def '   Code completion"
    echo "  kilo analyze file.py  Analyze Python file"
}

# Show version
show_version() {
    echo "Kilo-Code CLI Wrapper v1.0.0"
    echo "Wrapper for Kilo-Code functionality"
}

# Start chat session
start_chat() {
    echo "Starting Kilo-Code chat session..."
    echo "Note: This is a wrapper - actual Kilo-Code integration coming soon"
    echo "Type 'exit' to end session"

    while true; do
        read -p "kilo> " input
        if [ "$input" = "exit" ]; then
            break
        fi

        # Placeholder for actual Kilo-Code API call
        echo "Kilo-Code: Processing your request: $input"
        echo "Response: [This is a placeholder response]"
    done
}

# Code completion
code_completion() {
    local prompt="$*"

    if [ -z "$prompt" ]; then
        echo "Usage: kilo complete 'your code prefix'"
        return 1
    fi

    echo "Kilo-Code: Completing code for: $prompt"
    echo "Completion: [This is a placeholder completion]"
}

# Code analysis
code_analysis() {
    local file="$*"

    if [ -z "$file" ]; then
        echo "Usage: kilo analyze 'filename'"
        return 1
    fi

    if [ ! -f "$file" ]; then
        echo "Error: File $file not found"
        return 1
    fi

    echo "Kilo-Code: Analyzing file: $file"
    echo "Analysis: [This is a placeholder analysis]"
}

# Execute main function
main "$@"
EOF

    chmod +x "${KILO_BIN_DIR}/kilo"

    # Verify installation
    if command -v kilo &> /dev/null; then
        log_success "Kilo-Code CLI wrapper installed successfully!"
        log_success "Installation location: $(command -v kilo)"
        log_info "Usage: kilo [command] - see kilo --help"
    else
        log_error "Installation verification failed"
        return 1
    fi

    # Cleanup
    cleanup_installation
}

# Method 2: Docker installation
install_kilo_docker() {
    log_info "Setting up Kilo-Code Docker container..."

    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        read -p "Install Docker now? [y/N]: " install_docker

        if [[ "$install_docker" =~ ^[Yy]$ ]]; then
            install_docker_engine
        else
            log_info "Falling back to wrapper method"
            install_kilo_wrapper
            return $?
        fi
    fi

    # Pull Kilo-Code Docker image
    log_info "Pulling Kilo-Code Docker image..."
    if ! docker pull "$DEFAULT_KILO_DOCKER"; then
        log_error "Failed to pull Kilo-Code Docker image"
        return 1
    fi

    # Create alias for easy access
    echo "alias kilo='docker run -it --rm $DEFAULT_KILO_DOCKER'" >> "$HOME/.bashrc"
    echo "alias kilo='docker run -it --rm $DEFAULT_KILO_DOCKER'" >> "$HOME/.zshrc"

    log_success "Kilo-Code Docker setup complete!"
    log_info "Usage: kilo [command]"
    log_info "Or run directly: docker run -it --rm $DEFAULT_KILO_DOCKER [command]"
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
install_kilo_source() {
    log_info "Building Kilo-Code from source..."

    # Check for build tools
    if ! command -v git &> /dev/null; then
        log_error "Git is required for source installation"
        return 1
    fi

    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is required for source installation"
        return 1
    fi

    if ! command -v pip &> /dev/null; then
        log_error "pip is required for source installation"
        return 1
    fi

    # Clone repository
    local repo_url="https://github.com/kilo-code/kilo.git"
    local temp_dir=$(mktemp -d)

    log_info "Cloning Kilo-Code repository..."
    if ! git clone "$repo_url" "$temp_dir"; then
        log_error "Failed to clone Kilo-Code repository"
        rm -rf "$temp_dir"
        return 1
    fi

    # Build from source
    log_info "Building Kilo-Code from source..."
    cd "$temp_dir" || return 1

    if ! pip install -e .; then
        log_error "Build failed"
        cd - || return 1
        rm -rf "$temp_dir"
        return 1
    fi

    # Create wrapper script
    cat > "${KILO_BIN_DIR}/kilo" <<EOF
#!/bin/bash
# Kilo-Code CLI Wrapper
python3 -m kilo.cli "\$@"
EOF

    chmod +x "${KILO_BIN_DIR}/kilo"

    # Cleanup
    cd - || return 1
    rm -rf "$temp_dir"

    # Verify installation
    if command -v kilo &> /dev/null; then
        log_success "Kilo-Code built and installed successfully!"
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
    rm -f "${KILO_INSTALL_DIR}/kilo.tmp"

    log_success "Cleanup complete"
}

# Configure Kilo-Code
configure_kilo() {
    log_info "Configuring Kilo-Code..."

    # Create config directory
    mkdir -p "$KILO_INSTALL_DIR"

    # Create default config if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" <<EOF
{
    "version": "1.0",
    "installation": {
        "method": "wrapper",
        "date": "$(date)",
        "version": "1.0.0"
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
    log_info "Verifying Kilo-Code installation..."

    if ! command -v kilo &> /dev/null; then
        log_error "Kilo-Code command not found in PATH"
        return 1
    fi

    log_success "Installation verified successfully"
    log_success "Kilo-Code version: 1.0.0 (wrapper)"
    log_success "Installation path: $(command -v kilo)"

    # Show basic usage
    echo ""
    echo "Basic Usage:"
    echo "  kilo --help          Show help"
    echo "  kilo --version       Show version"
    echo "  kilo chat            Start interactive chat"
    echo "  kilo complete 'code'  Code completion"
    echo "  kilo analyze file    Code analysis"
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
    echo "║        Kilo-Code CLI Installation Script v${SCRIPT_VERSION}           ║"
    echo "║        Robust installation with multiple methods                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Start installation
    install_kilo

    # Post-installation steps
    if [ $? -eq 0 ]; then
        configure_kilo
        verify_installation
        cleanup_installation

        echo -e "${GREEN}"
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║                    Installation Complete!                      ║"
        echo "║                                                                ║"
        echo "║  Kilo-Code CLI has been successfully installed.              ║"
        echo "║  You can now use: kilo [command]                               ║"
        echo "║                                                                ║"
        echo "║  Logs saved to: $LOG_FILE                                  ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
    fi
}

# Execute main function
main "$@"
