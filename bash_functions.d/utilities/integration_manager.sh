#!/bin/bash
#===============================================================================
#
#          FILE:  integration_manager.sh
#
#         USAGE:  system_integrate
#                 system_test
#                 system_status
#                 system_help
#
#   DESCRIPTION:  Integration and testing system for all bash.d components
#                 Ensures all systems work together seamlessly
#
#       OPTIONS:  ---
#  REQUIREMENTS:  jq, curl, git, ssh
#         NOTES:  Comprehensive system integration and testing
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Configuration
INTEGRATION_LOG="${HOME}/.cache/bashd_integration.log"
mkdir -p "$(dirname "$INTEGRATION_LOG")"

# Integrate all systems
system_integrate() {
    echo "Integrating all bash.d systems..."
    echo "Log: $INTEGRATION_LOG"
    echo "" > "$INTEGRATION_LOG"

    local start_time
    start_time=$(date +%s)

    # Test documentation system
    _test_doc_system

    # Test connection management
    _test_connection_system

    # Test YADM integration
    _test_yadm_system

    # Test bundle system
    _test_bundle_system

    # Test inventory system
    _test_inventory_system

    # Test keybinding system
    _test_keybinding_system

    # Test automation system
    _test_automation_system

    local end_time
    end_time=$(date +%s)
    local duration
    duration=$((end_time - start_time))

    echo "Integration completed in ${duration}s"
    echo "Full log: $INTEGRATION_LOG"
}

# Test documentation system
_test_doc_system() {
    echo "Testing Documentation System..."
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test doc_lookup
    if doc_lookup ls >/dev/null 2>&1; then
        echo "✓ doc_lookup working" >> "$INTEGRATION_LOG"
    else
        echo "✗ doc_lookup failed" >> "$INTEGRATION_LOG"
    fi

    # Test doc_cache
    if doc_cache git >/dev/null 2>&1; then
        echo "✓ doc_cache working" >> "$INTEGRATION_LOG"
    else
        echo "✗ doc_cache failed" >> "$INTEGRATION_LOG"
    fi

    # Test doc_search
    if doc_search "recursive" >/dev/null 2>&1; then
        echo "✓ doc_search working" >> "$INTEGRATION_LOG"
    else
        echo "✗ doc_search failed" >> "$INTEGRATION_LOG"
    fi

    echo "Documentation system test completed" >> "$INTEGRATION_LOG"
}

# Test connection management system
_test_connection_system() {
    echo "Testing Connection Management System..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test github_connect
    if github_connect check >/dev/null 2>&1; then
        echo "✓ github_connect working" >> "$INTEGRATION_LOG"
    else
        echo "✗ github_connect failed" >> "$INTEGRATION_LOG"
    fi

    # Test gitlab_connect
    if gitlab_connect check >/dev/null 2>&1; then
        echo "✓ gitlab_connect working" >> "$INTEGRATION_LOG"
    else
        echo "✗ gitlab_connect failed" >> "$INTEGRATION_LOG"
    fi

    # Test connection_troubleshoot
    if connection_troubleshoot >/dev/null 2>&1; then
        echo "✓ connection_troubleshoot working" >> "$INTEGRATION_LOG"
    else
        echo "✗ connection_troubleshoot failed" >> "$INTEGRATION_LOG"
    fi

    echo "Connection management system test completed" >> "$INTEGRATION_LOG"
}

# Test YADM system
_test_yadm_system() {
    echo "Testing YADM System..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test yadm_status
    if yadm_status >/dev/null 2>&1; then
        echo "✓ yadm_status working" >> "$INTEGRATION_LOG"
    else
        echo "✗ yadm_status failed" >> "$INTEGRATION_LOG"
    fi

    # Test yadm_help
    if yadm_help >/dev/null 2>&1; then
        echo "✓ yadm_help working" >> "$INTEGRATION_LOG"
    else
        echo "✗ yadm_help failed" >> "$INTEGRATION_LOG"
    fi

    echo "YADM system test completed" >> "$INTEGRATION_LOG"
}

# Test bundle system
_test_bundle_system() {
    echo "Testing Bundle System..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test bundle_list
    if bundle_list >/dev/null 2>&1; then
        echo "✓ bundle_list working" >> "$INTEGRATION_LOG"
    else
        echo "✗ bundle_list failed" >> "$INTEGRATION_LOG"
    fi

    # Test bundle_help
    if bundle_help >/dev/null 2>&1; then
        echo "✓ bundle_help working" >> "$INTEGRATION_LOG"
    else
        echo "✗ bundle_help failed" >> "$INTEGRATION_LOG"
    fi

    echo "Bundle system test completed" >> "$INTEGRATION_LOG"
}

