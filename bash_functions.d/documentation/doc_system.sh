#!/bin/bash
#===============================================================================
#
#          FILE:  doc_system.sh
#
#         USAGE:  doc_lookup <command> [source]
#                 doc_cache <command>
#                 doc_update
#                 doc_search <query>
#
#   DESCRIPTION:  Enhanced documentation system with cheat.sh, man pages,
#                 tldr, and function documentation integration
#
#       OPTIONS:  command - The command to get documentation for
#                 source - Specific source: cheat, man, tldr, func, all
#  REQUIREMENTS:  curl, man, tldr (optional), cheat (optional)
#         NOTES:  Caches documentation locally for offline access
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Configuration
DOC_CACHE_DIR="${HOME}/.cache/bashd_docs"
mkdir -p "$DOC_CACHE_DIR"

# Unified documentation lookup with caching
doc_lookup() {
    local command="${1}"
    local source="${2}"
    local cache_file="${DOC_CACHE_DIR}/${command}.txt"

    if [[ -z "$command" ]]; then
        echo "Usage: doc_lookup <command> [source]"
        echo ""
        echo "Sources:"
        echo "  cheat   - cheat.sh community cheatsheets"
        echo "  man     - Traditional man pages"
        echo "  tldr    - Community-driven examples"
        echo "  func    - Search bash_functions.d"
        echo "  all     - Try all sources"
        echo "  update  - Update cached documentation"
        echo ""
        echo "Examples:"
        echo "  doc_lookup git"
        echo "  doc_lookup tar cheat"
        echo "  doc_lookup ls man"
        return 1
    fi

    # Update cache if requested
    if [[ "$source" == "update" ]]; then
        doc_cache "$command"
        return $?
    fi

    # Check cache first
    if [[ -f "$cache_file" && -s "$cache_file" ]]; then
        echo "Showing cached documentation for: $command"
        echo "Last updated: $(stat -c %y "$cache_file" 2>/dev/null || echo "unknown")"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$cache_file"
        echo ""
        echo "For fresh documentation: doc_lookup $command update"
        return 0
    fi

    # If a specific source is requested
    if [[ -n "$source" ]]; then
        case "$source" in
            cheat)
                _doc_cheat "$command"
                ;;
            man)
                _doc_man "$command"
                ;;
            tldr)
                _doc_tldr "$command"
                ;;
            func)
                _doc_func "$command"
                ;;
            all)
                _doc_all "$command"
                ;;
            *)
                echo "Unknown source: $source"
                return 1
                ;;
        esac
        return $?
    fi

    # Default: try cheat.sh first (most comprehensive), then tldr, then man
    if _doc_cheat "$command"; then
        # Cache the result
        _doc_cheat "$command" > "$cache_file"
        return 0
    fi

    if _doc_tldr "$command"; then
        # Cache the result
        _doc_tldr "$command" > "$cache_file"
        return 0
    fi

    if _doc_man "$command"; then
        # Cache the result
        _doc_man "$command" > "$cache_file"
        return 0
    fi

    # Search our functions
    _doc_func "$command"
}

# Cache documentation for offline use
doc_cache() {
    local command="${1}"

    if [[ -z "$command" ]]; then
        echo "Usage: doc_cache <command>"
        return 1
    fi

    local cache_file="${DOC_CACHE_DIR}/${command}.txt"
    echo "Caching documentation for: $command"

    # Try cheat.sh first
    if _doc_cheat "$command" > "$cache_file" 2>/dev/null; then
        echo "✓ Cached cheat.sh documentation"
        return 0
    fi

    # Try tldr
    if _doc_tldr "$command" > "$cache_file" 2>/dev/null; then
        echo "✓ Cached tldr documentation"
        return 0
    fi

    # Try man
    if _doc_man "$command" > "$cache_file" 2>/dev/null; then
        echo "✓ Cached man page"
        return 0
    fi

    echo "✗ Could not cache documentation for: $command"
    return 1
}

