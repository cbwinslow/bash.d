#!/bin/bash
# AI System Agent - Analyzes system and can take actions

set -euo pipefail

# Configuration
BASHD_DIR="$HOME/bash.d"
OLLAMA_MODEL="qwen3:4b"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== AI System Agent ===${NC}"
echo "Using model: $OLLAMA_MODEL"
echo ""

# Collect system data
collect_system_info() {
    cat << 'EOF'
You are analyzing a Linux system. Here is the current state:

=== MEMORY ===
EOF
    free -h
    
    cat << 'EOF'

=== TOP MEMORY PROCESSES ===
EOF
    ps aux --sort=-%mem | head -10
    
    cat << 'EOF'

=== TOP CPU PROCESSES ===
EOF
    ps aux --sort=-%cpu | head -10
    
    cat << 'EOF'

=== DOCKER PROCESSES ===
EOF
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null || echo "Docker not available"
    
    cat << 'EOF'

=== LOAD AVERAGE ===
EOF
    uptime
    
    cat << 'EOF'

=== DISK USAGE ===
EOF
    df -h | grep -E "^/dev|Filesystem"
}

# Main analysis prompt
get_analysis_prompt() {
    cat << 'EOF'
Based on the system information above, analyze and provide:
1. What's causing high memory usage (if any)?
2. Are there processes that should be killed?
3. Recommendations to improve performance
4. Should any docker containers be stopped?

Be specific with PIDs and commands. Format your response with clear sections.
EOF
}

# Ask user what they want to do
if [ "${1:-}" = "analyze" ]; then
    echo "Collecting system information..."
    system_info=$(collect_system_info)
    prompt=$(get_analysis_prompt)
    
    echo -e "${YELLOW}Sending to AI for analysis...${NC}"
    echo "$system_info" | ollama run $OLLAMA_MODEL "$prompt" 2>/dev/null
    
elif [ "${1:-}" = "kill" ]; then
    # Interactive process killing
    echo "Which process PID to kill? (or 'list' to see processes)"
    read -r pid
    
    if [ "$pid" = "list" ]; then
        ps aux --sort=-%mem | head -15
    elif [ -n "$pid" ]; then
        echo "Killing PID $pid..."
        kill "$pid" 2>/dev/null && echo "Process killed" || echo "Failed to kill process"
    fi

elif [ "${1:-}" = "recommend" ]; then
    # Get AI recommendations
    system_info=$(collect_system_info)
    
    prompt="Based on this system info, recommend specific commands to free up memory and improve performance. Only respond with bash commands, one per line, no explanations:"
    
    echo -e "${YELLOW}Getting AI recommendations...${NC}"
    recommendations=$(echo "$system_info" | ollama run $OLLAMA_MODEL "$prompt" 2>/dev/null)
    
    echo -e "${GREEN}AI Recommendations:${NC}"
    echo "$recommendations"
    
    echo -e "\n${YELLOW}Execute these recommendations? (yes/no)${NC}"
    read -r confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "$recommendations" | while read -r cmd; do
            if [ -n "$cmd" ]; then
                echo "Running: $cmd"
                eval "$cmd" 2>/dev/null || echo "Failed: $cmd"
            fi
        done
    fi

else
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  analyze    - Analyze system with AI"
    echo "  recommend  - Get AI recommendations and optionally execute"
    echo "  kill       - Kill a process (interactive)"
    echo ""
    echo "Examples:"
    echo "  $0 analyze"
    echo "  $0 recommend"
    echo "  $0 kill"
fi
