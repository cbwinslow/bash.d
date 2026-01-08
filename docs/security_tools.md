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

```bash
# Interactive security dashboard
security

# Quick security scan
security_scan

# Start continuous monitoring
security_monitor

# Analyze your ports
security_ports

# Setup anonymity
security_anonymity

# View security status
security_status

# Generate security report
security_report
```

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
```bash
security_help  # Show all available commands
```