#!/bin/bash
# Security and Anonymity Aliases

# Quick access to security tools
alias sec='security_dashboard'
alias sec-scan='security_scan'
alias sec-mon='security_monitor'
alias sec-ports='security_ports'
alias sec-status='security_status'
alias sec-logs='security_logs'
alias sec-toolkit='security_toolkit'
alias sec-report='security_report'
alias sec-lock='security_lockdown'
alias sec-install='security_install'

# Quick anonymity commands
alias anon='security_anonymity'
alias anon-setup='$HOME/.bash.d/4nonimizer/4nonimizer'
alias anon-anon='$HOME/.bash.d/kali-anonymous/anonymous'

# Direct script access
alias portscan='$HOME/.bash.d/port_scan_detector.sh'
alias netmon='$HOME/.bash.d/network_security_monitor.sh'
alias iptables-anon='$HOME/.bash.d/iptables_anonymity.sh'

# Quick security checks
alias check-ports='security_quick_check'
alias check-firewall='sudo iptables -L -n -v'
alias check-connections='ss -tulnp'
alias check-auth='sudo tail -20 /var/log/auth.log'

# Quick anonymity checks
alias check-ip='curl -s https://check.torproject.org'
alias check-dns='dig +short myip.opendns.com @resolver1.opendns.com'

# Quick security commands
alias block-ip='sudo iptables -A INPUT -s'
alias unblock-ip='sudo iptables -D INPUT -s'
alias block-port='sudo iptables -A INPUT -p tcp --dport'
alias unblock-port='sudo iptables -D INPUT -p tcp --dport'

# Rate limiting aliases
alias limit-ssh='sudo iptables -A INPUT -p tcp --dport 22 -m limit --limit 3/min --limit-burst 3 -j ACCEPT'
alias limit-web='sudo iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/min --limit-burst 25 -j ACCEPT'

# Service security
alias ssh-secure='sudo nano /etc/ssh/sshd_config'
alias fail2ban-status='sudo fail2ban-client status'
alias ufw-allow='sudo ufw allow'
alias ufw-deny='sudo ufw deny'

# Monitoring aliases
alias live-ports='watch "netstat -tlnp | grep LISTEN"'
alias live-connections='watch "ss -tulnp"'
alias live-auth='sudo tail -f /var/log/auth.log'

# Security backup/restore
alias backup-rules='sudo iptables-save > $HOME/.bash.d/logs/security/firewall_backup.rules'
alias restore-rules='sudo iptables-restore < $HOME/.bash.d/logs/security/firewall_backup.rules'

# Anonymity quick toggles
alias tor-start='sudo systemctl start tor'
alias tor-stop='sudo systemctl stop tor'
alias tor-status='sudo systemctl status tor'

# DNS protection aliases
alias dns-leak-test='dnsleaktest.com'
alias force-dns='sudo iptables -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53'

# Network analysis aliases
alias scan-network='nmap -sP 192.168.1.0/24'
alias scan-ports='nmap -sS localhost'
alias scan-self='nmap -sS localhost'

# Emergency commands
alias emergency-cleanup='sudo iptables -F && sudo iptables -X'
alias emergency-restore='sudo iptables-restore < $HOME/.bash.d/logs/security/emergency_backup.rules'

# Help alias for security tools
alias sec-help='echo "Security Commands:
  sec/alias - Security dashboard
  sec-scan - Quick security scan
  sec-mon - Continuous monitoring
  sec-ports - Port analysis
  sec-status - Security status
  sec-logs - View security logs
  sec-report - Generate security report
  sec-lock - Emergency lockdown
  anon - Setup anonymity
  check-* - Various quick checks
  block-*/unblock-* - IP/port control
  tor-* - Tor service control"'