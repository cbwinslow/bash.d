#!/bin/bash
#===============================================================================
#
#          FILE:  search.sh
#
#         USAGE:  bashd_search <term>
#                 bashd_find <pattern>
#                 bashd_locate <name>
#                 bashd_fuzzy [term]
#
#   DESCRIPTION:  Comprehensive search system for bash.d repository
#                 Provides multiple search methods with different use cases
#
#       OPTIONS:  See individual function help
#  REQUIREMENTS:  jq, grep, fzf (optional)
#         NOTES:  Uses index for fast searches when available
#        AUTHOR:  bash.d project
#       VERSION:  2.0.0
#===============================================================================

# Unified search across all content types
bashd_search() {
    local search_term="$1"
    local search_type="${2:-all}"  # all, functions, aliases, scripts, content
    
    if [[ -z "$search_term" ]]; then
        cat << 'EOF'
Usage: bashd_search <term> [type]

Search for functions, aliases, scripts, and content in bash.d

Types:
  all         Search everything (default)
  functions   Search only functions
  aliases     Search only aliases
  scripts     Search only scripts
  content     Full-text search in file contents
  
Examples:
  bashd_search docker            # Find all docker-related items
  bashd_search git functions     # Search only in functions
  bashd_search "network" content # Search file contents

Options:
  -i, --interactive  Use interactive fuzzy search (requires fzf)
  -v, --verbose      Show detailed information
  -c, --count        Show only count of matches
EOF
        return 1
    fi
    
    # Parse options
    local interactive=false
    local verbose=false
    local count_only=false
    
    while [[ "$1" =~ ^- ]]; do
        case "$1" in
            -i|--interactive) interactive=true; shift ;;
            -v|--verbose) verbose=true; shift ;;
            -c|--count) count_only=true; shift ;;
            *) shift ;;
        esac
    done
    
    local index_file="${BASHD_INDEX_FILE:-${BASHD_HOME:-$HOME/.bash.d}/.index/master_index.json}"
    
    # Use index if available
    if [[ -f "$index_file" ]]; then
        _bashd_search_indexed "$search_term" "$search_type" "$verbose" "$count_only"
    else
        echo "Note: Index not found. Using slower direct search."
        echo "Run 'bashd_index_build' for faster searches."
        echo ""
        _bashd_search_direct "$search_term" "$search_type"
    fi
}

