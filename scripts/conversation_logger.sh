#!/usr/bin/env bash

# Conversation Logger - Save AI terminal conversations
# Part of bash.d - Logs and stores AI tool conversations

set -euo pipefail

BASHD_HOME="${BASHD_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONVERSATION_LOGS_DIR="$BASHD_HOME/conversation-logs"
UPLOAD_REPO="${UPLOAD_REPO:-cbwinslow/conversations}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_DIR=$(date +%Y/%m)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Ensure directories exist
mkdir -p "$CONVERSATION_LOGS_DIR/$DATE_DIR"

# ============================================
# Configuration
# ============================================

load_config() {
    export CONVERSATION_GITHUB_TOKEN="${CONVERSATION_GITHUB_TOKEN:-}"
    export CONVERSATION_AUTO_UPLOAD="${CONVERSATION_AUTO_UPLOAD:-false}"
    export CONVERSATION_MAX_LOCAL_DAYS="${CONVERSATION_MAX_LOCAL_DAYS:-30}"
}

# ============================================
# Detect current AI tool
# ============================================

detect_ai_tool() {
    local tool="unknown"
    
    # Check environment variables first
    if [[ -n "${CLAUDE_ID:-}" ]] || [[ -n "${CLAUDE_API_KEY:-}" ]]; then
        tool="claude"
    elif [[ -n "${OPENAI_API_KEY:-}" ]]; then
        tool="openai"
    elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        tool="anthropic"
    elif [[ -n "${OLLAMA_HOST:-}" ]]; then
        tool="ollama"
    fi
    
    # Check process tree for common AI tools
    if ps aux | grep -qi "[c]line"; then
        tool="cline"
    elif ps aux | grep -qi "[c]laude"; then
        tool="claude"
    elif ps aux | grep -qi "[w]indsurf"; then
        tool="windsurf"
    elif ps aux | grep -qi "[c]ursor"; then
        tool="cursor"
    fi
    
    echo "$tool"
}

# ============================================
# Log current conversation
# ============================================

log_conversation() {
    local tool="${1:-$(detect_ai_tool)}"
    local session_id="${2:-$TIMESTAMP}"
    local title="${3:-Conversation $TIMESTAMP}"
    
    local log_file="$CONVERSATION_LOGS_DIR/$DATE_DIR/${tool}_${session_id}.md"
    
    # Create log entry
    cat > "$log_file" << EOF
---
title: "$title"
date: "$(date -Iseconds)"
tool: "$tool"
session_id: "$session_id"
hostname: "$(hostname)"
---

# $title

**Tool:** $tool  
**Date:** $(date)  
**Session:** $session_id  
**Host:** $(hostname)

---

## Conversation Log

EOF
    
    # If there's a terminal recording or logs, capture them
    if [[ -n "${TMUX:-}" ]]; then
        echo "Session: TMUX" >> "$log_file"
    fi
    
    if [[ -n "${ITERM_SESSION_ID:-}" ]]; then
        echo "Session: iTerm2" >> "$log_file"
    fi
    
    log_info "Created conversation log: $log_file"
    echo "$log_file"
}

# ============================================
# Append to conversation
# ============================================

append_to_conversation() {
    local log_file="$1"
    local content="$2"
    
    if [[ ! -f "$log_file" ]]; then
        log_error "Log file not found: $log_file"
        return 1
    fi
    
    echo -e "\n$content" >> "$log_file"
}

# ============================================
# Add system prompt to log
# ============================================

