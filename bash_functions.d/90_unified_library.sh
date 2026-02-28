#!/bin/bash
#===============================================================================
#
#          FILE:  90_unified_library.sh
#
#         USAGE:  Source this file to get all bash.d functions
#
#   DESCRIPTION:  Unified function library for bash.d - wraps all tools
#                 with consistent naming conventions
#
#  CONVENTIONS:
#    - bfd_     = bash.d function (core functions)
#    - sys_     = system utilities
#    - net_     = network utilities
#    - dev_     = development tools
#    - ai_      = AI agent functions
#    - backup_  = backup functions
#    - inv_     = inventory functions
#    - db_      = database functions
#    - mon_     = monitoring functions
#    - api_     = API utility functions
#    - docker_  = Docker utilities
#    - git_     = Git utilities
#
#       VERSION:  1.0.0
#===============================================================================

# Colors
export BFD_COLOR_RED='\033[0;31m'
export BFD_COLOR_GREEN='\033[0;32m'
export BFD_COLOR_YELLOW='\033[1;33m'
export BFD_COLOR_BLUE='\033[0;34m'
export BFD_COLOR_CYAN='\033[0;36m'
export BFD_COLOR_RESET='\033[0m'
export BFD_COLOR_BOLD='\033[1m'

# BASHD directories
export BFD_HOME="${BASH_D_REPO:-$HOME/bash.d}"
export BFD_SCRIPTS="$BFD_HOME/scripts"
export BFD_APIS="$BFD_HOME/apis"
export BFD_TELEMETRY="$BFD_HOME/telemetry"
export BFD_INVENTORY="$BFD_HOME/inventory"
export BFD_CONFIG="$BFD_HOME/config"

#===============================================================================
# CORE FUNCTIONS
#===============================================================================

# Show bash.d status
bfd_status() {
    echo -e "${BFD_COLOR_CYAN}═══════════════════════════════════════════════════════════${BFD_COLOR_RESET}"
    echo -e "${BFD_COLOR_BOLD}  bash.d - Unified Function Library${BFD_COLOR_RESET}"
    echo -e "${BFD_COLOR_CYAN}═══════════════════════════════════════════════════════════${BFD_COLOR_RESET}"
    echo ""
    echo "Home:     $BFD_HOME"
    echo "Scripts:  $BFD_SCRIPTS"
    echo "APIs:     $BFD_APIS"
    echo "Telemetry:$BFD_TELEMETRY"
    echo ""
    echo "Quick Commands:"
    echo "  bfd_help              - Show this help"
    echo "  bfd_search <term>    - Search functions"
    echo "  bfd_list             - List all functions"
    echo ""
}

# List all available functions
bfd_list() {
    echo -e "${BFD_COLOR_CYAN}Available bash.d Functions:${BFD_COLOR_RESET}"
    echo ""
    
    # Show function categories
    declare -F | grep "^declare -f bfd_\|^declare -f sys_\|^declare -f net_\|^declare -f dev_\|^declare -f ai_\|^declare -f backup_\|^declare -f inv_\|^declare -f db_\|^declare -f mon_\|^declare -f api_" | \
        sed 's/declare -f //' | sort
}

# Search functions
bfd_search() {
    local term="$1"
    if [[ -z "$term" ]]; then
        echo "Usage: bfd_search <search_term>"
        return 1
    fi
    
    echo -e "${BFD_COLOR_CYAN}Searching for: $term${BFD_COLOR_RESET}"
    echo ""
    
    # Search in this file
    grep -n "$term" "${BASH_SOURCE[0]}" | head -20
}

# Show help for a specific function
bfd_help() {
    local func="$1"
    
    if [[ -z "$func" ]]; then
        bfd_status
        echo "Function Categories:"
        echo "  bfd_*    - Core bash.d functions"
        echo "  sys_*   - System utilities"
        echo "  net_*   - Network utilities"
        echo "  dev_*   - Development tools"
        echo "  ai_*    - AI agent functions"
        echo "  backup_* - Backup functions"
        echo "  inv_*   - Inventory functions"
        echo "  db_*    - Database functions"
        echo "  mon_*   - Monitoring functions"
        echo "  api_*   - API utilities"
        echo ""
        echo "Examples:"
        echo "  bfd_help bfd_status    - Help for bfd_status"
        echo "  bfd_help ai_chat      - Help for AI chat"
        echo "  bfd_help backup_full  - Help for backup"
        return 0
    fi
    
    # Try to get help from function docstring
    local func_name="bfd_${func#bfd_}"
    if declare -f "$func_name" > /dev/null 2>&1; then
        echo -e "${BFD_COLOR_GREEN}$func_name${BFD_COLOR_RESET}"
        echo "Documentation:"
        # Extract first block comment
        local file=$(declare -f "$func_name" | head -20)
        echo "$file"
    else
        echo "Function not found: $func"
    fi
}

