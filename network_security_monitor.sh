#!/bin/bash
# Real-time network security monitor and anomaly detector

# Configuration
LOG_FILE="/var/log/network_security_monitor.log"
ALERT_THRESHOLD_CONNECTIONS=50
ALERT_THRESHOLD_PORT_SCAN=10
ALERT_THRESHOLD_BRUTE_FORCE=5
MONITORING_INTERFACE="eth0"
SCAN_WINDOW="60"  # seconds

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure we're running as root for some operations
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] This script requires root for full functionality${NC}"
        echo "Some features may not work properly"
    fi
}

# Initialize logging
setup_logging() {
    sudo mkdir -p "$(dirname "$LOG_FILE")"
    sudo touch "$LOG_FILE"
    sudo chmod 666 "$LOG_FILE"
    echo "$(date): Network security monitoring started" >> "$LOG_FILE"
}

# Monitor active connections and detect anomalies
monitor_connections() {
    echo -e "${BLUE}🔍 Monitoring active connections...${NC}"
    
    # Get connection counts by IP
    netstat -ntu 2>/dev/null | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | \
    while read -r count ip; do
        if [[ "$count" -gt "$ALERT_THRESHOLD_CONNECTIONS" ]] && [[ -n "$ip" ]]; then
            alert "HIGH_CONNECTIONS" "IP $ip has $count connections (threshold: $ALERT_THRESHOLD_CONNECTIONS)"
        fi
    done
}

# Detect potential port scans
detect_port_scans() {
    echo -e "${BLUE}🔍 Detecting port scans...${NC}"
    
    # Use recent iptables module or analyze connection patterns
    if command -v journalctl >/dev/null 2>&1; then
        recent_scans=$(sudo journalctl --since "5 minutes ago" | grep -i "portscan\|connection.*\]" | wc -l)
        if [[ "$recent_scans" -gt "$ALERT_THRESHOLD_PORT_SCAN" ]]; then
            alert "PORT_SCAN" "Recent port scan activity detected: $recent_scans attempts"
        fi
    fi
    
    # Alternative: Look for many connections from same IP to different ports
    netstat -ntu 2>/dev/null | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | \
    while read -r count ip; do
        if [[ "$count" -gt 10 ]] && [[ -n "$ip" ]]; then
            # Check if same IP is connecting to multiple ports
            port_count=$(netstat -ntu 2>/dev/null | grep "$ip" | awk '{print $4}' | cut -d: -f2 | sort | uniq | wc -l)
            if [[ "$port_count" -gt 5 ]]; then
                alert "SUSPICIOUS_PATTERN" "IP $ip connecting to $port_count different ports ($count total connections)"
            fi
        fi
    done
}

# Detect brute force attempts
detect_brute_force() {
    echo -e "${BLUE}🔍 Detecting brute force attempts...${NC}"
    
    if [[ -f "/var/log/auth.log" ]]; then
        # SSH brute force detection
        failed_attempts=$(sudo grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date '+%b %d')" | wc -l)
        if [[ "$failed_attempts" -gt "$ALERT_THRESHOLD_BRUTE_FORCE" ]]; then
            alert "BRUTE_FORCE" "SSH brute force detected: $failed_attempts failed attempts today"
        fi
        
        # Show recent failed attempts
        echo -e "${YELLOW}Recent SSH failures:${NC}"
        sudo grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5
    fi
}

# Monitor for suspicious processes
monitor_suspicious_processes() {
    echo -e "${BLUE}🔍 Monitoring for suspicious processes...${NC}"
    
    # Check for common backdoor tools
    suspicious_processes=$(ps aux 2>/dev/null | grep -E "(nc|ncat|socat|netcat)" | grep -v grep)
    if [[ -n "$suspicious_processes" ]]; then
        alert "SUSPICIOUS_PROCESS" "Suspicious network process detected:\n$suspicious_processes"
    fi
    
    # Check for listening on suspicious ports
    suspicious_ports=$(netstat -tlnp 2>/dev/null | grep -E ":(4444|5555|6666|7777|8888|9999|31337)")
    if [[ -n "$suspicious_ports" ]]; then
        alert "SUSPICIOUS_PORT" "Listening on suspicious port detected:\n$suspicious_ports"
    fi
}

