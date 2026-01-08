#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  test_system.sh
#
#         USAGE:  ./test_system.sh
#
#   DESCRIPTION:  Test script to verify all GitHub API, Cloudflare storage,
#                 file management, and quick functions work correctly.
#                 Performs integration tests with error validation.
#
#  REQUIREMENTS:  All system components loaded and configured
#
#          BUGS:  None - all test failures are logged
#         NOTES:  Run this script after configuring credentials
#
#        AUTHOR:  bash.d project
#       VERSION: 1.0.0
#       CREATED:  2025-01-08
#      REVISION:  
#===============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test logging
log_test() {
    local status="$1"
    local test_name="$2"
    local message="${3:-}"
    
    ((TESTS_TOTAL++))
    
    case "$status" in
        PASS)
            echo -e "${GREEN}✓ PASS${NC} $test_name"
            ((TESTS_PASSED++))
            [[ -n "$message" ]] && echo "  $message"
            ;;
        FAIL)
            echo -e "${RED}✗ FAIL${NC} $test_name"
            ((TESTS_FAILED++))
            [[ -n "$message" ]] && echo -e "  ${RED}Error:${NC} $message"
            ;;
        SKIP)
            echo -e "${YELLOW}⊘ SKIP${NC} $test_name"
            [[ -n "$message" ]] && echo "  $message"
            ;;
        INFO)
            echo -e "${BLUE}ℹ INFO${NC} $test_name"
            [[ -n "$message" ]] && echo "  $message"
            ;;
    esac
}

# Test function exists
test_function_exists() {
    local function_name="$1"
    local description="$2"
    
    if command -v "$function_name" >/dev/null 2>&1; then
        log_test PASS "$description" "Function '$function_name' is available"
        return 0
    else
        log_test FAIL "$description" "Function '$function_name' not found"
        return 1
    fi
}

# Test script loads
test_script_loading() {
    log_test INFO "Testing Script Loading"
    
    # Test all required scripts
    local scripts=(
        "github_api_enhanced.sh:GitHub API"
        "cloudflare_storage.sh:Cloudflare Storage" 
        "file_manager.sh:File Manager"
        "quick_functions.sh:Quick Functions"
    )
    
    for script_info in "${scripts[@]}"; do
        local script_file="${script_info%%:*}"
        local description="${script_info##*:}"
        
        local script_path="${BASH_FUNCTIONS_DIR:-$HOME/bash_functions.d}/tools/$script_file"
        if [[ -f "$script_path" ]]; then
            log_test PASS "Script Available" "$description script found at $script_path"
        else
            log_test FAIL "Script Available" "$description script not found at $script_path"
        fi
    done
}

# Test GitHub API functions
test_github_api() {
    log_test INFO "Testing GitHub API Functions"
    
    # Test basic functions exist
    test_function_exists "gh_create_repo" "GitHub - Repository Creation"
    test_function_exists "gh_commit_file" "GitHub - File Commit"
    test_function_exists "gh_list_repos" "GitHub - Repository Listing"
    test_function_exists "gh_config" "GitHub - Configuration"
    
    # Test configuration (without actually calling API)
    local config_output
    if config_output=$(gh_config 2>&1); then
        log_test PASS "GitHub Configuration" "Config function executed successfully"
        
        if echo "$config_output" | grep -q "GitHub API Configuration"; then
            log_test PASS "GitHub Configuration Output" "Config displays expected information"
        else
            log_test FAIL "GitHub Configuration Output" "Unexpected config output"
        fi
    else
        log_test SKIP "GitHub Configuration" "Config function failed (expected if no credentials)"
    fi
}

# Test Cloudflare functions
test_cloudflare_storage() {
    log_test INFO "Testing Cloudflare Storage Functions"
    
    # Test basic functions exist
    test_function_exists "cf_upload_file" "Cloudflare - File Upload"
    test_function_exists "cf_download_file" "Cloudflare - File Download"
    test_function_exists "cf_list_files" "Cloudflare - File Listing"
    test_function_exists "cf_config" "Cloudflare - Configuration"
    
    # Test configuration
    local config_output
    if config_output=$(cf_config 2>&1); then
        log_test PASS "Cloudflare Configuration" "Config function executed successfully"
        
        if echo "$config_output" | grep -q "Cloudflare R2 Configuration"; then
            log_test PASS "Cloudflare Configuration Output" "Config displays expected information"
        else
            log_test FAIL "Cloudflare Configuration Output" "Unexpected config output"
        fi
    else
        log_test SKIP "Cloudflare Configuration" "Config function failed (expected if no credentials)"
    fi
}