# Update all cached documentation
doc_update() {
    echo "Updating documentation cache..."
    local count=0

    # Update for all commands we've cached
    for cache_file in "$DOC_CACHE_DIR"/*.txt; do
        if [[ -f "$cache_file" ]]; then
            local command
            command=$(basename "$cache_file" .txt)
            if doc_cache "$command"; then
                ((count++))
            fi
        fi
    done

    echo "Updated $count documentation entries"
}

# Search documentation cache
doc_search() {
    local query="${1}"

    if [[ -z "$query" ]]; then
        echo "Usage: doc_search <query>"
        return 1
    fi

    echo "Searching documentation cache for: $query"
    echo ""

    # Search in cached files
    grep -l "$query" "$DOC_CACHE_DIR"/*.txt 2>/dev/null | while read -r cache_file; do
        local command
        command=$(basename "$cache_file" .txt)
        echo "Found in: $command"
        echo "─────────────────────────────────────────────────────────────────"
        grep -A 3 -B 3 "$query" "$cache_file" | head -20
        echo ""
    done

    if [[ $? -ne 0 ]]; then
        echo "No cached documentation found for: $query"
        echo "Try: doc_lookup $query"
    fi
}

# cheat.sh integration
_doc_cheat() {
    local command="${1}"

    if ! command -v curl >/dev/null 2>&1; then
        echo "curl is required for cheat.sh integration"
        return 1
    fi

    echo "Fetching cheat.sh documentation for: $command"
    echo ""

    # Use cheat.sh API
    curl -s "https://cheat.sh/$command" || return 1

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Source: cheat.sh"
    echo "Cache: doc_cache $command"
}

# Man page viewer
_doc_man() {
    local command="${1}"

    if man "$command" 2>/dev/null; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Source: man page"
        echo "Cache: doc_cache $command"
        return 0
    fi

    return 1
}

# TLDR help
_doc_tldr() {
    local command="${1}"

    if command -v tldr >/dev/null 2>&1; then
        if tldr "$command" 2>/dev/null; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Source: tldr"
            echo "Cache: doc_cache $command"
            return 0
        fi
    else
        echo "tldr is not installed."
        echo "Install with: npm install -g tldr"
        return 1
    fi

    return 1
}

# Search bash_functions.d
_doc_func() {
    local search_term="${1}"
    local repo_dir="${BASH_D_REPO:-$HOME/bash.d}"
    local functions_dir="${repo_dir}/bash_functions.d"

    if [[ ! -d "$functions_dir" ]]; then
        echo "bash_functions.d not found"
        return 1
    fi

    # Search for function by name
    local found_file
    found_file=$(find "$functions_dir" -name "${search_term}.sh" -type f 2>/dev/null | head -1)

    if [[ -n "$found_file" ]]; then
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║  bash_functions.d: $search_term"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""

        # Extract and display usage info from header
        sed -n '/#.*USAGE/,/#.*[A-Z]\{4,\}/p' "$found_file" | head -20
        echo ""

        # Show function signature
        echo "Function signature:"
        grep -E "^${search_term}\(\)" "$found_file" | head -5

        return 0
    fi

    # Search in function content
    echo "Searching bash_functions.d for '$search_term'..."
    grep -l "$search_term" "$functions_dir"/*/*.sh 2>/dev/null | while read -r file; do
        echo "  Found in: $(basename "$file" .sh)"
    done

    return 0
}

# Show help from all sources
_doc_all() {
    local command="${1}"

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Documentation for: $command"
    echo "╚════════════════════════════════════════════════════════════════╝"

    echo ""
    echo "=== cheat.sh ==="
    _doc_cheat "$command" 2>/dev/null || echo "  (not available)"

    echo ""
    echo "=== TLDR ==="
    _doc_tldr "$command" 2>/dev/null || echo "  (not available)"

    echo ""
    echo "=== bash_functions.d ==="
    _doc_func "$command" 2>/dev/null || echo "  (not available)"

    echo ""
    echo "=== Man Page (first 50 lines) ==="
    man "$command" 2>/dev/null | head -50 || echo "  (not available)"
}

# Documentation autocomplete
_doc_autocomplete() {
    local current_word="${1}"

    if [[ -z "$current_word" ]]; then
        # List all cached commands
        ls "$DOC_CACHE_DIR" 2>/dev/null | sed 's/\.txt$//'
        return
    fi

    # Filter cached commands
    ls "$DOC_CACHE_DIR" 2>/dev/null | sed 's/\.txt$//' | grep "^$current_word"
}

# Show documentation system help
doc_help() {
    cat << 'EOF'
Documentation System Commands:

  doc_lookup <command> [source]  - Lookup documentation (cheat.sh > tldr > man)
  doc_cache <command>           - Cache documentation for offline use
  doc_update                     - Update all cached documentation
  doc_search <query>             - Search cached documentation
  doc_help                       - Show this help message

Sources:
  cheat   - cheat.sh community cheatsheets (default priority)
  tldr    - Community-driven examples
  man     - Traditional man pages
  func    - Search bash_functions.d
  all     - Show all available sources

Examples:
  doc_lookup git
  doc_lookup tar cheat
  doc_lookup ls man
  doc_cache git
  doc_update
  doc_search "recursive delete"
EOF
}

# Export functions
export -f doc_lookup 2>/dev/null
export -f doc_cache 2>/dev/null
export -f doc_update 2>/dev/null
export -f doc_search 2>/dev/null
export -f _doc_cheat 2>/dev/null
export -f _doc_man 2>/dev/null
export -f _doc_tldr 2>/dev/null
export -f _doc_func 2>/dev/null
export -f _doc_all 2>/dev/null
export -f _doc_autocomplete 2>/dev/null
export -f doc_help 2>/dev/null
