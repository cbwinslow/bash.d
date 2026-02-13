#!/bin/bash
# Complete network security and monitoring guide

echo "=== NETWORK SECURITY & ANOMALY DETECTION ==="
echo ""

echo "🚫 PREVENTING UNAUTHORIZED ACCESS:"
echo ""

echo "1. PORT PROTECTION WITH IPTABLES:"
echo ""
echo "# Block all incoming connections by default"
echo "sudo iptables -P INPUT DROP"
echo "sudo iptables -P FORWARD DROP"
echo ""

echo "# Allow only essential services"
echo "sudo iptables -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT  # SSH from home only"
echo "sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT  # HTTPS"
echo "sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT   # HTTP"
echo ""

echo "# Block common attack ports"
echo "sudo iptables -A INPUT -p tcp --dport 23 -j DROP    # Telnet"
echo "sudo iptables -A INPUT -p tcp --dport 135 -j DROP   # RPC"
echo "sudo iptables -A INPUT -p tcp --dport 445 -j DROP   # SMB"
echo "sudo iptables -A INPUT -p tcp --dport 3389 -j DROP  # RDP"
echo ""

echo "# Rate limiting to prevent brute force"
echo "sudo iptables -A INPUT -p tcp --dport 22 -m limit --limit 3/min --limit-burst 3 -j ACCEPT"
echo "sudo iptables -A INPUT -p tcp --dport 22 -j DROP     # Block excess attempts"
echo ""

echo "2. PORT SCANNING PROTECTION:"
echo ""
echo "# Block port scans"
echo "sudo iptables -A INPUT -m recent --name portscan --rcheck --seconds 86400 -j DROP"
echo "sudo iptables -A INPUT -m recent --name portscan --set -j LOG --log-prefix 'Portscan:'"
echo "sudo iptables -A INPUT -m recent --name portscan --set -j DROP"
echo ""

echo "# Detect and block SYN floods"
echo "sudo iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT"
echo "sudo iptables -A INPUT -p tcp --syn -j DROP"
echo ""

echo "3. FAIL2BAN INTEGRATION:"
echo ""
echo "# Install fail2ban"
echo "sudo apt install fail2ban"
echo ""
echo "# Basic fail2ban configuration"
echo "[DEFAULT]"
echo "bantime = 3600"
echo "findtime = 600"
echo "maxretry = 3"
echo ""
echo "[sshd]"
echo "enabled = true"
echo "port = ssh"
echo "logpath = /var/log/auth.log"
echo "maxretry = 3"
echo ""

echo "🔍 MONITORING NETWORK TRAFFIC:"
echo ""

echo "1. REAL-TIME TRAFFIC MONITORING:"
echo ""
echo "# View all active connections"
echo "sudo netstat -tulnp"
echo "sudo ss -tulnp"
echo ""

echo "# Monitor network bandwidth by process"
echo "sudo nethogs"
echo ""

echo "# Real-time network monitoring"
echo "sudo iftop -i eth0"
echo "sudo tcpdump -i eth0 -nn"
echo ""

echo "# Advanced monitoring with iptraf"
echo "sudo iptraf-ng"
echo ""

echo "2. LOGGING AND ANALYSIS:"
echo ""
echo "# Enable connection tracking logs"
echo "sudo iptables -A INPUT -j LOG --log-prefix 'INPUT-DENIED: ' --log-level 4"
echo "sudo iptables -A OUTPUT -j LOG --log-prefix 'OUTPUT-LOG: ' --log-level 4"
echo ""

echo "# Monitor suspicious activities"
echo "sudo tail -f /var/log/syslog | grep 'INPUT-DENIED'"
echo "sudo tail -f /var/log/kern.log"
echo "sudo tail -f /var/log/auth.log"
echo ""

echo "3. AUTOMATED MONITORING SCRIPT:"
echo ""
cat << 'SCRIPT'
#!/bin/bash
# Network anomaly detection script

LOG_FILE="/var/log/network_anomalies.log"
ALERT_THRESHOLD=100
SCAN_THRESHOLD=10

monitor_connections() {
    # Count connections per IP
    netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr > /tmp/conn_count.txt
    
    while read count ip; do
        if [ "$count" -gt "$ALERT_THRESHOLD" ]; then
            echo "$(date): HIGH CONNECTIONS - $ip has $count connections" >> "$LOG_FILE"
            echo "WARNING: $ip has $count connections (threshold: $ALERT_THRESHOLD)"
        fi
    done < /tmp/conn_count.txt
}

detect_port_scans() {
    # Monitor for rapid connection attempts
    sudo journalctl -f -n 100 | grep "Portscan:" | wc -l > /tmp/portscan_count.txt
    scan_count=$(cat /tmp/portscan_count.txt)
    
    if [ "$scan_count" -gt "$SCAN_THRESHOLD" ]; then
        echo "$(date): PORT SCAN DETECTED - $scan_count attempts" >> "$LOG_FILE"
        echo "CRITICAL: Port scan detected! $scan_count attempts"
    fi
}

# Run monitoring
monitor_connections
detect_port_scans
SCRIPT

