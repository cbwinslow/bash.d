#!/bin/bash
# System Information Collector Script
# Collects OS, hardware, and system configuration information
# Outputs JSON format for AI agent consumption

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

command_exists() {
    command -v "$1" &> /dev/null
}

# Collect OS information
collect_os_info() {
    local os_name os_version os_id kernel distro
    
    os_name=$(uname -s)
    kernel=$(uname -r)
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        os_id="${ID:-unknown}"
        os_version="${VERSION_ID:-unknown}"
        distro="${PRETTY_NAME:-unknown}"
    else
        os_id="unknown"
        os_version="unknown"
        distro="$os_name"
    fi
    
    cat << EOF
{
    "os_name": "$os_name",
    "os_id": "$os_id",
    "os_version": "$os_version",
    "distro": "$distro",
    "kernel": "$kernel",
    "architecture": "$(uname -m)"
}
EOF
}

# Collect hardware information
collect_hardware_info() {
    local cpu_model cpu_cores memory_total disk_info
    
    if [ -f /proc/cpuinfo ]; then
        cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        cpu_cores=$(grep -c "processor" /proc/cpuinfo)
    else
        cpu_model="unknown"
        cpu_cores="unknown"
    fi
    
    if [ -f /proc/meminfo ]; then
        memory_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        memory_total=$((memory_total / 1024)) # Convert to MB
    else
        memory_total="unknown"
    fi
    
    local disks=()
    if command_exists lsblk; then
        while IFS= read -r line; do
            disks+=("\"$line\"")
        done < <(lsblk -d -o NAME,SIZE,TYPE | tail -n +2)
    fi
    
    cat << EOF
{
    "cpu": {
        "model": "$cpu_model",
        "cores": $cpu_cores
    },
    "memory": {
        "total_mb": $memory_total
    },
    "disks": [$(IFS=,; echo "${disks[*]}")]
}
EOF
}

# Collect user information
collect_user_info() {
    local current_user current_uid current_groups
    
    current_user=$(whoami)
    current_uid=$(id -u)
    current_groups=$(id -Gn | tr ' ' ',')
    
    local all_users=()
    while IFS=: read -r username _ uid _ _ home shell; do
        if [ "$uid" -ge 1000 ] || [ "$uid" -eq 0 ]; then
            all_users+=("{\"username\":\"$username\",\"uid\":$uid,\"home\":\"$home\",\"shell\":\"$shell\"}")
        fi
    done < /etc/passwd
    
    cat << EOF
{
    "current_user": "$current_user",
    "current_uid": $current_uid,
    "current_groups": "$(echo $current_groups | sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/')",
    "users": [$(IFS=,; echo "${all_users[*]}")]
}
EOF
}

# Collect environment variables (filtered for sensitive data)
collect_env_vars() {
    local exclude_patterns=("PASSWORD" "SECRET" "KEY" "TOKEN" "API" "PRIVATE")
    
    echo "{"
    echo "    \"environment_variables\": ["
    
    local first=true
    while IFS='=' read -r key value; do
        local safe=true
        for pattern in "${exclude_patterns[@]}"; do
            if [[ "$key" == *"$pattern"* ]]; then
                safe=false
                break
            fi
        done
        
        if [ "$safe" = true ] && [ -n "$key" ]; then
            if [ "$first" = false ]; then
                echo ","
            fi
            # Use jq to properly escape the value
            echo -n "        {\"name\": $(echo "$key" | jq -R -s .), \"value\": $(echo "$value" | jq -R -s .)}"
            first=false
        fi
    done < <(env | sort)
    
    echo ""
    echo "    ]"
    echo "}"
}

# Collect systemd services (if available)
collect_services() {
    if command_exists systemctl; then
        log_info "Collecting systemd services..."
        
        local enabled_services=()
        while IFS= read -r service; do
            enabled_services+=("\"$service\"")
        done < <(systemctl list-unit-files --type=service --state=enabled --no-pager --no-legend | awk '{print $1}' | sort)
        
        cat << EOF
{
    "init_system": "systemd",
    "enabled_services": [$(IFS=,; echo "${enabled_services[*]}")]
}
EOF
    elif [ -d /etc/init.d ]; then
        local sysv_services=()
        while IFS= read -r service; do
            sysv_services+=("\"$(basename $service)\"")
        done < <(find /etc/init.d -type f -executable 2>/dev/null | sort)
        
        cat << EOF
{
    "init_system": "sysv",
    "services": [$(IFS=,; echo "${sysv_services[*]}")]
}
EOF
    else
        echo '{"init_system": "unknown"}'
    fi
}

# Collect cron jobs
collect_cron_jobs() {
    local cron_jobs=()
    
    # User crontab
    if crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' > /dev/null; then
        while IFS= read -r line; do
            line=$(echo "$line" | sed 's/"/\\"/g')
            cron_jobs+=("{\"type\":\"user\",\"entry\":\"$line\"}")
        done < <(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$')
    fi
    
    # System crontabs
    if [ -d /etc/cron.d ]; then
        for cronfile in /etc/cron.d/*; do
            if [ -f "$cronfile" ]; then
                while IFS= read -r line; do
                    if [[ ! "$line" =~ ^# ]] && [[ -n "$line" ]]; then
                        line=$(echo "$line" | sed 's/"/\\"/g')
                        cron_jobs+=("{\"type\":\"system\",\"file\":\"$(basename $cronfile)\",\"entry\":\"$line\"}")
                    fi
                done < "$cronfile"
            fi
        done
    fi
    
    cat << EOF
{
    "cron_jobs": [$(IFS=,; echo "${cron_jobs[*]}")]
}
EOF
}

# Collect network configuration
collect_network_info() {
    local interfaces=()
    
    if command_exists ip; then
        while IFS= read -r iface; do
            local name=$(echo "$iface" | awk '{print $2}' | sed 's/://')
            local state=$(echo "$iface" | grep -oP '(?<=state )\w+')
            interfaces+=("{\"name\":\"$name\",\"state\":\"${state:-unknown}\"}")
        done < <(ip link show | grep -E '^[0-9]+:')
    fi
    
    local hostname=$(hostname)
    local dns_servers=()
    if [ -f /etc/resolv.conf ]; then
        while IFS= read -r line; do
            dns_servers+=("\"$line\"")
        done < <(grep "^nameserver" /etc/resolv.conf | awk '{print $2}')
    fi
    
    cat << EOF
{
    "hostname": "$hostname",
    "interfaces": [$(IFS=,; echo "${interfaces[*]}")],
    "dns_servers": [$(IFS=,; echo "${dns_servers[*]}")]
}
EOF
}

# Main function
main() {
    log_info "Collecting system information..."
    
    # Check for jq
    if ! command_exists jq; then
        log_warn "jq not available, JSON may not be pretty"
    fi
    
    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "collection_host": "$(hostname)",
    "os_info": $(collect_os_info),
    "hardware": $(collect_hardware_info),
    "users": $(collect_user_info),
    "environment": $(collect_env_vars),
    "services": $(collect_services),
    "cron": $(collect_cron_jobs),
    "network": $(collect_network_info)
}
EOF
    
    log_info "System information collection complete!"
}

main "$@"
