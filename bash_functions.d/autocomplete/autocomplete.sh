#!/bin/bash
#===============================================================================
#
#          FILE:  autocomplete.sh
#
#         USAGE:  Automatically sourced by .bashrc
#
#   DESCRIPTION:  Advanced autocomplete functions using bash_history
#                 and intelligent command completion
#
#       OPTIONS:  ---
#  REQUIREMENTS:  bash 4.0+
#         NOTES:  Uses readline and compgen for completion
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

#===============================================================================
# HISTORY-BASED AUTOCOMPLETE
#===============================================================================

# Enable history-based completion with Ctrl+R improvements
_setup_history_completion() {
    # Enable incremental history search
    bind '"\C-r": reverse-search-history'
    bind '"\C-s": forward-search-history'
    
    # Enable history expansion on space
    bind 'Space: magic-space'
    
    # Better up/down arrow history search (search based on current input)
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
    bind '"\eOA": history-search-backward'
    bind '"\eOB": history-search-forward'
    
    # Alt+. to insert last argument from previous command
    bind '"\e.": insert-last-argument'
    
    # Ctrl+] to search character forward
    bind '"\C-]": character-search'
    
    # Show all if ambiguous
    bind 'set show-all-if-ambiguous on'
    
    # Color completion based on file type
    bind 'set colored-stats on'
    
    # Mark symlinked directories
    bind 'set mark-symlinked-directories on'
    
    # Color the common prefix
    bind 'set colored-completion-prefix on'
    
    # Menu complete on tab
    bind 'set menu-complete-display-prefix on'
    
    # Case insensitive completion
    bind 'set completion-ignore-case on'
    
    # Treat hyphens and underscores as equivalent
    bind 'set completion-map-case on'
    
    # Show visible characters for control characters
    bind 'set visible-stats on'
    
    # Enable bracketed paste mode
    bind 'set enable-bracketed-paste on'
}

# Call setup if we're in an interactive shell
if [[ $- == *i* ]]; then
    _setup_history_completion
fi

#===============================================================================
# INTELLIGENT COMMAND COMPLETION
#===============================================================================

# Complete commands from history
_complete_from_history() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local history_completions
    
    # Get unique commands from history that start with the current word
    history_completions=$(history | awk '{print $2}' | grep "^${cur}" | sort -u)
    
    COMPREPLY=($(compgen -W "$history_completions" -- "$cur"))
}

# Complete directory paths with previews
_complete_dir() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=($(compgen -d -- "$cur"))
}

# Complete files with extensions
_complete_file_ext() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local ext="${1:-*}"
    COMPREPLY=($(compgen -G "${cur}*.${ext}" 2>/dev/null))
}

#===============================================================================
# CUSTOM COMPLETIONS FOR bash_functions.d
#===============================================================================

# Completion for func_add
_func_add_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local repo_dir="${BASH_D_REPO:-$HOME/bash.d}"
    local functions_dir="${repo_dir}/bash_functions.d"
    
    # If completing the second argument (category)
    if [[ $COMP_CWORD -eq 2 ]]; then
        local categories
        categories=$(find "$functions_dir" -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | tail -n +2)
        COMPREPLY=($(compgen -W "$categories" -- "$cur"))
    fi
}

# Completion for func_edit, func_recall, func_info
_func_name_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local repo_dir="${BASH_D_REPO:-$HOME/bash.d}"
    local functions_dir="${repo_dir}/bash_functions.d"
    
    local func_names
    func_names=$(find "$functions_dir" -name "*.sh" -type f -exec basename {} .sh \; 2>/dev/null)
    COMPREPLY=($(compgen -W "$func_names" -- "$cur"))
}

# Completion for help_me
_help_me_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # If completing the second argument (source)
    if [[ $COMP_CWORD -eq 2 ]]; then
        COMPREPLY=($(compgen -W "man tldr help cheat func all" -- "$cur"))
        return
    fi
    
    # Complete command names
    COMPREPLY=($(compgen -c -- "$cur"))
}

# Register completions
if [[ $- == *i* ]]; then
    complete -F _func_add_completions func_add
    complete -F _func_name_completions func_edit
    complete -F _func_name_completions func_recall
    complete -F _func_name_completions func_info
    complete -F _func_name_completions func_remove
    complete -F _help_me_completions help_me
    complete -F _help_me_completions quickref
fi

#===============================================================================
# FZF-BASED COMPLETIONS (if fzf is available)
#===============================================================================