# Check iptables status
check_firewall_status() {
    echo -e "${BLUE}🔍 Checking firewall status...${NC}"
    
    # Check if iptables has rules
    rule_count=$(sudo iptables -L | grep -c "^[A-Z]")
    echo -e "${GREEN}Active iptables rules: $rule_count${NC}"
    
    if [[ "$rule_count" -lt 5 ]]; then
        alert "WEAK_FIREWALL" "Very few iptables rules detected ($rule_count). Firewall may be inadequately configured."
    fi
    
    # Show top rules
    echo -e "${YELLOW}Top iptables rules:${NC}"
    sudo iptables -L -n | head -10
}

# Alert function
alert() {
    local alert_type="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${RED}🚨 ALERT [$alert_type]: $message${NC}"
    echo "$timestamp: ALERT [$alert_type]: $message" >> "$LOG_FILE"
    
    # You can add email/SMS alerts here
    # echo "$message" | mail -s "Security Alert: $alert_type" admin@example.com
}

# System information
show_system_info() {
    echo -e "${GREEN}=== SYSTEM INFORMATION ===${NC}"
    echo "Hostname: $(hostname)"
    echo "Interface: $MONITORING_INTERFACE"
    echo "IP Address: $(ip route get 1.1.1.1 | awk '{print $7; exit}')"
    echo "Uptime: $(uptime -p)"
    echo ""
}

# Show active connections summary
show_connection_summary() {
    echo -e "${GREEN}=== CONNECTION SUMMARY ===${NC}"
    
    # Total connections
    total_connections=$(netstat -ntu 2>/dev/null | wc -l)
    echo -e "Total connections: ${GREEN}$total_connections${NC}"
    
    # Top connection destinations
    echo -e "\n${YELLOW}Top 5 connection destinations:${NC}"
    netstat -ntu 2>/dev/null | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -5
    
    # Listening ports
    echo -e "\n${YELLOW}Listening ports:${NC}"
    netstat -tlnp 2>/dev/null | grep LISTEN | head -10
}

# Real-time monitoring mode
realtime_monitor() {
    echo -e "${GREEN}Starting real-time monitoring...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    
    while true; do
        clear
        show_system_info
        monitor_connections
        detect_port_scans
        detect_brute_force
        monitor_suspicious_processes
        show_connection_summary
        
        echo -e "\n${BLUE}Next check in 30 seconds...$(date)${NC}"
        sleep 30
    done
}

# One-time scan mode
quick_scan() {
    echo -e "${GREEN}=== NETWORK SECURITY QUICK SCAN ===${NC}"
    show_system_info
    monitor_connections
    detect_port_scans
    detect_brute_force
    monitor_suspicious_processes
    check_firewall_status
    show_connection_summary
    
    echo -e "\n${GREEN}Scan completed. Log saved to: $LOG_FILE${NC}"
}

# Install required tools
install_tools() {
    echo -e "${BLUE}Installing required tools...${NC}"
    
    tools=(net-tools nethogs iftop iptraf-ng)
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "Installing $tool..."
            sudo apt install "$tool" -y
        fi
    done
    
    echo -e "${GREEN}Tools installation completed${NC}"
}

# Show usage
show_usage() {
    echo "Network Security Monitor"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  scan        - Perform one-time security scan"
    echo "  monitor     - Start real-time monitoring"
    echo "  install     - Install required tools"
    echo "  help        - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 scan     # Quick security check"
    echo "  $0 monitor  # Continuous monitoring"
}

# Main function
main() {
    case "${1:-scan}" in
        "scan")
            check_root
            setup_logging
            quick_scan
            ;;
        "monitor")
            check_root
            setup_logging
            realtime_monitor
            ;;
        "install")
            install_tools
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"