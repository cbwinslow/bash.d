#!/usr/bin/env bash
# Shell Configuration Debug and Performance Analysis Tool

set -euo pipefail

# Configuration
DEBUG_MODE=${SHELL_DEBUG:-false}
LOG_FILE="/tmp/shell_debug_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="/tmp/shell_performance_report_$(date +%Y%m%d_%H%M%S).json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Debug logging function
debug_log() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" | tee -a "$LOG_FILE"
    fi
}

# Performance timing function
time_shell_operation() {
    local shell="$1"
    local operation="$2"
    local description="$3"
    
    debug_log "Timing $description with $shell"
    
    # Use high-resolution timing
    local start_ns=$(date +%s%N)
    local output
    local exit_code
    
    if output=$(eval "$shell -c '$operation'" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    local end_ns=$(date +%s%N)
    local duration_ms=$(((end_ns - start_ns) / 1000000))
    
    echo "{\"shell\":\"$shell\",\"operation\":\"$description\",\"duration_ms\":$duration_ms,\"exit_code\":$exit_code,\"output\":\"$(echo "$output" | head -c 200 | tr '\n' ' ')\"}"
    
    debug_log "$description completed in ${duration_ms}ms with exit code $exit_code"
    
    return $exit_code
}

# Test shell syntax
test_syntax() {
    local shell="$1"
    local config_file="$2"
    
    debug_log "Testing $shell syntax for $config_file"
    
    case "$shell" in
        bash)
            time_shell_operation "bash" "bash -n '$config_file'" "syntax_check"
            ;;
        zsh)
            time_shell_operation "zsh" "zsh -n '$config_file'" "syntax_check"
            ;;
    esac
}

# Test shell loading
test_loading() {
    local shell="$1"
    local config_file="$2"
    
    debug_log "Testing $shell loading for $config_file"
    
    time_shell_operation "$shell" "source '$config_file' && echo 'LOADED'" "config_loading"
}

# Test interactive shell startup
test_interactive() {
    local shell="$1"
    
    debug_log "Testing $shell interactive startup"
    
    case "$shell" in
        bash)
            timeout 10 bash -c "bash -i -c 'echo INTERACTIVE_SUCCESS'" >/dev/null 2>&1
            local exit_code=$?
            echo "{\"shell\":\"$shell\",\"operation\":\"interactive_startup\",\"duration_ms\":0,\"exit_code\":$exit_code,\"output\":\"interactive_test\"}"
            ;;
        zsh)
            timeout 10 zsh -c "zsh -i -c 'echo INTERACTIVE_SUCCESS'" >/dev/null 2>&1
            local exit_code=$?
            echo "{\"shell\":\"$shell\",\"operation\":\"interactive_startup\",\"duration_ms\":0,\"exit_code\":$exit_code,\"output\":\"interactive_test\"}"
            ;;
    esac
}

# Test completion system
test_completions() {
    local shell="$1"
    
    debug_log "Testing $shell completion system"
    
    case "$shell" in
        bash)
            time_shell_operation "bash" "source ~/.bashrc && complete -p 2>/dev/null | wc -l" "completion_count"
            ;;
        zsh)
            time_shell_operation "zsh" "source ~/.zshrc && echo 'completions_loaded'" "completion_check"
            ;;
    esac
}

# Test plugin loading
test_plugins() {
    local shell="$1"
    
    debug_log "Testing $shell plugin loading"
    
    case "$shell" in
        bash)
            time_shell_operation "bash" "source ~/.bashrc && echo \$OSH" "oh_my_bash_check"
            ;;
        zsh)
            time_shell_operation "zsh" "source ~/.zshrc && echo \$ZSH" "oh_my_zsh_check"
            ;;
    esac
}

# Test function loading
test_functions() {
    local shell="$1"
    
    debug_log "Testing $shell function loading"
    
    case "$shell" in
        bash)
            time_shell_operation "bash" "source ~/.bashrc && type -t func_add >/dev/null && echo 'functions_loaded' || echo 'no_functions'" "function_check"
            ;;
        zsh)
            time_shell_operation "zsh" "source ~/.zshrc && echo 'zsh_functions_loaded'" "function_check"
            ;;
    esac
}

# Test environment setup
test_environment() {
    local shell="$1"
    
    debug_log "Testing $shell environment setup"
    
    time_shell_operation "$shell" "source ~/.$(basename "$shell")rc && echo \$PATH | tr ':' '\n' | wc -l" "path_entries"
}

