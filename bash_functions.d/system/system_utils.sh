#!/bin/bash
#===============================================================================
#
#          FILE:  system_utils.sh
#
#         USAGE:  Automatically sourced by .bashrc
#
#   DESCRIPTION:  Useful system utility functions for daily operations
#
#       OPTIONS:  ---
#  REQUIREMENTS:  bash 4.0+
#         NOTES:  Common system administration tasks
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

#===============================================================================
# FILE AND DIRECTORY OPERATIONS
#===============================================================================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1" || return 1
}

# Create a backup of a file
backup() {
    local file="$1"
    local backup_dir="${2:-$HOME/backups}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi
    
    mkdir -p "$backup_dir"
    cp "$file" "${backup_dir}/$(basename "$file").${timestamp}.bak"
    echo "Backup created: ${backup_dir}/$(basename "$file").${timestamp}.bak"
}

# Extract any archive
extract() {
    if [[ -z "$1" ]]; then
        echo "Usage: extract <archive>"
        return 1
    fi
    
    if [[ ! -f "$1" ]]; then
        echo "File not found: $1"
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
        *.xz)        unxz "$1"        ;;
        *.lzma)      unlzma "$1"      ;;
        *)           echo "Don't know how to extract '$1'..." ;;
    esac
}

# Create compressed archive
compress() {
    local format="${1:-tar.gz}"
    local name="${2:-archive}"
    shift 2
    
    case "$format" in
        tar.gz|tgz)
            tar czvf "${name}.tar.gz" "$@"
            ;;
        tar.bz2)
            tar cjvf "${name}.tar.bz2" "$@"
            ;;
        tar.xz)
            tar cJvf "${name}.tar.xz" "$@"
            ;;
        zip)
            zip -r "${name}.zip" "$@"
            ;;
        *)
            echo "Unknown format: $format"
            echo "Supported: tar.gz, tar.bz2, tar.xz, zip"
            return 1
            ;;
    esac
}

# Find files by name
ff() {
    find . -type f -name "*${1}*" 2>/dev/null
}

# Find directories by name
fd() {
    find . -type d -name "*${1}*" 2>/dev/null
}

# Find files containing text
ftext() {
    grep -rl "$1" . 2>/dev/null
}

# Show disk usage sorted by size
dusort() {
    local dir="${1:-.}"
    du -sh "$dir"/* 2>/dev/null | sort -hr | head -20
}

# Show largest files
largest() {
    local count="${1:-10}"
    local dir="${2:-.}"
    find "$dir" -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n "$count"
}

#===============================================================================
# PROCESS MANAGEMENT
#===============================================================================

# Find process by name
psg() {
    ps aux | head -1
    ps aux | grep -v grep | grep -i "$1"
}

# Kill process by name
killbyname() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: killbyname <process_name>"
        return 1
    fi
    
    local pids
    pids=$(pgrep -f "$name")
    
    if [[ -z "$pids" ]]; then
        echo "No processes found matching: $name"
        return 1
    fi
    
    echo "Found processes:"
    ps aux | grep -v grep | grep -i "$name"
    echo ""
    echo "Kill these processes? (y/n)"
    read -r response
    
    if [[ "$response" =~ ^[Yy] ]]; then
        echo "$pids" | xargs kill -9
        echo "Processes killed."
    fi
}

# Show port usage
ports() {
    if command -v ss >/dev/null 2>&1; then
        ss -tuln
    else
        netstat -tuln
    fi
}

# Find what's using a port
portuser() {
    local port="$1"
    if [[ -z "$port" ]]; then
        echo "Usage: portuser <port>"
        return 1
    fi
    
    if command -v lsof >/dev/null 2>&1; then
        sudo lsof -i :"$port"
    else
        sudo fuser -v "$port"/tcp 2>/dev/null
    fi
}

#===============================================================================
# SYSTEM INFORMATION
#===============================================================================

# System overview
sysinfo() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                      System Information                        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Hostname:    $(hostname)"
    echo "Kernel:      $(uname -r)"
    echo "OS:          $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo "Uptime:      $(uptime -p 2>/dev/null || uptime)"
    echo ""
    echo "CPU:         $(grep 'model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs)"
    echo "Cores:       $(nproc 2>/dev/null || echo "Unknown")"
    echo ""
    echo "Memory:"
    free -h 2>/dev/null | head -2
    echo ""
    echo "Disk Usage:"
    df -h / | tail -1
    echo ""
    echo "Network:"
    ip addr show 2>/dev/null | grep 'inet ' | head -3 | awk '{print "  " $2}'
}

# Quick system check
check() {
    echo "=== CPU Load ===" 
    uptime
    echo ""
    echo "=== Memory ===" 
    free -h
    echo ""
    echo "=== Disk ===" 
    df -h | grep -E '^/dev'
    echo ""
    echo "=== Top Processes ==="
    ps aux --sort=-%cpu | head -6
}

# Weather (requires curl and internet)
weather() {
    local location="${1:-}"
    curl -s "wttr.in/${location}?format=3"
}

#===============================================================================
# NETWORKING
#===============================================================================

# Get public IP
myip() {
    echo "Public IP: $(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null)"
    echo ""
    echo "Local IPs:"
    ip addr show 2>/dev/null | grep 'inet ' | awk '{print "  " $2}'
}

# Quick HTTP server
serve() {
    local port="${1:-8000}"
    echo "Starting HTTP server on port $port..."
    if command -v python3 >/dev/null 2>&1; then
        python3 -m http.server "$port"
    elif command -v python >/dev/null 2>&1; then
        python -m SimpleHTTPServer "$port"
    else
        echo "Python not found. Cannot start HTTP server."
        return 1
    fi
}

# Test if a host is reachable
isup() {
    local host="$1"
    if [[ -z "$host" ]]; then
        echo "Usage: isup <hostname>"
        return 1
    fi
    
    if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
        echo "✓ $host is up"
        return 0
    else
        echo "✗ $host is down"
        return 1
    fi
}

#===============================================================================
# HISTORY AND COMMAND UTILITIES
#===============================================================================

# Search history
hg() {
    history | grep -i "$1"
}

# Repeat last command with sudo
please() {
    sudo "$(fc -ln -1)"
}

# Create a script from the last N commands
scriptify() {
    local count="${1:-5}"
    local output="${2:-script.sh}"
    
    echo "#!/bin/bash" > "$output"
    echo "" >> "$output"
    fc -ln -"$count" | sed 's/^\s*//' >> "$output"
    chmod +x "$output"
    echo "Created: $output"
}

