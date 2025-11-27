#!/bin/bash
#===============================================================================
#
#          FILE:  syntax_highlighting.sh
#
#         USAGE:  Automatically sourced by .bashrc
#
#   DESCRIPTION:  Setup syntax highlighting for the terminal including
#                 command output coloring and prompt highlighting
#
#       OPTIONS:  ---
#  REQUIREMENTS:  bash 4.0+, grc (optional), bat (optional)
#         NOTES:  Provides fallback colors if tools aren't installed
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

#===============================================================================
# COLOR DEFINITIONS
#===============================================================================

# Reset
COLOR_RESET='\033[0m'

# Regular Colors
COLOR_BLACK='\033[0;30m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_PURPLE='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_WHITE='\033[0;37m'

# Bold Colors
COLOR_BOLD_BLACK='\033[1;30m'
COLOR_BOLD_RED='\033[1;31m'
COLOR_BOLD_GREEN='\033[1;32m'
COLOR_BOLD_YELLOW='\033[1;33m'
COLOR_BOLD_BLUE='\033[1;34m'
COLOR_BOLD_PURPLE='\033[1;35m'
COLOR_BOLD_CYAN='\033[1;36m'
COLOR_BOLD_WHITE='\033[1;37m'

# Background Colors
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# Export for use in scripts
export COLOR_RESET COLOR_BLACK COLOR_RED COLOR_GREEN COLOR_YELLOW
export COLOR_BLUE COLOR_PURPLE COLOR_CYAN COLOR_WHITE
export COLOR_BOLD_BLACK COLOR_BOLD_RED COLOR_BOLD_GREEN COLOR_BOLD_YELLOW
export COLOR_BOLD_BLUE COLOR_BOLD_PURPLE COLOR_BOLD_CYAN COLOR_BOLD_WHITE
export BG_BLACK BG_RED BG_GREEN BG_YELLOW BG_BLUE BG_PURPLE BG_CYAN BG_WHITE

#===============================================================================
# COLORED OUTPUT FUNCTIONS
#===============================================================================

# Print text in color
cecho() {
    local color="${1}"
    shift
    local text="$*"
    
    case "$color" in
        black)   echo -e "${COLOR_BLACK}${text}${COLOR_RESET}" ;;
        red)     echo -e "${COLOR_RED}${text}${COLOR_RESET}" ;;
        green)   echo -e "${COLOR_GREEN}${text}${COLOR_RESET}" ;;
        yellow)  echo -e "${COLOR_YELLOW}${text}${COLOR_RESET}" ;;
        blue)    echo -e "${COLOR_BLUE}${text}${COLOR_RESET}" ;;
        purple)  echo -e "${COLOR_PURPLE}${text}${COLOR_RESET}" ;;
        cyan)    echo -e "${COLOR_CYAN}${text}${COLOR_RESET}" ;;
        white)   echo -e "${COLOR_WHITE}${text}${COLOR_RESET}" ;;
        *)       echo -e "${text}" ;;
    esac
}

# Print success message
success() {
    echo -e "${COLOR_BOLD_GREEN}✓ $*${COLOR_RESET}"
}

# Print error message
error() {
    echo -e "${COLOR_BOLD_RED}✗ $*${COLOR_RESET}" >&2
}

# Print warning message
warning() {
    echo -e "${COLOR_BOLD_YELLOW}⚠ $*${COLOR_RESET}"
}

# Print info message
info() {
    echo -e "${COLOR_BOLD_CYAN}ℹ $*${COLOR_RESET}"
}

# Print header
header() {
    echo ""
    echo -e "${COLOR_BOLD_PURPLE}═══════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_BOLD_PURPLE}  $*${COLOR_RESET}"
    echo -e "${COLOR_BOLD_PURPLE}═══════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo ""
}

# Export functions
export -f cecho 2>/dev/null
export -f success 2>/dev/null
export -f error 2>/dev/null
export -f warning 2>/dev/null
export -f info 2>/dev/null
export -f header 2>/dev/null

