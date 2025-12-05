#!/bin/bash
# Minimal working bashrc - guaranteed to work

#          FILE:  .bashrc
#
#         USAGE:  Basic bash configuration
#
#   DESCRIPTION:  Simplified bash configuration for reliable initialization
#
#       OPTIONS:  ---
#  REQUIREMENTS:  bash 4.0+
#          BUGS:  ---
#         NOTES:  Minimal configuration to ensure bash starts properly
#        AUTHOR:  Cline
#       VERSION:  1.0.0
#       CREATED:  2025-12-03
#===============================================================================

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

#===============================================================================
# ENVIRONMENT VARIABLES
#===============================================================================
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-vim}"

# History settings
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTTIMEFORMAT="%F %T "

# Append to history, don't overwrite
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Enable extended globbing
shopt -s extglob

# Enable recursive globbing with **
shopt -s globstar 2>/dev/null

# Correct minor errors in directory names for cd
shopt -s cdspell

#===============================================================================
# PATH ADDITIONS
#===============================================================================
# Add local bin directories to PATH
[[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && PATH="$HOME/.cargo/bin:$PATH"
[[ -d "/usr/local/go/bin" ]] && PATH="/usr/local/go/bin:$PATH"
[[ -d "$HOME/go/bin" ]] && PATH="$HOME/go/bin:$PATH"

export PATH

#===============================================================================
# BASIC PROMPT
#===============================================================================
# Colors for prompt
RED='\[\033[0;31m\]'
GREEN='\[\033[0;32m\]'
YELLOW='\[\033[0;33m\]'
BLUE='\[\033[0;34m\]'
PURPLE='\[\033[0;35m\]'
CYAN='\[\033[0;36m\]'
WHITE='\[\033[0;37m\]'
RESET='\[\033[0m\]'
BOLD='\[\033[1m\]'

# Git branch in prompt
_git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null)
    if [[ -n "$branch" ]]; then
        local git_status
        git_status=$(git status --porcelain 2>/dev/null)
        if [[ -n "$git_status" ]]; then
            echo " (${branch}*)"
        else
            echo " (${branch})"
        fi
    fi
}

# Simple prompt
PS1="${BOLD}${GREEN}\u${RESET}@${BOLD}${BLUE}\h${RESET}:${CYAN}\w${YELLOW}\$(_git_branch)${RESET}\n\$ "

#===============================================================================
# BASIC ALIASES
#===============================================================================
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

#===============================================================================
# LOAD LOCAL CUSTOMIZATIONS
#===============================================================================
# Load any local customizations
if [[ -r ~/.bashrc.local ]]; then
    source ~/.bashrc.local
fi

#===============================================================================
# WELCOME MESSAGE
#===============================================================================
echo ""
echo "Welcome to $(hostname)!"
echo "Bash $(bash --version | head -n1 | cut -d' ' -f4)"
echo "Today is $(date '+%A, %B %d, %Y')"
echo ""
