# Security Tools Index

## 🛡️ Network Security Tools

### Core Security Scripts
- **network_security_monitor.sh** - Real-time security monitoring
  - Connection anomaly detection
  - Brute force attempt detection  
  - Suspicious process monitoring
  - Real-time alerting
  - Usage: `sudo ./network_security_monitor.sh scan|monitor`

- **port_scan_detector.sh** - Port scan detection & analysis
  - Open port analysis
  - Vulnerability assessment
  - Port scan attempt detection
  - Interactive scanning mode
  - Usage: `sudo ./port_scan_detector.sh detect|analyze|monitor`

- **iptables_anonymity.sh** - Complete anonymity ruleset
  - DNS leak prevention
  - Traffic forcing through Tor
  - Protocol blocking
  - Kill switch setup
  - Usage: `sudo ./iptables_anonymity.sh`

### Reference Documentation
- **iptables_cheat_sheet.sh** - Quick reference commands
- **iptables_rules_detailed.sh** - Detailed rule explanations
- **iptables_anonymity_guide.sh** - Complete anonymity guide

### Anonymity Tools
- **4nonimizer/** - VPN/Tor anonymization
  - Multiple VPN providers
  - Tor integration
  - DNSCrypt support
  - IP logging
  - Usage: `cd 4nonimizer && sudo ./4nonimizer install`

- **kali-anonymous/** - ParrotOS anonymity script
  - Tor network setup
  - MAC address spoofing
  - Process killing
  - DNS leak prevention
  - Usage: `cd kali-anonymous && sudo ./anonymous`

## 🎯 Security Functions Available

### Core Functions
```bash
security_scan()       # Quick security scan
security_monitor()     # Continuous monitoring
security_ports()       # Port analysis
security_status()      # Security status
security_dashboard()   # Interactive dashboard
```

### Quick Aliases
```bash
sec-scan             # Quick scan
sec-mon              # Monitoring
sec-ports            # Port analysis
sec-status           # Status check
sec-logs             # View logs
sec-report           # Generate report
sec-lock             # Emergency lockdown
```

### Anonymity Aliases
```bash
anon                 # Setup anonymity
check-ip             # Check current IP
tor-start           # Start Tor service
dns-leak-test       # Test for DNS leaks
```

## 📋 Security Checklist

### Basic Security
- [ ] Run initial security scan: `security_scan`
- [ ] Check open ports: `security_ports`
- [ ] Review firewall status: `security_status`
- [ ] Set up monitoring: `security_monitor`

### Anonymity Setup
- [ ] Install Tor: `sudo apt install tor`
- [ ] Setup anonymity rules: `security_anonymity`
- [ ] Test for leaks: `check-ip && dns-leak-test`
- [ ] Configure applications for Tor/VPN

### Ongoing Monitoring
- [ ] Enable continuous monitoring: `security_monitor`
- [ ] Set up log rotation: `security_report`
- [ ] Configure alert thresholds
- [ ] Regular security scans: `security_scan`

### Emergency Procedures
- [ ] Test lockdown: `security_lockdown`
- [ ] Verify backup rules: `backup-rules`
- [ ] Know restoration: `restore-rules`
- [ ] Emergency contacts documented

## 🚨 Emergency Commands

```bash
# Emergency lockdown
security_lockdown

# Generate security report
security_report

# Check security status
security_status
```