# Calculate simple math
calc() {
    echo "scale=4; $*" | bc
}

# Quick notes
note() {
    local notes_file="${HOME}/.notes"
    
    if [[ $# -eq 0 ]]; then
        if [[ -f "$notes_file" ]]; then
            cat "$notes_file"
        else
            echo "No notes yet. Usage: note <your note>"
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M') - $*" >> "$notes_file"
        echo "Note added."
    fi
}

# Quick timer
timer() {
    local seconds="${1:-60}"
    echo "Timer set for $seconds seconds..."
    sleep "$seconds"
    echo -e "\a" # Terminal bell
    echo "⏰ Time's up!"
    
    # Try to show notification
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Timer" "Time's up!"
    fi
}

# Countdown
countdown() {
    local seconds="${1:-10}"
    
    while [[ $seconds -gt 0 ]]; do
        printf "\r%02d seconds remaining..." "$seconds"
        sleep 1
        ((seconds--))
    done
    
    echo -e "\r⏰ Time's up!              "
    echo -e "\a"
}

#===============================================================================
# CLIPBOARD UTILITIES
#===============================================================================

# Copy to clipboard
copy() {
    if command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --input
    elif command -v pbcopy >/dev/null 2>&1; then
        pbcopy
    else
        echo "No clipboard tool found"
        return 1
    fi
}

# Paste from clipboard
paste() {
    if command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -o
    elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --output
    elif command -v pbpaste >/dev/null 2>&1; then
        pbpaste
    else
        echo "No clipboard tool found"
        return 1
    fi
}

# Copy file contents to clipboard
copyfile() {
    if [[ -z "$1" ]]; then
        echo "Usage: copyfile <filename>"
        return 1
    fi
    
    cat "$1" | copy
    echo "Contents of $1 copied to clipboard"
}

#===============================================================================
# ALIASES AS FUNCTIONS (for better flexibility)
#===============================================================================

# Clear screen and show directory
cls() {
    clear
    ls -la
}

# Go up N directories
up() {
    local count="${1:-1}"
    local path=""
    for ((i=0; i<count; i++)); do
        path="../$path"
    done
    cd "$path" || return 1
}

# Quick cd with history
cdh() {
    if command -v fzf >/dev/null 2>&1; then
        local dir
        dir=$(dirs -v | fzf | awk '{print $2}')
        [[ -n "$dir" ]] && cd "$(eval echo "$dir")" || return 1
    else
        dirs -v
        echo -n "Select directory number: "
        read -r num
        cd "~$num" || return 1
    fi
}

# Export all functions
export -f mkcd backup extract compress ff fd ftext dusort largest 2>/dev/null
export -f psg killbyname ports portuser 2>/dev/null
export -f sysinfo check weather 2>/dev/null
export -f myip serve isup 2>/dev/null
export -f hg please scriptify calc note timer countdown 2>/dev/null
export -f copy paste copyfile 2>/dev/null
export -f cls up cdh 2>/dev/null
