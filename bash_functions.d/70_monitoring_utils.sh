#!/bin/bash
# ============================================================================
# Monitoring and Diagnostic Utilities
# ============================================================================
# Tools for system monitoring, performance analysis, and diagnostics

# Monitor CPU usage
cpumonitor() {
    local interval="${1:-2}"
    
    echo -e "${COLOR_BOLD}${COLOR_CYAN}CPU Usage Monitor (refresh every ${interval}s)${COLOR_RESET}"
    echo -e "${COLOR_CYAN}Press Ctrl+C to stop${COLOR_RESET}"
    echo ""
    
    while true; do
        clear
        echo -e "${COLOR_BOLD}${COLOR_CYAN}CPU Usage:${COLOR_RESET}"
        top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "CPU Usage: " 100 - $1"%"}'
        echo ""
        echo -e "${COLOR_BOLD}${COLOR_CYAN}Top CPU Processes:${COLOR_RESET}"
        ps aux | sort -rk 3,3 | head -6
        sleep "$interval"
    done
}

# Monitor memory usage
memmonitor() {
    local interval="${1:-2}"
    
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Memory Usage Monitor (refresh every ${interval}s)${COLOR_RESET}"
    echo -e "${COLOR_CYAN}Press Ctrl+C to stop${COLOR_RESET}"
    echo ""
    
    while true; do
        clear
        echo -e "${COLOR_BOLD}${COLOR_CYAN}Memory Usage:${COLOR_RESET}"
        free -h
        echo ""
        echo -e "${COLOR_BOLD}${COLOR_CYAN}Top Memory Processes:${COLOR_RESET}"
        ps aux | sort -rk 4,4 | head -6
        sleep "$interval"
    done
}

# Monitor disk I/O
iomonitor() {
    if ! command -v iostat &> /dev/null; then
        echo "Error: iostat not installed. Install with: sudo apt-get install sysstat"
        return 1
    fi
    
    local interval="${1:-2}"
    iostat -x "$interval"
}

# Monitor network traffic
netmonitor() {
    if ! command -v iftop &> /dev/null; then
        echo "Error: iftop not installed. Install with: sudo apt-get install iftop"
        return 1
    fi
    
    sudo iftop
}

# Show system load average
loadavg() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}System Load Average:${COLOR_RESET}"
    uptime | awk -F'load average:' '{print $2}'
    
    echo ""
    echo -e "${COLOR_YELLOW}1 min   5 min   15 min${COLOR_RESET}"
}

# Monitor all system resources
sysmonitor() {
    if command -v htop &> /dev/null; then
        htop
    else
        top
    fi
}

# Check disk space and alert if low
diskcheck() {
    local threshold="${1:-80}"
    
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Disk Space Usage:${COLOR_RESET}"
    echo ""
    
    df -h | awk -v thresh="$threshold" 'NR>1 {
        gsub(/%/, "", $5);
        if ($5 > thresh) {
            print "\033[31m" $0 "\033[0m (ALERT: Over " thresh "%)";
        } else if ($5 > thresh-10) {
            print "\033[33m" $0 "\033[0m (Warning: Over " thresh-10 "%)";
        } else {
            print "\033[32m" $0 "\033[0m";
        }
    }'
}

# Monitor log file for patterns
logmonitor() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: logmonitor <log_file> <pattern>"
        return 1
    fi
    
    local logfile="$1"
    local pattern="$2"
    
    echo -e "${COLOR_CYAN}Monitoring $logfile for pattern: $pattern${COLOR_RESET}"
    echo -e "${COLOR_CYAN}Press Ctrl+C to stop${COLOR_RESET}"
    echo ""
    
    tail -f "$logfile" | grep --line-buffered --color=always "$pattern"
}

# Show open files by process
openfiles() {
    if [ -z "$1" ]; then
        echo "Usage: openfiles <process_name>"
        return 1
    fi
    
    local process="$1"
    lsof -c "$process"
}

# Show network connections
connections() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Active Network Connections:${COLOR_RESET}"
    echo ""
    
    if command -v netstat &> /dev/null; then
        netstat -tunapl 2>/dev/null | grep ESTABLISHED
    elif command -v ss &> /dev/null; then
        ss -tuna | grep ESTAB
    else
        echo "Error: netstat or ss command not found"
        return 1
    fi
}

# Show process tree
processtree() {
    if [ -z "$1" ]; then
        pstree
    else
        pstree -p "$1"
    fi
}

