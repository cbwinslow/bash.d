#!/bin/bash
#===============================================================================
#
#          FILE:  utilities.sh
#
#         USAGE:  bashd_sort, bashd_describe, bashd_next, bashd_prev, etc.
#
#   DESCRIPTION:  Utility functions for managing and navigating bash.d content
#                 Includes sorting, description, navigation, and statistics
#
#       OPTIONS:  See individual function help
#  REQUIREMENTS:  jq
#         NOTES:  Works with index system for optimal performance
#        AUTHOR:  bash.d project
#       VERSION:  2.0.0
#===============================================================================

# Session variables for navigation
export BASHD_SEARCH_RESULTS=()
export BASHD_CURRENT_INDEX=0

# Sort functions by various criteria
bashd_sort() {
    local criteria="${1:-name}"  # name, size, date, usage, category
    local order="${2:-asc}"      # asc, desc
    local type="${3:-functions}" # functions, aliases, scripts, all
    
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        cat << 'EOF'
Usage: bashd_sort [criteria] [order] [type]

Sort functions, aliases, or scripts by various criteria

Criteria:
  name      Sort alphabetically by name (default)
  size      Sort by file size
  date      Sort by last modification date
  usage     Sort by usage frequency (if tracked)
  category  Sort by category name
  lines     Sort by line count

Order:
  asc       Ascending order (default)
  desc      Descending order
  
Type:
  functions Functions only (default)
  aliases   Aliases only
  scripts   Scripts only
  all       Everything

Examples:
  bashd_sort name asc             # Sort functions A-Z
  bashd_sort size desc            # Sort by size, largest first
  bashd_sort date desc functions  # Sort functions by date, newest first
  bashd_sort category asc all     # Sort everything by category
EOF
        return 0
    fi
    
    local index_file="${BASHD_INDEX_FILE}"
    
    if [[ ! -f "$index_file" ]]; then
        echo "Index not found. Run: bashd_index_build"
        return 1
    fi
    
    echo "Sorting $type by $criteria ($order)"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    local jq_filter=""
    local sort_field=""
    
    case "$criteria" in
        name)
            sort_field=".key"
            ;;
        size)
            sort_field=".value.file_size // 0"
            ;;
        date)
            sort_field=".value.last_modified // 0"
            ;;
        lines)
            sort_field=".value.line_count // 0"
            ;;
        category)
            sort_field=".value.category // \"unknown\""
            ;;
        *)
            sort_field=".key"
            ;;
    esac
    
    local sort_order="sort_by($sort_field)"
    if [[ "$order" == "desc" ]]; then
        sort_order="$sort_order | reverse"
    fi
    
    # Build type filter
    local type_selector=""
    case "$type" in
        functions)
            type_selector=".functions"
            ;;
        aliases)
            type_selector=".aliases"
            ;;
        scripts)
            type_selector=".scripts"
            ;;
        all)
            type_selector="(.functions + .aliases + .scripts)"
            ;;
        *)
            type_selector=".functions"
            ;;
    esac
    
    # Execute sort and display
    jq -r "
        $type_selector | to_entries | $sort_order | .[] |
        \"\(.key) [\(.value.category // \"N/A\")] - \(.value.description // \"No description\")\"
    " "$index_file"
}

