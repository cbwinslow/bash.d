#!/usr/bin/env bash

# AI Agent System - Run AI tasks using Ollama
# Part of bash.d - Local AI agent automation

set -euo pipefail

BASHD_HOME="${BASHD_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
AGENTS_DIR="$BASHD_HOME/bash_functions.d/ai"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Default model (can be overridden)
DEFAULT_MODEL="${OLLAMA_MODEL:-qwen3:4b}"

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

# ============================================
# Ollama Helpers
# ============================================

# Check if Ollama is running
check_ollama() {
    if ! command -v ollama &> /dev/null; then
        log_error "Ollama not installed. Install from https://ollama.ai"
        return 1
    fi
    
    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        log_warn "Ollama is not running. Starting it..."
        ollama serve &
        sleep 3
    fi
    
    return 0
}

# List available models
list_models() {
    check_ollama || return 1
    ollama list
}

# Pull a model
pull_model() {
    local model="$1"
    log_info "Pulling model: $model"
    ollama pull "$model"
}

# ============================================
# Chat with AI
# ============================================

chat() {
    local model="${1:-$DEFAULT_MODEL}"
    local prompt="$2"
    
    check_ollama || return 1
    
    if [[ -z "$prompt" ]]; then
        # Interactive mode
        log_info "Starting interactive chat with $model (Ctrl+C to exit)"
        ollama run "$model"
    else
        # Single prompt
        ollama run "$model" "$prompt"
    fi
}

# ============================================
# Code Generation Agent
# ============================================

agent_code() {
    local task="$1"
    local language="${2:-bash}"
    local model="${3:-$DEFAULT_MODEL}"
    
    check_ollama || return 1
    
    log_info "Generating $language code for: $task"
    
    local prompt="You are an expert $language programmer. Write clean, efficient, and well-commented code for the following task:

Task: $task

Requirements:
- Write in $language
- Include comments explaining the code
- Handle errors gracefully
- Follow best practices

Code:"

    ollama run "$model" "$prompt"
}

# ============================================
# Script Writing Agent
# ============================================