#===============================================================================
# GRC (Generic Colouriser) SETUP
#===============================================================================

# Install grc aliases if grc is available
if command -v grc >/dev/null 2>&1; then
    # Colorize common commands
    alias colorize='grc -es --colour=auto'
    
    # System commands
    alias df='grc df -h'
    alias du='grc du -h'
    alias free='grc free -h'
    alias mount='grc mount'
    alias ps='grc ps'
    alias top='grc top'
    alias uptime='grc uptime'
    
    # Network commands
    alias ping='grc ping'
    alias traceroute='grc traceroute'
    alias netstat='grc netstat'
    alias ifconfig='grc ifconfig'
    alias ip='grc ip'
    alias dig='grc dig'
    alias nmap='grc nmap'
    
    # Development commands
    alias make='grc make'
    alias gcc='grc gcc'
    alias g++='grc g++'
    alias diff='grc diff'
    alias env='grc env'
    alias head='grc head'
    alias tail='grc tail'
    alias log='grc log'
    
    # Docker
    alias docker='grc docker'
fi

#===============================================================================
# BAT (Cat with Syntax Highlighting) SETUP
#===============================================================================

# Use bat instead of cat if available
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias less='bat --paging=always'
    
    # Configure bat with fallback theme
    # Check if Dracula theme exists, otherwise use a default
    if bat --list-themes 2>/dev/null | grep -q "Dracula"; then
        export BAT_THEME="Dracula"
    else
        export BAT_THEME="ansi"
    fi
    export BAT_STYLE="numbers,changes,header"
    
    # Preview function using bat
    preview() {
        bat --style=numbers --color=always "$@"
    }
    export -f preview 2>/dev/null
elif command -v batcat >/dev/null 2>&1; then
    # Ubuntu/Debian uses batcat
    alias cat='batcat --paging=never'
    alias less='batcat --paging=always'
    alias bat='batcat'
    
    # Configure bat with fallback theme
    if batcat --list-themes 2>/dev/null | grep -q "Dracula"; then
        export BAT_THEME="Dracula"
    else
        export BAT_THEME="ansi"
    fi
    export BAT_STYLE="numbers,changes,header"
fi

#===============================================================================
# EXA/EZA (Modern ls Replacement) SETUP
#===============================================================================

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --color=always --group-directories-first'
    alias ll='eza -alF --icons --color=always --group-directories-first'
    alias la='eza -a --icons --color=always --group-directories-first'
    alias lt='eza --tree --icons --color=always'
    alias l='eza -F --icons --color=always'
elif command -v exa >/dev/null 2>&1; then
    alias ls='exa --icons --color=always --group-directories-first'
    alias ll='exa -alF --icons --color=always --group-directories-first'
    alias la='exa -a --icons --color=always --group-directories-first'
    alias lt='exa --tree --icons --color=always'
    alias l='exa -F --icons --color=always'
else
    # Fallback to regular ls with colors
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
fi

#===============================================================================
# DIFF WITH COLORS
#===============================================================================

if command -v diff-so-fancy >/dev/null 2>&1; then
    # Use diff-so-fancy for git diffs
    git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX" 2>/dev/null
elif command -v delta >/dev/null 2>&1; then
    # Use delta for git diffs
    git config --global core.pager delta 2>/dev/null
fi

# Colored diff function
cdiff() {
    if command -v diff-so-fancy >/dev/null 2>&1; then
        diff -u "$@" | diff-so-fancy
    elif command -v colordiff >/dev/null 2>&1; then
        colordiff "$@"
    else
        diff --color=auto "$@"
    fi
}
export -f cdiff 2>/dev/null

#===============================================================================
# COLORED MAN PAGES
#===============================================================================

# Enhanced man pages with colors
man() {
    LESS_TERMCAP_mb=$'\E[1;31m' \
    LESS_TERMCAP_md=$'\E[1;36m' \
    LESS_TERMCAP_me=$'\E[0m' \
    LESS_TERMCAP_so=$'\E[01;44;33m' \
    LESS_TERMCAP_se=$'\E[0m' \
    LESS_TERMCAP_us=$'\E[1;32m' \
    LESS_TERMCAP_ue=$'\E[0m' \
    command man "$@"
}
export -f man 2>/dev/null