# Show detailed description of a function/script
bashd_describe() {
    local item_name="$1"
    local show_source="${2:-false}"
    
    if [[ -z "$item_name" ]]; then
        cat << 'EOF'
Usage: bashd_describe <name> [show_source]

Show detailed information about a function, alias, or script

Arguments:
  name         Name of the item to describe
  show_source  Set to 'true' to include source code (default: false)

Examples:
  bashd_describe docker_cleanup
  bashd_describe git.aliases
  bashd_describe network_scan true   # Include source code
EOF
        return 1
    fi
    
    local index_file="${BASHD_INDEX_FILE}"
    local repo_root="${BASHD_HOME:-$HOME/.bash.d}"
    
    # Try to find in index
    if [[ -f "$index_file" ]]; then
        local item_data=$(jq -r --arg name "$item_name" '
            .functions[$name] // .aliases[$name] // .scripts[$name] // null
        ' "$index_file")
        
        if [[ "$item_data" != "null" && -n "$item_data" ]]; then
            echo "╔══════════════════════════════════════════════════════════════╗"
            echo "║  Description: $item_name"
            echo "╚══════════════════════════════════════════════════════════════╝"
            echo ""
            
            # Extract and display all fields
            echo "$item_data" | jq -r '
                "Name:         \(.name // "N/A")",
                "Category:     \(.category // "N/A")",
                "File:         \(.file // "N/A")",
                "Description:  \(.description // "No description")",
                "",
                "Details:",
                "  Version:      \(.version // "N/A")",
                "  Author:       \(.author // "N/A")",
                "  Requirements: \(.requirements // "None specified")",
                "  Line Count:   \(.line_count // "N/A")",
                "  File Size:    \(.file_size // "N/A") bytes",
                "",
                "Functions Defined: \(.functions // "N/A")",
                "",
                "Usage:",
                "  \(.usage // "No usage information")"
            '
            
            # Show source if requested
            if [[ "$show_source" == "true" ]]; then
                local file_path=$(echo "$item_data" | jq -r '.full_path // .file')
                if [[ -f "$file_path" ]]; then
                    echo ""
                    echo "Source Code:"
                    echo "────────────────────────────────────────────────────────────"
                    if command -v bat >/dev/null 2>&1; then
                        bat --style=numbers --color=always "$file_path"
                    else
                        cat -n "$file_path"
                    fi
                fi
            fi
            
            return 0
        fi
    fi
    
    # Fallback: direct file search
    local file=$(find "$repo_root" -name "${item_name}.sh" -o -name "${item_name}.bash" 2>/dev/null | head -1)
    
    if [[ -f "$file" ]]; then
        echo "Description: $item_name"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "File: $file"
        echo ""
        head -40 "$file" | grep "^#"
        
        if [[ "$show_source" == "true" ]]; then
            echo ""
            echo "Source:"
            echo "───────"
            cat "$file"
        fi
    else
        echo "Item not found: $item_name"
        return 1
    fi
}

# Navigate to next item in search results
bashd_next() {
    if [[ ${#BASHD_SEARCH_RESULTS[@]} -eq 0 ]]; then
        echo "No active search results. Use bashd_search first."
        return 1
    fi
    
    BASHD_CURRENT_INDEX=$((BASHD_CURRENT_INDEX + 1))
    
    if [[ $BASHD_CURRENT_INDEX -ge ${#BASHD_SEARCH_RESULTS[@]} ]]; then
        BASHD_CURRENT_INDEX=$((${#BASHD_SEARCH_RESULTS[@]} - 1))
        echo "At last result"
    fi
    
    local current_item="${BASHD_SEARCH_RESULTS[$BASHD_CURRENT_INDEX]}"
    echo "[$((BASHD_CURRENT_INDEX + 1))/${#BASHD_SEARCH_RESULTS[@]}] $current_item"
    bashd_describe "$current_item"
}

# Navigate to previous item in search results
bashd_prev() {
    if [[ ${#BASHD_SEARCH_RESULTS[@]} -eq 0 ]]; then
        echo "No active search results. Use bashd_search first."
        return 1
    fi
    
    BASHD_CURRENT_INDEX=$((BASHD_CURRENT_INDEX - 1))
    
    if [[ $BASHD_CURRENT_INDEX -lt 0 ]]; then
        BASHD_CURRENT_INDEX=0
        echo "At first result"
    fi
    
    local current_item="${BASHD_SEARCH_RESULTS[$BASHD_CURRENT_INDEX]}"
    echo "[$((BASHD_CURRENT_INDEX + 1))/${#BASHD_SEARCH_RESULTS[@]}] $current_item"
    bashd_describe "$current_item"
}

# Jump to first result
bashd_first() {
    if [[ ${#BASHD_SEARCH_RESULTS[@]} -eq 0 ]]; then
        echo "No active search results. Use bashd_search first."
        return 1
    fi
    
    BASHD_CURRENT_INDEX=0
    local current_item="${BASHD_SEARCH_RESULTS[$BASHD_CURRENT_INDEX]}"
    echo "[1/${#BASHD_SEARCH_RESULTS[@]}] $current_item"
    bashd_describe "$current_item"
}

# Jump to last result
bashd_last() {
    if [[ ${#BASHD_SEARCH_RESULTS[@]} -eq 0 ]]; then
        echo "No active search results. Use bashd_search first."
        return 1
    fi
    
    BASHD_CURRENT_INDEX=$((${#BASHD_SEARCH_RESULTS[@]} - 1))
    local current_item="${BASHD_SEARCH_RESULTS[$BASHD_CURRENT_INDEX]}"
    echo "[${#BASHD_SEARCH_RESULTS[@]}/${#BASHD_SEARCH_RESULTS[@]}] $current_item"
    bashd_describe "$current_item"
}

# Show recently modified or used functions
bashd_recent() {
    local count="${1:-10}"
    local type="${2:-modified}"  # modified, used
    
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        cat << 'EOF'
Usage: bashd_recent [count] [type]

Show recently modified or used functions

Arguments:
  count  Number of items to show (default: 10)
  type   Type of recency: 'modified' or 'used' (default: modified)

Examples:
  bashd_recent              # Show 10 most recently modified
  bashd_recent 20           # Show 20 most recently modified
  bashd_recent 10 used      # Show 10 most recently used (from history)
EOF
        return 0
    fi
    
    local repo_root="${BASHD_HOME:-$HOME/.bash.d}"
    
    echo "Recently $type (last $count):"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    if [[ "$type" == "modified" ]]; then
        # Show recently modified files
        find "${repo_root}/bash_functions.d" -name "*.sh" -type f -printf '%T@ %p\n' 2>/dev/null | \
            sort -rn | head -n "$count" | while read -r timestamp file; do
            local name=$(basename "$file" .sh)
            local category=$(basename "$(dirname "$file")")
            local date=$(date -d "@${timestamp%.*}" '+%Y-%m-%d %H:%M' 2>/dev/null || date -r "${timestamp%.*}" '+%Y-%m-%d %H:%M')
            echo "  $date  $name [$category]"
        done
    else
        # Show recently used from history
        echo "Analyzing bash history..."
        
        # Get all function names
        local all_funcs=$(find "${repo_root}/bash_functions.d" -name "*.sh" -type f -exec basename {} .sh \; 2>/dev/null | sort -u)
        
        # Search history for these functions
        for func in $all_funcs; do
            local usage_count=$(grep -c "^${func}" ~/.bash_history 2>/dev/null || echo 0)
            if [[ "$usage_count" -gt 0 ]]; then
                echo "$usage_count $func"
            fi
        done | sort -rn | head -n "$count" | while read -r count func; do
            echo "  Used $count times: $func"
        done
    fi
}

# Show popular/most used functions
bashd_popular() {
    local count="${1:-10}"
    
    echo "Most popular functions (top $count):"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    bashd_recent "$count" used
}

# Save current search session
bashd_save() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        echo "Usage: bashd_save <session_name>"
        echo ""
        echo "Save current search results for later recall"
        echo ""
        echo "Examples:"
        echo "  bashd_save docker_functions"
        echo "  bashd_save network_utils"
        return 1
    fi
    
    local session_dir="${BASHD_INDEX_DIR:-${BASHD_HOME:-$HOME/.bash.d}/.index}/sessions"
    mkdir -p "$session_dir"
    
    local session_file="${session_dir}/${session_name}.json"
    
    # Save search results and current index
    cat > "$session_file" << EOF
{
  "name": "$session_name",
  "saved_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "results": [$(printf '"%s",' "${BASHD_SEARCH_RESULTS[@]}" | sed 's/,$//')],
  "current_index": $BASHD_CURRENT_INDEX
}
EOF
    
    echo "✓ Session saved: $session_name"
    echo "  Results: ${#BASHD_SEARCH_RESULTS[@]} items"
    echo "  File: $session_file"
}

# Recall saved search session
bashd_recall_session() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        echo "Usage: bashd_recall_session <session_name>"
        echo ""
        echo "Available sessions:"
        local session_dir="${BASHD_INDEX_DIR:-${BASHD_HOME:-$HOME/.bash.d}/.index}/sessions"
        if [[ -d "$session_dir" ]]; then
            for session in "$session_dir"/*.json; do
                if [[ -f "$session" ]]; then
                    local name=$(basename "$session" .json)
                    local saved=$(jq -r '.saved_at' "$session" 2>/dev/null)
                    local count=$(jq -r '.results | length' "$session" 2>/dev/null)
                    echo "  $name ($count results, saved: $saved)"
                fi
            done
        else
            echo "  (no saved sessions)"
        fi
        return 1
    fi
    
    local session_dir="${BASHD_INDEX_DIR:-${BASHD_HOME:-$HOME/.bash.d}/.index}/sessions"
    local session_file="${session_dir}/${session_name}.json"
    
    if [[ ! -f "$session_file" ]]; then
        echo "Session not found: $session_name"
        return 1
    fi
    
    # Load session
    mapfile -t BASHD_SEARCH_RESULTS < <(jq -r '.results[]' "$session_file")
    BASHD_CURRENT_INDEX=$(jq -r '.current_index' "$session_file")
    
    echo "✓ Session recalled: $session_name"
    echo "  Results: ${#BASHD_SEARCH_RESULTS[@]} items"
    echo ""
    
    # Show current item
    if [[ ${#BASHD_SEARCH_RESULTS[@]} -gt 0 ]]; then
        bashd_describe "${BASHD_SEARCH_RESULTS[$BASHD_CURRENT_INDEX]}"
    fi
}

# Quick edit from index
bashd_edit() {
    local item_name="$1"
    
    if [[ -z "$item_name" ]]; then
        echo "Usage: bashd_edit <name>"
        echo ""
        echo "Quickly edit a function, alias, or script"
        echo ""
        echo "Examples:"
        echo "  bashd_edit docker_cleanup"
        echo "  bashd_edit git.aliases"
        return 1
    fi
    
    local repo_root="${BASHD_HOME:-$HOME/.bash.d}"
    local index_file="${BASHD_INDEX_FILE}"
    
    # Try index first
    if [[ -f "$index_file" ]]; then
        local file_path=$(jq -r --arg name "$item_name" '
            (.functions[$name] // .aliases[$name] // .scripts[$name]).full_path // empty
        ' "$index_file")
        
        if [[ -n "$file_path" && -f "$file_path" ]]; then
            "${EDITOR:-vim}" "$file_path"
            return 0
        fi
    fi
    
    # Fallback search
    local file=$(find "$repo_root" -name "${item_name}.sh" -o -name "${item_name}.bash" 2>/dev/null | head -1)
    
    if [[ -f "$file" ]]; then
        "${EDITOR:-vim}" "$file"
    else
        echo "Item not found: $item_name"
        echo ""
        echo "Did you mean one of these?"
        find "$repo_root" -name "*${item_name}*" -type f 2>/dev/null | head -5
        return 1
    fi
}

# Export functions
export -f bashd_sort 2>/dev/null
export -f bashd_describe 2>/dev/null
export -f bashd_next 2>/dev/null
export -f bashd_prev 2>/dev/null
export -f bashd_first 2>/dev/null
export -f bashd_last 2>/dev/null
export -f bashd_recent 2>/dev/null
export -f bashd_popular 2>/dev/null
export -f bashd_save 2>/dev/null
export -f bashd_recall_session 2>/dev/null
export -f bashd_edit 2>/dev/null