agent_script() {
    local description="$1"
    local model="${2:-$DEFAULT_MODEL}"
    
    check_ollama || return 1
    
    log_info "Writing script for: $description"
    
    local prompt="You are an expert bash scripting specialist. Write a complete, production-ready bash script for the following task:

Task: $description

Requirements:
- Use 'set -euo pipefail' for strict error handling
- Include proper shebang (#!/usr/bin/env bash)
- Add colors for output (use ANSI color codes)
- Include usage/help function
- Handle arguments with getopts
- Add logging functions
- Include error handling

Write the complete script:"

    ollama run "$model" "$prompt"
}

# ============================================
# Debug Agent
# ============================================

agent_debug() {
    local error="$1"
    local context="${2:-}"
    local model="${3:-$DEFAULT_MODEL}"
    
    check_ollama || return 1
    
    log_info "Analyzing error..."
    
    local prompt="You are an expert debugging assistant. Analyze this error and provide solutions:

Error: $error

Context: ${context:-No additional context provided}

Provide:
1. Root cause analysis
2. Possible solutions
3. Step-by-step fix
4. Prevention tips"

    ollama run "$model" "$prompt"
}

# ============================================
# Explain Code Agent
# ============================================

agent_explain() {
    local code="$1"
    local model="${2:-$DEFAULT_MODEL}"
    
    check_ollama || return 1
    
    local prompt="You are a code documentation expert. Explain this code in detail:

\`\`\`
$code
\`\`\`

Provide:
1. What the code does (summary)
2. Line-by-line explanation
3. Any potential issues or improvements
4. How to use it"

    ollama run "$model" "$prompt"
}

# ============================================
# Research Agent
# ============================================

agent_research() {
    local topic="$1"
    local model="${2:-$DEFAULT_MODEL}"
    
    check_ollama || return 1
    
    log_info "Researching: $topic"
    
    local prompt="You are a research assistant. Provide comprehensive information about:

Topic: $topic

Include:
1. Overview and definition
2. Key concepts
3. Practical applications
4. Common use cases
5. Best practices
6. Resources for further learning"

    ollama run "$model" "$prompt"
}

# ============================================
# Bash Command Agent
# ============================================

agent_bash() {
    local task="$1"
    local model="${2:-$DEFAULT_MODEL}"
    
    check_ollama || return 1
    
    log_info "Finding bash command for: $task"
    
    local prompt="You are a Linux command expert. Provide the exact bash command(s) to accomplish this task:

Task: $task

Provide:
1. The exact command(s)
2. Explanation of each part
3. Example usage
4. Required tools/installations

Command:"

    ollama run "$model" "$prompt"
}

# ============================================
# Review Agent
# ============================================

agent_review() {
    local file="$1"
    local model="${2:-$DEFAULT_MODEL}"
    
    check_ollama || return 1
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    local content=$(cat "$file")
    
    log_info "Reviewing: $file"
    
    local prompt="You are a code review expert. Review this code:

\`\`\`
$content
\`\`\`

Provide:
1. Code quality assessment
2. Security concerns
3. Performance suggestions
4. Best practices compliance
5. Issues found
6. Recommendations"

    ollama run "$model" "$prompt"
}

# ============================================
# Workflow Agent - Multi-step task
# ============================================

agent_workflow() {
    local task="$1"
    local model="${2:-$DEFAULT_MODEL}"
    
    check_ollama || return 1
    
    log_info "Planning workflow for: $task"
    
    local prompt="You are a workflow automation expert. Break down this complex task into individual bash commands that can be executed sequentially:

Task: $task

Provide:
1. Step-by-step plan
2. Each step as a bash command
3. Dependencies between steps
4. Error handling for each step

Format:
Step 1: [description]
Command: [bash command]
..."

    ollama run "$model" "$prompt"
}

# ============================================
# Custom Agent - Run with system prompt
# ============================================

agent_custom() {
    local system_prompt="$1"
    local user_prompt="$2"
    local model="${3:-$DEFAULT_MODEL}"
    
    check_ollama || return 1
    
    ollama run "$model" "$system_prompt

User: $user_prompt

Response:"
}

# ============================================
# Install/Manage Ollama Models
# ============================================

manage_models() {
    local action="${1:-list}"
    
    check_ollama || return 1
    
    case "$action" in
        "list")
            list_models
            ;;
        "pull")
            pull_model "$2"
            ;;
        "remove"|"rm")
            log_info "Removing model: $2"
            ollama rm "$2"
            ;;
        "info")
            ollama show "$2"
            ;;
        "popular")
            log_info "Installing popular models..."
            ollama pull llama3.2:3b
            ollama pull qwen3:4b
            ollama pull deepseek-r1:7b
            ollama pull dolphin3:latest
            log_info "Popular models installed"
            ;;
        *)
            echo "Usage: $0 models {list|pull|remove|info|popular}"
            ;;
    esac
}

# ============================================
# Show status
# ============================================

show_status() {
    echo "=========================================="
    echo "  AI Agent System Status"
    echo "=========================================="
    echo ""
    
    if check_ollama; then
        echo "Ollama: ✓ Running"
        echo ""
        echo "Available Models:"
        ollama list | tail -n +2
    else
        echo "Ollama: ✗ Not available"
    fi
    
    echo ""
    echo "Default Model: $DEFAULT_MODEL"
}

# ============================================
# Main
# ============================================

main() {
    local command="${1:-status}"
    
    case "$command" in
        "chat")
            chat "$2" "$3"
            ;;
        "code")
            agent_code "$2" "$3" "$4"
            ;;
        "script")
            agent_script "$2" "$3"
            ;;
        "debug")
            agent_debug "$2" "$3" "$4"
            ;;
        "explain")
            agent_explain "$2" "$3"
            ;;
        "research")
            agent_research "$2" "$3"
            ;;
        "bash")
            agent_bash "$2" "$3"
            ;;
        "review")
            agent_review "$2" "$3"
            ;;
        "workflow")
            agent_workflow "$2" "$3"
            ;;
        "custom")
            agent_custom "$2" "$3" "$4"
            ;;
        "models"|"model")
            manage_models "$2" "$3"
            ;;
        "status"|"")
            show_status
            ;;
        *)
            echo "Usage: $0 {chat|code|script|debug|explain|research|bash|review|workflow|custom|models|status}"
            echo ""
            echo "Commands:"
            echo "  chat [model] [prompt]     - Chat with AI (interactive if no prompt)"
            echo "  code <task> [lang] [model] - Generate code"
            echo "  script <desc> [model]     - Write bash script"
            echo "  debug <error> [context]  - Debug an error"
            echo "  explain <code> [model]   - Explain code"
            echo "  research <topic> [model]  - Research a topic"
            echo "  bash <task> [model]      - Find bash command"
            echo "  review <file> [model]    - Review code"
            echo "  workflow <task> [model]  - Plan workflow"
            echo "  custom <system> <user>   - Custom prompt"
            echo "  models [action]          - Manage models"
            echo "  status                   - Show status"
            echo ""
            echo "Examples:"
            echo "  $0 chat qwen3:4b 'Hello'"
            echo "  $0 code 'create a REST API' python"
            echo "  $0 debug 'permission denied' 'trying to write to /tmp'"
            echo "  $0 bash 'find files modified today'"
            echo "  $0 models popular"
            exit 1
            ;;
    esac
}

main "$@"