# Search using index (fast)
_bashd_search_indexed() {
    local term="$1"
    local type="$2"
    local verbose="$3"
    local count_only="$4"
    
    local index_file="${BASHD_INDEX_FILE}"
    
    echo "Searching for: '$term' (type: $type)"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    local result_count=0
    local temp_results="${BASHD_INDEX_DIR}/temp_results.$$"
    
    # Search functions
    if [[ "$type" == "all" || "$type" == "functions" ]]; then
        echo "Functions:"
        echo "──────────"
        
        jq -r --arg term "$term" '
            .functions | to_entries | 
            map(select(
                (.key | ascii_downcase | contains($term | ascii_downcase)) or
                (.value.description | ascii_downcase | contains($term | ascii_downcase)) or
                (.value.category | ascii_downcase | contains($term | ascii_downcase)) or
                (.value.usage | ascii_downcase | contains($term | ascii_downcase))
            )) |
            if length == 0 then
                empty
            else
                .[] | "  ✓ \(.key) [\(.value.category)]|SPLIT|\(.value.description)|SPLIT|\(.value.file)"
            end
        ' "$index_file" 2>/dev/null > "$temp_results"
        
        if [[ -s "$temp_results" ]]; then
            while IFS='|SPLIT|' read -r header desc file; do
                echo "$header"
                if [[ "$verbose" == true ]]; then
                    echo "    Description: $desc"
                    echo "    File: $file"
                fi
                ((result_count++))
            done < "$temp_results"
        else
            echo "  (no matches)"
        fi
        echo ""
    fi
    
    # Search aliases
    if [[ "$type" == "all" || "$type" == "aliases" ]]; then
        echo "Aliases:"
        echo "────────"
        
        jq -r --arg term "$term" '
            .aliases | to_entries | 
            map(select(
                (.key | ascii_downcase | contains($term | ascii_downcase)) or
                (.value.description | ascii_downcase | contains($term | ascii_downcase))
            )) |
            if length == 0 then
                empty
            else
                .[] | "  ✓ \(.key)|SPLIT|\(.value.description)|SPLIT|\(.value.file)"
            end
        ' "$index_file" 2>/dev/null > "$temp_results"
        
        if [[ -s "$temp_results" ]]; then
            while IFS='|SPLIT|' read -r name desc file; do
                echo "$name"
                if [[ "$verbose" == true ]]; then
                    echo "    Description: $desc"
                    echo "    File: $file"
                fi
                ((result_count++))
            done < "$temp_results"
        else
            echo "  (no matches)"
        fi
        echo ""
    fi
    
    # Search scripts
    if [[ "$type" == "all" || "$type" == "scripts" ]]; then
        echo "Scripts:"
        echo "────────"
        
        jq -r --arg term "$term" '
            .scripts | to_entries | 
            map(select(
                (.key | ascii_downcase | contains($term | ascii_downcase)) or
                (.value.description | ascii_downcase | contains($term | ascii_downcase))
            )) |
            if length == 0 then
                empty
            else
                .[] | "  ✓ \(.key)|SPLIT|\(.value.description)"
            end
        ' "$index_file" 2>/dev/null > "$temp_results"
        
        if [[ -s "$temp_results" ]]; then
            while IFS='|SPLIT|' read -r name desc; do
                echo "$name"
                if [[ "$verbose" == true ]]; then
                    echo "    Description: $desc"
                fi
                ((result_count++))
            done < "$temp_results"
        else
            echo "  (no matches)"
        fi
        echo ""
    fi
    
    # Clean up
    rm -f "$temp_results"
    
    echo "Found $result_count matches"
}

# Direct search without index (slow but thorough)
_bashd_search_direct() {
    local term="$1"
    local type="$2"
    local repo_root="${BASHD_HOME:-$HOME/.bash.d}"
    
    echo "Searching for: '$term' (direct search)"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    if [[ "$type" == "all" || "$type" == "functions" ]]; then
        echo "Functions:"
        find "${repo_root}/bash_functions.d" -name "*${term}*.sh" -type f 2>/dev/null | while read -r file; do
            local name=$(basename "$file" .sh)
            local category=$(basename "$(dirname "$file")")
            echo "  ✓ $name [$category]"
        done
        echo ""
    fi
    
    if [[ "$type" == "content" || "$type" == "all" ]]; then
        echo "Content matches:"
        grep -r -i -n "$term" "${repo_root}/bash_functions.d" --include="*.sh" 2>/dev/null | head -20 | while IFS=: read -r file line content; do
            local name=$(basename "$file" .sh)
            echo "  ✓ $name (line $line)"
        done
        echo ""
    fi
}

# Find files/functions by pattern (supports wildcards)
bashd_find() {
    local pattern="$1"
    local search_in="${2:-functions}"  # functions, all, scripts, aliases
    
    if [[ -z "$pattern" ]]; then
        cat << 'EOF'
Usage: bashd_find <pattern> [where]

Find files matching a pattern (supports wildcards)

Where:
  functions  Search in bash_functions.d (default)
  all        Search everywhere
  scripts    Search in scripts/bin
  aliases    Search in aliases
  
Examples:
  bashd_find "docker*"           # Find all docker-related functions
  bashd_find "*network*"         # Find anything with 'network'
  bashd_find "git_*" functions   # Find git functions
  bashd_find "*.sh" all          # Find all .sh files

Wildcards:
  *    Match any characters
  ?    Match single character
  []   Match character set
EOF
        return 1
    fi
    
    local repo_root="${BASHD_HOME:-$HOME/.bash.d}"
    local search_path=""
    
    case "$search_in" in
        functions)
            search_path="${repo_root}/bash_functions.d"
            ;;
        scripts)
            search_path="${repo_root}/scripts ${repo_root}/bin"
            ;;
        aliases)
            search_path="${repo_root}/aliases"
            ;;
        all)
            search_path="$repo_root"
            ;;
        *)
            search_path="${repo_root}/bash_functions.d"
            ;;
    esac
    
    echo "Finding files matching: '$pattern' in $search_in"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    local count=0
    for path in $search_path; do
        if [[ -d "$path" ]]; then
            find "$path" -name "$pattern" -type f 2>/dev/null | while read -r file; do
                local relative="${file#$repo_root/}"
                local name=$(basename "$file")
                local dir=$(basename "$(dirname "$file")")
                echo "  ✓ $relative"
                echo "    Category: $dir"
                ((count++))
            done
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        echo "  (no matches found)"
    fi
}