# Test inventory system
_test_inventory_system() {
    echo "Testing Inventory System..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test inventory_list
    if inventory_list >/dev/null 2>&1; then
        echo "✓ inventory_list working" >> "$INTEGRATION_LOG"
    else
        echo "✗ inventory_list failed" >> "$INTEGRATION_LOG"
    fi

    # Test inventory_help
    if inventory_help >/dev/null 2>&1; then
        echo "✓ inventory_help working" >> "$INTEGRATION_LOG"
    else
        echo "✗ inventory_help failed" >> "$INTEGRATION_LOG"
    fi

    echo "Inventory system test completed" >> "$INTEGRATION_LOG"
}

# Test keybinding system
_test_keybinding_system() {
    echo "Testing Keybinding System..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test keybind_list
    if keybind_list >/dev/null 2>&1; then
        echo "✓ keybind_list working" >> "$INTEGRATION_LOG"
    else
        echo "✗ keybind_list failed" >> "$INTEGRATION_LOG"
    fi

    # Test keybind_help
    if keybind_help >/dev/null 2>&1; then
        echo "✓ keybind_help working" >> "$INTEGRATION_LOG"
    else
        echo "✗ keybind_help failed" >> "$INTEGRATION_LOG"
    fi

    echo "Keybinding system test completed" >> "$INTEGRATION_LOG"
}

# Test automation system
_test_automation_system() {
    echo "Testing Automation System..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test auto_help
    if auto_help >/dev/null 2>&1; then
        echo "✓ auto_help working" >> "$INTEGRATION_LOG"
    else
        echo "✗ auto_help failed" >> "$INTEGRATION_LOG"
    fi

    # Test auto_template_list
    if auto_template_list >/dev/null 2>&1; then
        echo "✓ auto_template_list working" >> "$INTEGRATION_LOG"
    else
        echo "✗ auto_template_list failed" >> "$INTEGRATION_LOG"
    fi

    echo "Automation system test completed" >> "$INTEGRATION_LOG"
}

# Run comprehensive system tests
system_test() {
    echo "Running Comprehensive System Tests..."
    echo "════════════════════════════════════════════════════════════════"

    local start_time
    start_time=$(date +%s)

    # Run integration tests
    system_integrate

    # Test specific workflows
    _test_workflow_documentation
    _test_workflow_connection
    _test_workflow_bundle
    _test_workflow_inventory
    _test_workflow_keybinding
    _test_workflow_automation

    local end_time
    end_time=$(date +%s)
    local duration
    duration=$((end_time - start_time))

    echo "System tests completed in ${duration}s"
    echo "Full results in: $INTEGRATION_LOG"
}

# Test documentation workflow
_test_workflow_documentation() {
    echo "Testing Documentation Workflow..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test doc_lookup -> doc_cache -> doc_search workflow
    if doc_lookup git >/dev/null 2>&1 && \
       doc_cache git >/dev/null 2>&1 && \
       doc_search "recursive" >/dev/null 2>&1; then
        echo "✓ Documentation workflow working" >> "$INTEGRATION_LOG"
    else
        echo "✗ Documentation workflow failed" >> "$INTEGRATION_LOG"
    fi

    echo "Documentation workflow test completed" >> "$INTEGRATION_LOG"
}

# Test connection workflow
_test_workflow_connection() {
    echo "Testing Connection Workflow..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test github_connect -> gitlab_connect -> connection_troubleshoot workflow
    if github_connect check >/dev/null 2>&1 && \
       gitlab_connect check >/dev/null 2>&1 && \
       connection_troubleshoot >/dev/null 2>&1; then
        echo "✓ Connection workflow working" >> "$INTEGRATION_LOG"
    else
        echo "✗ Connection workflow failed" >> "$INTEGRATION_LOG"
    fi

    echo "Connection workflow test completed" >> "$INTEGRATION_LOG"
}

# Test bundle workflow
_test_workflow_bundle() {
    echo "Testing Bundle Workflow..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test bundle_list -> bundle_help workflow
    if bundle_list >/dev/null 2>&1 && \
       bundle_help >/dev/null 2>&1; then
        echo "✓ Bundle workflow working" >> "$INTEGRATION_LOG"
    else
        echo "✗ Bundle workflow failed" >> "$INTEGRATION_LOG"
    fi

    echo "Bundle workflow test completed" >> "$INTEGRATION_LOG"
}

