#!/usr/bin/env bash

# Bitwarden Integration Plugin for bash.d
# Handles credential management, MCP server setup, and secure access

set -euo pipefail

# Plugin metadata
readonly PLUGIN_NAME="bitwarden"
readonly PLUGIN_VERSION="1.0.0"
readonly PLUGIN_DEPENDENCIES="curl,jq,bw"

# Bitwarden configuration
readonly BITWARDEN_SERVER="https://bitwarden.com"
readonly BITWARDEN_EMAIL="blaine.winslow@gmail.com"
readonly BITWARDEN_MASTERPASS="CBW89pass"

# Initialize Bitwarden plugin
plugin_init() {
    echo "Initializing Bitwarden plugin..."
    
    # Check if Bitwarden CLI is installed
    if ! command -v bw &> /dev/null; then
        echo "Installing Bitwarden CLI..."
        install_bitwarden
    fi
    
    # Login if not already authenticated
    if ! check_bitwarden_auth; then
        echo "Authenticating with Bitwarden..."
        authenticate_bitwarden
    fi
    
    # Setup MCP server
    setup_mcp_server
    
    echo "Bitwarden plugin initialized successfully"
}

# Check Bitwarden authentication status
check_bitwarden_auth() {
    local status=$(bw status 2>/dev/null || echo "not_logged_in")
    [[ "$status" != "not_logged_in" ]]
}

# Authenticate with Bitwarden
authenticate_bitwarden() {
    echo "Logging into Bitwarden..."
    echo "$BITWARDEN_MASTERPASS" | bw login --raw "$BITWARDEN_EMAIL"
    
    if check_bitwarden_auth; then
        echo "Successfully authenticated with Bitwarden"
        # Get session token for MCP server
        export BW_SESSION=$(bw unlock --raw "$BITWARDEN_MASTERPASS")
    else
        echo "Failed to authenticate with Bitwarden"
        return 1
    fi
}

# Install Bitwarden CLI
install_bitwarden() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) echo "Unsupported architecture: $arch"; return 1 ;;
    esac
    
    # Download and install Bitwarden CLI
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    echo "Downloading Bitwarden CLI for $os-$arch..."
    curl -L "https://vault.bitwarden.com/download/?app=cli&platform=$os" -o bw.zip
    unzip bw.zip
    chmod +x bw
    sudo mv bw /usr/local/bin/
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
    
    echo "Bitwarden CLI installed successfully"
}

# Setup MCP server for Bitwarden
setup_mcp_server() {
    echo "Setting up Bitwarden MCP server..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Install Bitwarden MCP server
    echo "Installing Bitwarden MCP server..."
    npm install -g @bitwarden/mcp-server
    
    # Create MCP configuration
    local mcp_config_dir="$HOME/.config/claude"
    mkdir -p "$mcp_config_dir"
    
    cat > "$mcp_config_dir/claude_desktop_config.json" << EOF
{
  "mcpServers": {
    "bitwarden": {
      "command": "npx",
      "args": ["-y", "@bitwarden/mcp-server"],
      "env": {
        "BW_SESSION": "\${BW_SESSION}"
      }
    }
  }
}
EOF
    
    echo "MCP server configured for Bitwarden"
}

# Get credential from Bitwarden
get_credential() {
    local item_name="$1"
    local field="${2:-password}"
    
    if ! check_bitwarden_auth; then
        echo "Not authenticated with Bitwarden"
        return 1
    fi
    
    echo "Retrieving credential: $item_name"
    bw get item "$item_name" --raw | jq -r ".${field}"
}

# List all credentials
list_credentials() {
    local pattern="${1:-}"
    
    if ! check_bitwarden_auth; then
        echo "Not authenticated with Bitwarden"
        return 1
    fi
    
    if [[ -n "$pattern" ]]; then
        bw list items --search "$pattern" --raw | jq -r '.[] | "\(.name): \(.login.username)"'
    else
        bw list items --raw | jq -r '.[] | "\(.name): \(.login.username)"'
    fi
}

# Generate secure password
generate_password() {
    local length="${1:-16}"
    local symbols="${2:-true}"
    
    bw generate --uppercase --lowercase --numbers --symbols --length "$length"
}

# Check plugin status
plugin_status() {
    echo "Bitwarden Plugin Status:"
    echo "  Version: $PLUGIN_VERSION"
    echo "  Dependencies: $PLUGIN_DEPENDENCIES"
    
    if command -v bw &> /dev/null; then
        echo "  Bitwarden CLI: Installed"
        if check_bitwarden_auth; then
            echo "  Authentication: Logged in"
        else
            echo "  Authentication: Not logged in"
        fi
    else
        echo "  Bitwarden CLI: Not installed"
    fi
    
    if command -v node &> /dev/null; then
        echo "  Node.js: Installed"
    else
        echo "  Node.js: Not installed"
    fi
}

# Configure plugin
plugin_config() {
    echo "Bitwarden Plugin Configuration:"
    echo "  Server: $BITWARDEN_SERVER"
    echo "  Email: $BITWARDEN_EMAIL"
    echo "  Master Password: [REDACTED]"
    echo ""
    echo "To reconfigure:"
    echo "  1. bw logout"
    echo "  2. bashd plugins bitwarden init"
}

# Cleanup plugin resources
plugin_cleanup() {
    echo "Cleaning up Bitwarden plugin..."
    
    # Logout from Bitwarden
    if check_bitwarden_auth; then
        bw logout
        echo "Logged out from Bitwarden"
    fi
    
    # Clear session
    unset BW_SESSION
    
    echo "Bitwarden plugin cleaned up"
}

# Main function for direct calls
case "${1:-}" in
    "init") plugin_init ;;
    "status") plugin_status ;;
    "config") plugin_config ;;
    "cleanup") plugin_cleanup ;;
    "get") get_credential "$2" "$3" ;;
    "list") list_credentials "$2" ;;
    "generate") generate_password "$2" "$3" ;;
    *) echo "Usage: bitwarden_plugin.sh {init|status|config|cleanup|get|list|generate}" ;;
esac