# Monitor specific process
procmonitor() {
    if [ -z "$1" ]; then
        echo "Usage: procmonitor <process_name>"
        return 1
    fi
    
    local process="$1"
    local interval="${2:-2}"
    
    while true; do
        clear
        echo -e "${COLOR_BOLD}${COLOR_CYAN}Process Monitor: $process${COLOR_RESET}"
        echo ""
        ps aux | grep "$process" | grep -v grep
        echo ""
        echo -e "${COLOR_CYAN}Refreshing every ${interval}s... (Ctrl+C to stop)${COLOR_RESET}"
        sleep "$interval"
    done
}

# Show zombie processes
zombies() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Zombie Processes:${COLOR_RESET}"
    echo ""
    
    ps aux | awk '$8=="Z" {print}'
}

# Kill zombie processes
killzombies() {
    echo -e "${COLOR_CYAN}Attempting to kill zombie processes...${COLOR_RESET}"
    
    ps aux | awk '$8=="Z" {print $2}' | xargs kill -9 2>/dev/null
    echo -e "${COLOR_GREEN}Done${COLOR_RESET}"
}

# Show system temperature (if available)
temperature() {
    if command -v sensors &> /dev/null; then
        sensors
    elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        echo "CPU Temperature: $((temp/1000))°C"
    else
        echo "Temperature monitoring not available"
    fi
}

# Show battery status (if available)
battery() {
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        local capacity=$(cat /sys/class/power_supply/BAT0/capacity)
        local status=$(cat /sys/class/power_supply/BAT0/status)
        echo -e "${COLOR_BOLD}Battery:${COLOR_RESET} $capacity% ($status)"
    elif command -v pmset &> /dev/null; then
        pmset -g batt
    else
        echo "Battery information not available"
    fi
}

# Show hardware information
hardware() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Hardware Information${COLOR_RESET}"
    echo -e "${COLOR_CYAN}════════════════════${COLOR_RESET}"
    echo ""
    
    if command -v lshw &> /dev/null; then
        sudo lshw -short
    elif command -v dmidecode &> /dev/null; then
        sudo dmidecode -t system
    else
        echo "CPU Info:"
        cat /proc/cpuinfo | grep "model name" | head -1
        echo ""
        echo "Memory Info:"
        free -h
        echo ""
        echo "Disk Info:"
        lsblk
    fi
}

# Show USB devices
usbdevices() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}USB Devices:${COLOR_RESET}"
    echo ""
    
    lsusb
}

# Show PCI devices
pcidevices() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}PCI Devices:${COLOR_RESET}"
    echo ""
    
    lspci
}

# Check service status
servicestatus() {
    if [ -z "$1" ]; then
        echo "Usage: servicestatus <service_name>"
        return 1
    fi
    
    local service="$1"
    
    if command -v systemctl &> /dev/null; then
        systemctl status "$service"
    elif command -v service &> /dev/null; then
        service "$service" status
    else
        echo "Error: systemctl or service command not found"
        return 1
    fi
}

# List all running services
listservices() {
    if command -v systemctl &> /dev/null; then
        systemctl list-units --type=service --state=running
    elif command -v service &> /dev/null; then
        service --status-all
    else
        echo "Error: systemctl or service command not found"
        return 1
    fi
}

# Show kernel messages
kernellog() {
    local lines="${1:-50}"
    
    dmesg | tail -n "$lines"
}

# Watch system log
syslog() {
    if [ -f /var/log/syslog ]; then
        tail -f /var/log/syslog
    elif [ -f /var/log/messages ]; then
        tail -f /var/log/messages
    else
        journalctl -f
    fi
}

# Show failed login attempts
failedlogins() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Failed Login Attempts:${COLOR_RESET}"
    echo ""
    
    if [ -f /var/log/auth.log ]; then
        grep "Failed password" /var/log/auth.log | tail -20
    elif [ -f /var/log/secure ]; then
        grep "Failed password" /var/log/secure | tail -20
    else
        echo "Authentication log not found"
    fi
}

# Performance test - CPU
cputest() {
    echo -e "${COLOR_CYAN}Running CPU performance test...${COLOR_RESET}"
    time echo "scale=5000; a(1)*4" | bc -l
}

# Performance test - disk write
diskwritetest() {
    local size="${1:-1G}"
    
    echo -e "${COLOR_CYAN}Testing disk write performance with ${size} file...${COLOR_RESET}"
    dd if=/dev/zero of=/tmp/testfile bs=1M count=1024 oflag=direct 2>&1 | grep -E "copied|MB/s"
    rm -f /tmp/testfile
}

# Performance test - disk read
diskreadtest() {
    echo -e "${COLOR_CYAN}Testing disk read performance...${COLOR_RESET}"
    hdparm -t /dev/sda 2>/dev/null || echo "hdparm not available"
}