# Test inventory workflow
_test_workflow_inventory() {
    echo "Testing Inventory Workflow..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test inventory_list -> inventory_help workflow
    if inventory_list >/dev/null 2>&1 && \
       inventory_help >/dev/null 2>&1; then
        echo "✓ Inventory workflow working" >> "$INTEGRATION_LOG"
    else
        echo "✗ Inventory workflow failed" >> "$INTEGRATION_LOG"
    fi

    echo "Inventory workflow test completed" >> "$INTEGRATION_LOG"
}

# Test keybinding workflow
_test_workflow_keybinding() {
    echo "Testing Keybinding Workflow..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test keybind_list -> keybind_help workflow
    if keybind_list >/dev/null 2>&1 && \
       keybind_help >/dev/null 2>&1; then
        echo "✓ Keybinding workflow working" >> "$INTEGRATION_LOG"
    else
        echo "✗ Keybinding workflow failed" >> "$INTEGRATION_LOG"
    fi

    echo "Keybinding workflow test completed" >> "$INTEGRATION_LOG"
}

# Test automation workflow
_test_workflow_automation() {
    echo "Testing Automation Workflow..." >> "$INTEGRATION_LOG"
    echo "════════════════════════════════════════════════════════════════" >> "$INTEGRATION_LOG"

    # Test auto_help -> auto_template_list workflow
    if auto_help >/dev/null 2>&1 && \
       auto_template_list >/dev/null 2>&1; then
        echo "✓ Automation workflow working" >> "$INTEGRATION_LOG"
    else
        echo "✗ Automation workflow failed" >> "$INTEGRATION_LOG"
    fi

    echo "Automation workflow test completed" >> "$INTEGRATION_LOG"
}

# Show system status
system_status() {
    echo "System Status:"
    echo "════════════════════════════════════════════════════════════════"

    # Count available functions
    local func_count
    func_count=$(find "${BASH_D_REPO:-$HOME/bash.d}/bash_functions.d" -name "*.sh" -type f 2>/dev/null | wc -l)

    # Count bundles
    local bundle_count
    bundle_count=$(ls "${HOME}/.bundles/meta" 2>/dev/null | wc -l)

    # Count inventory items
    local inventory_count
    inventory_count=$(ls "${HOME}/.inventory/meta" 2>/dev/null | wc -l)

    # Count cached docs
    local doc_count
    doc_count=$(ls "${HOME}/.cache/bashd_docs" 2>/dev/null | wc -l)

    echo ""
    echo "Components:"
    echo "  Functions: $func_count"
    echo "  Bundles: $bundle_count"
    echo "  Inventory Items: $inventory_count"
    echo "  Cached Docs: $doc_count"
    echo ""

    # Show recent log entries
    if [[ -f "$INTEGRATION_LOG" ]]; then
        echo "Recent Integration Log:"
        echo "─────────────────────────────────────────────────────────────────"
        tail -10 "$INTEGRATION_LOG"
    else
        echo "No integration log found"
    fi
}

# System help
system_help() {
    cat << 'EOF'
System Integration Commands:

  system_integrate          - Integrate all systems
  system_test               - Run comprehensive system tests
  system_status             - Show system status
  system_help               - Show this help message

Integration Tests:
  Tests all major components:
  - Documentation system
  - Connection management
  - YADM integration
  - Bundle system
  - Inventory system
  - Keybinding system
  - Automation system

Workflow Tests:
  Tests complete workflows:
  - Documentation workflow
  - Connection workflow
  - Bundle workflow
  - Inventory workflow
  - Keybinding workflow
  - Automation workflow

Examples:
  system_integrate
  system_test
  system_status
EOF
}

# Export functions
export -f system_integrate 2>/dev/null
export -f system_test 2>/dev/null
export -f _test_doc_system 2>/dev/null
export -f _test_connection_system 2>/dev/null
export -f _test_yadm_system 2>/dev/null
export -f _test_bundle_system 2>/dev/null
export -f _test_inventory_system 2>/dev/null
export -f _test_keybinding_system 2>/dev/null
export -f _test_automation_system 2>/dev/null
export -f _test_workflow_documentation 2>/dev/null
export -f _test_workflow_connection 2>/dev/null
export -f _test_workflow_bundle 2>/dev/null
export -f _test_workflow_inventory 2>/dev/null
export -f _test_workflow_keybinding 2>/dev/null
export -f _test_workflow_automation 2>/dev/null
export -f system_status 2>/dev/null
export -f system_help 2>/dev/null
