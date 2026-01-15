#!/bin/bash
#===============================================================================
#
#          FILE:  search_completions.bash
#
#         USAGE:  Auto-sourced for bash completion
#
#   DESCRIPTION:  Tab completion for bash.d search and utility commands
#
#  REQUIREMENTS:  bash-completion
#         NOTES:  Provides intelligent completions for all search commands
#        AUTHOR:  bash.d project
#       VERSION:  2.0.0
#===============================================================================

# Completion for bashd_search
_bashd_search_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Type options
    local types="all functions aliases scripts content"
    
    # Options
    local options="-i --interactive -v --verbose -c --count"
    
    if [[ ${COMP_CWORD} -eq 2 ]]; then
        # Second argument: suggest types
        COMPREPLY=( $(compgen -W "${types}" -- "${cur}") )
    elif [[ ${cur} == -* ]]; then
        # Options
        COMPREPLY=( $(compgen -W "${options}" -- "${cur}") )
    fi
    
    return 0
}

# Completion for bashd_find
_bashd_find_completion() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    local where="functions all scripts aliases"
    
    if [[ ${COMP_CWORD} -eq 2 ]]; then
        # Second argument: where to search
        COMPREPLY=( $(compgen -W "${where}" -- "${cur}") )
    fi
    
    return 0
}

# Completion for bashd_locate, bashd_describe, bashd_edit
_bashd_item_name_completion() {
    local cur index_file
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    
    index_file="${BASHD_INDEX_FILE:-${BASHD_HOME:-$HOME/.bash.d}/.index/master_index.json}"
    
    if [[ -f "$index_file" ]] && command -v jq >/dev/null 2>&1; then
        # Get names from index
        local names=$(jq -r '(.functions // {}) | keys[]' "$index_file" 2>/dev/null)
        COMPREPLY=( $(compgen -W "${names}" -- "${cur}") )
    else
        # Fallback: get from filesystem
        local repo_root="${BASHD_HOME:-$HOME/.bash.d}"
        if [[ -d "${repo_root}/bash_functions.d" ]]; then
            local names=$(find "${repo_root}/bash_functions.d" -name "*.sh" -type f -exec basename {} .sh \; 2>/dev/null)
            COMPREPLY=( $(compgen -W "${names}" -- "${cur}") )
        fi
    fi
    
    return 0
}

# Completion for bashd_sort
_bashd_sort_completion() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    local criteria="name size date usage category lines"
    local order="asc desc"
    local types="functions aliases scripts all"
    
    case ${COMP_CWORD} in
        1)
            COMPREPLY=( $(compgen -W "${criteria}" -- "${cur}") )
            ;;
        2)
            COMPREPLY=( $(compgen -W "${order}" -- "${cur}") )
            ;;
        3)
            COMPREPLY=( $(compgen -W "${types}" -- "${cur}") )
            ;;
    esac
    
    return 0
}

# Completion for bashd_help
_bashd_help_completion() {
    local cur
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    
    local topics="search find locate fuzzy grep index sort describe navigate recent save edit"
    
    COMPREPLY=( $(compgen -W "${topics}" -- "${cur}") )
    
    return 0
}

# Completion for bashd_recent
_bashd_recent_completion() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    local types="modified used"
    
    if [[ ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=( $(compgen -W "${types}" -- "${cur}") )
    fi
    
    return 0
}

# Completion for bashd_recall_session
_bashd_recall_session_completion() {
    local cur session_dir
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    
    session_dir="${BASHD_INDEX_DIR:-${BASHD_HOME:-$HOME/.bash.d}/.index}/sessions"
    
    if [[ -d "$session_dir" ]]; then
        local sessions=$(find "$session_dir" -name "*.json" -type f -exec basename {} .json \; 2>/dev/null)
        COMPREPLY=( $(compgen -W "${sessions}" -- "${cur}") )
    fi
    
    return 0
}

# Completion for bashd_index_query
_bashd_index_query_completion() {
    local cur index_file
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    
    index_file="${BASHD_INDEX_FILE}"
    
    if [[ -f "$index_file" ]] && command -v jq >/dev/null 2>&1; then
        # Suggest categories
        local categories=$(jq -r '.categories | keys[]' "$index_file" 2>/dev/null)
        COMPREPLY=( $(compgen -W "${categories}" -- "${cur}") )
    fi
    
    return 0
}

# Register all completions
complete -F _bashd_search_completion bashd_search bds
complete -F _bashd_find_completion bashd_find bdf
complete -F _bashd_item_name_completion bashd_locate bdl
complete -F _bashd_item_name_completion bashd_describe
complete -F _bashd_item_name_completion bashd_edit bde
complete -F _bashd_sort_completion bashd_sort
complete -F _bashd_help_completion bashd_help bdh
complete -F _bashd_recent_completion bashd_recent
complete -F _bashd_recent_completion bashd_popular
complete -F _bashd_recall_session_completion bashd_recall_session
complete -F _bashd_index_query_completion bashd_index_query

# Simple completions (no special logic needed)
complete -o default bashd_grep bdg
complete -o default bashd_fuzzy bdz
complete -o nospace bashd_save
complete -o default bashd_next
complete -o default bashd_prev
complete -o default bashd_first
complete -o default bashd_last

# Index commands (no arguments needed typically)
complete -o default bashd_index_build bdi
complete -o default bashd_index_update bdiu
complete -o default bashd_index_stats bdis
