#!/bin/bash
# Port scan detection and analysis tool

# Configuration
SCAN_LOG="/var/log/port_scans.log"
ALERT_THRESHOLD=20
TIME_WINDOW="300"  # 5 minutes in seconds

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect port scans using multiple methods
detect_port_scans() {
    echo -e "${BLUE}🔍 Detecting port scans...${NC}"
    
    # Method 1: Analyze recent connection attempts
    echo -e "${YELLOW}Method 1: Connection pattern analysis${NC}"
    
    # Get recent connection attempts from various sources
    recent_connections=$(sudo journalctl --since "5 minutes ago" | grep -i "connection\| refused\| rejected" | wc -l)
    echo "Recent connection attempts: $recent_connections"
    
    # Method 2: Analyze netstat for suspicious patterns
    echo -e "\n${YELLOW}Method 2: Netstat analysis${NC}"
    
    # Look for IPs connecting to multiple ports
    netstat -ntu 2>/dev/null | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | \
    while read -r count ip; do
        if [[ "$count" -gt 10 ]] && [[ -n "$ip" ]] && [[ "$ip" != "127.0.0.1" ]]; then
            # Check if connecting to multiple ports
            port_count=$(netstat -ntu 2>/dev/null | grep "$ip" | awk '{print $4}' | cut -d: -f2 | sort | uniq | wc -l)
            
            if [[ "$port_count" -gt 5 ]]; then
                echo -e "${RED}🚨 POTENTIAL PORT SCAN: $ip connecting to $port_count ports ($count total connections)${NC}"
                log_scan_attempt "$ip" "$count" "$port_count"
            fi
        fi
    done
    
    # Method 3: Check iptables recent module (if available)
    echo -e "\n${YELLOW}Method 3: Iptables recent module${NC}"
    
    if sudo iptables -L INPUT -n | grep -q "recent"; then
        echo "Iptables recent module is active"
        sudo iptables -L INPUT -n -v | head -10
    else
        echo "Iptables recent module not configured"
    fi
    
    # Method 4: Check system logs for scan indicators
    echo -e "\n${YELLOW}Method 4: Log analysis${NC}"
    
    # Check for patterns in auth log
    if [[ -f "/var/log/auth.log" ]]; then
        auth_scans=$(sudo grep "$(date '+%b %d')" /var/log/auth.log | grep -c "Invalid user\|connection from")
        echo "Auth-based scan attempts today: $auth_scans"
        
        if [[ "$auth_scans" -gt 50 ]]; then
            echo -e "${RED}🚨 High number of auth-based scans detected!${NC}"
        fi
    fi
}

# Detect SYN flood attacks
detect_syn_flood() {
    echo -e "\n${BLUE}🔍 Detecting SYN flood attempts...${NC}"
    
    # Use tcpdump to monitor SYN packets (requires root)
    if command -v tcpdump >/dev/null 2>&1 && [[ $EUID -eq 0 ]]; then
        echo "Monitoring SYN packets for 10 seconds..."
        syn_count=$(timeout 10 tcpdump -i eth0 -nn "tcp[tcpflags] & tcp-syn != 0" 2>/dev/null | wc -l)
        
        if [[ "$syn_count" -gt 100 ]]; then
            echo -e "${RED}🚨 Potential SYN flood detected: $syn_count SYN packets in 10 seconds${NC}"
            log_attack_attempt "SYN_FLOOD" "$syn_count"
        else
            echo -e "${GREEN}SYN packet rate appears normal: $syn_count packets in 10 seconds${NC}"
        fi
    else
        echo "tcpdump not available or not root - skipping SYN flood detection"
    fi
}

# Analyze current port status
analyze_open_ports() {
    echo -e "\n${BLUE}🔍 Analyzing open ports...${NC}"
    
    # Show listening ports
    echo -e "${YELLOW}Currently listening ports:${NC}"
    netstat -tlnp 2>/dev/null | grep LISTEN | while read -r line; do
        port=$(echo "$line" | awk '{print $4}' | cut -d: -f2)
        service=$(echo "$line" | awk '{print $7}' | cut -d/ -f2)
        echo -e "  Port ${GREEN}$port${NC} - Service: ${BLUE}$service${NC}"
        
        # Check for common vulnerable ports
        case "$port" in
            23|135|139|445|3389|1433|3306)
                echo -e "    ${RED}⚠️  Potentially vulnerable service!${NC}"
                ;;
        esac
    done
    
    # Check for unexpected ports
    echo -e "\n${YELLOW}Checking for unexpected services:${NC}"
    
    common_ports=(22 80 443 53 25 110 143 993 995 587)
    netstat -tlnp 2>/dev/null | grep LISTEN | awk '{print $4}' | cut -d: -f2 | while read -r port; do
        if [[ ! " ${common_ports[@]} " =~ " $port " ]]; then
            service=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d/ -f2)
            echo -e "  ${YELLOW}⚠️  Unexpected port $port (service: $service)${NC}"
        fi
    done
}

