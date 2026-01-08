#!/bin/bash
# Security Tools Setup and Integration Script

echo "🛡️ Integrating Security Tools into bash.d..."
echo ""

# Create necessary directories
TOOLS_DIR="$HOME/.bash.d/tools/security"
mkdir -p "$TOOLS_DIR"
mkdir -p "$HOME/.bash.d/docs"
mkdir -p "$HOME/.bash.d/logs/security"

echo "📦 Organizing tools in $TOOLS_DIR..."

# Create symbolic links for security tools
SECURITY_SCRIPTS=(
    "network_security_monitor.sh"
    "port_scan_detector.sh"
    "iptables_anonymity.sh"
    "iptables_cheat_sheet.sh"
    "iptables_rules_detailed.sh"
    "iptables_anonymity_guide.sh"
    "security_toolkit_summary.sh"
)

for script in "${SECURITY_SCRIPTS[@]}"; do
    if [[ -f "$HOME/.bash.d/$script" ]]; then
        echo "🔗 Linking $script"
        ln -sf "$HOME/.bash.d/$script" "$TOOLS_DIR/$script"
    fi
done

# Move anonymity tools
ANON_TOOLS=(
    "4nonimizer"
    "kali-anonymous"
)

for tool in "${ANON_TOOLS[@]}"; do
    if [[ -d "$HOME/.bash.d/$tool" ]]; then
        echo "🔗 Linking $tool"
        ln -sf "$HOME/.bash.d/$tool" "$TOOLS_DIR/$tool"
    fi
done

echo ""
echo "📚 Creating security documentation..."

# Create security index
cat > "$HOME/.bash.d/docs/security_tools.md" << 'ENDFILE'
# Security and Anonymity Tools

## 🛡️ Security Functions

Your bash.d now includes comprehensive security functions:

### Core Functions
- `security` or `sec` - Interactive security dashboard
- `security_scan` - Quick security check
- `security_monitor` - Continuous monitoring
- `security_ports` - Port analysis
- `security_status` - Current security status

### Anonymity Functions
- `security_anonymity` - Setup anonymity rules
- `security_dashboard` - Interactive interface

### Quick Aliases
- `sec-scan` - Quick security scan
- `sec-mon` - Start monitoring
- `sec-ports` - Port analysis
- `sec-status` - Security status
- `sec-logs` - View security logs
- `sec-report` - Generate security report
- `sec-lock` - Emergency lockdown

### Anonymity Aliases
- `anon` - Setup anonymity
- `anon-setup` - 4nonimizer setup
- `anon-anon` - kali-anonymous setup

## 📋 Available Scripts

### Security Tools
- `network_security_monitor.sh` - Real-time security monitoring
- `port_scan_detector.sh` - Port scan detection and analysis
- `iptables_anonymity.sh` - Complete anonymity ruleset
- `iptables_cheat_sheet.sh` - Quick reference commands
- `iptables_rules_detailed.sh` - Detailed rule explanations
- `iptables_anonymity_guide.sh` - Complete anonymity guide

### Anonymity Tools
- `4nonimizer/` - VPN/Tor anonymization script
- `kali-anonymous/` - ParrotOS anonymity script

## 🚀 Quick Start

