#!/bin/bash
#===============================================================================
#
#          FILE:  connection_manager.sh
#
#         USAGE:  ssh_monitor [start|stop|status]
#                 github_connect [check|fix]
#                 gitlab_connect [check|fix]
#                 connection_help
#
#   DESCRIPTION:  Advanced SSH and connection management for GitHub/GitLab
#                 with automatic monitoring, troubleshooting, and reconnect
#
#       OPTIONS:  start/stop/status - Control connection monitoring
#                 check/fix - Check connection status and fix issues
#  REQUIREMENTS:  ssh, curl, ping, dig
#         NOTES:  Uses background processes for continuous monitoring
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Configuration
CONNECTION_LOG="${HOME}/.cache/bashd_connection.log"
CONNECTION_PID="${HOME}/.cache/bashd_connection.pid"
mkdir -p "$(dirname "$CONNECTION_LOG")"

# SSH connection monitor - runs in background
ssh_monitor() {
    local action="${1:-start}"

    case "$action" in
        start)
            _ssh_monitor_start
            ;;
        stop)
            _ssh_monitor_stop
            ;;
        status)
            _ssh_monitor_status
            ;;
        *)
            echo "Usage: ssh_monitor [start|stop|status]"
            return 1
            ;;
    esac
}

# Start SSH monitoring
_ssh_monitor_start() {
    if [[ -f "$CONNECTION_PID" && -d "/proc/$(cat "$CONNECTION_PID")" ]]; then
        echo "SSH monitor is already running (PID: $(cat "$CONNECTION_PID"))"
        return 0
    fi

    echo "Starting SSH connection monitor..."
    echo "Monitor started at $(date)" >> "$CONNECTION_LOG"

    # Start background process
    (
        while true; do
            _ssh_monitor_check
            sleep 60
        done
    ) > /dev/null 2>&1 &

    echo $! > "$CONNECTION_PID"
    echo "SSH monitor started (PID: $!)"

    # Add to cleanup
    trap "_ssh_monitor_stop" EXIT
}

# Stop SSH monitoring
_ssh_monitor_stop() {
    if [[ -f "$CONNECTION_PID" && -d "/proc/$(cat "$CONNECTION_PID")" ]]; then
        echo "Stopping SSH monitor (PID: $(cat "$CONNECTION_PID"))"
        kill "$(cat "$CONNECTION_PID")" 2>/dev/null
        rm -f "$CONNECTION_PID"
        echo "SSH monitor stopped"
    else
        echo "SSH monitor is not running"
    fi
}

# Check SSH monitor status
_ssh_monitor_status() {
    if [[ -f "$CONNECTION_PID" && -d "/proc/$(cat "$CONNECTION_PID")" ]]; then
        echo "SSH monitor is running (PID: $(cat "$CONNECTION_PID"))"
        echo "Log: $CONNECTION_LOG"
        tail -5 "$CONNECTION_LOG" 2>/dev/null || echo "No log entries yet"
    else
        echo "SSH monitor is not running"
    fi
}

# SSH monitoring check function
_ssh_monitor_check() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Check SSH agent
    if ! ssh-add -l >/dev/null 2>&1; then
        echo "[$timestamp] SSH agent not running - starting..." >> "$CONNECTION_LOG"
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add ~/.ssh/id_rsa 2>/dev/null || ssh-add ~/.ssh/id_ed25519 2>/dev/null
        echo "[$timestamp] SSH agent started and keys added" >> "$CONNECTION_LOG"
    fi

    # Test GitHub connection
    if ! _test_github_connection >/dev/null 2>&1; then
        echo "[$timestamp] GitHub connection issue detected - attempting fix..." >> "$CONNECTION_LOG"
        github_connect fix >> "$CONNECTION_LOG" 2>&1
    fi

    # Test GitLab connection
    if ! _test_gitlab_connection >/dev/null 2>&1; then
        echo "[$timestamp] GitLab connection issue detected - attempting fix..." >> "$CONNECTION_LOG"
        gitlab_connect fix >> "$CONNECTION_LOG" 2>&1
    fi

    echo "[$timestamp] Connection check completed" >> "$CONNECTION_LOG"
}

# GitHub connection management
github_connect() {
    local action="${1:-check}"

    case "$action" in
        check)
            _test_github_connection
            ;;
        fix)
            _fix_github_connection
            ;;
        *)
            echo "Usage: github_connect [check|fix]"
            return 1
            ;;
    esac
}

# Test GitHub connection
_test_github_connection() {
    echo "Testing GitHub connection..."

    # Test SSH connection
    if timeout 10 ssh -T git@github.com 2>/dev/null; then
        echo "✓ GitHub SSH connection: OK"
        return 0
    else
        echo "✗ GitHub SSH connection: FAILED"
    fi

    # Test HTTPS connection
    if curl -sI https://github.com >/dev/null 2>&1; then
        echo "✓ GitHub HTTPS connection: OK"
        return 0
    else
        echo "✗ GitHub HTTPS connection: FAILED"
    fi

    return 1
}