# Port vulnerability assessment
check_port_vulnerabilities() {
    echo -e "\n${BLUE}🔍 Checking port vulnerabilities...${NC}"
    
    # Check for common vulnerable services
    vulnerable_ports=(
        "23:Telnet - Unencrypted remote access"
        "135:Windows RPC - DCOM vulnerabilities"
        "139:NetBIOS - Windows file sharing"
        "445:SMB - EternalBlue vulnerabilities"
        "3389:RDP - BlueScreen vulnerabilities"
        "1433:MSSQL - Database access"
        "3306:MySQL - Database access"
        "5432:PostgreSQL - Database access"
        "6379:Redis - No authentication required"
        "27017:MongoDB - No authentication required"
    )
    
    for entry in "${vulnerable_ports[@]}"; do
        port=$(echo "$entry" | cut -d: -f1)
        description=$(echo "$entry" | cut -d: -f2-)
        
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            echo -e "  ${RED}⚠️  Port $port open: $description${NC}"
        fi
    done
}

# Generate port hardening recommendations
generate_recommendations() {
    echo -e "\n${BLUE}📋 Port Hardening Recommendations:${NC}"
    
    # Check what needs to be secured
    open_ports=$(netstat -tlnp 2>/dev/null | grep LISTEN | wc -l)
    echo -e "Total open ports: ${YELLOW}$open_ports${NC}"
    
    if [[ "$open_ports" -gt 10 ]]; then
        echo -e "${RED}⚠️  Consider reducing the number of open ports${NC}"
    fi
    
    echo -e "\n${YELLOW}Recommended actions:${NC}"
    echo "1. Close unnecessary services: sudo systemctl disable <service>"
    echo "2. Use firewall to block unauthorized access:"
    echo "   sudo iptables -A INPUT -p tcp --dport <port> -j DROP"
    echo "3. Implement rate limiting for SSH:"
    echo "   sudo iptables -A INPUT -p tcp --dport 22 -m limit --limit 3/min -j ACCEPT"
    echo "4. Use fail2ban for automatic blocking"
    echo "5. Regularly update services to patch vulnerabilities"
    
    # Show iptables status
    echo -e "\n${YELLOW}Current firewall status:${NC}"
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw status
    elif [[ $(sudo iptables -L | wc -l) -gt 10 ]]; then
        echo -e "${GREEN}iptables rules configured ($(sudo iptables -L | wc -l) rules)${NC}"
    else
        echo -e "${RED}⚠️  No significant firewall rules detected${NC}"
    fi
}

# Log function
log_scan_attempt() {
    local ip="$1"
    local connections="$2"
    local ports="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp: PORT_SCAN - IP: $ip, Connections: $connections, Ports: $ports" >> "$SCAN_LOG"
}

log_attack_attempt() {
    local attack_type="$1"
    local count="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp: $attack_type - Count: $count" >> "$SCAN_LOG"
}

# Setup logging
setup_logging() {
    sudo mkdir -p "$(dirname "$SCAN_LOG")"
    sudo touch "$SCAN_LOG"
    sudo chmod 666 "$SCAN_LOG"
    echo "$(date): Port scan monitoring initialized" >> "$SCAN_LOG"
}

# Show recent scan history
show_scan_history() {
    echo -e "\n${BLUE}📜 Recent Scan History:${NC}"
    
    if [[ -f "$SCAN_LOG" ]]; then
        tail -10 "$SCAN_LOG"
    else
        echo "No scan history available"
    fi
}

# Interactive port scan
interactive_scan() {
    echo -e "${GREEN}=== INTERACTIVE PORT SCAN ===${NC}"
    
    read -p "Enter IP to scan (or press Enter to scan localhost): " target_ip
    target_ip=${target_ip:-127.0.0.1}
    
    read -p "Enter port range (default 1-1000): " port_range
    port_range=${port_range:-"1-1000"}
    
    echo -e "${BLUE}Scanning $target_ip ports $port_range...${NC}"
    
    if command -v nmap >/dev/null 2>&1; then
        nmap -sS -p "$port_range" "$target_ip" --open
    else
        # Simple port scan using netcat
        for port in $(seq "${port_range%-*}" "${port_range#*-}"); do
            timeout 1 bash -c "</dev/tcp/$target_ip/$port" 2>/dev/null && echo "Port $port open"
        done
    fi
}

# Show usage
show_usage() {
    echo "Port Scan Detection and Analysis Tool"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  detect      - Detect current port scan attempts"
    echo "  analyze     - Analyze open ports and vulnerabilities"
    echo "  history     - Show scan history"
    echo "  interactive - Interactive port scanning mode"
    echo "  monitor     - Continuous monitoring mode"
    echo "  help        - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 detect    # Check for ongoing port scans"
    echo "  $0 analyze   # Analyze your open ports"
}

# Continuous monitoring
continuous_monitor() {
    echo -e "${GREEN}Starting continuous port scan monitoring...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    
    while true; do
        clear
        detect_port_scans
        detect_syn_flood
        show_scan_history
        echo -e "\n${BLUE}Next check in 60 seconds...$(date)${NC}"
        sleep 60
    done
}

# Main function
main() {
    case "${1:-detect}" in
        "detect")
            setup_logging
            detect_port_scans
            detect_syn_flood
            ;;
        "analyze")
            analyze_open_ports
            check_port_vulnerabilities
            generate_recommendations
            ;;
        "history")
            show_scan_history
            ;;
        "interactive")
            interactive_scan
            ;;
        "monitor")
            setup_logging
            continuous_monitor
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