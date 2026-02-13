#!/bin/bash
# Simple Security Dashboard Launcher

echo "🛡️  Launching Security Dashboard..."
echo "This will start an interactive terminal session"
echo ""

# Function to provide usage info
show_usage() {
    echo "Usage:"
    echo "  ./security_dashboard_launcher.sh          # Start dashboard in current terminal"
    echo "  ./security_dashboard_launcher.sh interactive   # Force interactive mode"
    echo "  ./security_dashboard_launcher.sh test         # Run functional test"
    echo ""
    echo "Security Functions (when loaded):"
    echo "  source bash_functions.d/90-security/security.sh"
    echo "  security_dashboard    # Start interactive dashboard"
    echo "  security_scan       # Quick security scan"
    echo "  security_status    # Check security status"
    echo ""
    echo "Quick Aliases (when loaded):"
    echo "  sec-help           # Show help"
    echo "  sec-scan           # Quick scan"
    echo "  sec-status         # Status check"
}

# Function to test security functions
test_functions() {
    echo "🧪 Testing Security Functions..."
    echo "================================="
    
    # Source security functions
    if [[ -f "bash_functions.d/90-security/security.sh" ]]; then
        source bash_functions.d/90-security/security.sh
        echo "✅ Security functions loaded"
    else
        echo "❌ Security functions not found"
        return 1
    fi
    
    # Test function availability
    local functions=("security_scan" "security_status" "security_help" "security_dashboard")
    local available=0
    local total=${#functions[@]}
    
    for func in "${functions[@]}"; do
        if declare -f "$func" >/dev/null; then
            echo "✅ $func function available"
            ((available++))
        else
            echo "❌ $func function NOT available"
        fi
    done
    
    echo ""
    echo "📊 Test Summary:"
    echo "Total functions tested: $total"
    echo "Available: $available/$total"
    echo "Success rate: $(( available * 100 / total ))%"
    
    # Show help if available
    if declare -f security_help >/dev/null; then
        echo ""
        echo "🔍 Help command available: security_help"
    fi
}

# Function to start interactive dashboard
start_interactive() {
    echo "🚀 Starting Interactive Security Dashboard..."
    echo "Loading security functions..."
    
    # Source security functions
    if [[ -f "bash_functions.d/90-security/security.sh" ]]; then
        source bash_functions.d/90-security/security.sh
        source bash_functions.d/90-security/security_aliases.bash
        echo "✅ Security functions loaded"
    else
        echo "❌ Security functions not found"
        exit 1
    fi
    
    # Start dashboard
    if declare -f security_dashboard >/dev/null; then
        echo "✅ Starting security dashboard..."
        echo "Use 'sec-help' for available commands"
        echo ""
        
        # Execute the dashboard
        security_dashboard
    else
        echo "❌ security_dashboard function not available"
        exit 1
    fi
}

# Main logic
case "${1:-}" in
    "interactive"|"-i"|"")
        start_interactive
        ;;
    "test"|"-t")
        test_functions
        ;;
    "help"|"-h")
        show_usage
        ;;
    *)
        # Default: try interactive mode
        echo "🚀 Starting Security Dashboard (default mode)..."
        start_interactive
        ;;
esac