#===============================================================================
# JSON/YAML PRETTY PRINTING
#===============================================================================

# Pretty print JSON
ppjson() {
    if command -v jq >/dev/null 2>&1; then
        jq '.' "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m json.tool "$@"
    else
        cat "$@"
    fi
}
export -f ppjson 2>/dev/null

# Pretty print YAML
ppyaml() {
    if command -v yq >/dev/null 2>&1; then
        yq '.' "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import yaml, sys; print(yaml.dump(yaml.safe_load(sys.stdin), default_flow_style=False))" < "$1"
    else
        cat "$@"
    fi
}
export -f ppyaml 2>/dev/null

#===============================================================================
# LOG FILE COLORING
#===============================================================================

# Colorize log files
clog() {
    if command -v ccze >/dev/null 2>&1; then
        ccze -A < "$1"
    elif command -v grc >/dev/null 2>&1; then
        grc cat "$1"
    else
        tail -f "$1"
    fi
}
export -f clog 2>/dev/null

# Follow log files with color
tailc() {
    if command -v ccze >/dev/null 2>&1; then
        tail -f "$@" | ccze -A
    elif command -v grc >/dev/null 2>&1; then
        grc tail -f "$@"
    else
        tail -f "$@"
    fi
}
export -f tailc 2>/dev/null

#===============================================================================
# SYNTAX HIGHLIGHTING INSTALLER
#===============================================================================

# Install syntax highlighting tools
install_syntax_tools() {
    echo "Installing syntax highlighting tools..."
    echo ""
    
    local tools_to_install=""
    
    # Check what's missing
    command -v bat >/dev/null 2>&1 || tools_to_install="$tools_to_install bat"
    command -v eza >/dev/null 2>&1 || tools_to_install="$tools_to_install eza"
    command -v grc >/dev/null 2>&1 || tools_to_install="$tools_to_install grc"
    command -v jq >/dev/null 2>&1 || tools_to_install="$tools_to_install jq"
    command -v fzf >/dev/null 2>&1 || tools_to_install="$tools_to_install fzf"
    command -v delta >/dev/null 2>&1 || tools_to_install="$tools_to_install git-delta"
    
    if [[ -z "$tools_to_install" ]]; then
        success "All syntax highlighting tools are already installed!"
        return 0
    fi
    
    echo "Tools to install: $tools_to_install"
    echo ""
    
    # Detect package manager
    if command -v apt-get >/dev/null 2>&1; then
        echo "Using apt-get..."
        sudo apt-get update
        for tool in $tools_to_install; do
            echo "Installing $tool..."
            case "$tool" in
                bat)
                    sudo apt-get install -y bat || sudo apt-get install -y batcat
                    ;;
                eza)
                    # eza might not be in default repos
                    sudo apt-get install -y exa 2>/dev/null || echo "eza/exa not available via apt"
                    ;;
                git-delta)
                    echo "Install delta manually from: https://github.com/dandavison/delta"
                    ;;
                *)
                    sudo apt-get install -y "$tool"
                    ;;
            esac
        done
    elif command -v brew >/dev/null 2>&1; then
        echo "Using Homebrew..."
        for tool in $tools_to_install; do
            echo "Installing $tool..."
            case "$tool" in
                git-delta)
                    brew install delta
                    ;;
                *)
                    brew install "$tool"
                    ;;
            esac
        done
    elif command -v dnf >/dev/null 2>&1; then
        echo "Using dnf..."
        for tool in $tools_to_install; do
            echo "Installing $tool..."
            sudo dnf install -y "$tool" 2>/dev/null || echo "$tool not available"
        done
    else
        error "No supported package manager found. Please install manually:"
        echo "$tools_to_install"
        return 1
    fi
    
    success "Installation complete! Restart your shell to apply changes."
}

export -f install_syntax_tools 2>/dev/null