echo ""

echo "📊 ADVANCED MONITORING TOOLS:"
echo ""

echo "1. SURICATA - INTRUSION DETECTION"
echo ""
echo "# Install Suricata IDS"
echo "sudo apt install suricata"
echo ""
echo "# Update rules"
echo "sudo suricata-update"
echo ""
echo "# Start monitoring"
echo "sudo suricata -i eth0 -c /etc/suricata/suricata.yaml"
echo ""

echo "2. OSQUERY - SYSTEM MONITORING"
echo ""
echo "# Install osquery"
echo "sudo apt install osquery"
echo ""
echo "# Monitor network connections"
echo "osquery 'SELECT pid, name, local_address, local_port, remote_address, remote_port FROM process_open_sockets;'"
echo ""

echo "3. GRAFANA + PROMETHEUS - VISUAL MONITORING"
echo ""
echo "# Prometheus configuration snippet"
echo "- job_name: 'node_exporter'"
echo "  static_configs:"
echo "    - targets: ['localhost:9100']"
echo ""
echo "# Query network anomalies"
echo "rate(node_netstat_Tcp_CurrEstab[5m]) > 100"
echo ""

echo "🎯 SPECIFIC ATTACK DETECTION:"
echo ""

echo "1. BRUTE FORCE DETECTION:"
echo ""
echo "# Monitor SSH brute force attempts"
echo "sudo grep 'Failed password' /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -nr"
echo ""

echo "# Real-time brute force monitoring"
echo "sudo tail -f /var/log/auth.log | grep 'Failed password'"
echo ""

echo "2. DDoS DETECTION:"
echo ""
echo "# Monitor SYN packets"
echo "sudo tcpdump -i eth0 'tcp[tcpflags] & tcp-syn != 0'"
echo ""

echo "# Check for high connection rates"
echo "sudo iptables -L INPUT -v -n | head -10"
echo ""

echo "3. MALWARE TRAFFIC DETECTION:"
echo ""
echo "# Monitor suspicious ports"
echo "sudo netstat -tulnp | grep -E ':(4444|5555|6666|7777|8888|9999)'"
echo ""

echo "# Check for unusual processes"
echo "ps aux | grep -E '(nc|ncat|socat)'"
echo ""

echo "🛡️ DEFENSE MECHANISMS:"
echo ""

echo "1. AUTOMATED BLOCKING:"
echo ""
cat << 'BLOCKSCRIPT'
#!/bin/bash
# Automated IP blocking script

THRESHOLD=50
LOG_FILE="/var/log/blocked_ips.log"

block_suspicious_ips() {
    # Get IPs with too many connections
    netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | \
    while read count ip; do
        if [ "$count" -gt "$THRESHOLD" ] && [ "$ip" != "" ]; then
            # Block the IP
            sudo iptables -A INPUT -s "$ip" -j DROP
            echo "$(date): Blocked $ip (connections: $count)" >> "$LOG_FILE"
        fi
    done
}

block_suspicious_ips
BLOCKSCRIPT

echo ""

echo "2. HONEYPOT SETUP:"
echo ""
echo "# Simple SSH honeypot using cowrie"
echo "git clone https://github.com/cowrie/cowrie.git"
echo "cd cowrie && pip install -r requirements.txt"
echo "./bin/cowrie start"
echo ""

echo "3. NETWORK SEGMENTATION:"
echo ""
echo "# Separate networks for different security levels"
echo "sudo ip addr add 192.168.10.1/24 dev eth0:0"
echo "sudo iptables -A FORWARD -i eth0 -o eth0:0 -j DROP"
echo ""

echo "⚠️ CONTINUOUS MONITORING:"
echo ""

echo "1. SETUP ALERTS:"
echo ""
echo "# Email alerts for security events"
echo "echo 'Security alert detected' | mail -s 'Network Alert' admin@example.com"
echo ""

echo "# SMS alerts using twilio (requires setup)"
echo "# curl -X POST 'https://api.twilio.com/...' -d 'Body=Security Alert'"
echo ""

echo "2. DASHBOARD SETUP:"
echo ""
echo "# Simple monitoring dashboard"
echo "watch -n 5 'netstat -tulnp && echo \"=== Connections ===\" && ss -tulnp'"
echo ""

echo "3. LOG ROTATION:"
echo ""
echo "# Prevent log files from growing too large"
echo "sudo nano /etc/logrotate.d/network-logs"
echo ""
echo "/var/log/network_*.log {"
echo "    daily"
echo "    rotate 7"
echo "    compress"
echo "    missingok"
echo "    notifempty"
echo "}"
echo ""

echo "🎯 KEY TAKEAWAYS:"
echo ""
echo "✅ Layered defense (iptables + fail2ban + monitoring)"
echo "✅ Real-time monitoring and alerting"
echo "✅ Automated response to threats"
echo "✅ Regular log analysis"
echo "✅ Network segmentation"
echo ""
echo "⚠️ Requires continuous monitoring and updates"
echo "⚠️ Balance security with usability"
echo "⚠️ Test configurations thoroughly"