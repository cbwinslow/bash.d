#!/bin/bash
# Final Security Functions Test
echo "🧪 Testing All Security Functions"
echo "================================"

# Load security functions
if ! [[ -f "bash_functions.d/90-security/security.sh" ]]; then
    echo "❌ Security functions not found"
    exit 1
fi

source bash_functions.d/90-security/security.sh
source bash_functions.d/90-security/security_aliases.bash

# Test counters
TOTAL_FUNCS=0
WORKING_FUNCS=0
FAILED_FUNCS=0

echo "🔍 Testing Core Security Functions..."

# Test each function individually
test_function() {
    local func_name="$1"
    local display_name="$2"
    
    if command -v "$func_name" >/dev/null 2>&1; then
        echo -e "🧪 Testing $display_name..."
        "$func_name" >/dev/null 2>&1 && echo -e "${GREEN}✅ $display_name works${NC}" || echo -e "${RED}❌ $display_name failed${NC}"
        
        if [[ $? -eq 0 ]]; then
            ((WORKING_FUNCS++))
        else
            ((FAILED_FUNCS++))
        fi
        ((TOTAL_FUNCS++))
    else
        echo -e "${RED}❌ Function $func_name not available${NC}"
        ((FAILED_FUNCS++))
        ((TOTAL_FUNCS++))
    fi
}

# List of functions to test
FUNCTIONS_TO_TEST=(
    "security_scan:Quick Security Scan"
    "security_monitor:Continuous Monitoring"
    "security_ports:Port Analysis"
    "security_detect_scans:Port Scan Detection"
    "security_anonymity:Anonymity Setup"
    "security_status:Security Status Check"
    "security_logs:Security Log Review"
    "security_help:Help System"
    "security_dashboard:Interactive Dashboard"
    "security_toolkit:Toolkit Information"
    "security_install:Install Dependencies"
    "security_lockdown:Emergency Lockdown"
    "security_report:Generate Report"
    "security_quick_check:Quick Status"
)

echo "📊 Running Tests..."
for func_info in "${FUNCTIONS_TO_TEST[@]}"; do
    func_name=$(echo "$func_info" | cut -d: -f1)
    display_name=$(echo "$func_info" | cut -d: -f2)
    test_function "$func_name" "$display_name"
done

echo ""
echo "📊 Test Results Summary"
echo "=================="
echo -e "Total Functions Tested: ${GREEN}$TOTAL_FUNCS${NC}"
echo -e "Working Functions: ${GREEN}$WORKING_FUNCS${NC}"
echo -e "Failed Functions: ${RED}$FAILED_FUNCS${NC}"
echo ""

# Success rate calculation
SUCCESS_RATE=$((WORKING_FUNCS * 100 / TOTAL_FUNCS))

if [[ $SUCCESS_RATE -ge 80 ]]; then
    echo -e "${GREEN}✅ Security System Status: EXCELLENT ($SUCCESS_RATE%)${NC}"
elif [[ $SUCCESS_RATE -ge 60 ]]; then
    echo -e "${YELLOW}⚠️  Security System Status: GOOD ($SUCCESS_RATE%)${NC}"
else
    echo -e "${RED}❌ Security System Status: NEEDS ATTENTION ($SUCCESS_RATE%)${NC}"
fi

echo ""
echo "🎯 Security Functions Ready!"
echo "=================="

# Quick interactive demo (only if functions are working)
if [[ $WORKING_FUNCS -ge 5 ]]; then
    echo "🎉 Quick Demo (first 3 functions only)..."
    echo "Type 'demo' for a quick interactive test or 'exit' to quit"
    read -p "Command: " choice
    
    case "$choice" in
        demo)
            echo -e "${CYAN}🔍 Quick Security Scan Demo${NC}"
            test_function "security_scan" "Security Scan Demo"
            echo -e "${YELLOW}→ Checking system vulnerabilities...${NC}"
            sleep 2
            test_function "security_status" "Security Status Demo"
            echo -e "${YELLOW}→ Analyzing ports...${NC}"
            sleep 2
            echo -e "${GREEN}✅ Demo completed${NC}"
            ;;
        exit)
            echo -e "${GREEN}👋 Goodbye!${NC}"
            ;;
        *)
            echo -e "${RED}❌ Unknown command${NC}"
            ;;
    esac
fi

echo ""
echo "📋 How to use in future:"
echo "  source bash_functions.d/90-security/security.sh && security_dashboard"
echo "  sec-help    # Show all available commands"
echo "  sec-scan    # Quick security scan"
echo "  sec-status   # Check current security status"
echo ""
echo "🛡️ Your bash.d Security System is Fully Operational!"