# Test file manager functions
test_file_manager() {
    log_test INFO "Testing File Manager Functions"
    
    # Test basic functions exist
    test_function_exists "fm_store_file" "File Manager - Store File"
    test_function_exists "fm_retrieve_file" "File Manager - Retrieve File"
    test_function_exists "fm_list_files" "File Manager - List Files"
    test_function_exists "fm_config" "File Manager - Configuration"
    
    # Test configuration
    local config_output
    if config_output=$(fm_config 2>&1); then
        log_test PASS "File Manager Configuration" "Config function executed successfully"
        
        if echo "$config_output" | grep -q "File Manager Configuration"; then
            log_test PASS "File Manager Configuration Output" "Config displays expected information"
        else
            log_test FAIL "File Manager Configuration Output" "Unexpected config output"
        fi
    else
        log_test FAIL "File Manager Configuration" "Config function failed unexpectedly"
    fi
    
    # Test basic file operations (local only)
    local test_content="# Test File Content
Created on $(date)
This is a test file for verification.
"
    
    local test_file="test_agents.md"
    local category="agents"
    
    if fm_store_file "$category" "$test_file" "$test_content" 2>/dev/null; then
        log_test PASS "File Storage" "Successfully stored test file"
        
        # Test retrieval
        local retrieved_content
        if retrieved_content=$(fm_retrieve_file "$category" "$test_file" 2>/dev/null); then
            if echo "$retrieved_content" | grep -q "Test File Content"; then
                log_test PASS "File Retrieval" "Successfully retrieved stored content"
            else
                log_test FAIL "File Retrieval" "Retrieved content doesn't match original"
            fi
        else
            log_test FAIL "File Retrieval" "Failed to retrieve stored file"
        fi
        
        # Cleanup test file
        local category_dir
        category_dir=$(_get_category_dir "$category" 2>/dev/null || echo "$HOME/.file_manager/agents")
        rm -f "$category_dir/$test_file" 2>/dev/null || true
    else
        log_test FAIL "File Storage" "Failed to store test file"
    fi
}

# Test quick functions
test_quick_functions() {
    log_test INFO "Testing Quick Functions"
    
    # Test basic functions exist
    test_function_exists "quick_repo" "Quick - Repository Creation"
    test_function_exists "quick_commit" "Quick - File Commit"
    test_function_exists "quick_agent" "Quick - Agent Creation"
    test_function_exists "quick_status" "Quick - Status Check"
    
    # Test status function
    local status_output
    if status_output=$(quick_status 2>&1); then
        log_test PASS "Quick Status" "Status function executed successfully"
        
        if echo "$status_output" | grep -q "System Status"; then
            log_test PASS "Quick Status Output" "Status displays expected information"
        else
            log_test FAIL "Quick Status Output" "Unexpected status output"
        fi
    else
        log_test FAIL "Quick Status" "Status function failed unexpectedly"
    fi
}

# Test directory structure
test_directory_structure() {
    log_test INFO "Testing Directory Structure"
    
    local expected_dirs=(
        "$HOME/.file_manager/agents"
        "$HOME/.file_manager/rules" 
        "$HOME/.file_manager/tools"
        "$HOME/.file_manager/logs"
        "$HOME/.file_manager/todos"
        "$HOME/.file_manager/configs"
        "$HOME/.file_manager/memorys"
        "$HOME/.file_manager/.metadata"
        "$HOME/.file_manager/.versions"
        "$HOME/.file_manager/.backups"
    )
    
    for dir in "${expected_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_test PASS "Directory Structure" "Directory exists: $(basename "$dir")"
        else
            log_test FAIL "Directory Structure" "Directory missing: $(basename "$dir")"
        fi
    done
}

# Test dependencies
test_dependencies() {
    log_test INFO "Testing Dependencies"
    
    local dependencies=(
        "curl:HTTP Client"
        "jq:JSON Processor"
        "openssl:Crypto Library"
        "gzip:Compression Tool"
    )
    
    for dep_info in "${dependencies[@]}"; do
        local command="${dep_info%%:*}"
        local description="${dep_info##*:}"
        
        if command -v "$command" >/dev/null 2>&1; then
            local version
            case "$command" in
                curl) version=$(curl --version 2>/dev/null | head -1) ;;
                jq) version=$(jq --version 2>/dev/null) ;;
                openssl) version=$(openssl version 2>/dev/null | head -1) ;;
                gzip) version=$(gzip --version 2>/dev/null | head -1) ;;
            esac
            
            log_test PASS "Dependency Available" "$description ($command) - $version"
        else
            log_test FAIL "Dependency Missing" "$description ($command) - not found"
        fi
    done
}

