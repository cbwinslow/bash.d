#!/bin/bash
# Working Security Dashboard
# This version handles all the issues found in testing

# ANSI Colors for better display
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Display menu with colors and better formatting
display_menu() {
    # Clear screen only if we have colors
    command -v clear >/dev/null 2>&1 && clear
    
    # Header
    echo -e "${BOLD}${CYAN}🛡️  SECURITY DASHBOARD${NC}"
    echo -e "${CYAN}====================${NC}"
    echo ""
    
    # Menu items with descriptions
    echo -e "${GREEN}1.${NC} ${YELLOW}📊 Quick Security Scan${NC}"
    echo -e "   ${BLUE}→${NC} Fast security vulnerability assessment"
    echo ""
    
    echo -e "${GREEN}2.${NC} ${YELLOW}🔍 Start Continuous Monitoring${NC}"
    echo -e "   ${BLUE}→${NC} Real-time threat detection"
    echo ""
    
    echo -e "${GREEN}3.${NC} ${YELLOW}🌐 Analyze Open Ports${NC}"
    echo -e "   ${BLUE}→${NC} Port scanning and vulnerability assessment"
    echo ""
    
    echo -e "${GREEN}4.${NC} ${YELLOW}🚨 Detect Port Scans${NC}"
    echo -e "   ${BLUE}→${NC} Identify active scanning attempts"
    echo ""
    
    echo -e "${GREEN}5.${NC} ${YELLOW}🛡️ Setup Anonymity Rules${NC}"
    echo -e "   ${BLUE}→${NC} Configure DNS leak protection and traffic forcing"
    echo ""
    
    echo -e "${GREEN}6.${NC} ${YELLOW}📈 Security Status${NC}"
    echo -e "   ${BLUE}→${NC} Check current security configuration"
    echo ""
    
    echo -e "${GREEN}7.${NC} ${YELLOW}📝 Show Security Logs${NC}"
    echo -e "   ${BLUE}→${NC} View recent security events"
    echo ""
    
    echo -e "${GREEN}8.${NC} ${YELLOW}🧪 Security Toolkit Info${NC}"
    echo -e "   ${BLUE}→${NC} Show available security tools and functions"
    echo ""
    
    echo -e "${GREEN}9.${NC} ${YELLOW}⚡ Performance Analysis${NC}"
    echo -e "   ${BLUE}→${NC} Analyze script performance and suggest optimizations"
    echo ""
    
    echo -e "${GREEN}0.${NC} ${RED}Exit${NC}"
    echo -e "   ${BLUE}→${NC} Exit dashboard"
    echo ""
    
    echo -e "${CYAN}====================${NC}"
    echo ""
}

# Function to get user input with better error handling
get_input() {
    local prompt="$1"
    local timeout="${2:-30}"
    local response
    
    # Try to read with timeout
    if command -v timeout >/dev/null 2>&1; then
        read -t "$timeout" -p "$prompt" response 2>/dev/null || response=""
    else
        read -p "$prompt" response 2>/dev/null || response=""
    fi
    
    # Handle empty input
    if [[ -z "$response" ]]; then
        echo -e "${YELLOW}⏰  Timeout or no input${NC}"
        echo ""
        return 1
    fi
    
    echo "$response"
}

# Function to execute security functions with error handling
execute_security_function() {
    local func_name="$1"
    local display_name="$2"
    
    echo -e "${BLUE}→ Starting $display_name...${NC}"
    
    if command -v "$func_name" >/dev/null 2>&1; then
        "$func_name"
        echo -e "${GREEN}✅ $display_name completed${NC}"
    else
        echo -e "${RED}❌ Function '$func_name' not available${NC}"
        echo -e "${YELLOW}💡 Try running: source bash_functions.d/90-security/security.sh${NC}"
    fi
}

# Main dashboard function
security_dashboard() {
    # Main menu loop
    local loop_count=0
    local max_loops=50  # Safety limit
    
    while [[ $loop_count -lt $max_loops ]]; do
        ((loop_count++))
        
        display_menu
        
        echo -e "${CYAN}Select option [0-9]:${NC} "
        local choice
        choice=$(get_input "")
        
        # Process choice
        case "$choice" in
            1)
                execute_security_function "security_scan" "security scan"
                ;;
            2)
                execute_security_function "security_monitor" "continuous monitoring"
                ;;
            3)
                execute_security_function "security_ports" "port analysis"
                ;;
            4)
                execute_security_function "security_detect_scans" "port scan detection"
                ;;
            5)
                execute_security_function "security_anonymity" "anonymity setup"
                ;;
            6)
                execute_security_function "security_status" "security status check"
                ;;
            7)
                execute_security_function "security_logs" "security logs review"
                ;;
            8)
                execute_security_function "security_toolkit" "toolkit information"
                ;;
            9)
                execute_security_function "security_quick_check" "quick security check"
                ;;
            0)
                echo -e "${GREEN}👋 Goodbye!${NC}"
                break
                ;;
            *)
                echo -e "${RED}❌ Invalid option: $choice${NC}"
                echo -e "${YELLOW}Please select a number between 0 and 9${NC}"
                ;;
        esac
        
        echo ""
        if [[ "$choice" != "0" && $loop_count -lt $((max_loops - 1)) ]]; then
            echo -e "${CYAN}Press Enter to continue (or Ctrl+C to exit)...${NC}"
            read -r
        fi
        
        # Safety: handle Ctrl+C gracefully
        trap 'echo -e "\n${YELLOW}⚠️  Dashboard interrupted${NC}"; break' INT
        
    done
    
    echo -e "${GREEN}✅ Security dashboard completed${NC}"
}

# Show help
security_help() {
    echo -e "${BOLD}${CYAN}🛡️ Security Tools Help${NC}"
    echo -e "${CYAN}====================${NC}"
    echo ""
    echo -e "${YELLOW}Quick Commands:${NC}"
    echo "  ${GREEN}security_dashboard${NC}    - Interactive security dashboard"
    echo "  ${GREEN}security_scan${NC}       - Quick security scan"
    echo "  ${GREEN}security_monitor${NC}      - Start continuous monitoring"
    echo "  ${GREEN}security_ports${NC}       - Port analysis"
    echo "  ${GREEN}security_status${NC}      - Security status check"
    echo "  ${GREEN}security_anonymity${NC}   - Setup anonymity rules"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ${BLUE}source bash_functions.d/90-security/security.sh${NC}"
    echo "  ${BLUE}security_dashboard${NC}"
    echo ""
}

# Check if being called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    security_dashboard "$@"
fi