if command -v fzf >/dev/null 2>&1; then
    # History search with fzf
    fzf_history() {
        local selected
        selected=$(history | fzf --tac --no-sort --height 40% --query "$READLINE_LINE" | sed 's/^[ ]*[0-9]*[ ]*//')
        if [[ -n "$selected" ]]; then
            READLINE_LINE="$selected"
            READLINE_POINT=${#READLINE_LINE}
        fi
    }
    
    # Bind to Ctrl+R if in interactive shell
    if [[ $- == *i* ]]; then
        bind -x '"\C-r": fzf_history'
    fi
    
    # File search with fzf
    fzf_file() {
        local selected
        selected=$(find . -type f 2>/dev/null | fzf --height 40% --preview 'head -100 {}')
        if [[ -n "$selected" ]]; then
            READLINE_LINE="${READLINE_LINE}${selected}"
            READLINE_POINT=${#READLINE_LINE}
        fi
    }
    
    # Directory search with fzf
    fzf_dir() {
        local selected
        selected=$(find . -type d 2>/dev/null | fzf --height 40% --preview 'ls -la {}')
        if [[ -n "$selected" ]]; then
            cd "$selected" || return 1
        fi
    }
    
    # Git branch selector with fzf
    fzf_git_branch() {
        local selected
        selected=$(git branch --all 2>/dev/null | fzf --height 40%)
        if [[ -n "$selected" ]]; then
            git checkout "$(echo "$selected" | sed 's/^[* ]*//;s/remotes\/origin\///')"
        fi
    }
    
    # Process killer with fzf
    fzf_kill() {
        local pid
        pid=$(ps -ef | sed 1d | fzf -m --height 40% | awk '{print $2}')
        if [[ -n "$pid" ]]; then
            echo "Kill process(es): $pid? (y/n)"
            read -r response
            if [[ "$response" =~ ^[Yy] ]]; then
                echo "$pid" | xargs kill -9
            fi
        fi
    }
    
    # Export fzf functions
    export -f fzf_history 2>/dev/null
    export -f fzf_file 2>/dev/null
    export -f fzf_dir 2>/dev/null
    export -f fzf_git_branch 2>/dev/null
    export -f fzf_kill 2>/dev/null
fi

#===============================================================================
# SSH HOST COMPLETION
#===============================================================================

_complete_ssh_hosts() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local hosts=""
    
    # From ~/.ssh/config
    if [[ -f ~/.ssh/config ]]; then
        hosts="$hosts $(grep -iE '^Host[[:space:]]' ~/.ssh/config | awk '{print $2}' | grep -v '[*?]')"
    fi
    
    # From /etc/hosts
    if [[ -f /etc/hosts ]]; then
        hosts="$hosts $(grep -v '^#' /etc/hosts | awk '{print $2}')"
    fi
    
    # From ~/.ssh/known_hosts
    if [[ -f ~/.ssh/known_hosts ]]; then
        hosts="$hosts $(cut -d' ' -f1 ~/.ssh/known_hosts | cut -d, -f1 | grep -v '^\[' | sort -u)"
    fi
    
    COMPREPLY=($(compgen -W "$hosts" -- "$cur"))
}

if [[ $- == *i* ]]; then
    complete -F _complete_ssh_hosts ssh scp sftp
fi

#===============================================================================
# DOCKER COMPLETIONS (enhanced)
#===============================================================================

if command -v docker >/dev/null 2>&1; then
    _docker_container_names() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local containers
        containers=$(docker ps --format '{{.Names}}' 2>/dev/null)
        COMPREPLY=($(compgen -W "$containers" -- "$cur"))
    }
    
    _docker_image_names() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local images
        images=$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null)
        COMPREPLY=($(compgen -W "$images" -- "$cur"))
    }
fi

#===============================================================================
# GIT COMPLETIONS (enhanced)
#===============================================================================

if command -v git >/dev/null 2>&1; then
    _git_branch_names() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local branches
        branches=$(git branch --list --format='%(refname:short)' 2>/dev/null)
        COMPREPLY=($(compgen -W "$branches" -- "$cur"))
    }
    
    _git_tag_names() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local tags
        tags=$(git tag --list 2>/dev/null)
        COMPREPLY=($(compgen -W "$tags" -- "$cur"))
    }
fi

#===============================================================================
# PROGRAMMABLE COMPLETION FOR COMMON COMMANDS
#===============================================================================

# Make completion
if [[ $- == *i* ]]; then
    complete -W '$(make -qp 2>/dev/null | grep -E "^[a-zA-Z0-9_-]+:" | cut -d: -f1)' make
fi

# Systemctl completion
if command -v systemctl >/dev/null 2>&1 && [[ $- == *i* ]]; then
    _systemctl_units() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local units
        units=$(systemctl list-unit-files --no-pager 2>/dev/null | awk '{print $1}')
        COMPREPLY=($(compgen -W "$units" -- "$cur"))
    }
fi