# Locate - quick find by exact name
bashd_locate() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo "Usage: bashd_locate <name>"
        echo ""
        echo "Quickly locate a function, script, or alias by exact name"
        echo ""
        echo "Examples:"
        echo "  bashd_locate docker_cleanup"
        echo "  bashd_locate git.aliases"
        return 1
    fi
    
    local repo_root="${BASHD_HOME:-$HOME/.bash.d}"
    local index_file="${BASHD_INDEX_FILE}"
    
    # Try index first
    if [[ -f "$index_file" ]]; then
        local result=$(jq -r --arg name "$name" '
            .functions[$name] // .aliases[$name] // .scripts[$name] // null
        ' "$index_file")
        
        if [[ "$result" != "null" && -n "$result" ]]; then
            local file=$(echo "$result" | jq -r '.full_path // .file')
            local desc=$(echo "$result" | jq -r '.description // ""')
            local category=$(echo "$result" | jq -r '.category // ""')
            
            echo "Found: $name"
            echo "═══════════════════════════════════════════════════════════════"
            [[ -n "$category" ]] && echo "Category:    $category"
            [[ -n "$desc" ]] && echo "Description: $desc"
            echo "Location:    $file"
            echo ""
            
            # Show quick preview
            if [[ -f "$file" ]]; then
                echo "Preview:"
                echo "────────"
                head -30 "$file" | grep -v "^#" | head -10
            fi
            
            return 0
        fi
    fi
    
    # Fallback to direct search
    echo "Searching for: $name"
    echo ""
    
    # Search for .sh files
    local found=$(find "$repo_root" -name "${name}.sh" -type f 2>/dev/null | head -1)
    
    if [[ -n "$found" ]]; then
        echo "Found: $found"
        echo ""
        head -30 "$found" | grep "^#"
    else
        # Try without .sh extension
        found=$(find "$repo_root" -name "$name" -type f 2>/dev/null | head -1)
        if [[ -n "$found" ]]; then
            echo "Found: $found"
        else
            echo "Not found: $name"
            echo ""
            echo "Similar names:"
            find "$repo_root" -name "*${name}*" -type f 2>/dev/null | head -5
            return 1
        fi
    fi
}

