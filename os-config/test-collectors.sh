#!/bin/bash
# Test script for collectors
# Runs each collector and validates output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECTORS_DIR="$SCRIPT_DIR/collectors"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_collector() {
    local collector="$1"
    local script="$COLLECTORS_DIR/${collector}.sh"
    
    if [ ! -f "$script" ]; then
        echo -e "${YELLOW}[SKIP]${NC} $collector - script not found"
        return
    fi
    
    echo -n "Testing $collector... "
    
    # Run collector and capture output
    local output=$(bash "$script" 2>/dev/null)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}[FAIL]${NC} - exit code $exit_code"
        return
    fi
    
    # Check if output is valid JSON (if jq is available)
    if command -v jq &> /dev/null; then
        if echo "$output" | jq . &> /dev/null; then
            echo -e "${GREEN}[PASS]${NC} - valid JSON"
        else
            echo -e "${RED}[FAIL]${NC} - invalid JSON"
        fi
    else
        if [ -n "$output" ]; then
            echo -e "${GREEN}[PASS]${NC} - produced output"
        else
            echo -e "${YELLOW}[WARN]${NC} - no output"
        fi
    fi
}

echo "========================================"
echo "  Testing OS Config Collectors"
echo "========================================"
echo ""

test_collector "system"
test_collector "packages"
test_collector "dotfiles"
test_collector "tools"
test_collector "databases"
test_collector "containers"
test_collector "repositories"
test_collector "themes"

echo ""
echo "Testing complete!"