# Fix GitHub connection issues
_fix_github_connection() {
    echo "Attempting to fix GitHub connection..."

    # Check SSH keys
    if [[ ! -f ~/.ssh/id_rsa && ! -f ~/.ssh/id_ed25519 ]]; then
        echo "No SSH keys found. Generating new key..."
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "$(whoami)@$(hostname)"
    fi

    # Ensure SSH agent is running
    if ! ssh-add -l >/dev/null 2>&1; then
        echo "Starting SSH agent..."
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add ~/.ssh/id_rsa 2>/dev/null || ssh-add ~/.ssh/id_ed25519 2>/dev/null
    fi

    # Test connection again
    if _test_github_connection; then
        echo "✓ GitHub connection fixed!"
        return 0
    else
        echo "✗ Could not fix GitHub connection automatically"
        echo "Manual steps:"
        echo "  1. Check your internet connection"
        echo "  2. Verify GitHub SSH keys are added to your account"
        echo "  3. Check firewall/proxy settings"
        echo "  4. Run: ssh -T git@github.com"
        return 1
    fi
}

# GitLab connection management
gitlab_connect() {
    local action="${1:-check}"

    case "$action" in
        check)
            _test_gitlab_connection
            ;;
        fix)
            _fix_gitlab_connection
            ;;
        *)
            echo "Usage: gitlab_connect [check|fix]"
            return 1
            ;;
    esac
}

# Test GitLab connection
_test_gitlab_connection() {
    echo "Testing GitLab connection..."

    # Test SSH connection
    if timeout 10 ssh -T git@gitlab.com 2>/dev/null; then
        echo "✓ GitLab SSH connection: OK"
        return 0
    else
        echo "✗ GitLab SSH connection: FAILED"
    fi

    # Test HTTPS connection
    if curl -sI https://gitlab.com >/dev/null 2>&1; then
        echo "✓ GitLab HTTPS connection: OK"
        return 0
    else
        echo "✗ GitLab HTTPS connection: FAILED"
    fi

    return 1
}

# Fix GitLab connection issues
_fix_gitlab_connection() {
    echo "Attempting to fix GitLab connection..."

    # Check SSH keys
    if [[ ! -f ~/.ssh/id_rsa && ! -f ~/.ssh/id_ed25519 ]]; then
        echo "No SSH keys found. Generating new key..."
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "$(whoami)@$(hostname)"
    fi

    # Ensure SSH agent is running
    if ! ssh-add -l >/dev/null 2>&1; then
        echo "Starting SSH agent..."
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add ~/.ssh/id_rsa 2>/dev/null || ssh-add ~/.ssh/id_ed25519 2>/dev/null
    fi

    # Test connection again
    if _test_gitlab_connection; then
        echo "✓ GitLab connection fixed!"
        return 0
    else
        echo "✗ Could not fix GitLab connection automatically"
        echo "Manual steps:"
        echo "  1. Check your internet connection"
        echo "  2. Verify GitLab SSH keys are added to your account"
        echo "  3. Check firewall/proxy settings"
        echo "  4. Run: ssh -T git@gitlab.com"
        return 1
    fi
}

# Connection troubleshooting
connection_troubleshoot() {
    echo "Running comprehensive connection troubleshooting..."
    echo ""

    # Network diagnostics
    echo "=== Network Diagnostics ==="
    echo "Public IP: $(curl -s ifconfig.me 2>/dev/null || echo "unknown")"
    echo "DNS Resolution: $(dig +short github.com 2>/dev/null | head -1 || echo "failed")"
    echo ""

    # SSH diagnostics
    echo "=== SSH Diagnostics ==="
    echo "SSH Agent: $(ssh-add -l 2>/dev/null | wc -l || echo "not running") keys loaded"
    echo "SSH Config: $(ls ~/.ssh/config 2>/dev/null && echo "exists" || echo "missing")"
    echo ""

    # Git diagnostics
    echo "=== Git Diagnostics ==="
    echo "Git Version: $(git --version 2>/dev/null || echo "not installed")"
    echo "Git Config: $(git config --global user.name 2>/dev/null || echo "not configured")"
    echo ""

    # Connection tests
    echo "=== Connection Tests ==="
    echo "GitHub SSH: $(timeout 5 ssh -T git@github.com 2>/dev/null && echo "OK" || echo "FAILED")"
    echo "GitLab SSH: $(timeout 5 ssh -T git@gitlab.com 2>/dev/null && echo "OK" || echo "FAILED")"
    echo "GitHub HTTPS: $(curl -sI https://github.com >/dev/null 2>&1 && echo "OK" || echo "FAILED")"
    echo "GitLab HTTPS: $(curl -sI https://gitlab.com >/dev/null 2>&1 && echo "OK" || echo "FAILED")"
}

# Connection help
connection_help() {
    cat << 'EOF'
Connection Management Commands:

  ssh_monitor [start|stop|status]  - Monitor SSH connections in background
  github_connect [check|fix]        - Test and fix GitHub connections
  gitlab_connect [check|fix]        - Test and fix GitLab connections
  connection_troubleshoot          - Run comprehensive troubleshooting
  connection_help                  - Show this help message

Examples:
  ssh_monitor start                # Start background monitoring
  github_connect check             # Test GitHub connection
  gitlab_connect fix               # Fix GitLab connection issues
  connection_troubleshoot         # Run full diagnostics
EOF
}

# Export functions
export -f ssh_monitor 2>/dev/null
export -f _ssh_monitor_start 2>/dev/null
export -f _ssh_monitor_stop 2>/dev/null
export -f _ssh_monitor_status 2>/dev/null
export -f _ssh_monitor_check 2>/dev/null
export -f github_connect 2>/dev/null
export -f _test_github_connection 2>/dev/null
export -f _fix_github_connection 2>/dev/null
export -f gitlab_connect 2>/dev/null
export -f _test_gitlab_connection 2>/dev/null
export -f _fix_gitlab_connection 2>/dev/null
export -f connection_troubleshoot 2>/dev/null
export -f connection_help 2>/dev/null
