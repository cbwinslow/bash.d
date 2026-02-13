#!/bin/bash
# Comprehensive test suite for bash.d modular system
# Tests standalone, bash-it, and oh-my-bash integration

# Do not exit on first error so we can see all test results
# set -e

# Get the repository root (two directories up from scripts/test/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_DIR="/tmp/bashd-test-$$"
PASSED=0
FAILED=0

# Debug: show where we are
# echo "SCRIPT_DIR=$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

cleanup() {
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

trap cleanup EXIT

# Setup test environment
setup_test_env() {
    mkdir -p "$TEST_DIR"
    export BASHD_HOME="$TEST_DIR/.bash.d"
    export BASHD_REPO_ROOT="$SCRIPT_DIR"
    export BASHD_STATE_DIR="$BASHD_HOME/state"
}

# Test 1: Directory Structure
test_directory_structure() {
    section "Test 1: Directory Structure"
    
    local required_dirs=(
        "lib"
        "plugins"
        "aliases"
        "completions"
        "bash_functions.d"
        "bash_aliases.d"
        "bash_env.d"
        "bash_prompt.d"
        "bash_history.d"
        "bash_secrets.d"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$SCRIPT_DIR/$dir" ]]; then
            success "Directory exists: $dir"
        else
            fail "Directory missing: $dir"
        fi
    done
}

# Test 2: Core Files Exist
test_core_files() {
    section "Test 2: Core Files"
    
    local required_files=(
        "bashrc"
        "README.md"
        "CONTRIBUTING.md"
        "install.sh"
        "scripts/setup/install-bash-it.sh"
        "lib/module-manager.sh"
        "lib/bash-it-integration.sh"
        "lib/bash-it-plugin.bash"
        "lib/bash-it-compat.sh"
        "lib/indexer.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            success "File exists: $file"
        else
            fail "File missing: $file"
        fi
    done
}

# Test 3: bashrc Loads Without Errors
test_bashrc_loads() {
    section "Test 3: bashrc Loading"
    
    if bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc" 2>&1 | grep -qi "error"; then
        fail "bashrc has errors"
    else
        success "bashrc loads without critical errors"
    fi
}

# Test 4: Module Manager Functions
test_module_manager() {
    section "Test 4: Module Manager Functions"
    
    local output
    output=$(bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc && type bashd_module_list" 2>&1)
    
    if echo "$output" | grep -q "is a function"; then
        success "bashd_module_list function exists"
    else
        fail "bashd_module_list function not found"
    fi
    
    output=$(bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc && type bashd_module_enable" 2>&1)
    if echo "$output" | grep -q "is a function"; then
        success "bashd_module_enable function exists"
    else
        fail "bashd_module_enable function not found"
    fi
    
    output=$(bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc && type bashd_module_disable" 2>&1)
    if echo "$output" | grep -q "is a function"; then
        success "bashd_module_disable function exists"
    else
        fail "bashd_module_disable function not found"
    fi
}

# Test 5: Indexer Functions
test_indexer() {
    section "Test 5: Indexer Functions"
    
    local output
    output=$(bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc && type bashd_index_update" 2>&1)
    
    if echo "$output" | grep -q "is a function"; then
        success "bashd_index_update function exists"
    else
        fail "bashd_index_update function not found"
    fi
    
    output=$(bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc && type bashd_index_stats" 2>&1)
    if echo "$output" | grep -q "is a function"; then
        success "bashd_index_stats function exists"
    else
        fail "bashd_index_stats function not found"
    fi
}

# Test 6: Module Listing
test_module_listing() {
    section "Test 6: Module Listing"
    
    local output
    output=$(bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc && bashd_module_list aliases" 2>&1)
    
    if echo "$output" | grep -q "aliases"; then
        success "Can list aliases"
    else
        fail "Cannot list aliases"
    fi
    
    if echo "$output" | grep -q "git\|docker\|general"; then
        success "Aliases are detected"
    else
        fail "No aliases detected"
    fi
}

# Test 7: Plugins Load
test_plugins_load() {
    section "Test 7: Plugins Loading"
    
    local output
    output=$(bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc && type bashd-list" 2>&1)
    
    if echo "$output" | grep -q "alias\|function"; then
        success "bashd-list command available"
    else
        fail "bashd-list command not available"
    fi
}

# Test 8: Aliases Load
test_aliases_load() {
    section "Test 8: Aliases Loading"
    
    local output
    output=$(bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc && alias | grep -E '(^g=|^d=|^gs=)'" 2>&1)
    
    if echo "$output" | grep -q "git\|docker"; then
        success "Git and Docker aliases loaded"
    else
        fail "Aliases not loaded correctly"
    fi
}

# Test 9: Completions Load
test_completions_load() {
    section "Test 9: Completions Loading"
    
    local output
    output=$(bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc && complete -p | grep bashd" 2>&1)
    
    if echo "$output" | grep -q "bashd"; then
        success "bash.d completions loaded"
    else
        fail "Completions not loaded"
    fi
}

# Test 10: bash-it Compatibility
test_bash_it_compat() {
    section "Test 10: bash-it Compatibility"
    
    local output
    output=$(bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc && type cite && type about-plugin" 2>&1)
    
    if echo "$output" | grep -q "is a function"; then
        success "bash-it compatibility stubs available"
    else
        fail "bash-it compatibility stubs missing"
    fi
}

# Test 11: Index Creation
test_index_creation() {
    section "Test 11: Index Creation"
    
    local output
    output=$(bash --norc --noprofile -c "export BASHD_STATE_DIR='$TEST_DIR/state' && source $SCRIPT_DIR/bashrc && bashd_index_update && bashd_index_stats" 2>&1)
    
    if echo "$output" | grep -q "Index updated"; then
        success "Index can be created"
    else
        fail "Index creation failed"
    fi
    
    if echo "$output" | grep -q "Total Modules"; then
        success "Index stats available"
    else
        fail "Index stats not working"
    fi
}

# Test 12: Function Discovery
test_function_discovery() {
    section "Test 12: Function Discovery"
    
    local output
    output=$(bash --norc --noprofile -c "source $SCRIPT_DIR/bashrc && bashd_module_list functions 2>&1 | head -20" 2>&1)
    
    if echo "$output" | grep -q "functions"; then
        success "Functions can be listed"
    else
        fail "Function listing failed"
    fi
}

# Test 13: Shell Check
test_shellcheck() {
    section "Test 13: Shellcheck Validation"
    
    if ! command -v shellcheck &>/dev/null; then
        info "Shellcheck not installed, skipping"
        return 0
    fi
    
    local errors=0
    
    for file in "$SCRIPT_DIR"/lib/*.sh "$SCRIPT_DIR"/lib/*.bash; do
        if [[ -f "$file" ]]; then
            if shellcheck -x "$file" 2>&1 | grep -q "error:"; then
                fail "Shellcheck errors in $(basename $file)"
                ((errors++))
            fi
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        success "All lib files pass shellcheck"
    fi
}

# Test 14: Documentation
test_documentation() {
    section "Test 14: Documentation"
    
    if grep -q "bash-it" "$SCRIPT_DIR/README.md"; then
        success "README mentions bash-it integration"
    else
        fail "README missing bash-it documentation"
    fi
    
    if grep -q "bashd-enable" "$SCRIPT_DIR/README.md"; then
        success "README documents module management"
    else
        fail "README missing module management docs"
    fi
    
    if [[ -f "$SCRIPT_DIR/CONTRIBUTING.md" ]]; then
        success "CONTRIBUTING.md exists"
    else
        fail "CONTRIBUTING.md missing"
    fi
}

# Test 15: Install Scripts
test_install_scripts() {
    section "Test 15: Install Scripts"
    
    if [[ -x "$SCRIPT_DIR/install.sh" ]]; then
        success "install.sh is executable"
    else
        fail "install.sh not executable"
    fi
    
    if [[ -x "$SCRIPT_DIR/scripts/setup/install-bash-it.sh" ]]; then
        success "install-bash-it.sh is executable"
    else
        fail "install-bash-it.sh not executable"
    fi
}

# Run all tests
run_all_tests() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         bash.d Comprehensive Test Suite                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    
    setup_test_env
    
    test_directory_structure
    test_core_files
    test_bashrc_loads
    test_module_manager
    test_indexer
    test_module_listing
    test_plugins_load
    test_aliases_load
    test_completions_load
    test_bash_it_compat
    test_index_creation
    test_function_discovery
    test_shellcheck
    test_documentation
    test_install_scripts
    
    # Summary
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    echo ""
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

run_all_tests
