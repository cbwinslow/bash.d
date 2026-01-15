#!/bin/bash
#===============================================================================
#
#          FILE:  search_system_loader.sh
#
#         USAGE:  Source this file to load the complete search system
#
#   DESCRIPTION:  Loads all search, index, and utility functions
#                 Initializes the search system
#
#       OPTIONS:  None
#  REQUIREMENTS:  jq (for index system)
#         NOTES:  Auto-sourced by bashrc
#        AUTHOR:  bash.d project
#       VERSION:  2.0.0
#===============================================================================

# Set up environment
export BASHD_HOME="${BASHD_HOME:-$HOME/.bash.d}"
export BASHD_INDEX_DIR="${BASHD_HOME}/.index"
export BASHD_INDEX_FILE="${BASHD_INDEX_DIR}/master_index.json"

# Source directory for this script
SEARCH_SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load core search system components
_bashd_load_search_system() {
    local components=(
        "indexer.sh"
        "search.sh"
        "utilities.sh"
        "search_help.sh"
    )
    
    for component in "${components[@]}"; do
        local component_path="${SEARCH_SYSTEM_DIR}/${component}"
        if [[ -f "$component_path" ]]; then
            # shellcheck source=/dev/null
            source "$component_path"
        else
            echo "Warning: Search system component not found: $component" >&2
        fi
    done
}

# Initialize search system
_bashd_init_search_system() {
    # Create index directory if it doesn't exist
    mkdir -p "${BASHD_INDEX_DIR}"
    
    # Check if index exists, suggest building if not
    if [[ ! -f "${BASHD_INDEX_FILE}" ]]; then
        # Don't auto-build on every shell start, just inform
        :  # Silent - user can run bashd_index_build manually
    fi
}

# Check dependencies
_bashd_check_dependencies() {
    local missing_deps=()
    
    # jq is required for index system
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    # Optional but recommended
    if ! command -v fzf >/dev/null 2>&1; then
        : # fzf is optional for bashd_fuzzy
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "bash.d search system: Missing required dependencies:" >&2
        printf "  - %s\n" "${missing_deps[@]}" >&2
        echo "Install with: sudo apt install ${missing_deps[*]}" >&2
        return 1
    fi
    
    return 0
}

# Create aliases for convenience
_bashd_create_search_aliases() {
    # Short aliases for common commands
    alias bds='bashd_search'
    alias bdf='bashd_find'
    alias bdl='bashd_locate'
    alias bdz='bashd_fuzzy'  # z for fuzzy
    alias bdg='bashd_grep'
    alias bde='bashd_edit'
    alias bdh='bashd_help'
    
    # Index aliases
    alias bdi='bashd_index_build'
    alias bdiu='bashd_index_update'
    alias bdis='bashd_index_stats'
}

# Main loader
_bashd_main_loader() {
    # Load all components
    _bashd_load_search_system
    
    # Initialize
    _bashd_init_search_system
    
    # Check dependencies (silent if all good)
    _bashd_check_dependencies >/dev/null 2>&1 || true
    
    # Create convenient aliases
    _bashd_create_search_aliases
    
    # Print welcome message on first load (only if interactive shell)
    if [[ $- == *i* ]] && [[ ! -f "${BASHD_INDEX_FILE}" ]]; then
        cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════╗
║              bash.d Search & Index System Loaded                         ║
╚══════════════════════════════════════════════════════════════════════════╝

Welcome! The search and index system is now available.

Quick Start:
  1. Build the index:      bashd_index_build  (or 'bdi')
  2. Search for something: bashd_search docker  (or 'bds docker')
  3. Get help:             bashd_help  (or 'bdh')

Interactive fuzzy search: bashd_fuzzy  (or 'bdz') - requires fzf

Run 'bashd_help' to see all available commands.

EOF
    fi
}

# Run the loader
_bashd_main_loader

# Clean up loader functions from environment
unset -f _bashd_main_loader
unset -f _bashd_create_search_aliases
unset -f _bashd_init_search_system
unset -f _bashd_check_dependencies
unset -f _bashd_load_search_system