log_system_prompt() {
    local log_file="$1"
    local prompt="$2"
    
    if [[ ! -f "$log_file" ]]; then
        log_error "Log file not found: $log_file"
        return 1
    fi
    
    cat >> "$log_file" << EOF

### System Prompt

\`\`\`
$prompt
\`\`\`

---
EOF
}

# ============================================
# Add user message to log
# ============================================

log_user_message() {
    local log_file="$1"
    local message="$2"
    
    if [[ ! -f "$log_file" ]]; then
        log_error "Log file not found: $log_file"
        return 1
    fi
    
    cat >> "$log_file" << EOF

### User

$message

EOF
}

# ============================================
# Add AI response to log
# ============================================

log_ai_response() {
    local log_file="$1"
    local response="$2"
    
    if [[ ! -f "$log_file" ]]; then
        log_error "Log file not found: $log_file"
        return 1
    fi
    
    cat >> "$log_file" << EOF

### AI Response

$response

EOF
}

# ============================================
# Upload to GitHub
# ============================================

upload_to_github() {
    local file="$1"
    local destination="${2:-}"
    
    if [[ -z "$CONVERSATION_GITHUB_TOKEN" ]]; then
        log_warn "GitHub token not set. Skipping upload."
        return 1
    fi
    
    if [[ -z "$destination" ]]; then
        destination="conversations/$(basename "$file")"
    fi
    
    log_info "Uploading to GitHub..."
    
    # Check if file exists
    local exists=$(curl -s -H "Authorization: token $CONVERSATION_GITHUB_TOKEN" \
        "https://api.github.com/repos/$UPLOAD_REPO/contents/$destination" | \
        jq -r '.sha // empty' 2>/dev/null || echo "")
    
    local data
    if [[ -n "$exists" ]]; then
        data=$(jq -n \
            --arg msg "Update conversation log" \
            --arg content "$(base64 -w0 "$file")" \
            --arg sha "$exists" \
            '{message: $msg, content: $content, sha: $sha}')
    else
        data=$(jq -n \
            --arg msg "Upload conversation log" \
            --arg content "$(base64 -w0 "$file")" \
            '{message: $msg, content: $content}')
    fi
    
    local response=$(curl -s -X PUT \
        -H "Authorization: token $CONVERSATION_GITHUB_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "https://api.github.com/repos/$UPLOAD_REPO/contents/$destination")
    
    if echo "$response" | jq -e '.content' > /dev/null 2>&1; then
        log_info "  ✓ Uploaded: $destination"
        return 0
    else
        log_error "Upload failed: $(echo "$response" | jq -r '.message // "Unknown error"')"
        return 1
    fi
}

# ============================================
# Upload all pending conversations
# ============================================

upload_pending() {
    if [[ -z "$CONVERSATION_GITHUB_TOKEN" ]]; then
        log_warn "GitHub token not set. Set CONVERSATION_GITHUB_TOKEN to enable upload."
        return 1
    fi
    
    log_info "Uploading pending conversations..."
    
    local count=0
    for file in "$CONVERSATION_LOGS_DIR"/**/*.md; do
        [[ -f "$file" ]] || continue
        
        local dest="conversations/${file#$CONVERSATION_LOGS_DIR/}"
        if upload_to_github "$file" "$dest"; then
            ((count++))
        fi
    done
    
    log_info "Uploaded $count conversation(s)"
}

# ============================================
# Clean old local logs
# ============================================

cleanup_old_logs() {
    log_info "Cleaning up old conversation logs (older than $CONVERSATION_MAX_LOCAL_DAYS days)..."
    
    find "$CONVERSATION_LOGS_DIR" -name "*.md" -mtime "+$CONVERSATION_MAX_LOCAL_DAYS" -delete 2>/dev/null || true
    
    # Also clean empty directories
    find "$CONVERSATION_LOGS_DIR" -type d -empty -delete 2>/dev/null || true
    
    log_info "Cleanup complete"
}

# ============================================
# List conversations
# ============================================

list_conversations() {
    log_info "Local Conversations"
    echo "======================"
    echo ""
    
    local total=0
    for file in "$CONVERSATION_LOGS_DIR"/**/*.md; do
        [[ -f "$file" ]] || continue
        
        local title=$(grep -m1 "^title:" "$file" 2>/dev/null | cut -d'"' -f2 || basename "$file")
        local date=$(grep -m1 "^date:" "$file" 2>/dev/null | cut -d'"' -f2 || "unknown")
        local tool=$(grep -m1 "^tool:" "$file" 2>/dev/null | cut -d'"' -f2 || "unknown")
        
        echo "  $tool | $date | $title"
        ((total++))
    done
    
    echo ""
    echo "Total: $total conversation(s)"
}

# ============================================
# Show status
# ============================================

show_status() {
    log_info "Conversation Logger Status"
    echo "============================"
    echo ""
    echo "Log Directory: $CONVERSATION_LOGS_DIR"
    echo "Upload Repo: $UPLOAD_REPO"
    echo "Auto Upload: $CONVERSATION_AUTO_UPLOAD"
    echo "Max Local Days: $CONVERSATION_MAX_LOCAL_DAYS"
    echo "GitHub Token: ${CONVERSATION_GITHUB_TOKEN:+set} ${CONVERSATION_GITHUB_TOKEN:+***}"
    echo ""
    
    list_conversations
}

# ============================================
# Quick start a new conversation
# ============================================

new_conversation() {
    local tool="${1:-$(detect_ai_tool)}"
    local title="${2:-New Conversation}"
    
    log_conversation "$tool" "$TIMESTAMP" "$title"
}

# ============================================
# Main
# ============================================

main() {
    load_config
    
    local command="${1:-status}"
    
    case "$command" in
        "new")
            new_conversation "${2:-}" "${3:-}"
            ;;
        "log")
            shift
            log_conversation "$@"
            ;;
        "append")
            append_to_conversation "${2:-}" "${3:-}"
            ;;
        "upload")
            upload_pending
            ;;
        "cleanup")
            cleanup_old_logs
            ;;
        "list")
            list_conversations
            ;;
        "status")
            show_status
            ;;
        *)
            echo "Usage: $0 {new|log|append|upload|cleanup|list|status}"
            echo ""
            echo "Commands:"
            echo "  new [tool] [title] - Start new conversation"
            echo "  log [tool] [session] [title] - Create log file"
            echo "  append <file> <content> - Append to conversation"
            echo "  upload                 - Upload all pending to GitHub"
            echo "  cleanup                - Remove old local logs"
            echo "  list                   - List local conversations"
            echo "  status                 - Show status"
            exit 1
            ;;
    esac
}

main "$@"
