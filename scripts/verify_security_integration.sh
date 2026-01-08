#!/bin/bash
# Security Tools Verification and Integration Test

echo "🛡️ SECURITY TOOLS INTEGRATION VERIFICATION"
echo "=========================================="
echo ""

# Test functions
echo "🔧 Testing Security Functions:"
echo ""

# Check if security functions are loaded
if declare -f security_help >/dev/null; then
    echo "✅ Security functions loaded"
else
    echo "⚠️ Security functions not loaded - loading now..."
    source bash_functions.d/90-security/security.sh
    source bash_functions.d/90-security/security_aliases.bash
fi

# Show available functions
echo ""
echo "📋 Available Security Functions:"
declare -F | grep "security_" | sed 's/declare -f/  /'
echo ""

echo "🔖 Available Security Aliases:"
alias | grep "sec-\|anon\|check-" | head -10
echo ""

echo "🛠️ Security Scripts Available:"
if [[ -d "tools/security" ]]; then
    echo "✅ Tools directory found:"
    ls -1 tools/security/
else
    echo "❌ Security tools directory not found"
fi

echo ""
echo "📚 Documentation Available:"
if [[ -f "docs/security_tools.md" ]]; then
    echo "✅ Security documentation: docs/security_tools.md"
else
    echo "❌ Security documentation not found"
fi

if [[ -f "tools/security_index.md" ]]; then
    echo "✅ Security index: tools/security_index.md"
else
    echo "❌ Security index not found"
fi

echo ""
echo "🪪 Anonymity Tools Available:"
if [[ -d "tools/security/4nonimizer" ]]; then
    echo "✅ 4nonimizer available"
else
    if [[ -d "4nonimizer" ]]; then
        echo "⚠️ 4nonimizer found in root"
    else
        echo "❌ 4nonimizer not found"
    fi
fi

if [[ -d "tools/security/kali-anonymous" ]]; then
    echo "✅ kali-anonymous available"
else
    if [[ -d "kali-anonymous" ]]; then
        echo "⚠️ kali-anonymous found in root"
    else
        echo "❌ kali-anonymous not found"
    fi
fi

echo ""
echo "🚀 Quick Test Commands:"
echo ""
echo "# Test security help (should show commands):"
echo "security_help"
echo ""
echo "# Test quick scan (requires sudo):"
echo "security_quick_check"
echo ""
echo "# Test security status:"
echo "security_status"
echo ""
echo "# Test alias (should work):"
echo "sec-status"
echo ""

echo "📋 Security Functions Usage Guide:"
echo ""
echo "🔍 Core Security:"
echo "  security_scan           - Quick security scan"
echo "  security_monitor        - Start continuous monitoring"
echo "  security_ports          - Analyze open ports"
echo "  security_status         - Show current security status"
echo "  security_dashboard      - Interactive security dashboard"
echo ""
echo "🛡️ Anonymity:"
echo "  security_anonymity     - Setup anonymity rules"
echo ""
echo "🚨 Emergency:"
echo "  security_lockdown     - Emergency lockdown"
echo "  security_report       - Generate security report"
echo ""
echo "🪪 Quick Commands:"
echo "  sec-help               - Show all security commands"
echo "  sec-scan               - Quick security scan"
echo "  sec-mon                - Start monitoring"
echo "  sec-status             - Security status"
echo "  sec-ports              - Port analysis"
echo "  sec-logs               - View security logs"
echo "  sec-report             - Generate security report"
echo "  sec-lock               - Emergency lockdown"
echo "  anon                   - Setup anonymity"
echo ""
echo "🔧 Utilities:"
echo "  check-ip               - Check current external IP"
echo "  check-firewall          - Show iptables rules"
echo "  check-connections      - Show active connections"
echo "  check-auth             - Show recent auth attempts"
echo "  backup-rules           - Backup firewall rules"
echo "  restore-rules          - Restore firewall rules"
echo ""
echo "⚠️ Requirements:"
echo "  • Root access for full functionality"
echo "  • iptables for firewall rules"
echo "  • Basic networking tools (netstat, ss, etc.)"
echo "  • Optional: nmap, fail2ban, nethogs"
echo ""
echo "📚 Documentation:"
echo "  • docs/security_tools.md - Comprehensive guide"
echo "  • tools/security_index.md - Tools reference"
echo ""
echo "🔄 To reload all security functions:"
echo "  source bash_functions.d/90-security/security.sh"
echo "  source bash_functions.d/90-security/security_aliases.bash"
echo ""
echo "🎯 Integration Status:"
if declare -f security_help >/dev/null && [[ -d "tools/security" ]]; then
    echo "✅ Security tools fully integrated and ready!"
else
    echo "⚠️ Some security components may not be loaded properly"
fi