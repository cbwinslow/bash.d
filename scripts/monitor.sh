#!/bin/bash
# System Monitor - Continuous monitoring with alerts

set -euo pipefail

# Configuration
INTERVAL=${1:-10}  # Check interval in seconds (default 10)
MEMORY_THRESHOLD=85
CPU_THRESHOLD=90

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_alert() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> /tmp/system_monitor.log
}

get_mem_percent() {
    free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}'
}

get_cpu_percent() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0"
}

echo "=== System Monitor Started ==="
echo "Memory threshold: ${MEMORY_THRESHOLD}%"
echo "CPU threshold: ${CPU_THRESHOLD}%"
echo "Check interval: ${INTERVAL}s"
echo "Log file: /tmp/system_monitor.log"
echo ""

# Initial memory for trend
prev_mem=0

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mem_percent=$(get_mem_percent)
    cpu_percent=$(get_cpu_percent)
    
    # Get top memory consumer
    top_mem_proc=$(ps aux --sort=-%mem | head -2 | tail -1 | awk '{print $11" "$12" "$13}' | cut -c1-40)
    top_mem_pid=$(ps aux --sort=-%mem | head -2 | tail -1 | awk '{print $2}')
    top_mem_usage=$(ps aux --sort=-%mem | head -2 | tail -1 | awk '{print $4}')
    
    # Check memory
    if [ "$mem_percent" -ge "$MEMORY_THRESHOLD" ]; then
        echo -e "${RED}[$timestamp] ⚠️  MEMORY ALERT: ${mem_percent}%${NC} (threshold: ${MEMORY_THRESHOLD}%)"
        echo -e "${RED}   Top consumer: PID $top_mem_pid ($top_mem_usage%) - $top_mem_proc${NC}"
        log_alert "MEMORY" "High memory: ${mem_percent}% - $top_mem_proc"
    elif [ "$mem_percent" -ge 75 ]; then
        echo -e "${YELLOW}[$timestamp] ⚡ Memory: ${mem_percent}%${NC}"
    else
        echo -e "${GREEN}[$timestamp] ✓ Memory: ${mem_percent}%${NC}"
    fi
    
    # Check CPU
    cpu_int=$(echo "$cpu_percent" | cut -d'.' -f1)
    if [ "$cpu_int" -ge "$CPU_THRESHOLD" ]; then
        echo -e "${RED}[$timestamp] ⚠️  CPU ALERT: ${cpu_percent}%${NC}"
        log_alert "CPU" "High CPU: ${cpu_percent}%"
    fi
    
    # Detect memory spike (sudden increase)
    mem_delta=$((mem_percent - prev_mem))
    if [ "$mem_delta" -gt 10 ]; then
        echo -e "${RED}[$timestamp] ⚠️  MEMORY SPIKE: +${mem_delta}% sudden increase!${NC}"
        log_alert "SPIKE" "Memory sudden increase: +${mem_delta}%"
    fi
    
    prev_mem=$mem_percent
    
    sleep "$INTERVAL"
done
