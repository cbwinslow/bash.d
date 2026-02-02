#!/bin/bash
# ============================================================================
# System Utilities
# ============================================================================
# Essential system utilities for file operations, process management, and more

# Extract any type of archive
extract() {
    if [ -z "$1" ]; then
        echo "Usage: extract <archive_file>"
        return 1
    fi
    
    if [ ! -f "$1" ]; then
        echo "Error: File '$1' not found"
        return 1
    fi
    
    case "$1" in
        *.tar.bz2)   tar xjf "$1"     ;;
        *.tar.gz)    tar xzf "$1"     ;;
        *.tar.xz)    tar xJf "$1"     ;;
        *.bz2)       bunzip2 "$1"     ;;
        *.rar)       unrar x "$1"     ;;
        *.gz)        gunzip "$1"      ;;
        *.tar)       tar xf "$1"      ;;
        *.tbz2)      tar xjf "$1"     ;;
        *.tgz)       tar xzf "$1"     ;;
        *.zip)       unzip "$1"       ;;
        *.Z)         uncompress "$1"  ;;
        *.7z)        7z x "$1"        ;;
        *)           echo "Error: Unknown archive format for '$1'" ;;
    esac
}

# Create archive from files/directories
compress() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: compress <archive.tar.gz> <file1> [file2] ..."
        return 1
    fi
    
    local archive="$1"
    shift
    
    case "$archive" in
        *.tar.gz|*.tgz)  tar czf "$archive" "$@" ;;
        *.tar.bz2|*.tbz) tar cjf "$archive" "$@" ;;
        *.tar.xz)        tar cJf "$archive" "$@" ;;
        *.zip)           zip -r "$archive" "$@" ;;
        *.7z)            7z a "$archive" "$@" ;;
        *)               echo "Error: Unknown archive format"; return 1 ;;
    esac
    
    echo "Created: $archive"
}

# Find files by name pattern
ff() {
    if [ -z "$1" ]; then
        echo "Usage: ff <pattern> [directory]"
        return 1
    fi
    
    local pattern="$1"
    local dir="${2:-.}"
    
    find "$dir" -type f -iname "*${pattern}*" 2>/dev/null
}

# Find directories by name pattern
fd() {
    if [ -z "$1" ]; then
        echo "Usage: fd <pattern> [directory]"
        return 1
    fi
    
    local pattern="$1"
    local dir="${2:-.}"
    
    find "$dir" -type d -iname "*${pattern}*" 2>/dev/null
}

# Get file size in human readable format
fsize() {
    if [ -z "$1" ]; then
        echo "Usage: fsize <file_or_directory>"
        return 1
    fi
    
    du -sh "$1"
}

# Count files in directory
fcount() {
    local dir="${1:-.}"
    find "$dir" -type f | wc -l
}

# Show disk usage sorted by size
dusort() {
    local dir="${1:-.}"
    du -h "$dir"/* 2>/dev/null | sort -hr | head -20
}

# Quick backup of a file
backup() {
    if [ -z "$1" ]; then
        echo "Usage: backup <file>"
        return 1
    fi
    
    local filename="$1"
    local backup_name="${filename}.backup.$(date +%Y%m%d_%H%M%S)"
    
    cp -r "$filename" "$backup_name"
    echo "Backup created: $backup_name"
}

# Find and kill process by name
killnamed() {
    if [ -z "$1" ]; then
        echo "Usage: killnamed <process_name>"
        return 1
    fi
    
    local pname="$1"
    ps aux | grep "$pname" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null
    echo "Killed processes matching: $pname"
}

# Show top CPU consuming processes
topcpu() {
    local count="${1:-10}"
    ps aux | sort -rk 3,3 | head -n $((count + 1))
}

# Show top memory consuming processes
topmem() {
    local count="${1:-10}"
    ps aux | sort -rk 4,4 | head -n $((count + 1))
}

# Create directory and cd into it
mkcd() {
    if [ -z "$1" ]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    
    mkdir -p "$1" && cd "$1"
}

# Show directory tree with depth limit
tree_limited() {
    local depth="${1:-3}"
    local dir="${2:-.}"
    
    if command -v tree &> /dev/null; then
        tree -L "$depth" "$dir"
    else
        find "$dir" -maxdepth "$depth" -print | sed -e "s;[^/]*/;|____;g;s;____|; |;g"
    fi
}

# Get file permissions in octal format
perms() {
    if [ -z "$1" ]; then
        echo "Usage: perms <file>"
        return 1
    fi
    
    stat -c "%a %n" "$1" 2>/dev/null || stat -f "%OLp %N" "$1" 2>/dev/null
}

# Make script executable
mkexec() {
    if [ -z "$1" ]; then
        echo "Usage: mkexec <script_file>"
        return 1
    fi
    
    chmod +x "$1"
    echo "Made executable: $1"
}

# Find large files (>100MB by default)
findlarge() {
    local size="${1:-100M}"
    local dir="${2:-.}"
    
    find "$dir" -type f -size "+${size}" -exec ls -lh {} \; 2>/dev/null | awk '{print $9 ": " $5}'
}

# Remove empty directories
rmempty() {
    local dir="${1:-.}"
    find "$dir" -type d -empty -delete
    echo "Removed empty directories in: $dir"
}

# Show system information summary
sysinfo() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}System Information${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_YELLOW}Hostname:${COLOR_RESET}    $(hostname)"
    echo -e "${COLOR_YELLOW}OS:${COLOR_RESET}          $(uname -s)"
    echo -e "${COLOR_YELLOW}Kernel:${COLOR_RESET}      $(uname -r)"
    echo -e "${COLOR_YELLOW}Uptime:${COLOR_RESET}      $(uptime | awk '{print $3,$4}' | sed 's/,$//')"
    echo -e "${COLOR_YELLOW}Load:${COLOR_RESET}        $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_CYAN}CPU & Memory${COLOR_RESET}"
    echo -e "${COLOR_CYAN}════════════${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}CPU:${COLOR_RESET}         $(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo 'N/A')"
    echo -e "${COLOR_YELLOW}Cores:${COLOR_RESET}       $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 'N/A')"
    echo -e "${COLOR_YELLOW}Memory:${COLOR_RESET}      $(free -h 2>/dev/null | awk '/^Mem:/{print $2}' || echo 'N/A')"
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Disk Usage${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════${COLOR_RESET}"
    df -h / 2>/dev/null | tail -1 | awk '{printf "  %s used of %s (%.0f%%)\n", $3, $2, ($3/$2)*100}'
    echo ""
}

# Repeat command every N seconds
watch_cmd() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: watch_cmd <seconds> <command>"
        return 1
    fi
    
    local interval="$1"
    shift
    
    while true; do
        clear
        echo "Every ${interval}s: $*"
        echo ""
        eval "$@"
        sleep "$interval"
    done
}
