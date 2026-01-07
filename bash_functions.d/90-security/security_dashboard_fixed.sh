#!/bin/bash

# Robust Security Dashboard Implementation
# This version addresses common issues with interactive menus

robust_security_dashboard() {
    # Environment validation
    local dashboard_error=false
    local menu_choice=""
    local timeout_duration=30
    
    # Check if we're in an interactive terminal
    if [[ $- != *i* ]]; then
        echo "⚠️  Dashboard requires interactive shell"
        echo "Usage: bash -c 'source bash_functions.d/90-security/security.sh && security_dashboard'"
        return 1
    fi

    # Function to display menu
    display_menu() {
        # Clear screen safely
        if command -v clear >/dev/null 2>&1; then
            clear
        else
            # Print newlines to "clear" screen
            printf '\n%.0s' ''
        fi
        
        # Display header
        if command -v tput >/dev/null 2>&1; then
            tput cup 0 0
            echo -e "\033[1;32m🛡️  SECURITY DASHBOARD\033[0m"
            echo -e "\033[1;36m====================\033[0m"
        else
            echo "SECURITY DASHBOARD"
            echo "===================="
        fi
        echo ""
        
        # Display options
        echo "1. 📊 Quick Security Scan"
        echo "2. 🔍 Start Continuous Monitoring"
        echo "3. 🌐 Analyze Open Ports"
        echo "4. 🚨 Detect Port Scans"
        echo "5. 🛡️ Setup Anonymity Rules"
        echo "6. 📈 Security Status"
        echo "7. 📝 Show Security Logs"
        echo "8. 🧪 Security Toolkit Info"
        echo "9. 🚨 Emergency Lockdown"
        echo "10. 📊 Generate Security Report"
        echo "11. 🔧 Install Security Dependencies"
        echo "0.  Exit"
        echo ""
    }
    
    # Function to get user input with timeout and validation
    get_user_input() {
        local prompt="$1"
        local timeout="$2"
        local default_choice="$3"
        local user_input=""
        
        # Read with timeout
        if command -v timeout >/dev/null 2>&1; then
            read -t "$timeout" -p "$prompt" user_input
        else
            read -p "$prompt" user_input
        fi
        
        # Handle timeout or empty input
        if [[ -z "$user_input" ]]; then
            if [[ -n "$default_choice" ]]; then
                echo "⏰  Timeout or no input, using default: $default_choice"
                echo "$default_choice"
            else
                echo "⏰  Timeout, continuing..."
                echo "0"  # Default to exit
            fi
        else
            echo "$user_input"
        fi
    }
    
    # Function to process menu choice
    process_choice() {
        local choice="$1"
        
        case "$choice" in
            1)
                echo "→ Starting security scan..."
                if command -v security_scan >/dev/null; then
                    security_scan
                else
                    echo "❌ security_scan function not found"
                fi
                ;;
            2)
                echo "→ Starting continuous monitoring..."
                if command -v security_monitor >/dev/null; then
                    security_monitor
                else
                    echo "❌ security_monitor function not found"
                fi
                ;;
            3)
                echo "→ Analyzing ports..."
                if command -v security_ports >/dev/null; then
                    security_ports
                else
                    echo "❌ security_ports function not found"
                fi
                ;;
            4)
                echo "→ Detecting port scans..."
                if command -v security_detect_scans >/dev/null; then
                    security_detect_scans
                else
                    echo "❌ security_detect_scans function not found"
                fi
                ;;
            5)
                echo "→ Setting up anonymity rules..."
                if command -v security_anonymity >/dev/null; then
                    security_anonymity
                else
                    echo "❌ security_anonymity function not found"
                fi
                ;;
            6)
                echo "→ Checking security status..."
                if command -v security_status >/dev/null; then
                    security_status
                else
                    echo "❌ security_status function not found"
                fi
                ;;
            7)
                echo "→ Showing security logs..."
                if command -v security_logs >/dev/null; then
                    security_logs
                else
                    echo "❌ security_logs function not found"
                fi
                ;;
            8)
                echo "→ Showing security toolkit info..."
                if command -v security_toolkit >/dev/null; then
                    security_toolkit
                else
                    echo "❌ security_toolkit function not found"
                fi
                ;;
            9)
                echo "→ Initiating emergency lockdown..."
                echo "⚠️  WARNING: This will block most network traffic!"
                read -p "Confirm emergency lockdown? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    if command -v security_lockdown >/dev/null; then
                        security_lockdown
                    else
                        echo "❌ security_lockdown function not found"
                    fi
                else
                    echo "Emergency lockdown cancelled"
                fi
                ;;
            10)
                echo "→ Generating security report..."
                if command -v security_report >/dev/null; then
                    security_report
                else
                    echo "❌ security_report function not found"
                fi
                ;;
            11)
                echo "→ Installing security dependencies..."
                if command -v security_install >/dev/null; then
                    security_install
                else
                    echo "❌ security_install function not found"
                fi
                ;;
            0)
                echo "→ Exiting security dashboard..."
                return 0
                ;;
            *)
                echo "❌ Invalid choice: $choice"
                echo "Please select a number between 0 and 11"
                ;;
        esac
    }
    
    # Main menu loop
    local loop_count=0
    local max_loops=50  # Prevent infinite loops
    
    while [[ $loop_count -lt $max_loops ]]; do
        ((loop_count++))
        
        display_menu
        
        # Get user input with timeout
        local user_input
        user_input=$(get_user_input "Select option [0-11]: " "$timeout_duration" "0")
        
        # Process the choice
        process_choice "$user_input"
        
        # Check if user wants to exit
        if [[ "$user_input" == "0" ]]; then
            echo "Goodbye!"
            break
        fi
        
        echo ""
        echo "Press Enter to continue (or Ctrl+C to exit)..."
        read -r input
        echo ""
    done
    
    # Safety: if we exit due to max loops
    if [[ $loop_count -ge $max_loops ]]; then
        echo "⚠️  Maximum menu iterations reached. Exiting."
    fi
}

# Export the function for use
export -f robust_security_dashboard

# If script is run directly, execute the dashboard
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "🛡️  Starting Robust Security Dashboard"
    robust_security_dashboard
fi