# Main testing function
run_comprehensive_tests() {
    echo -e "${GREEN}🔍 Starting Comprehensive Shell Configuration Tests${NC}"
    echo "Debug mode: $DEBUG_MODE"
    echo "Log file: $LOG_FILE"
    echo "Report file: $REPORT_FILE"
    echo ""
    
    # Initialize report
    echo "{\"timestamp\":\"$(date -Iseconds)\",\"tests\":[" > "$REPORT_FILE"
    local first_test=true
    
    # Test bash
    if [[ -f "$HOME/.bashrc" ]]; then
        echo -e "${BLUE}Testing Bash Configuration${NC}"
        
        for test in syntax loading interactive completions plugins functions environment; do
            local result
            case "$test" in
                syntax) result=$(test_syntax bash "$HOME/.bashrc") ;;
                loading) result=$(test_loading bash "$HOME/.bashrc") ;;
                interactive) result=$(test_interactive bash) ;;
                completions) result=$(test_completions bash) ;;
                plugins) result=$(test_plugins bash) ;;
                functions) result=$(test_functions bash) ;;
                environment) result=$(test_environment bash) ;;
            esac
            
            if [[ "$first_test" == "true" ]]; then
                first_test=false
            else
                echo "," >> "$REPORT_FILE"
            fi
            echo "$result" >> "$REPORT_FILE"
        done
    else
        echo -e "${YELLOW}⚠️  .bashrc not found${NC}"
    fi
    
    # Test zsh
    if [[ -f "$HOME/.zshrc" ]]; then
        echo -e "${BLUE}Testing Zsh Configuration${NC}"
        
        for test in syntax loading interactive completions plugins functions environment; do
            local result
            case "$test" in
                syntax) result=$(test_syntax zsh "$HOME/.zshrc") ;;
                loading) result=$(test_loading zsh "$HOME/.zshrc") ;;
                interactive) result=$(test_interactive zsh) ;;
                completions) result=$(test_completions zsh) ;;
                plugins) result=$(test_plugins zsh) ;;
                functions) result=$(test_functions zsh) ;;
                environment) result=$(test_environment zsh) ;;
            esac
            
            if [[ "$first_test" == "true" ]]; then
                first_test=false
            else
                echo "," >> "$REPORT_FILE"
            fi
            echo "$result" >> "$REPORT_FILE"
        done
    else
        echo -e "${YELLOW}⚠️  .zshrc not found${NC}"
    fi
    
    # Close report
    echo "]}" >> "$REPORT_FILE"
    
    echo -e "${GREEN}✅ Tests completed!${NC}"
    echo "Report saved to: $REPORT_FILE"
    echo "Log saved to: $LOG_FILE"
}

# Analyze results
analyze_results() {
    echo -e "${BLUE}📊 Analyzing Test Results${NC}"
    
    if [[ ! -f "$REPORT_FILE" ]]; then
        echo -e "${RED}❌ No report file found${NC}"
        return 1
    fi
    
    # Parse JSON and generate summary
    local total_tests=$(jq '.tests | length' "$REPORT_FILE")
    local failed_tests=$(jq '.tests | map(select(.exit_code != 0)) | length' "$REPORT_FILE")
    local total_duration=$(jq '.tests | map(.duration_ms) | add' "$REPORT_FILE")
    local avg_duration=$(echo "scale=2; $total_duration / $total_tests" | bc -l)
    
    echo "Total Tests: $total_tests"
    echo "Failed Tests: $failed_tests"
    echo "Total Duration: ${total_duration}ms"
    echo "Average Duration: ${avg_duration}ms"
    
    # Show slowest tests
    echo -e "\n${YELLOW}🐌 Slowest Tests:${NC}"
    jq -r '.tests | sort_by(.duration_ms) | reverse | .[0:3] | .[] | "  \(.operation): \(.duration_ms)ms (\(.shell))"' "$REPORT_FILE"
    
    # Show failed tests
    if [[ "$failed_tests" -gt 0 ]]; then
        echo -e "\n${RED}❌ Failed Tests:${NC}"
        jq -r '.tests | map(select(.exit_code != 0)) | .[] | "  \(.operation) (\(.shell)): \(.output)"' "$REPORT_FILE"
    fi
    
    # Performance recommendations
    echo -e "\n${GREEN}💡 Performance Analysis:${NC}"
    
    local slow_loading=$(jq '.tests | map(select(.operation == "config_loading" and .duration_ms > 1000)) | length' "$REPORT_FILE")
    if [[ "$slow_loading" -gt 0 ]]; then
        echo "  ⚠️  Slow configuration loading detected (>1s)"
    fi
    
    local failed_interactive=$(jq '.tests | map(select(.operation == "interactive_startup" and .exit_code != 0)) | length' "$REPORT_FILE")
    if [[ "$failed_interactive" -gt 0 ]]; then
        echo "  ❌ Interactive shell startup issues detected"
    fi
    
    local failed_syntax=$(jq '.tests | map(select(.operation == "syntax_check" and .exit_code != 0)) | length' "$REPORT_FILE")
    if [[ "$failed_syntax" -gt 0 ]]; then
        echo "  ❌ Syntax errors detected in configuration files"
    fi
}

# Install dependencies
install_dependencies() {
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    
    # Install jq if not present
    if ! command -v jq >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y jq
    fi
    
    # Install bc if not present
    if ! command -v bc >/dev/null 2>&1; then
        sudo apt install -y bc
    fi
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# Main execution
main() {
    case "${1:-test}" in
        install)
            install_dependencies
            ;;
        test)
            install_dependencies
            run_comprehensive_tests
            analyze_results
            ;;
        analyze)
            analyze_results
            ;;
        debug)
            export SHELL_DEBUG=true
            run_comprehensive_tests
            analyze_results
            ;;
        *)
            echo "Usage: $0 {install|test|analyze|debug}"
            echo "  install - Install dependencies"
            echo "  test    - Run comprehensive tests"
            echo "  analyze - Analyze existing results"
            echo "  debug   - Run tests with debug output"
            exit 1
            ;;
    esac
}

# Check if running directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
