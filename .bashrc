#!/bin/bash
#===============================================================================
#
#          FILE:  .bashrc
#
#         USAGE:  Source this file in your home directory or symlink it
#
#   DESCRIPTION:  Advanced bash configuration with oh-my-bash integration
#                 and modular function loading from bash_functions.d
#
#       OPTIONS:  ---
#  REQUIREMENTS:  bash 4.0+, git (optional), oh-my-bash (optional)
#          BUGS:  ---
#         NOTES:  This file sources all functions from bash_functions.d
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#       CREATED:  2024
#===============================================================================

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

#===============================================================================
# ENVIRONMENT VARIABLES
#===============================================================================
export BASH_FUNCTIONS_D="${HOME}/.bash_functions.d"
export BASH_D_REPO="${HOME}/bash.d"
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

# Autocomplete after sudo and man
complete -cf sudo
complete -cf man

#===============================================================================
# OH-MY-BASH CONFIGURATION
#===============================================================================
# Path to your oh-my-bash installation.
export OSH="${HOME}/.oh-my-bash"

# Set name of the theme to load
OSH_THEME="powerline"

# Uncomment the following line to use case-sensitive completion.
# OMB_CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# OMB_HYPHEN_SENSITIVE="false"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_OSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which completions would you like to load? (completions can be found in ~/.oh-my-bash/completions/*)
# Custom completions may be added to ~/.oh-my-bash/custom/completions/
# Example format: completions=(ssh git bundler gem pip pip3)
# Add wisely, as too many completions slow down shell startup.
completions=(
  git
  composer
  ssh
  docker
  kubectl
  npm
  pip
  pip3
)

# Which aliases would you like to load? (aliases can be found in ~/.oh-my-bash/aliases/*)
# Custom aliases may be added to ~/.oh-my-bash/custom/aliases/
# Example format: aliases=(vagrant hierarchical_history docker docker-compose)
# Add wisely, as too many aliases slow down shell startup.
aliases=(
  general
  chmod
  docker
  docker-compose
  git
  kubectl
)

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  bashmarks
  progress
  sudo
)

# Which plugins would you like conditionally loaded? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format:
#  if [ "$DISPLAY" ] || [ "$SSH" ]; then
#      plugins+=(googler hierarchical_history)
#  fi

# Source oh-my-bash if it exists
if [[ -r "${OSH}/oh-my-bash.sh" ]]; then
    source "${OSH}/oh-my-bash.sh"
fi

#===============================================================================
# SYNTAX HIGHLIGHTING (bash-preexec based)
#===============================================================================
# Enable colored output for common commands
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# GCC colors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Less colors for man pages
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

# Grep colors
export GREP_COLORS='ms=01;31:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Directory colors
if [[ -x /usr/bin/dircolors ]]; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
fi

#===============================================================================
# SOURCE BASH FUNCTIONS FROM bash_functions.d
#===============================================================================
# Function to source all .sh files from a directory
_source_bash_functions() {
    local functions_dir="${1:-$BASH_FUNCTIONS_D}"
    
    if [[ -d "$functions_dir" ]]; then
        # Source all .sh files recursively
        while IFS= read -r -d '' func_file; do
            if [[ -r "$func_file" ]]; then
                # shellcheck source=/dev/null
                source "$func_file"
            fi
        done < <(find "$functions_dir" -type f -name "*.sh" -print0 2>/dev/null)
    fi
}

# Source functions from the standard location
_source_bash_functions "$BASH_FUNCTIONS_D"

# Also source from the repo directory if it exists
if [[ -d "${BASH_D_REPO}/bash_functions.d" ]]; then
    _source_bash_functions "${BASH_D_REPO}/bash_functions.d"
fi

#===============================================================================
# PROMPT CUSTOMIZATION (fallback if oh-my-bash is not installed)
#===============================================================================
if [[ ! -r "${OSH}/oh-my-bash.sh" ]]; then
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

    # Custom prompt
    PS1="${BOLD}${GREEN}\u${RESET}@${BOLD}${BLUE}\h${RESET}:${CYAN}\w${YELLOW}\$(_git_branch)${RESET}\n\$ "
fi

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
# FZF INTEGRATION (if available)
#===============================================================================
if [[ -f ~/.fzf.bash ]]; then
    source ~/.fzf.bash
fi

# FZF default options
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_OPTS="--preview 'head -100 {}'"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

#===============================================================================
# FINAL SETUP
#===============================================================================
# Welcome message
echo ""
echo "Welcome to $(hostname)!"
echo "Bash $(bash --version | head -n1 | cut -d' ' -f4)"
echo "Today is $(date '+%A, %B %d, %Y')"
echo ""

# Load any local customizations
if [[ -r ~/.bashrc.local ]]; then
    source ~/.bashrc.local
fi
