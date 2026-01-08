#!/bin/bash
# Security Dashboard Test and Debug Script

echo "🔍 Testing Security Dashboard Functionality"
echo "=========================================="
echo ""

# Test 1: Check if security.sh is loaded
echo "📋 Test 1: Function Loading Test"
if declare -f security_dashboard >/dev/null; then
    echo "✅ security_dashboard function exists"
else
    echo "❌ security_dashboard function NOT found"
    echo "Loading security functions..."
    source bash_functions.d/90-security/security.sh 2>/dev/null
    if declare -f security_dashboard >/dev/null; then
        echo "✅ Functions loaded successfully"
    else
        echo "❌ FAILED to load security functions"
        exit 1
    fi
fi

echo ""

# Test 2: Check security_dashboard function content
echo "📋 Test 2: Function Content Check"
if declare -f security_dashboard >/dev/null; then
    echo "✅ Checking security_dashboard function definition..."
    
    # Check if function has a while loop (typical for interactive menus)
    if type security_dashboard | grep -q "while"; then
        echo "✅ Has interactive loop"
    else
        echo "⚠️  No interactive loop detected"
    fi
    
    # Check for read commands
    if type security_dashboard | grep -q "read"; then
        echo "✅ Has user input handling"
    else
        echo "⚠️  No read commands found"
    fi
    
    # Check for case statement
    if type security_dashboard | grep -q "case"; then
        echo "✅ Has case statement for menu"
    else
        echo "⚠️  No case statement found"
    fi
fi

echo ""

# Test 3: Try to call security_dashboard with timeout
echo "📋 Test 3: Function Execution Test"
echo "Calling security_dashboard with 10-second timeout..."

# Create a test version that will timeout
timeout 10s bash -c '
    source bash_functions.d/90-security/security.sh
    echo "Type any option (1-8) within 10 seconds..."
    security_dashboard
' &
DASHBOARD_PID=$!

# Wait a bit for it to start
sleep 2

# Check if process is running
if kill -0 $DASHBOARD_PID 2>/dev/null; then
    echo "✅ Dashboard process started (PID: $DASHBOARD_PID)"
    echo "✅ Menu should be displayed"
    
    # Kill it after testing
    sleep 3
    kill $DASHBOARD_PID 2>/dev/null
    wait $DASHBOARD_PID 2>/dev/null
    echo "✅ Process terminated for testing"
else
    echo "❌ Dashboard process failed to start properly"
fi

echo ""

# Test 4: Check individual menu functions
echo "📋 Test 4: Individual Menu Function Tests"

# Check if all referenced functions exist
MENU_FUNCTIONS=(
    "security_scan"
    "security_monitor" 
    "security_ports"
    "security_detect_scans"
    "security_anonymity"
    "security_status"
    "security_logs"
    "security_toolkit"
)

for func in "${MENU_FUNCTIONS[@]}"; do
    if declare -f "$func" >/dev/null; then
        echo "✅ $func function exists"
    else
        echo "❌ $func function NOT found"
    fi
done

echo ""

# Test 5: Test a simpler menu implementation
echo "📋 Test 5: Simple Menu Implementation Test"

simple_test_menu() {
    echo "🧪 Simple Test Menu"
    echo "=================="
    echo "1. Test Option 1"
    echo "2. Test Option 2" 
    echo "3. Test Option 3"
    echo "0. Exit"
    echo ""
    read -p "Select option [0-3]: " choice
    
    case $choice in
        1) echo "✅ Option 1 selected" ;;
        2) echo "✅ Option 2 selected" ;;
        3) echo "✅ Option 3 selected" ;;
        0) echo "✅ Exiting..." ;;
        *) echo "❌ Invalid option" ;;
    esac
}

echo "Testing simple menu..."
timeout 5s simple_test_menu &
SIMPLE_PID=$!
sleep 1

if kill -0 $SIMPLE_PID 2>/dev/null; then
    echo "✅ Simple menu works"
    kill $SIMPLE_PID 2>/dev/null
    wait $SIMPLE_PID 2>/dev/null
else
    echo "❌ Simple menu failed"
fi

echo ""

# Test 6: Environment Check
echo "📋 Test 6: Environment Check"

# Check shell type
echo "Shell: $SHELL"

# Check if running interactively
if [[ $- == *i* ]]; then
    echo "✅ Interactive shell detected"
else
    echo "⚠️  Non-interactive shell - menus may not work"
fi

# Check terminal capabilities
if command -v tput >/dev/null 2>&1; then
    echo "✅ Terminal capabilities available (colors, cursor control)"
else
    echo "⚠️  Limited terminal capabilities"
fi

echo ""

# Test 7: Check dependencies
echo "📋 Test 7: Dependencies Check"

DEPENDENCIES=("bash" "grep" "sed" "awk" "read")
for dep in "${DEPENDENCIES[@]}"; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo "✅ $dep available"
    else
        echo "❌ $dep NOT available"
    fi
done

echo ""

# Test 8: Function reload test
echo "📋 Test 8: Function Reload Test"

echo "Testing function reloading..."
source bash_functions.d/90-security/security_aliases.bash

# Check if aliases are loaded
if alias sec-help >/dev/null 2>&1; then
    echo "✅ Security aliases loaded"
else
    echo "❌ Security aliases NOT loaded"
fi

echo ""

# Test 9: Create a robust dashboard version
echo "📋 Test 9: Robust Dashboard Creation"