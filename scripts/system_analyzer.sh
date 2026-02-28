#!/bin/bash
# System Process Analyzer - Finds memory/CPU issues and can terminate problem processes

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== SYSTEM PROCESS ANALYZER ===${NC}"
echo "Time: $(date)"
echo ""

# System Overview
echo -e "${BLUE}--- System Resources ---${NC}"
free -h | grep -E "^Mem:|Swap:"
echo ""

# Check uptime and load
echo -e "${BLUE}--- Load Average ---${NC}"
uptime | sed 's/.*load average:/Load:/'
echo ""

# Top Memory Consumers
echo -e "${RED}--- TOP 15 MEMORY CONSUMERS ---${NC}"
ps aux --sort=-%mem | head -16 | tail -15 | awk '{
    printf "%-10s %-8s %-6s %-6s %-10s %s\n", $1, $2, $3"%", $4"%", $6"KB", $11" "$12" "$13" "$14
}'
echo ""

# Top CPU Consumers
echo -e "${YELLOW}--- TOP 10 CPU CONSUMERS ---${NC}"
ps aux --sort=-%cpu | head -11 | tail -10 | awk '{
    printf "%-10s %-8s %-6s %-6s %s\n", $1, $2, $3"%", $4"%", $11" "$12" "$13
}'
echo ""

# Find duplicate processes (potential issues)
echo -e "${BLUE}--- DUPLICATE PROCESSES (potential issue) ---${NC}"
ps -eo comm,pid,user,%mem,cmd | sort | uniq -D -w20 | head -20 || echo "None found"
echo ""

# Long-running processes (>1 day)
echo -e "${BLUE}--- LONG RUNNING PROCESSES (>1 day) ---${NC}"
ps -eo pid,user,etime,%mem,cmd --no-headers | grep -v "^$" | awk '
{
    split($4, a, "-")
    if (a[1] > 0 || $4 ~ /^[0-9]+-[0-9]+:[0-9]+/) {
        print
    }
}' | head -10 || echo "None found"
echo ""

# Zombie processes
echo -e "${RED}--- ZOMBIE PROCESSES ---${NC}"
zombies=$(ps aux | grep -c "Z" | grep -v grep || echo "0")
if [ "$zombies" -gt "0" ]; then
    ps aux | grep "Z"
else
    echo "None found ✓"
fi
echo ""

# Docker processes
echo -e "${BLUE}--- DOCKER PROCESSES ---${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null || echo "Docker not available"
echo ""

# Recommendations
echo -e "${GREEN}=== RECOMMENDATIONS ===${NC}"

# Count duplicate processes
kilo_count=$(pgrep -c kilo 2>/dev/null || echo "0")
cline_count=$(pgrep -c cline 2>/dev/null || echo "0")
node_count=$(pgrep -c node 2>/dev/null || echo "0")

if [ "$kilo_count" -gt 1 ]; then
    echo -e "${RED}⚠️  Multiple kilo processes running: $kilo_count instances${NC}"
fi

if [ "$cline_count" -gt 1 ]; then
    echo -e "${RED}⚠️  Multiple cline processes: $cline_count instances${NC}"
fi

# Check memory pressure
mem_percent=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}')
if [ "$mem_percent" -gt 85 ]; then
    echo -e "${RED}⚠️  HIGH MEMORY USAGE: ${mem_percent}%${NC}"
    echo "   Consider killing idle processes or restarting heavy apps"
elif [ "$mem_percent" -gt 70 ]; then
    echo -e "${YELLOW}⚠️  Elevated memory usage: ${mem_percent}%${NC}"
fi

echo ""
echo -e "${GREEN}=== QUICK ACTIONS ===${NC}"
echo "To kill a process:     kill <PID>"
echo "To force kill:         kill -9 <PID>"
echo "To kill duplicate kilo: pkill -f kilo (careful!)"
echo "To analyze with AI:    ai-sys-analyze"
echo ""
