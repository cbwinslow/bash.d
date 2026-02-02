#!/bin/bash
#===============================================================================
#
#          FILE:  func_recall.sh
#
#         USAGE:  func_recall [search_term]
#
#   DESCRIPTION:  Recall and search for functions in bash_functions.d
#                 Uses fzf for fuzzy searching if available
#
#       OPTIONS:  search_term - Optional term to filter functions
#  REQUIREMENTS:  fzf (optional, for fuzzy search)
#         NOTES:  Integrates with bash history for frequently used functions
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Recall a function - show its source code and usage
func_recall() {
    local search_term="${1}"
    local repo_dir="${BASH_D_REPO:-$HOME/bash.d}"
    local functions_dir="${repo_dir}/bash_functions.d"
    
    if [[ ! -d "$functions_dir" ]]; then
        echo "Functions directory not found: $functions_dir"
        return 1
    fi
    
    local selected_file
    
    # If fzf is available, use it for fuzzy search
    if command -v fzf >/dev/null 2>&1; then
        if [[ -n "$search_term" ]]; then
            selected_file=$(find "$functions_dir" -name "*.sh" -type f 2>/dev/null | \
                fzf --query="$search_term" \
                    --preview 'head -50 {}' \
                    --preview-window=right:60% \
                    --header="Select a function to recall")
        else
            selected_file=$(find "$functions_dir" -name "*.sh" -type f 2>/dev/null | \
                fzf --preview 'head -50 {}' \
                    --preview-window=right:60% \
                    --header="Select a function to recall")
        fi
    else
        # Fallback to basic selection
        echo "Functions matching '$search_term':"
        echo "=================================="
        
        local files
        if [[ -n "$search_term" ]]; then
            mapfile -t files < <(find "$functions_dir" -name "*${search_term}*.sh" -type f 2>/dev/null)
        else
            mapfile -t files < <(find "$functions_dir" -name "*.sh" -type f 2>/dev/null)
        fi
        
        if [[ ${#files[@]} -eq 0 ]]; then
            echo "No functions found."
            return 1
        fi
        
        local i=1
        for file in "${files[@]}"; do
            local func_name
            func_name=$(basename "$file" .sh)
            local category
            category=$(basename "$(dirname "$file")")
            echo "  $i) [$category] $func_name"
            ((i++))
        done
        
        echo ""
        echo -n "Select a function (1-${#files[@]}): "
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#files[@]} )); then
            selected_file="${files[$((selection-1))]}"
        else
            echo "Invalid selection."
            return 1
        fi
    fi
    
    if [[ -n "$selected_file" && -f "$selected_file" ]]; then
        local func_name
        func_name=$(basename "$selected_file" .sh)
        
        echo ""
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║  Function: $func_name"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""
        
        # Show syntax highlighted source if pygmentize is available
        if command -v pygmentize >/dev/null 2>&1; then
            pygmentize -l bash "$selected_file"
        elif command -v highlight >/dev/null 2>&1; then
            highlight -O ansi --syntax=bash "$selected_file"
        elif command -v bat >/dev/null 2>&1; then
            bat --style=plain --language=bash "$selected_file"
        else
            cat "$selected_file"
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Actions:"
        echo "  1) Source this function now"
        echo "  2) Edit this function"
        echo "  3) Copy to clipboard"
        echo "  4) Exit"
        echo ""
        echo -n "Choose action (1-4): "
        read -r action
        
        case "$action" in
            1)
                # shellcheck source=/dev/null
                source "$selected_file"
                echo "Function sourced. You can now use: $func_name"
                ;;
            2)
                "${EDITOR:-vim}" "$selected_file"
                ;;
            3)
                if command -v xclip >/dev/null 2>&1; then
                    cat "$selected_file" | xclip -selection clipboard
                    echo "Copied to clipboard!"
                elif command -v pbcopy >/dev/null 2>&1; then
                    cat "$selected_file" | pbcopy
                    echo "Copied to clipboard!"
                else
                    echo "Clipboard tool not available (install xclip or use pbcopy on macOS)"
                fi
                ;;
            4)
                return 0
                ;;
            *)
                echo "No action taken."
                ;;
        esac
    fi
}

# Quick function search - just shows matching function names
func_search() {
    local search_term="${1}"
    local repo_dir="${BASH_D_REPO:-$HOME/bash.d}"
    local functions_dir="${repo_dir}/bash_functions.d"
    
    if [[ -z "$search_term" ]]; then
        echo "Usage: func_search <search_term>"
        return 1
    fi
    
    echo "Searching for '$search_term' in function names and content..."
    echo ""
    
    # Search in filenames
    echo "Functions matching by name:"
    echo "==========================="
    find "$functions_dir" -name "*${search_term}*.sh" -type f 2>/dev/null | while read -r file; do
        local func_name
        func_name=$(basename "$file" .sh)
        local category
        category=$(basename "$(dirname "$file")")
        echo "  [$category] $func_name"
    done
    
    echo ""
    echo "Functions containing '$search_term' in code:"
    echo "============================================="
    grep -l "$search_term" "$functions_dir"/*/*.sh 2>/dev/null | while read -r file; do
        local func_name
        func_name=$(basename "$file" .sh)
        local category
        category=$(basename "$(dirname "$file")")
        echo "  [$category] $func_name"
    done
}

# Show recently used functions from history
func_recent() {
    local count="${1:-10}"
    
    echo "Recently used functions from history:"
    echo "======================================"
    
    # Extract function calls from bash history that match our functions
    local repo_dir="${BASH_D_REPO:-$HOME/bash.d}"
    local functions_dir="${repo_dir}/bash_functions.d"
    
    # Get list of our functions
    local our_funcs
    our_funcs=$(find "$functions_dir" -name "*.sh" -type f -exec basename {} .sh \; 2>/dev/null | sort -u)
    
    # Search history for these functions
    for func in $our_funcs; do
        local usage_count
        usage_count=$(grep -c "^${func}" ~/.bash_history 2>/dev/null || echo 0)
        if [[ "$usage_count" -gt 0 ]]; then
            echo "  $func (used $usage_count times)"
        fi
    done | sort -t'(' -k2 -rn | head -n "$count"
}

# Show function info without full source
func_info() {
    local func_name="${1}"
    local repo_dir="${BASH_D_REPO:-$HOME/bash.d}"
    local functions_dir="${repo_dir}/bash_functions.d"
    
    if [[ -z "$func_name" ]]; then
        echo "Usage: func_info <function_name>"
        return 1
    fi
    
    # Find the function file
    local found_file
    found_file=$(find "$functions_dir" -name "${func_name}.sh" -type f 2>/dev/null | head -1)
    
    if [[ -z "$found_file" ]]; then
        echo "Function not found: $func_name"
        return 1
    fi
    
    echo "Function: $func_name"
    echo "Location: $found_file"
    echo "Category: $(basename "$(dirname "$found_file")")"
    echo "Size: $(wc -l < "$found_file") lines"
    echo ""
    echo "Header Information:"
    echo "==================="
    # Extract header comments (first block of comments)
    sed -n '/^#/,/^[^#]/p' "$found_file" | head -30
}

# Export functions
export -f func_recall 2>/dev/null
export -f func_search 2>/dev/null
export -f func_recent 2>/dev/null
export -f func_info 2>/dev/null