#===============================================================================
# INVENTORY FUNCTIONS (inv_*)
#===============================================================================

# Run full inventory
inv_run() {
    "$BFD_SCRIPTS/inventory.sh" all
}

# Run specific inventory type
inv_packages() {
    "$BFD_SCRIPTS/inventory.sh" packages
}

inv_repos() {
    "$BFD_SCRIPTS/inventory.sh" repos
}

inv_scripts() {
    "$BFD_SCRIPTS/inventory.sh" scripts
}

inv_system() {
    "$BFD_SCRIPTS/inventory.sh" system
}

inv_docker() {
    "$BFD_SCRIPTS/inventory.sh" docker
}

# Show inventory status
inv_status() {
    echo -e "${BFD_COLOR_CYAN}Inventory Status:${BFD_COLOR_RESET}"
    ls -lh "$BFD_INVENTORY"/*".txt" 2>/dev/null | head -10 || echo "No inventory files found"
}

#===============================================================================
# BACKUP FUNCTIONS (backup_*)
#===============================================================================

# Run full backup
backup_full() {
    "$BFD_SCRIPTS/backup.sh" full
}

# Run quick backup
backup_quick() {
    "$BFD_SCRIPTS/backup.sh" quick
}

# Show backup status
backup_status() {
    "$BFD_SCRIPTS/backup.sh" status
}

# Restore from backup
backup_restore() {
    local backup_file="$1"
    if [[ -z "$backup_file" ]]; then
        echo "Usage: backup_restore <backup_file>"
        return 1
    fi
    "$BFD_SCRIPTS/backup.sh" restore "$backup_file"
}

#===============================================================================
# AI AGENT FUNCTIONS (ai_*)
#===============================================================================

# Chat with AI (Ollama)
ai_chat() {
    "$BFD_SCRIPTS/ai_agent.sh" chat "$@"
}

# Generate code
ai_code() {
    "$BFD_SCRIPTS/ai_agent.sh" code "$@"
}

# Debug an error
ai_debug() {
    "$BFD_SCRIPTS/ai_agent.sh" debug "$@"
}

# Review code
ai_review() {
    "$BFD_SCRIPTS/ai_agent.sh" review "$@"
}

# Write a script
ai_script() {
    "$BFD_SCRIPTS/ai_agent.sh" script "$@"
}

# Find bash command
ai_bash() {
    "$BFD_SCRIPTS/ai_agent.sh" bash "$@"
}

# Research a topic
ai_research() {
    "$BFD_SCRIPTS/ai_agent.sh" research "$@"
}

# AI status
ai_status() {
    "$BFD_SCRIPTS/ai_agent.sh" status
}

# List available models
ai_models() {
    "$BFD_SCRIPTS/ai_agent.sh" models list
}

# Pull a model
ai_pull() {
    "$BFD_SCRIPTS/ai_agent.sh" models pull "$@"
}

#===============================================================================
# API FUNCTIONS (api_*)
#===============================================================================

# API status
api_status() {
    "$BFD_APIS/api_manager.sh" status
}

# GitHub API
api_github() {
    "$BFD_APIS/api_manager.sh" github "$@"
}

# Cloudflare API
api_cf() {
    "$BFD_APIS/api_manager.sh" cloudflare "$@"
}

# Test APIs
api_test() {
    "$BFD_APIS/api_manager.sh" test
}

#===============================================================================
# CONVERSATION LOGGER FUNCTIONS (chatlog_*)
#===============================================================================

# Start new conversation log
chatlog_new() {
    "$BFD_SCRIPTS/conversation_logger.sh" new "$@"
}

# Upload conversations
chatlog_upload() {
    "$BFD_SCRIPTS/conversation_logger.sh" upload
}

# List conversations
chatlog_list() {
    "$BFD_SCRIPTS/conversation_logger.sh" list
}

# Chatlog status
chatlog_status() {
    "$BFD_SCRIPTS/conversation_logger.sh" status
}

#===============================================================================
# TELEMETRY FUNCTIONS (mon_*)
#===============================================================================

# Start telemetry collector
mon_start() {
    if [[ -d "$BFD_TELEMETRY" ]]; then
        python -m telemetry.collector "$@"
    else
        echo "Telemetry not installed. Run: cd $BFD_TELEMETRY && pip install -r requirements.txt"
    fi
}

# Start dashboard
mon_dashboard() {
    if [[ -d "$BFD_TELEMETRY" ]]; then
        python -m telemetry.dashboard "$@"
    else
        echo "Telemetry not installed. Run: cd $BFD_TELEMETRY && pip install -r requirements.txt"
    fi
}

# Initialize database
mon_db_init() {
    if [[ -d "$BFD_TELEMETRY" ]]; then
        python -m telemetry.db
    else
        echo "Telemetry not installed."
    fi
}

#===============================================================================
# SYSTEM FUNCTIONS (sys_*)
#===============================================================================

# Quick system info
sys_info() {
    echo -e "${BFD_COLOR_CYAN}System Information:${BFD_COLOR_RESET}"
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s) $(uname -r)"
    echo "Arch: $(uname -m)"
    echo "Shell: $SHELL"
    echo "Bash: $BASH_VERSION"
    echo ""
    echo "Uptime: $(uptime -p)"
    echo "Date: $(date)"
}

# Disk usage
sys_disk() {
    df -h | grep -v tmpfs | head -10
}

# Memory usage
sys_mem() {
    free -h
}

# CPU usage
sys_cpu() {
    top -bn1 | head -15
}

# List largest files
sys_largest() {
    find . -type f -exec du -h {} + 2>/dev/null | sort -rh | head -15
}

#===============================================================================
# NETWORK FUNCTIONS (net_*)
#===============================================================================

# Check internet
net_check() {
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${BFD_COLOR_GREEN}✓ Internet connected${BFD_COLOR_RESET}"
    else
        echo -e "${BFD_COLOR_RED}✗ No internet${BFD_COLOR_RESET}"
    fi
}

# My IP addresses
net_myip() {
    echo "External: $(curl -s ifconfig.me 2>/dev/null || echo 'N/A')"
    echo "Internal: $(hostname -I 2>/dev/null | awk '{print $1}')"
}

# DNS lookup
net_dns() {
    local domain="${1:-google.com}"
    dig +short "$domain"
}

# Port scan
net_ports() {
    local host="${1:-localhost}"
    local start="${2:-1}"
    local end="${3:-1024}"
    
    for port in $(seq $start $end); do
        timeout 0.1 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null && \
            echo "Port $port is open"
    done
}

#===============================================================================
# DEVELOPMENT FUNCTIONS (dev_*)
#===============================================================================

# Quick git status
dev_git_status() {
    git status --short
}

# Git add all and commit
dev_git_commit() {
    local msg="${1:-Update}"
    git add -A
    git commit -m "$msg"
}

# Git push
dev_git_push() {
    git push
}

# Create backup of file
dev_backup() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "Usage: dev_backup <filepath>"
        return 1
    fi
    cp "$file" "$file.backup.$(date +%Y%m%d)"
}

# Find in files
dev_grep() {
    local term="$1"
    local dir="${2:-.}"
    grep -rn "$term" "$dir" --include="*.sh" --include="*.py" --include="*.js" 2>/dev/null | head -30
}

#===============================================================================
# DOCKER FUNCTIONS (docker_*)
#===============================================================================

# Docker ps
docker_ps() {
    docker ps -a
}

# Docker logs follow
docker_logs() {
    local container="$1"
    docker logs -f "$container"
}

# Docker cleanup
docker_clean() {
    echo "Cleaning up Docker..."
    docker container prune -f
    docker image prune -f
    docker volume prune -f
    echo "Done!"
}

# Docker stats
docker_stats() {
    docker stats --no-stream
}

#===============================================================================
# EXPORT ALL FUNCTIONS
#===============================================================================

# Make functions available
export -f bfd_status 2>/dev/null
export -f bfd_list 2>/dev/null
export -f bfd_search 2>/dev/null
export -f bfd_help 2>/dev/null

export -f inv_run 2>/dev/null
export -f inv_packages 2>/dev/null
export -f inv_repos 2>/dev/null
export -f inv_scripts 2>/dev/null
export -f inv_system 2>/dev/null
export -f inv_status 2>/dev/null

export -f backup_full 2>/dev/null
export -f backup_quick 2>/dev/null
export -f backup_status 2>/dev/null

export -f ai_chat 2>/dev/null
export -f ai_code 2>/dev/null
export -f ai_debug 2>/dev/null
export -f ai_review 2>/dev/null
export -f ai_script 2>/dev/null
export -f ai_status 2>/dev/null

export -f api_status 2>/dev/null
export -f api_github 2>/dev/null
export -f api_cf 2>/dev/null

export -f chatlog_new 2>/dev/null
export -f chatlog_upload 2>/dev/null
export -f chatlog_list 2>/dev/null

export -f mon_start 2>/dev/null
export -f mon_dashboard 2>/dev/null

export -f sys_info 2>/dev/null
export -f sys_disk 2>/dev/null
export -f sys_mem 2>/dev/null

export -f net_check 2>/dev/null
export -f net_myip 2>/dev/null

export -f dev_git_status 2>/dev/null
export -f dev_git_commit 2>/dev/null
export -f dev_backup 2>/dev/null

export -f docker_ps 2>/dev/null
export -f docker_logs 2>/dev/null
export -f docker_clean 2>/dev/null

# Aliases
alias bfd='bfd_status'
alias inv='inv_run'
alias backup='backup_full'
alias ai='ai_chat'
alias apis='api_status'
alias log='chatlog_new'
alias mon='mon_dashboard'