# Test error handling
test_error_handling() {
    log_test INFO "Testing Error Handling"
    
    # Test invalid file path (should fail gracefully)
    if fm_store_file "agents" "../../../etc/passwd" "test" "content" 2>/dev/null; then
        log_test FAIL "Error Handling" "Should reject directory traversal"
    else
        log_test PASS "Error Handling" "Correctly rejected directory traversal"
    fi
    
    # Test invalid repository name (should fail gracefully)
    if gh_create_repo "" 2>/dev/null; then
        log_test FAIL "Error Handling" "Should reject empty repository name"
    else
        log_test PASS "Error Handling" "Correctly rejected empty repository name"
    fi
}

# Test auto-completion
test_autocompletion() {
    log_test INFO "Testing Auto-completion"
    
    # Test if completion functions exist
    local completion_functions=(
        "_gh_complete:GitHub completion"
        "_cf_complete:Cloudflare completion" 
        "_fm_complete:File Manager completion"
        "_quick_complete:Quick functions completion"
    )
    
    for completion_info in "${completion_functions[@]}"; do
        local function_name="${completion_info%%:*}"
        local description="${completion_info##*:}"
        
        if declare -f "$function_name" >/dev/null 2>&1; then
            log_test PASS "Auto-completion" "$description function available"
        else
            log_test SKIP "Auto-completion" "$description function not available"
        fi
    done
}

# Integration test
test_integration() {
    log_test INFO "Testing Integration"
    
    # Test loading quick functions (which depends on all other modules)
    if source "${BASH_FUNCTIONS_DIR:-$HOME/bash_functions.d}/tools/quick_functions.sh" 2>/dev/null; then
        log_test PASS "Integration" "Quick functions loaded successfully"
        
        # Test if quick functions can see other functions
        if command -v gh_create_repo >/dev/null 2>&1 && command -v cf_upload_file >/dev/null 2>&1 && command -v fm_store_file >/dev/null 2>&1; then
            log_test PASS "Integration" "All dependencies available to quick functions"
        else
            log_test FAIL "Integration" "Quick functions missing dependencies"
        fi
    else
        log_test FAIL "Integration" "Failed to load quick functions"
    fi
}

# Main test execution
main() {
    echo "=============================================================================="
    echo "      System Integration Test Suite"
    echo "=============================================================================="
    echo ""
    
    # Run all tests
    test_script_loading
    test_dependencies
    test_directory_structure
    test_github_api
    test_cloudflare_storage
    test_file_manager
    test_quick_functions
    test_error_handling
    test_autocompletion
    test_integration
    
    # Print results
    echo ""
    echo "=============================================================================="
    echo "                      TEST RESULTS"
    echo "=============================================================================="
    echo -e "Total Tests:  $TESTS_TOTAL"
    echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
    echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
    echo -e "${YELLOW}Skipped:      $((TESTS_TOTAL - TESTS_PASSED - TESTS_FAILED))${NC}"
    
    local success_rate=0
    if [[ $TESTS_TOTAL -gt 0 ]]; then
        success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    fi
    
    echo -e "Success Rate: ${success_rate}%"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 ALL TESTS PASSED! System is ready for use.${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Configure your GitHub PAT in Bitwarden (entry: github_pat)"
        echo "2. Configure your Cloudflare credentials in Bitwarden (entry: cloudflare_r2)"
        echo "3. Set default repositories/buckets with environment variables:"
        echo "   export FM_DEFAULT_GITHUB_REPO='your-repo'"
        echo "   export FM_DEFAULT_CLOUDFLARE_BUCKET='your-bucket'"
        echo "4. Load the system: source ~/bash_functions.d/tools/quick_functions.sh"
        echo "5. Run: quick_status"
        return 0
    else
        echo -e "\n${RED}❌ SOME TESTS FAILED. Please check the errors above.${NC}"
        echo ""
        echo "Common issues:"
        echo "1. Missing dependencies - install required tools"
        echo "2. Permission issues - check directory permissions"
        echo "3. Missing scripts - ensure all files are in place"
        echo "4. Credential configuration - set up Bitwarden entries"
        return 1
    fi
}

# Helper function for file manager testing
_get_category_dir() {
    local category="$1"
    
    case "$category" in
        agents) echo "${FM_ROOT_DIR:-$HOME/.file_manager}/agents" ;;
        rules) echo "${FM_ROOT_DIR:-$HOME/.file_manager}/rules" ;;
        tools) echo "${FM_ROOT_DIR:-$HOME/.file_manager}/tools" ;;
        logs) echo "${FM_ROOT_DIR:-$HOME/.file_manager}/logs" ;;
        todos) echo "${FM_ROOT_DIR:-$HOME/.file_manager}/todos" ;;
        configs) echo "${FM_ROOT_DIR:-$HOME/.file_manager}/configs" ;;
        memorys) echo "${FM_ROOT_DIR:-$HOME/.file_manager}/memorys" ;;
        *) echo "${FM_ROOT_DIR:-$HOME/.file_manager}/$category" ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi