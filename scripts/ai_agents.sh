#!/usr/bin/env bash

# Advanced AI Agent System - OpenRouter + Ollama
# Uses OpenRouter for sophisticated tasks, Ollama for simple ones
# Part of bash.d - Advanced AI automation

set -euo pipefail

BASHD_HOME="${BASHD_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-${OPENROUTER_KEY:-}}"
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen3:4b}"
DEFAULT_PROVIDER="${DEFAULT_PROVIDER:-openrouter}"  # or "ollama"

# ============================================
# OpenRouter API
# ============================================

# List available free models on OpenRouter
list_openrouter_models() {
    log_info "Fetching OpenRouter free models..."
    
    if [[ -z "$OPENROUTER_API_KEY" ]]; then
        log_error "OpenRouter API key not set. Set OPENROUTER_API_KEY env var."
        return 1
    fi
    
    curl -s -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "HTTP-Referer: https://bash.d" \
        "https://openrouter.ai/api/v1/models" | \
        jq -r '.data[] | select(.free === true or .context_length_value >= 32000) | "\(.id) | \(.context_length_value // "N/A") ctx | \(.pricing // "free")"' 2>/dev/null | \
        head -20 || echo "Could not fetch models"
}

# Chat with OpenRouter
openrouter_chat() {
    local model="${1:-deepseek/deepseek-chat}"
    local prompt="$2"
    local system_prompt="${3:-You are a helpful assistant.}"
    
    if [[ -z "$OPENROUTER_API_KEY" ]]; then
        log_error "OpenRouter API key not set"
        return 1
    fi
    
    if [[ -z "$prompt" ]]; then
        # Interactive mode
        log_info "Starting interactive chat with $model (Ctrl+C to exit)"
        while true; do
            echo -n -e "${CYAN}You: ${NC}"
            read -r prompt
            [[ -z "$prompt" ]] && continue
            response=$(openrouter_chat "$model" "$prompt" "$system_prompt")
            echo -e "${GREEN}AI:${NC} $response"
            echo ""
        done
        return 0
    fi
    
    # API call
    curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "HTTP-Referer: https://bash.d" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"$system_prompt\"},
                {\"role\": \"user\", \"content\": \"$prompt\"}
            ]
        }" | jq -r '.choices[0].message.content' 2>/dev/null
}

# Generate code with OpenRouter
openrouter_code() {
    local language="${1:-python}"
    local task="$2"
    
    if [[ -z "$task" ]]; then
        echo "Usage: openrouter_code <language> <task>"
        return 1
    fi
    
    local prompt="You are an expert $language programmer. Write clean, efficient, well-commented code for:

Task: $task

Requirements:
- Write in $language
- Include error handling
- Follow best practices
- Add comments

Code:"
    
    openrouter_chat "deepseek/deepseek-chat" "$prompt"
}

# Debug with OpenRouter
openrouter_debug() {
    local error="$1"
    local context="${2:-No additional context}"
    
    local prompt="You are an expert debugger. Analyze this error and provide solutions:

Error: $error
Context: $context

Provide:
1. Root cause
2. Step-by-step fix
3. Prevention tips"

    openrouter_chat "deepseek/deepseek-chat" "$prompt"
}

# Review code with OpenRouter
openrouter_review() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    local content=$(cat "$file")
    
    local prompt="You are a code review expert. Review this code:

