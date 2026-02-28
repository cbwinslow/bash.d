#!/bin/bash
# AI Debug & Test Agent
# Specializes in debugging, testing, and providing feedback

set -euo pipefail

BASHD_DIR="$HOME/bash.d"
OLLAMA_MODEL="qwen3:4b"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}=== 🤖 AI Debug & Test Agent ===${NC}"
echo "Model: $OLLAMA_MODEL"
echo ""

# Collect system state for debugging
collect_debug_info() {
    cat << 'EOF'
You are debugging and testing a bash.d system. Current state:

=== RECENT ERROR LOGS ===
EOF
    tail -50 /tmp/system_monitor.log 2>/dev/null || echo "No logs found"
    
    cat << 'EOF'

=== DOCKER CONTAINERS ===
EOF
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    
    cat << 'EOF'

=== MEMORY STATE ===
EOF
    free -h
    
    cat << 'EOF'

=== FAILED SERVICES ===
EOF
    systemctl --failed 2>/dev/null | head -20 || echo "systemd not available"
}

# Run smoke tests and collect output
run_smoke_tests() {
    echo -e "${YELLOW}Running smoke tests...${NC}"
    python3 "$BASHD_DIR/tests/test_framework.py" 2>&1 || true
}

# Analyze a specific error
analyze_error() {
    local error="$1"
    
    prompt="Analyze this error and provide:
1. Root cause
2. Fix suggestions (specific commands)
3. Prevention tips

Error: $error"
    
    echo -e "${CYAN}Analyzing error...${NC}"
    echo "$prompt" | ollama run $OLLAMA_MODEL "$prompt" 2>/dev/null
}

# Debug a script
debug_script() {
    local script="$1"
    
    if [ ! -f "$script" ]; then
        echo -e "${RED}Script not found: $script${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Debugging script: $script${NC}"
    echo ""
    
    # Get script content
    content=$(cat "$script")
    
    prompt="Debug this bash script. Look for:
1. Syntax errors
2. Logic bugs
3. Race conditions
4. Missing error handling
5. Security issues

Script:
$content

Provide specific fixes with line numbers."
    
    echo "$prompt" | ollama run $OLLAMA_MODEL "$prompt" 2>/dev/null
}

# Run end-to-end test
e2e_test() {
    local test_name="$1"
    
    echo -e "${CYAN}Running E2E test: $test_name${NC}"
    
    # Test inventory
    if [ "$test_name" = "inventory" ] || [ "$test_name" = "all" ]; then
        echo -e "\n${YELLOW}Testing inventory...${NC}"
        if bash "$BASHD_DIR/scripts/inventory.sh" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Inventory works${NC}"
        else
            echo -e "${RED}✗ Inventory failed${NC}"
        fi
    fi
    
    # Test backup
    if [ "$test_name" = "backup" ] || [ "$test_name" = "all" ]; then
        echo -e "\n${YELLOW}Testing backup...${NC}"
        if bash "$BASHD_DIR/scripts/backup.sh quick" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Backup works${NC}"
        else
            echo -e "${RED}✗ Backup failed${NC}"
        fi
    fi
    
    # Test analyzer
    if [ "$test_name" = "analyzer" ] || [ "$test_name" = "all" ]; then
        echo -e "\n${YELLOW}Testing system analyzer...${NC}"
        if bash "$BASHD_DIR/scripts/system_analyzer.sh" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ System analyzer works${NC}"
        else
            echo -e "${RED}✗ System analyzer failed${NC}"
        fi
    fi
    
    # Test Docker services
    if [ "$test_name" = "docker" ] || [ "$test_name" = "all" ]; then
        echo -e "\n${YELLOW}Testing Docker services...${NC}"
        containers=("telemetry-postgres" "epstein-redis" "epstein-chroma" "epstein-neo4j")
        for c in "${containers[@]}"; do
            if docker ps --format '{{.Names}}' | grep -q "^${c}$"; then
                echo -e "${GREEN}✓ $c running${NC}"
            else
                echo -e "${RED}✗ $c not running${NC}"
            fi
        done
    fi
}

# Provide feedback on the system
give_feedback() {
    echo -e "${CYAN}Collecting system feedback...${NC}"
    
    debug_info=$(collect_debug_info)
    
    prompt="Analyze this bash.d system and provide feedback on:
1. Overall health score (0-100)
2. What's working well
3. What needs attention
4. Recommendations for improvements
5. Any potential issues

System state:
$debug_info

Provide a detailed report with actionable items."
    
    echo "$prompt" | ollama run $OLLAMA_MODEL "$prompt" 2>/dev/null
}

# Main command handler
case "${1:-}" in
    analyze)
        collect_debug_info | ollama run $OLLAMA_MODEL "Analyze this debug info and provide recommendations"
        ;;
    debug)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 debug <script_path>"
            exit 1
        fi
        debug_script "$2"
        ;;
    error)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 error '<error_message>'"
            exit 1
        fi
        analyze_error "$2"
        ;;
    test)
        e2e_test "${2:-all}"
        ;;
    smoke)
        run_smoke_tests
        ;;
    feedback)
        give_feedback
        ;;
    *)
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  analyze              - Analyze current system state"
        echo "  debug <script>       - Debug a specific script"
        echo "  error '<message>'    - Analyze an error message"
        echo "  test [name]          - Run E2E tests (inventory, backup, analyzer, docker, all)"
        echo "  smoke                - Run smoke tests"
        echo "  feedback             - Get AI feedback on system health"
        echo ""
        echo "Examples:"
        echo "  $0 analyze"
        echo "  $0 debug ~/bash.d/scripts/my_script.sh"
        echo "  $0 error 'connection refused'"
        echo "  $0 test all"
        echo "  $0 feedback"
esac
