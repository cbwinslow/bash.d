#!/bin/bash
# Quick system health check - optimized for your specific issues

echo "🏥 System Health Check - $(date)"
echo "=================================="

# Check if alert daemon is running
if pgrep -f "alert_daemon.py" > /dev/null; then
    echo "✅ Alert Daemon: RUNNING (PID: $(pgrep -f alert_daemon.py))"
else
    echo "❌ Alert Daemon: NOT RUNNING"
    echo "   Start with: systemctl --user start alert-daemon.service"
fi

echo ""
echo "📊 Current System Status:"

# Memory check
MEM_INFO=$(free -g | awk '/^Mem:/ {printf "%.1fGB used / %.1fGB total (%.1f%%)", $3, $2, ($3/$2)*100}')
MEM_PERCENT=$(free | awk '/^Mem:/ {printf "%.1f", ($3/$2)*100}')
if (( $(echo "$MEM_PERCENT > 85" | bc -l) )); then
    echo "🔴 Memory: $MEM_INFO (CRITICAL)"
elif (( $(echo "$MEM_PERCENT > 70" | bc -l) )); then
    echo "🟡 Memory: $MEM_INFO (WARNING)"
else
    echo "🟢 Memory: $MEM_INFO (OK)"
fi

# Load average
LOAD_1M=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
CPU_CORES=$(nproc)
if (( $(echo "$LOAD_1M > $CPU_CORES" | bc -l) )); then
    echo "🔴 Load: $LOAD_1M (Critical - >$CPU_CORES cores)"
elif (( $(echo "$LOAD_1M > $((CPU_CORES/2))" | bc -l) )); then
    echo "🟡 Load: $LOAD_1M (High)"
else
    echo "🟢 Load: $LOAD_1M (OK)"
fi

# Disk usage
DISK_PERCENT=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if (( DISK_PERCENT > 90 )); then
    echo "🔴 Disk: $DISK_PERCENT% (Critical)"
elif (( DISK_PERCENT > 80 )); then
    echo "🟡 Disk: $DISK_PERCENT% (Warning)"
else
    echo "🟢 Disk: $DISK_PERCENT% (OK)"
fi

echo ""
echo "🔍 Problematic Processes (Top 5 by memory):"
ps aux --sort=-%mem | head -6 | tail -5 | while read -r line; do
    PID=$(echo $line | awk '{print $2}')
    MEM=$(echo $line | awk '{print $4}')
    NAME=$(echo $line | awk '{print $11}' | cut -d'/' -f1)
    
    # Check for problematic processes
    if echo "$NAME" | grep -E -q "(ollama|docker|code|node|proton)"; then
        if (( $(echo "$MEM > 20" | bc -l) )); then
            echo "🔴 $NAME: ${MEM}% (PID: $PID)"
        elif (( $(echo "$MEM > 10" | bc -l) )); then
            echo "🟡 $NAME: ${MEM}% (PID: $PID)"
        else
            echo "🟢 $NAME: ${MEM}% (PID: $PID)"
        fi
    else
        echo "🔵 $NAME: ${MEM}% (PID: $PID)"
    fi
done

echo ""
echo "📋 Recent Alerts (last 5):"
if [ -f ~/.system_monitor_alerts.log ]; then
    tail -5 ~/.system_monitor_alerts.log | while read -r line; do
        TIMESTAMP=$(echo $line | jq -r '.timestamp' 2>/dev/null || echo "$(date)")
        ALERT_MSG=$(echo $line | jq -r '.alert.message' 2>/dev/null || echo "Parse error")
        echo "   [$TIMESTAMP] $ALERT_MSG"
    done
else
    echo "   No alerts logged yet"
fi

echo ""
echo "🎯 Quick Actions:"
echo "  • Run 'sysmon' for detailed TUI monitor"
echo "  • Run 'alertd' to start alert daemon"
echo "  • Check logs: tail -f ~/.system_monitor_alerts.log"
echo "  • Kill memory hog: pkill -f ollama"
echo ""

# Auto-suggest fixes
if (( $(echo "$MEM_PERCENT > 85" | bc -l) )); then
    echo "⚠️  SUGGESTED ACTIONS:"
    if pgrep -f ollama > /dev/null; then
        echo "  • Ollama is using high memory. Consider: pkill -f ollama"
    fi
    if pgrep -f docker > /dev/null; then
        echo "  • Docker containers running. Check: docker stats"
        echo "  • Restart Docker: sudo systemctl restart docker"
    fi
fi

if (( DISK_PERCENT > 80 )); then
    echo "💾 DISK SPACE LOW:"
    echo "  • Clean temp files: sudo apt autoremove && sudo apt autoclean"
    echo "  • Clean old logs: journalctl --vacuum-time=7d"
fi