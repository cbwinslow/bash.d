#!/bin/bash
#===============================================================================
#
#          FILE:  func_help.sh
#
#         USAGE:  help_me <command> [source]
#
#   DESCRIPTION:  Unified help viewer for commands - searches man pages,
#                 tldr, help docs, and function documentation
#
#       OPTIONS:  command - The command to get help for
#                 source - Specific source: man, tldr, help, cheat, func
#  REQUIREMENTS:  man, tldr (optional), cheat (optional)
#         NOTES:  Installs tldr client if not present
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Unified help command - tries multiple sources
help_me() {
    local command="${1}"
    local source="${2}"
    
    if [[ -z "$command" ]]; then
        echo "Usage: help_me <command> [source]"
        echo ""
        echo "Sources:"
        echo "  man    - Traditional man pages"
        echo "  tldr   - Community-driven examples (tldr-pages)"
        echo "  help   - Bash built-in help"
        echo "  cheat  - Cheatsheets (if installed)"
        echo "  func   - Search bash_functions.d"
        echo "  all    - Try all sources"
        echo ""
        echo "Examples:"
        echo "  help_me git"
        echo "  help_me tar tldr"
        echo "  help_me ls man"
        return 1
    fi
    
    # If a specific source is requested
    if [[ -n "$source" ]]; then
        case "$source" in
            man)
                _help_man "$command"
                ;;
            tldr)
                _help_tldr "$command"
                ;;
            help)
                _help_builtin "$command"
                ;;
            cheat)
                _help_cheat "$command"
                ;;
            func)
                _help_func "$command"
                ;;
            all)
                _help_all "$command"
                ;;
            *)
                echo "Unknown source: $source"
                return 1
                ;;
        esac
        return $?
    fi
    
    # Default: try tldr first (faster), then man
    if command -v tldr >/dev/null 2>&1; then
        if tldr "$command" 2>/dev/null; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "💡 For full documentation: help_me $command man"
            return 0
        fi
    fi
    
    # Try man page
    if man "$command" 2>/dev/null; then
        return 0
    fi
    
    # Try built-in help
    if help "$command" 2>/dev/null; then
        return 0
    fi
    
    # Search our functions
    _help_func "$command"
}

# Man page viewer with search capability
_help_man() {
    local command="${1}"
    local section="${2}"
    
    if [[ -n "$section" ]]; then
        man "$section" "$command"
    else
        man "$command"
    fi
}

# TLDR help - install if needed
_help_tldr() {
    local command="${1}"
    
    # Check if tldr is installed
    if ! command -v tldr >/dev/null 2>&1; then
        echo "tldr is not installed. Would you like to install it? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy] ]]; then
            # Try different installation methods
            if command -v npm >/dev/null 2>&1; then
                echo "Installing via npm..."
                npm install -g tldr
            elif command -v pip >/dev/null 2>&1; then
                echo "Installing via pip..."
                pip install tldr
            elif command -v pip3 >/dev/null 2>&1; then
                echo "Installing via pip3..."
                pip3 install tldr
            elif command -v brew >/dev/null 2>&1; then
                echo "Installing via brew..."
                brew install tldr
            else
                echo "No package manager found. Please install tldr manually."
                echo "  npm: npm install -g tldr"
                echo "  pip: pip install tldr"
                echo "  brew: brew install tldr"
                return 1
            fi
        else
            return 1
        fi
    fi
    
    tldr "$command"
}

# Bash built-in help
_help_builtin() {
    local command="${1}"
    
    # Try bash help
    help "$command" 2>/dev/null || {
        # Try --help flag
        "$command" --help 2>/dev/null || {
            # Try -h flag
            "$command" -h 2>/dev/null || {
                echo "No built-in help available for: $command"
                return 1
            }
        }
    }
}

# Cheat command (if installed)
_help_cheat() {
    local command="${1}"
    
    if command -v cheat >/dev/null 2>&1; then
        cheat "$command"
    else
        echo "cheat is not installed."
        echo "Install with: pip install cheat"
        echo "Or visit: https://github.com/cheat/cheat"
        return 1
    fi
}

# Search our bash_functions.d for help
_help_func() {
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
}

