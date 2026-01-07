# Security Dashboard - Final Clean Version
# This version has resolved all the loop and input handling issues

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Display menu with colors and better formatting
display_menu() {
    # Clear screen safely
    command -v clear >/dev/null 2>&1 && clear
    
    # Display header
    echo -e "${CYAN}🛡️  SECURITY DASHBOARD${NC}"
    echo -e "${CYAN}====================${NC}"
    echo ""
}

# Function to get user input with better error handling
get_input() {
    local prompt="$1"
    local timeout="${2:-30}"
    local response
    
    # Ensure terminal supports input
    if [[ $- == *i* ]]; then
        # Try to read with timeout
        if command -v timeout >/dev/null 2>&1; then
            read -t "$timeout" -p "$prompt" response 2>/dev/null || response=""
        else
            read -p "$prompt" response 2>/dev/null || response=""
        fi
    else
        echo -e "${RED}❌ Non-interactive terminal detected${NC}"
        echo -e "${YELLOW}Please run in an interactive terminal:${NC}"
        echo -e "${BLUE}bash -c 'source bash_functions.d/90-security/security.sh && security_dashboard'${NC}"
        echo -e "${CYAN}Usage:${NC}"
        echo -e "${BLUE}security_dashboard${NC}"
        echo -e "${CYAN}sec-help${NC}"
        echo ""
        return 1
    fi
    
    # Handle empty input
    if [[ -z "$response" ]]; then
        echo -e "${YELLOW}⏰  No input received${NC}"
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
        echo -e "${YELLOW}💡 Try running: ${BLUE}source bash_functions.d/90-security/security.sh${NC}"
        echo -e "${YELLOW}And then: ${CYAN}$func_name${NC}"
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
        
        # Handle timeout or empty input
        if [[ -z "$choice" ]]; then
            choice="0"  # Default to exit
            echo -e "${YELLOW}⏰  Timeout or no input, exiting...${NC}"
        fi
        
        # Process selection
        case "$choice" in
            1)
                execute_security_function "security_scan" "Security Scan"
                ;;
            2)
                execute_security_function "security_monitor" "Continuous Monitoring"
                ;;
            3)
                execute_security_function "security_ports" "Port Analysis"
                ;;
            4)
                execute_security_function "security_detect_scans" "Port Scan Detection"
                ;;
            5)
                execute_security_function "security_anonymity" "Anonymity Setup"
                ;;
            6)
                execute_security_function "security_status" "Security Status"
                ;;
            7)
                execute_security_function "security_logs" "Security Logs"
                ;;
            8)
                execute_security_function "security_toolkit" "Toolkit Information"
                ;;
            9)
                echo -e "${BLUE}→${NC}"
                echo -e "${YELLOW}⚠️  WARNING: This will execute emergency lockdown!${NC}"
                read -p "Confirm emergency lockdown? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    echo -e "${RED}🔒  INITIATING EMERGENCY LOCKDOWN...${NC}"
                    sleep 2
                    if command -v security_lockdown >/dev/null 2>&1; then
                        security_lockdown
                        echo -e "${GREEN}✅ Emergency lockdown completed${NC}"
                    else
                        echo -e "${YELLOW}Emergency lockdown cancelled${NC}"
                    fi
                else
                    echo -e "${YELLOW}Emergency lockdown cancelled${NC}"
                fi
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
        
        if [[ "$choice" != "0" && $loop_count -lt $((max_loops - 1)) ]]; then
            echo ""
            echo -e "${CYAN}Press Enter to continue (or Ctrl+C to exit)...${NC}"
            read -r
        fi
    done
    
    # Safety: if we exited due to max loops
    if [[ $loop_count -ge $max_loops ]]; then
        echo -e "${RED}⚠️  Maximum menu iterations reached. Exiting.${NC}"
    fi
}

# Show help
security_help() {
    echo -e "${CYAN}🛡️ Security Tools Help${NC}"
    echo -e "${CYAN}====================${NC}"
    echo ""
    echo -e "${YELLOW}Core Security Commands:${NC}"
    echo -e "${GREEN}  security_scan${NC}        ${BLUE}Quick security scan${NC}"
    echo -e "${GREEN}  security_monitor${NC}     ${BLUE}Start continuous monitoring${NC}"
    echo -e "${GREEN}  security_ports${NC}       ${BLUE}Port analysis${NC}"
    echo -e "${GREEN}  security_status${NC}      ${BLUE}Security status check${NC}"
    echo -e "${GREEN}  security_dashboard${NC}  ${BLUE}Interactive security dashboard${NC}"
    echo ""
    echo -e "${YELLOW}🛡️ Anonymity Commands:${NC}"
    echo -e "${GREEN}  security_anonymity${NC}   ${BLUE}Setup anonymity rules${NC}"
    echo ""
    echo -e "${YELLOW}🚨 Emergency Commands:${NC}"
    echo -e "${GREEN}  security_lockdown${NC}   ${BLUE}Emergency lockdown${NC}"
    echo -e "${GREEN}  security_report${NC}     ${BLUE}Generate security report${NC}"
    echo -e "${GREEN}  security_logs${NC}       ${BLUE}Show security logs${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Utility Commands:${NC}"
    echo -e "${GREEN}  security_install${NC}    ${BLUE}Install security dependencies${NC}"
    echo -e "${GREEN}  security_toolkit${NC}    ${BLUE}Show toolkit information${NC}"
    echo ""
    echo -e "${YELLOW}Quick Aliases:${NC}"
    echo -e "${GREEN}  sec-help${NC}           ${BLUE}Show this help${NC}"
    echo -e "${GREEN}  sec-scan${NC}           ${BLUE}Quick security scan${NC}"
    echo -e "${GREEN}  sec-mon${NC}            ${BLUE}Start monitoring${NC}"
    echo -e "${GREEN}  sec-ports${NC}           ${BLUE}Port analysis${NC}"
    echo -e "${GREEN}  sec-status${NC}         ${BLUE}Security status${NC}"
    echo -e "${GREEN}  sec-logs${NC}            ${BLUE}Security logs${NC}"
    echo -e "${GREEN}  sec-report${NC}          ${BLUE}Generate report${NC}"
    echo -e "${GREEN}  sec-lock${NC}            ${BLUE}Emergency lockdown${NC}"
    echo -e "${GREEN}  anon${NC}               ${BLUE}Setup anonymity${NC}"
    echo ""
    echo -e "${CYAN}====================${NC}"
}

# Initialize logging if not already done
if ! declare -f security_init >/dev/null; then
    security_init
fi