\`\`\`
$content
\`\`\`

Provide:
1. Quality assessment
2. Security concerns
3. Performance suggestions
4. Issues found
5. Recommendations"

    openrouter_chat "deepseek/deepseek-chat" "$prompt"
}

# ============================================
# Ollama (for simpler tasks)
# ============================================

# Chat with Ollama
ollama_chat() {
    local model="${1:-$OLLAMA_MODEL}"
    local prompt="$2"
    
    if ! command -v ollama &> /dev/null; then
        log_error "Ollama not installed"
        return 1
    fi
    
    if [[ -z "$prompt" ]]; then
        log_info "Starting interactive chat with $model"
        ollama run "$model"
        return 0
    fi
    
    ollama run "$model" "$prompt"
}

# Generate code with Ollama
ollama_code() {
    local task="$1"
    local language="${2:-bash}"
    local model="${3:-$OLLAMA_MODEL}"
    
    local prompt="You are an expert $language programmer. Write clean, efficient code for:

$task"

    ollama run "$model" "$prompt"
}

# ============================================
# Smart Router - Choose best provider
# ============================================

# Decide which provider to use based on task complexity
smart_chat() {
    local prompt="$1"
    local provider="${2:-$DEFAULT_PROVIDER}"
    
    case "$provider" in
        "openrouter"|"or")
            openrouter_chat "deepseek/deepseek-chat" "$prompt"
            ;;
        "ollama"|"oll")
            ollama_chat "" "$prompt"
            ;;
        "auto")
            # Use OpenRouter for complex tasks, Ollama for simple
            if [[ ${#prompt} -gt 500 ]] || [[ "$prompt" =~ "debug|review|explain|analyze" ]]; then
                log_info "Using OpenRouter (complex task detected)"
                openrouter_chat "deepseek/deepseek-chat" "$prompt"
            else
                log_info "Using Ollama (simple task)"
                ollama_chat "" "$prompt"
            fi
            ;;
        *)
            log_error "Unknown provider: $provider"
            return 1
            ;;
    esac
}

# ============================================
# Agent System
# ============================================

agent_sophisticated() {
    # Use OpenRouter for sophisticated tasks
    local action="$1"
    shift
    
    case "$action" in
        "code")
            openrouter_code "$@"
            ;;
        "debug")
            openrouter_debug "$@"
            ;;
        "review")
            openrouter_review "$@"
            ;;
        "chat")
            openrouter_chat "$@"
            ;;
        "research")
            local topic="$*"
            local prompt="Research: $topic. Provide comprehensive information with sources."
            openrouter_chat "deepseek/deepseek-chat" "$prompt"
            ;;
        *)
            echo "Usage: ai_agents sophisticated {code|debug|review|chat|research}"
            ;;
    esac
}

agent_simple() {
    # Use Ollama for simpler tasks
    local action="$1"
    shift
    
    case "$action" in
        "chat")
            ollama_chat "$@"
            ;;
        "code")
            ollama_code "$@"
            ;;
        "explain")
            ollama run "$OLLAMA_MODEL" "Explain this: $*"
            ;;
        "bash")
            ollama run "$OLLAMA_MODEL" "Find the bash command for: $*"
            ;;
        *)
            echo "Usage: ai_agents simple {chat|code|explain|bash}"
            ;;
    esac
}

# ============================================
# Swarm/Agent Crew System (using Ollama)
# ============================================

# Run multiple agents for complex tasks
agent_swarm() {
    local task="$1"
    
    log_info "Running agent swarm for: $task"
    
    # Break down task and run multiple agents
    echo -e "${CYAN}=== Agent 1: Research ===${NC}"
    local research=$(ollama run "$OLLAMA_MODEL" "Research and outline: $task")
    echo "$research"
    
    echo -e "${CYAN}=== Agent 2: Implementation ===${NC}"
    local implementation=$(ollama run "$OLLAMA_MODEL" "Based on this research: $research. Provide implementation code.")
    echo "$implementation"
    
    echo -e "${CYAN}=== Agent 3: Review ===${NC}"
    local review=$(ollama run "$OLLAMA_MODEL" "Review this implementation: $implementation. Suggest improvements.")
    echo "$review"
    
    log_info "Swarm complete!"
}

# ============================================
# Status
# ============================================

show_status() {
    echo "=========================================="
    echo "  AI Agents Status"
    echo "=========================================="
    echo ""
    
    echo "Default Provider: $DEFAULT_PROVIDER"
    echo ""
    
    echo "OpenRouter:"
    if [[ -n "$OPENROUTER_API_KEY" ]]; then
        echo "  ✓ API Key configured"
        echo "  Free models available:"
        list_openrouter_models | head -5
    else
        echo "  ✗ API Key not set"
        echo "  Set OPENROUTER_API_KEY to enable"
    fi
    
    echo ""
    echo "Ollama:"
    if command -v ollama &> /dev/null; then
        echo "  ✓ Ollama installed"
        ollama list | tail -n +2 | head -5
    else
        echo "  ✗ Ollama not installed"
    fi
}

# ============================================
# Main
# ============================================

main() {
    local command="${1:-status}"
    
    case "$command" in
        "status")
            show_status
            ;;
        "sophisticated"|"or")
            agent_sophisticated "${@:2}"
            ;;
        "simple"|"oll")
            agent_simple "${@:2}"
            ;;
        "chat")
            smart_chat "${2:-}" "${3:-auto}"
            ;;
        "code")
            shift
            local lang="${1:-python}"
            local task="$2"
            if [[ -n "$task" ]]; then
                openrouter_code "$lang" "$task"
            else
                echo "Usage: $0 code <language> <task>"
            fi
            ;;
        "debug")
            shift
            openrouter_debug "$@"
            ;;
        "review")
            openrouter_review "$2"
            ;;
        "swarm")
            agent_swarm "${2:-}"
            ;;
        "models")
            list_openrouter_models
            ;;
        "test")
            # Quick test
            echo "Testing OpenRouter..."
            openrouter_chat "deepseek/deepseek-chat" "Say 'Hello' if you can hear me."
            ;;
        *)
            echo "Usage: $0 {status|sophisticated|simple|chat|code|debug|review|swarm|models|test}"
            echo ""
            echo "Commands:"
            echo "  status        - Show status"
            echo "  sophisticated - Use OpenRouter (complex tasks)"
            echo "  simple       - Use Ollama (simple tasks)"
            echo "  chat         - Auto-select provider"
            echo "  code         - Generate code"
            echo "  debug        - Debug errors"
            echo "  review       - Review code"
            echo "  swarm        - Multi-agent swarm"
            echo "  models       - List OpenRouter models"
            echo "  test         - Test connection"
            ;;
    esac
}

main "$@"