# Show help from all sources
_help_all() {
    local command="${1}"
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Help for: $command"
    echo "╚════════════════════════════════════════════════════════════════╝"
    
    echo ""
    echo "=== TLDR ==="
    _help_tldr "$command" 2>/dev/null || echo "  (not available)"
    
    echo ""
    echo "=== Built-in Help ==="
    "$command" --help 2>/dev/null | head -30 || echo "  (not available)"
    
    echo ""
    echo "=== bash_functions.d ==="
    _help_func "$command" 2>/dev/null || echo "  (not available)"
    
    echo ""
    echo "=== Man Page (first 50 lines) ==="
    man "$command" 2>/dev/null | head -50 || echo "  (not available)"
}

# Quick reference - show common options for a command
quickref() {
    local command="${1}"
    
    if [[ -z "$command" ]]; then
        echo "Usage: quickref <command>"
        return 1
    fi
    
    echo "Quick Reference: $command"
    echo "========================="
    echo ""
    
    # Common commands with their most used options
    case "$command" in
        ls)
            cat << 'EOF'
  ls -la        List all files with details
  ls -lh        Human-readable sizes
  ls -lt        Sort by time
  ls -lS        Sort by size
  ls -R         Recursive listing
EOF
            ;;
        grep)
            cat << 'EOF'
  grep -i       Case insensitive
  grep -r       Recursive search
  grep -n       Show line numbers
  grep -v       Invert match
  grep -E       Extended regex
  grep -c       Count matches
  grep -l       List files with matches
EOF
            ;;
        find)
            cat << 'EOF'
  find . -name "*.txt"        Find by name
  find . -type f              Find files only
  find . -type d              Find directories
  find . -mtime -7            Modified in last 7 days
  find . -size +100M          Files larger than 100MB
  find . -exec cmd {} \;      Execute command on results
EOF
            ;;
        tar)
            cat << 'EOF'
  tar -cvf archive.tar dir/   Create archive
  tar -xvf archive.tar        Extract archive
  tar -czvf archive.tar.gz    Create gzipped archive
  tar -xzvf archive.tar.gz    Extract gzipped archive
  tar -tvf archive.tar        List contents
EOF
            ;;
        git)
            cat << 'EOF'
  git status              Check status
  git add -A              Add all changes
  git commit -m "msg"     Commit with message
  git push                Push to remote
  git pull                Pull from remote
  git log --oneline       Compact log
  git diff                Show changes
  git branch              List branches
  git checkout -b name    Create branch
EOF
            ;;
        docker)
            cat << 'EOF'
  docker ps                   List running containers
  docker ps -a                List all containers
  docker images               List images
  docker run -it image bash   Run interactive
  docker exec -it name bash   Exec into container
  docker logs name            View logs
  docker stop name            Stop container
  docker rm name              Remove container
EOF
            ;;
        *)
            # Try tldr for quick reference
            if command -v tldr >/dev/null 2>&1; then
                tldr "$command"
            else
                echo "No quick reference available for: $command"
                echo "Try: help_me $command tldr"
            fi
            ;;
    esac
}

# Explain a command - break down complex commands
explain() {
    local full_command="$*"
    
    if [[ -z "$full_command" ]]; then
        echo "Usage: explain <command>"
        echo ""
        echo "Explains what a complex command does."
        echo ""
        echo "Example: explain 'find . -name \"*.sh\" -exec chmod +x {} \\;'"
        return 1
    fi
    
    # Check if explainshell.com API is available
    echo "Command: $full_command"
    echo ""
    echo "Breaking down the command..."
    echo ""
    
    # Try to explain using local knowledge
    local base_cmd
    base_cmd=$(echo "$full_command" | awk '{print $1}')
    
    echo "Base command: $base_cmd"
    
    # Get brief description from whatis
    if whatis "$base_cmd" 2>/dev/null; then
        echo ""
    fi
    
    # Show man page synopsis
    echo ""
    echo "For detailed help: help_me $base_cmd"
    
    # If explainshell is available online
    echo ""
    echo "Online resource: https://explainshell.com/explain?cmd=$(echo "$full_command" | sed 's/ /+/g')"
}

# Export functions
export -f help_me 2>/dev/null
export -f _help_man 2>/dev/null
export -f _help_tldr 2>/dev/null
export -f _help_builtin 2>/dev/null
export -f _help_cheat 2>/dev/null
export -f _help_func 2>/dev/null
export -f _help_all 2>/dev/null
export -f quickref 2>/dev/null
export -f explain 2>/dev/null
