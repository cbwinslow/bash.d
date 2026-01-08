#!/bin/bash
# Test the fixed security dashboard

echo "🧪 Testing Security Dashboard Fix"
echo "================================="
echo ""

# Load all security functions
source bash_functions.d/90-security/security.sh
source bash_functions.d/90-security/security_aliases.bash

echo "✅ Loaded security functions"

# Test if security_dashboard is now available
if declare -f security_dashboard >/dev/null; then
    echo "✅ security_dashboard function is available"
    
    # Test simple menu call
    echo "🧪 Testing simple menu interface..."
    
    # Create a minimal test menu
    test_menu() {
        local choice=""
        echo "🧪 TEST MENU"
        echo "============"
        echo "1. Test security_scan"
        echo "2. Test security_status"
        echo "3. Exit"
        echo ""
        read -t 10 -p "Select option [1-3]: " choice || choice="3"
        
        case "$choice" in
            1)
                if command -v security_scan >/dev/null; then
                    echo "✅ Testing security_scan..."
                    security_scan
                else
                    echo "❌ security_scan not found"
                fi
                ;;
            2)
                if command -v security_status >/dev/null; then
                    echo "✅ Testing security_status..."
                    security_status
                else
                    echo "❌ security_status not found"
                fi
                ;;
            3|*)
                echo "✅ Exiting test menu"
                ;;
        esac
    }
    
    # Run the test menu
    test_menu
else
    echo "❌ security_dashboard function still NOT available"
    
    # Check what functions were loaded
    echo "📋 Available security functions:"
    declare -F | grep "security_" | head -10
fi

echo ""
echo "✅ Test completed"