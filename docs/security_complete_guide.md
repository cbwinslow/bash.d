# Security and Anonymity Tools - Complete Guide

## 🛡️ Overview

Your bash.d system now includes comprehensive security and anonymity tools for network protection, monitoring, and traffic anonymization.

## 📦 Tools Included

### Core Security Tools
- **network_security_monitor.sh** - Real-time security monitoring with anomaly detection
- **port_scan_detector.sh** - Port scan detection and vulnerability analysis  
- **iptables_anonymity.sh** - Complete anonymity firewall ruleset
- **iptables_cheat_sheet.sh** - Quick reference commands
- **iptables_rules_detailed.sh** - Detailed rule explanations

### Anonymity Tools  
- **4nonimizer/** - VPN/Tor anonymization script
- **kali-anonymous/** - ParrotOS anonymity script

### Integration Functions
- **Security Functions** (`bash_functions.d/90-security/`)
- **Security Aliases** - Quick access commands
- **Completions** - Tab completion support

## 🚀 Quick Start

```bash
# Load security functions (run once)
source bash_functions.d/90-security/security.sh

# Interactive security dashboard
security_dashboard

# Quick security scan
security_scan

# Start continuous monitoring  
security_monitor

# Analyze ports
security_ports

# Setup anonymity
security_anonymity
```

## 🛡️ Security Features

### Prevention
- **DNS Leak Prevention** - Forces DNS through anonymity networks
- **Traffic Forcing** - Redirects all connections through Tor/VPN
- **Port Blocking** - Blocks vulnerable and unnecessary ports
- **Rate Limiting** - Prevents brute force attacks
- **Application Control** - Blocks apps that ignore proxy settings

### Detection  
- **Port Scan Detection** - Identifies scanning attempts
- **Brute Force Monitoring** - Detects SSH/service attacks
- **Anomaly Detection** - Flags suspicious connection patterns
- **Process Monitoring** - Identifies suspicious background processes
- **Vulnerability Assessment** - Scans for open vulnerable ports

### Response
- **Automated IP Blocking** - Blocks malicious IPs automatically
- **Emergency Lockdown** - Instant network isolation
- **Alert System** - Real-time threat notification
- **Logging System** - Comprehensive incident tracking

## 🎯 Quick Aliases

```bash
# Core security commands
sec                 # Security dashboard
sec-scan            # Quick scan
sec-mon              # Monitoring
sec-ports           # Port analysis
sec-status          # Security status
sec-logs            # View logs
sec-report          # Generate report
sec-lock            # Emergency lockdown

# Anonymity commands  
anon                # Setup anonymity
check-ip            # Check external IP
check-dns           # DNS leak test
tor-start           # Start Tor service

# Quick checks
check-ports         # Quick port check
check-firewall      # Firewall status
check-connections  # Active connections
check-auth          # Recent auth attempts
```

## ⚙️ Configuration

### Thresholds
Edit values in security scripts:
- `ALERT_THRESHOLD_CONNECTIONS=50` - High connection alerts
- `ALERT_THRESHOLD_PORT_SCAN=10` - Port scan detection
- `ALERT_THRESHOLD_BRUTE_FORCE=5` - Brute force alerts

### Log Locations
- Security logs: `~/.bash.d/logs/security/`
- System logs: `/var/log/network_security_monitor.log`
- Port scan logs: `/var/log/port_scans.log`

## 🔧 Requirements

### Essential
- Root access for full functionality
- iptables for firewall rules
- Basic networking tools (netstat, ss, curl, dig)

### Recommended
- nmap for port scanning
- fail2ban for automated blocking
- nethogs for bandwidth monitoring
- iftop for traffic analysis

## 📋 Security Checklist

### Initial Setup
- [ ] Run security functions: `source bash_functions.d/90-security/security.sh`
- [ ] Test quick scan: `security_scan`
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
- [ ] Document emergency contacts

## 🚨 Emergency Commands

```bash
# Immediate lockdown (blocks all traffic)
security_lockdown

# Restore from emergency rules
restore-rules

# Generate immediate security report
security_report

# Check current threat level
security_status
```

## 📚 Documentation

- **Security Guide**: `docs/security_tools.md` (this file)
- **Tools Index**: `docs/tools_security_index.md`
- **Function Reference**: `bash_functions.d/90-security/security.sh`
- **Alias List**: `bash_functions.d/90-security/security_aliases.bash`

## 🔄 Updates and Maintenance

### Regular Tasks
- Update security tools: Check for new script versions
- Review firewall rules: `check-firewall`
- Analyze security logs: `sec-logs`
- Test anonymity: `check-ip && dns-leak-test`
- Backup configurations: `backup-rules`

### Log Management
- View recent security events: `security_logs`
- Generate weekly reports: `security_report`
- Rotate log files (automatic): Set up logrotate
- Archive old logs: Move to archive directory

## 🎯 Best Practices

1. **Layered Security** - Use multiple defense mechanisms
2. **Regular Monitoring** - Don't set and forget security tools
3. **Test Rules** - Verify configurations in safe environments
4. **Back Up Rules** - Save working firewall configurations
5. **Update Regularly** - Keep tools and signatures current
6. **Document Changes** - Track security modifications
7. **Emergency Planning** - Know response procedures

## ⚠️ Important Notes

- **Root Required**: Full functionality requires root privileges
- **Test First**: Always test rules in safe environments
- **Monitor Performance**: Security tools can impact system performance
- **Legal Compliance**: Ensure anonymity usage complies with local laws
- **Network Impact**: Security rules may affect legitimate traffic

## 🆘 Getting Help

```bash
# Show all available security commands
security_help

# Interactive help dashboard  
security_dashboard

# Quick reference
sec-help
```

For detailed help on specific tools, run:
```bash
./tools/security/network_security_monitor.sh help
./tools/security/port_scan_detector.sh help
./tools/security/iptables_anonymity.sh help
```