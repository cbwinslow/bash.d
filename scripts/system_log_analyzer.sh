#!/bin/bash

# System Crash Log Analyzer
# Analyzes system logs for session termination, crashes, and memory issues

analyze_system_logs() {
    local time_range=${1:-"2 hours ago"}
    local output_file="/tmp/system_crash_analysis_$(date +%Y%m%d_%H%M%S).log"
    
    echo "=== System Crash Log Analysis ===" | tee "$output_file"
    echo "Analysis Time: $(date)" | tee -a "$output_file"
    echo "Time Range: $time_range" | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # 1. Critical System Services
    echo "=== Critical Service Failures ===" | tee -a "$output_file"
    journalctl --since "$time_range" --priority=0..3 --no-pager | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # 2. Display Manager Issues
    echo "=== Display Manager (GDM) Issues ===" | tee -a "$output_file"
    journalctl --since "$time_range" --unit=gdm.service --no-pager | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # 3. Login Service Issues
    echo "=== Login Service Issues ===" | tee -a "$output_file"
    journalctl --since "$time_range" --unit=systemd-logind.service --no-pager | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # 4. Session Management
    echo "=== Session Management Events ===" | tee -a "$output_file"
    journalctl --since "$time_range" --grep="session.*logged out\|session.*created\|X connection" --no-pager | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # 5. Memory and Resource Issues
    echo "=== Memory/Resource Issues ===" | tee -a "$output_file"
    journalctl --since "$time_range" --grep="memory\|OOM\|kill\|resource" --no-pager | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # 6. NetworkManager Issues
    echo "=== Network Manager Issues ===" | tee -a "$output_file"
    journalctl --since "$time_range" --unit=NetworkManager.service --no-pager | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # 7. Current System Status
    echo "=== Current System Status ===" | tee -a "$output_file"
    echo "Memory Usage:" | tee -a "$output_file"
    free -h | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    echo "Top Memory Processes:" | tee -a "$output_file"
    ps aux --sort=-%mem | head -10 | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # 8. System Uptime
    echo "=== System Uptime ===" | tee -a "$output_file"
    uptime | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Analysis complete. Report saved to: $output_file"
    echo "Summary:" | tee -a "$output_file"
    
    # Generate summary
    local critical_services=$(journalctl --since "$time_range" --priority=0..3 --no-pager | wc -l)
    local gdm_failures=$(journalctl --since "$time_range" --unit=gdm.service --no-pager | grep -i "fail\|error\|terminate" | wc -l)
    local session_events=$(journalctl --since "$time_range" --grep="session.*logged out" --no-pager | wc -l)
    
    echo "- Critical service errors: $critical_services" | tee -a "$output_file"
    echo "- GDM failures: $gdm_failures" | tee -a "$output_file"  
    echo "- Session logouts: $session_events" | tee -a "$output_file"
}

check_memory_pressure() {
    echo "=== Memory Pressure Analysis ==="
    echo "Available memory:"
    free -h
    echo ""
    echo "Top memory consumers:"
    ps aux --sort=-%mem | head -10
    echo ""
    echo "Swap usage:"
    swapon --show
}

quick_diagnosis() {
    echo "=== Quick Diagnosis ==="
    
    # Check recent session terminations
    echo "Recent session events:"
    journalctl --since "1 hour ago" --grep="session.*logged out\|X connection" --no-pager
    echo ""
    
    # Check memory status
    echo "Current memory status:"
    free -h
    echo ""
    
    # Check service failures
    echo "Recent service failures:"
    journalctl --since "1 hour ago" --priority=0..3 --no-pager
}

# Main execution
case "${1:-analyze}" in
    "analyze")
        analyze_system_logs "${2:-2 hours ago}"
        ;;
    "memory")
        check_memory_pressure
        ;;
    "quick")
        quick_diagnosis
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [analyze|memory|quick] [time_range]"
        echo "  analyze: Full log analysis (default)"
        echo "  memory:  Memory pressure analysis"
        echo "  quick:   Quick diagnosis"
        echo "  time_range: '1 hour ago', '2 hours ago', etc."
        ;;
    *)
        echo "Unknown option. Use '$0 help' for usage."
        exit 1
        ;;
esac