# Fuzzy search with fzf
bashd_fuzzy() {
    local initial_query="$1"
    
    if ! command -v fzf >/dev/null 2>&1; then
        echo "Error: fzf not installed"
        echo "Install with: sudo apt install fzf  (or brew install fzf on macOS)"
        echo ""
        echo "Falling back to regular search..."
        [[ -n "$initial_query" ]] && bashd_search "$initial_query"
        return 1
    fi
    
    local repo_root="${BASHD_HOME:-$HOME/.bash.d}"
    local index_file="${BASHD_INDEX_FILE}"
    
    # Build searchable list
    local search_list=""
    
    if [[ -f "$index_file" ]]; then
        # Use index for better descriptions
        search_list=$(jq -r '
            (.functions | to_entries | .[] | "[FUNC] \(.key) - \(.value.description) (\(.value.category))"),
            (.aliases | to_entries | .[] | "[ALIAS] \(.key) - \(.value.description)"),
            (.scripts | to_entries | .[] | "[SCRIPT] \(.key)")
        ' "$index_file" 2>/dev/null)
    else
        # Build from filesystem
        search_list=$(find "${repo_root}/bash_functions.d" -name "*.sh" -type f 2>/dev/null | while read -r f; do
            local name=$(basename "$f" .sh)
            local cat=$(basename "$(dirname "$f")")
            echo "[FUNC] $name ($cat)"
        done)
    fi
    
    # Interactive fuzzy search
    local selected=$(echo "$search_list" | fzf \
        --query="$initial_query" \
        --preview='
            name=$(echo {} | sed "s/^\[.*\] //" | cut -d" " -f1)
            file=$(find '"${repo_root}"' -name "${name}.sh" -o -name "${name}.bash" 2>/dev/null | head -1)
            if [[ -n "$file" ]]; then
                if command -v bat >/dev/null 2>&1; then
                    bat --style=numbers --color=always "$file"
                else
                    cat "$file"
                fi
            fi
        ' \
        --preview-window=right:60%:wrap \
        --header="Search bash.d repository - Enter to view, Ctrl-C to cancel" \
        --border \
        --height=80%)
    
    if [[ -n "$selected" ]]; then
        local item_type=$(echo "$selected" | grep -oP '^\[\K[^\]]+')
        local item_name=$(echo "$selected" | sed 's/^\[.*\] //' | cut -d' ' -f1)
        
        echo ""
        echo "Selected: $item_name [$item_type]"
        echo ""
        
        # Show details
        bashd_locate "$item_name"
        
        echo ""
        echo "Actions:"
        echo "  1) View source"
        echo "  2) Edit file"
        echo "  3) Source/load function"
        echo "  4) Cancel"
        echo ""
        echo -n "Choose action (1-4): "
        read -r action
        
        local file=$(find "$repo_root" -name "${item_name}.sh" -o -name "${item_name}.bash" 2>/dev/null | head -1)
        
        case "$action" in
            1)
                if [[ -f "$file" ]]; then
                    if command -v bat >/dev/null 2>&1; then
                        bat "$file"
                    elif command -v less >/dev/null 2>&1; then
                        less "$file"
                    else
                        cat "$file"
                    fi
                fi
                ;;
            2)
                [[ -f "$file" ]] && "${EDITOR:-vim}" "$file"
                ;;
            3)
                if [[ -f "$file" ]]; then
                    # shellcheck source=/dev/null
                    source "$file"
                    echo "✓ Loaded: $item_name"
                fi
                ;;
            *)
                return 0
                ;;
        esac
    fi
}

# Content search (grep through files)
bashd_grep() {
    local pattern="$1"
    local context="${2:-2}"  # lines of context
    
    if [[ -z "$pattern" ]]; then
        cat << 'EOF'
Usage: bashd_grep <pattern> [context_lines]

Search for pattern in file contents (with context)

Arguments:
  pattern         Text or regex pattern to search for
  context_lines   Number of context lines (default: 2)

Examples:
  bashd_grep "docker exec"           # Find docker exec usage
  bashd_grep "function.*network" 5   # Find network functions with 5 lines context
  bashd_grep "TODO" 0                # Find TODOs without context

Options supported:
  Use standard grep options by setting BASHD_GREP_OPTS
  Example: export BASHD_GREP_OPTS="-i -E"
EOF
        return 1
    fi
    
    local repo_root="${BASHD_HOME:-$HOME/.bash.d}"
    local grep_opts="${BASHD_GREP_OPTS:--n}"
    
    echo "Searching for: '$pattern'"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    # Search in functions
    echo "In Functions:"
    # shellcheck disable=SC2086
    grep -r $grep_opts -C "$context" "$pattern" "${repo_root}/bash_functions.d" \
        --include="*.sh" --include="*.bash" \
        --color=always 2>/dev/null | head -50
    
    echo ""
    echo "In Aliases:"
    # shellcheck disable=SC2086
    grep -r $grep_opts -C "$context" "$pattern" "${repo_root}/aliases" \
        --include="*.sh" --include="*.bash" \
        --color=always 2>/dev/null | head -20
    
    echo ""
    echo "(Showing first 50 matches in functions and 20 in aliases)"
}

# Export all functions
export -f bashd_search 2>/dev/null
export -f bashd_find 2>/dev/null
export -f bashd_locate 2>/dev/null
export -f bashd_fuzzy 2>/dev/null
export -f bashd_grep 2>/dev/null
export -f _bashd_search_indexed 2>/dev/null
export -f _bashd_search_direct 2>/dev/null
