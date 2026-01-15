#!/bin/bash
#===============================================================================
#
#          FILE:  search_help.sh
#
#         USAGE:  bashd_help [command]
#
#   DESCRIPTION:  Comprehensive help system for bash.d search and utility functions
#
#       OPTIONS:  command - specific command to get help for
#  REQUIREMENTS:  None
#         NOTES:  Provides usage examples and guides
#        AUTHOR:  bash.d project
#       VERSION:  2.0.0
#===============================================================================

# Main help function
bashd_help() {
    local command="$1"
    
    if [[ -z "$command" ]]; then
        _bashd_help_overview
        return 0
    fi
    
    case "$command" in
        search|bashd_search)
            _bashd_help_search
            ;;
        find|bashd_find)
            _bashd_help_find
            ;;
        locate|bashd_locate)
            _bashd_help_locate
            ;;
        fuzzy|bashd_fuzzy)
            _bashd_help_fuzzy
            ;;
        grep|bashd_grep)
            _bashd_help_grep
            ;;
        index|bashd_index*)
            _bashd_help_index
            ;;
        sort|bashd_sort)
            _bashd_help_sort
            ;;
        describe|bashd_describe)
            _bashd_help_describe
            ;;
        navigate|nav|bashd_next|bashd_prev)
            _bashd_help_navigate
            ;;
        recent|popular|bashd_recent|bashd_popular)
            _bashd_help_recent
            ;;
        save|recall|bashd_save|bashd_recall*)
            _bashd_help_sessions
            ;;
        edit|bashd_edit)
            _bashd_help_edit
            ;;
        *)
            echo "Unknown command: $command"
            echo ""
            _bashd_help_overview
            ;;
    esac
}

_bashd_help_overview() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════╗
║                  bash.d Search & Utility System Help                     ║
╚══════════════════════════════════════════════════════════════════════════╝

A comprehensive system for organizing, indexing, and searching bash functions,
aliases, and scripts in the bash.d repository.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INDEXING COMMANDS:
  bashd_index_build      Build complete index from scratch
  bashd_index_update     Update index incrementally  
  bashd_index_stats      Show index statistics
  bashd_index_query      Query the index directly

SEARCH COMMANDS:
  bashd_search <term>    Unified search across all content
  bashd_find <pattern>   Find by filename pattern (wildcards)
  bashd_locate <name>    Quick locate by exact name
  bashd_fuzzy [term]     Interactive fuzzy search (requires fzf)
  bashd_grep <pattern>   Content search with context

UTILITY COMMANDS:
  bashd_sort [criteria]  Sort items by name, size, date, etc.
  bashd_describe <name>  Show detailed item description
  bashd_recent [count]   Show recently modified/used items
  bashd_popular [count]  Show most frequently used items
  bashd_edit <name>      Quick edit an item

NAVIGATION COMMANDS:
  bashd_next            Navigate to next search result
  bashd_prev            Navigate to previous result  
  bashd_first           Jump to first result
  bashd_last            Jump to last result

SESSION MANAGEMENT:
  bashd_save <name>          Save current search session
  bashd_recall_session <n>   Recall saved session

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

QUICK START:

1. Build the index:
   $ bashd_index_build

2. Search for something:
   $ bashd_search docker

3. Use fuzzy search for interactive exploration:
   $ bashd_fuzzy

4. Get detailed help for any command:
   $ bashd_help <command>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXAMPLES:

  # Search for all docker-related functions
  bashd_search docker

  # Find files matching a pattern
  bashd_find "network*"

  # Quickly locate and view a specific function
  bashd_locate docker_cleanup

  # Sort functions by size
  bashd_sort size desc

  # Show recently modified functions
  bashd_recent 20

  # Interactive fuzzy search
  bashd_fuzzy network

  # Search file contents for a pattern
  bashd_grep "TODO" 3

  # Save your search results
  bashd_save my_docker_search

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For detailed help on specific commands, use:
  bashd_help <command>

Available help topics:
  search, find, locate, fuzzy, grep, index, sort, describe,
  navigate, recent, save, edit

EOF
}

_bashd_help_search() {
    bashd_search -h 2>/dev/null || cat << 'EOF'
bashd_search - Unified Search System

See: bashd_search --help
EOF
}

_bashd_help_find() {
    bashd_find -h 2>/dev/null || cat << 'EOF'
bashd_find - Pattern-Based File Finder

See: bashd_find --help
EOF
}

_bashd_help_locate() {
    cat << 'EOF'
bashd_locate - Quick Exact Name Locator

USAGE: bashd_locate <name>

Quickly locate and view details of a function, script, or alias.
EOF
}

_bashd_help_fuzzy() {
    cat << 'EOF'
bashd_fuzzy - Interactive Fuzzy Search

USAGE: bashd_fuzzy [initial_query]

Requires fzf. Interactive search with live preview.
EOF
}

_bashd_help_grep() {
    bashd_grep -h 2>/dev/null || cat << 'EOF'
bashd_grep - Content Search

See: bashd_grep --help
EOF
}

_bashd_help_index() {
    cat << 'EOF'
Index System Commands

  bashd_index_build    Build complete index
  bashd_index_update   Update index
  bashd_index_stats    Show statistics
  bashd_index_query    Query index
EOF
}

_bashd_help_sort() {
    bashd_sort -h 2>/dev/null || cat << 'EOF'
bashd_sort - Sort and Organize

See: bashd_sort --help
EOF
}

_bashd_help_describe() {
    bashd_describe -h 2>/dev/null || cat << 'EOF'
bashd_describe - Detailed Descriptions

See: bashd_describe --help
EOF
}

_bashd_help_navigate() {
    cat << 'EOF'
Navigation Commands

  bashd_next     Next search result
  bashd_prev     Previous result
  bashd_first    First result
  bashd_last     Last result
EOF
}

_bashd_help_recent() {
    bashd_recent -h 2>/dev/null || cat << 'EOF'
Recent & Popular Commands

  bashd_recent [count] [type]
  bashd_popular [count]
EOF
}

_bashd_help_sessions() {
    cat << 'EOF'
Session Management

  bashd_save <name>             Save session
  bashd_recall_session <name>   Recall session
EOF
}

_bashd_help_edit() {
    cat << 'EOF'
bashd_edit - Quick Edit

USAGE: bashd_edit <name>

Opens the specified item in $EDITOR
EOF
}

# Show available help topics
bashd_help_topics() {
    cat << 'EOF'
Available Help Topics:

  index, search, find, locate, fuzzy, grep
  sort, describe, recent, popular
  navigate, save, edit

Usage: bashd_help <topic>
EOF
}

# Export functions
export -f bashd_help 2>/dev/null
export -f bashd_help_topics 2>/dev/null
export -f _bashd_help_overview 2>/dev/null
