#!/usr/bin/env bash

# Core System Functions for bash.d
# Provides main system functionality, logging, and utilities

set -euo pipefail

# Strict settings for security
set -o errexit
set -o pipefail
set -o nounset

# Debug mode if requested
[[ -n "${DEBUG:-}" ]] && set -x

# Global variables (not readonly to allow modification)
BASHD_VERSION="1.0.0"
BASHD_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHD_CONFIG_DIR="$HOME/.bash.d"
BASHD_LOG_FILE="$BASHD_CONFIG_DIR/bashd.log"
BASHD_PLUGINS_DIR="$BASHD_HOME/plugins"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $timestamp - $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $timestamp - $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $timestamp - $message" ;;
        "DEBUG") [[ -n "${DEBUG:-}" ]] && echo -e "${BLUE}[DEBUG]${NC} $timestamp - $message" ;;
    esac
    
    # Log to file
    echo "[$level] $timestamp - $message" >> "$BASHD_LOG_FILE"
}

# Error handling function
error_exit() {
    local exit_code="${1:-1}"
    local error_message="$2"
    local line_number="${3:-${BASH_LINENO:-}}"
    
    log "ERROR" "$error_message at line $line_number"
    exit "$exit_code"
}

# Success message
success() {
    local message="$1"
    log "INFO" "✅ $message"
}

# Warning message
warning() {
    local message="$1"
    log "WARN" "⚠️  $message"
}

# Error message
error() {
    local message="$1"
    log "ERROR" "❌ $message"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if file exists and is readable
file_exists() {
    [[ -f "$1" && -r "$1" ]]
}

# Check if directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir_path="$1"
    if [[ ! -d "$dir_path" ]]; then
        mkdir -p "$dir_path"
        log "DEBUG" "Created directory: $dir_path"
    fi
}

# Load configuration
load_config() {
    local config_file="${1:-$BASHD_CONFIG_DIR/config.yaml}"
    
    if file_exists "$config_file"; then
        log "DEBUG" "Loading configuration from: $config_file"
        # Simple YAML parsing for basic values
        while IFS='=' read -r key value; do
            case "$key" in
                default_email) export BASHD_EMAIL="$value" ;;
                default_domain) export BASHD_DOMAIN="$value" ;;
                bitwarden_server) export BASHD_BITWARDEN_SERVER="$value" ;;
                cloudflare_account_id) export BASHD_CLOUDFLARE_ACCOUNT_ID="$value" ;;
                oracle_region) export BASHD_ORACLE_REGION="$value" ;;
            esac
        done < <(grep -E '^(default_email|default_domain|bitwarden_server|cloudflare_account_id|oracle_region):' "$config_file" 2>/dev/null || true)
    else
        log "WARN" "Configuration file not found: $config_file"
    fi
}

# Load plugin
load_plugin() {
    local plugin_name="$1"
    local plugin_file="$BASHD_PLUGINS_DIR/${plugin_name}.sh"
    
    if file_exists "$plugin_file"; then
        log "DEBUG" "Loading plugin: $plugin_name"
        source "$plugin_file"
        
        # Initialize plugin if it has a function
        if command_exists "plugin_init"; then
            plugin_init
        fi
    else
        log "WARN" "Plugin not found: $plugin_name"
        return 1
    fi
}

# Load all plugins
load_all_plugins() {
    log "INFO" "Loading all plugins..."
    
    # Load core plugins first
    for plugin in bitwarden cloudflare government ai_tools; do
        load_plugin "$plugin"
    done
    
    log "INFO" "All plugins loaded"
}

# Validate dependencies
validate_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    for cmd in bash curl jq; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Report missing dependencies
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing_deps[*]}"
        error "Please install missing dependencies and try again"
        return 1
    fi
    
    success "All dependencies satisfied"
}

# System information
system_info() {
    echo "bash.d System Information:"
    echo "  Version: $BASHD_VERSION"
    echo "  Home Directory: $BASHD_HOME"
    echo "  Config Directory: $BASHD_CONFIG_DIR"
    echo "  Log File: $BASHD_LOG_FILE"
    echo "  Shell: $BASH_VERSION"
    echo "  OS: $(uname -s) $(uname -r)"
    echo "  Architecture: $(uname -m)"
    echo ""
    
    # Plugin status
    echo "Loaded Plugins:"
    for plugin_file in "$BASHD_PLUGINS_DIR"/*.sh; do
        if [[ -f "$plugin_file" ]]; then
            local plugin_name=$(basename "$plugin_file" .sh)
            echo "  - $plugin_name"
        fi
    done
}

# Cleanup function
cleanup() {
    log "INFO" "Cleaning up bash.d..."
    
    # Call cleanup on all loaded plugins
    for plugin_file in "$BASHD_PLUGINS_DIR"/*.sh; do
        if [[ -f "$plugin_file" ]]; then
            source "$plugin_file"
            if command_exists "plugin_cleanup"; then
                plugin_cleanup
            fi
        fi
    done
    
    success "bash.d cleanup completed"
}

# Health check
health_check() {
    log "INFO" "Performing health check..."
    
    local issues=0
    
    # Check directories
    if ! dir_exists "$BASHD_CONFIG_DIR"; then
        error "Config directory missing"
        ((issues++))
    fi
    
    if ! dir_exists "$BASHD_PLUGINS_DIR"; then
        error "Plugins directory missing"
        ((issues++))
    fi
    
    # Check log file writability
    if ! touch "$BASHD_LOG_FILE" 2>/dev/null; then
        error "Log file not writable"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        success "Health check passed"
    else
        error "Health check failed with $issues issues"
        return 1
    fi
    
    # Log audit
    local audit_entry="Health audit completed: $issues issues found"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [AUDIT] $audit_entry" >> "$BASHD_CONFIG_DIR/security.log"
}

# Export functions for use in other scripts
export -f log
export -f error_exit
export -f success
export -f warning
export -f error
export -f command_exists
export -f file_exists
export -f dir_exists
export -f ensure_dir
export -f load_config
export -f load_plugin
export -f load_all_plugins
export -f validate_dependencies
export -f system_info
export -f cleanup
export -f health_check

# Constants (export for use in other scripts)
export BASHD_VERSION
export BASHD_HOME
export BASHD_CONFIG_DIR
export BASHD_LOG_FILE
export BASHD_PLUGINS_DIR