\`\`\`bash
# Interactive security dashboard
sec

# Quick security scan
sec-scan

# Start continuous monitoring
sec-mon

# Analyze your ports
sec-ports

# Setup anonymity
anon

# View security status
sec-status

# Generate security report
sec-report
\`\`\`

## ⚠️ Requirements

- Root access for full functionality
- iptables for firewall rules
- Basic networking tools (netstat, ss, etc.)
- Optional: nmap, fail2ban, nethogs

## 🛡️ Features

### Protection
- DNS leak prevention
- Traffic forcing through anonymity networks
- Port blocking and rate limiting
- Application control
- Emergency lockdown

### Detection
- Port scan detection
- Brute force monitoring
- Suspicious process detection
- Anomalous connection patterns
- Vulnerability assessment

### Response
- Automated IP blocking
- Rate limiting
- Kill switch functionality
- Alert and logging systems

For detailed usage, see individual script documentation or use:
\`\`\`bash
sec-help  # Show all available commands
\`\`\`
ENDFILE

echo "📄 Creating security index..."

# Create tools index for security
cat > "$HOME/.bash.d/tools/security_index.md" << 'ENDFILE'
# Security Tools Index

## 🛡️ Network Security Tools

### Monitoring Scripts
- **network_security_monitor.sh** - Real-time security monitoring
  - Connection anomaly detection
  - Brute force attempt detection
  - Suspicious process monitoring
  - Real-time alerting
  - Usage: \`sudo ./network_security_monitor.sh scan|monitor\`

- **port_scan_detector.sh** - Port scan detection & analysis
  - Open port analysis
  - Vulnerability assessment
  - Port scan attempt detection
  - Interactive scanning mode
  - Usage: \`sudo ./port_scan_detector.sh detect|analyze|monitor\`

### Anonymity Scripts
- **iptables_anonymity.sh** - Complete anonymity ruleset
  - DNS leak prevention
  - Traffic forcing through Tor
  - Protocol blocking
  - Kill switch setup
  - Usage: \`sudo ./iptables_anonymity.sh\`

### Reference Scripts
- **iptables_cheat_sheet.sh** - Quick reference commands
- **iptables_rules_detailed.sh** - Detailed rule explanations
- **iptables_anonymity_guide.sh** - Complete anonymity guide

### Anonymity Tools
- **4nonimizer/** - VPN/Tor anonymization
  - Multiple VPN providers
  - Tor integration
  - DNSCrypt support
  - IP logging
  - Usage: \`cd 4nonimizer && sudo ./4nonimizer install\`

- **kali-anonymous/** - ParrotOS anonymity script
  - Tor network setup
  - MAC address spoofing
  - Process killing
  - DNS leak prevention
  - Usage: \`cd kali-anonymous && sudo ./anonymous\`

## 🎯 Security Functions Available

### Core Functions
\`\`\`bash
security_scan()       # Quick security scan
security_monitor()     # Continuous monitoring
security_ports()       # Port analysis
security_status()      # Security status
security_dashboard()   # Interactive dashboard
\`\`\`

### Quick Aliases
\`\`\`bash
sec-scan             # Quick scan
sec-mon              # Monitoring
sec-ports            # Port analysis
sec-status           # Status check
sec-logs             # View logs
sec-report           # Generate report
sec-lock             # Emergency lockdown
\`\`\`

### Anonymity Aliases
\`\`\`bash
anon                 # Setup anonymity
check-ip             # Check current IP
tor-start           # Start Tor service
dns-leak-test       # Test for DNS leaks
\`\`\`

## 📋 Security Checklist

### Basic Security
- [ ] Run initial security scan: \`sec-scan\`
- [ ] Check open ports: \`sec-ports\`
- [ ] Review firewall status: \`sec-status\`
- [ ] Set up monitoring: \`sec-mon\`

### Anonymity Setup
- [ ] Install Tor: \`sudo apt install tor\`
- [ ] Setup anonymity rules: \`anon\`
- [ ] Test for leaks: \`check-ip && dns-leak-test\`
- [ ] Configure applications for Tor/VPN

### Ongoing Monitoring
- [ ] Enable continuous monitoring: \`sec-mon\`
- [ ] Set up log rotation: \`sec-report\`
- [ ] Configure alerts: Edit threshold values
- [ ] Regular security scans: \`sec-scan\`

### Emergency Procedures
- [ ] Test lockdown: \`sec-lock\`
- [ ] Verify backup rules: \`backup-rules\`
- [ ] Know restoration: \`restore-rules\`
- [ ] Emergency contacts documented
ENDFILE

echo "🔧 Setting up security logging..."

# Create log rotation config
cat > "$HOME/.bash.d/logs/security/logrotate.conf" << 'ENDFILE'
/var/log/network_security_monitor.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 644 root root
}

/var/log/port_scans.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 644 root root
}
ENDFILE

echo "📝 Setting up completions..."

# Add completion loading to bash_completions
if [[ ! -f "$HOME/.bash.d/bash_functions.d/90-security/security_completions.bash" ]]; then
    echo "⚠️ Security completions not found"
else
    echo "✅ Security completions available"
fi

echo ""
echo "✅ Security Tools Integration Complete!"
echo ""
echo "🚀 Quick Test:"
echo "sec-help    # Show all security commands"
echo "sec-scan    # Quick security scan"
echo "sec-status   # Check current security status"
echo ""
echo "📚 Documentation:"
echo "  - $HOME/.bash.d/docs/security_tools.md"
echo "  - $HOME/.bash.d/tools/security_index.md"
echo ""
echo "🛠️ Tools Location:"
echo "  - Scripts: $TOOLS_DIR/"
echo "  - Functions: $HOME/.bash.d/bash_functions.d/90-security/"
echo "  - Logs: $HOME/.bash.d/logs/security/"
echo ""
echo "🔄 To reload shell and activate all functions:"
echo "source ~/.bashrc"