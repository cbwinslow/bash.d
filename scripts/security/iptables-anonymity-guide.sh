#!/bin/bash
# Comprehensive guide to iptables for anonymity

echo "=== IPTABLES FOR ANONYMITY - COMPLETE GUIDE ==="
echo ""

echo "🎯 WHY IPTABLES IS CRUCIAL FOR ANONYMITY:"
echo ""
echo "❌ WITHOUT PROTECTION:"
echo "Your App → Internet (direct connection)"
echo "├── DNS Query to 8.8.8.8 → Google sees your IP"
echo "├── HTTP Request to website → Website sees your IP" 
echo "├── Timezone in headers → Reveals your location"
echo "└── IPv6 traffic → Bypasses Tor entirely"
echo ""

echo "✅ WITH IPTABLES PROTECTION:"
echo "Your App → iptables → Tor/VPN → Internet (anonymous)"
echo "├── DNS Query intercepted → Goes through Tor → Google sees Tor IP"
echo "├── HTTP Request intercepted → Goes through Tor → Website sees Tor IP"
echo "├── IPv6 blocked → Can't leak your real IP"
echo "└── All other traffic forced through anonymity network"
echo ""

echo "=== CORE ANONYMITY TECHNIQUES ==="
echo ""

echo "🔍 1. DNS LEAK PREVENTION"
echo ""
echo "PROBLEM: DNS requests can bypass Tor/VPN"
echo "SOLUTION: Force all DNS through anonymity network"
echo ""
echo "RULES:"
echo "# Block external DNS"
echo "sudo iptables -A OUTPUT -p udp --dport 53 -j DROP"
echo "sudo iptables -A OUTPUT -p tcp --dport 53 -j DROP"
echo ""
echo "# Allow only local DNS (through Tor)"
echo "sudo iptables -A OUTPUT -p udp --dport 53 -d 127.0.0.1 -j ACCEPT"
echo "sudo iptables -A OUTPUT -p tcp --dport 53 -d 127.0.0.1 -j ACCEPT"
echo ""
echo "RESULT: All DNS queries must go through Tor → No DNS leaks"
echo ""

echo "🌐 2. TRAFFIC FORCING"
echo ""
echo "PROBLEM: Applications might connect directly to internet"
echo "SOLUTION: Intercept and redirect all traffic"
echo ""
echo "RULES:"
echo "# Redirect all HTTP/HTTPS to Tor proxy"
echo "sudo iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 9050"
echo "sudo iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-ports 9050"
echo ""
echo "# Force all other TCP through Tor"
echo "sudo iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040"
echo ""
echo "RESULT: All internet traffic must go through Tor"
echo ""

echo "🚫 3. LEAK BLOCKING"
echo ""
echo "PROBLEM: Various protocols can leak your identity"
echo "SOLUTION: Block suspicious/outdated protocols"
echo ""
echo "RULES:"
echo "# Block IPv6 (can bypass Tor completely)"
echo "sudo ip6tables -P INPUT DROP"
echo "sudo ip6tables -P OUTPUT DROP"
echo "sudo ip6tables -P FORWARD DROP"
echo ""
echo "# Block ICMP (can reveal location via latency)"
echo "sudo iptables -A OUTPUT -p icmp --icmp-type echo-request -j DROP"
echo ""
echo "# Block WebRTC (leaks real IP even with VPN)"
echo "sudo iptables -A OUTPUT -p udp --dport 3478:65535 -j DROP"
echo ""
echo "RESULT: Multiple leak vectors blocked"
echo ""

echo "🏠 4. LOCAL NETWORK ISOLATION"
echo ""
echo "PROBLEM: Local network traffic can reveal your location"
echo "SOLUTION: Control what can access local network"
echo ""
echo "RULES:"
echo "# Allow only specific local services"
echo "sudo iptables -A OUTPUT -d 192.168.1.1 -p tcp --dport 53 -j ACCEPT  # Router DNS"
echo "sudo iptables -A OUTPUT -d 192.168.1.1 -p udp --dport 67 -j ACCEPT  # DHCP"
echo ""
echo "# Block other local network discovery"
echo "sudo iptables -A OUTPUT -d 192.168.0.0/16 -j DROP"
echo ""
echo "RESULT: Local access limited to essential services"
echo ""

echo "🎭 5. APPLICATION CONTROL"
echo ""
echo "PROBLEM: Some applications ignore system proxy settings"
echo "SOLUTION: Block problematic applications at network level"
echo ""
echo "RULES:"
echo "# Block Firefox unless using Tor"
echo "sudo iptables -A OUTPUT -m owner --uid-owner \$(id -u firefox) -j DROP"
echo ""
echo "# Block Chromium unless using proxy"
echo "sudo iptables -A OUTPUT -m owner --uid-owner \$(id -u chromium) -j DROP"
echo ""
echo "RESULT: Applications forced to use Tor/VPN or blocked entirely"
echo ""

echo "🔧 6. FAILSAFE MECHANISMS"
echo ""
echo "PROBLEM: Tor/VPN connection might fail, exposing real IP"
echo "SOLUTION: Kill switch - block all traffic if anonymity fails"
echo ""
echo "RULES:"
echo "# Monitor Tor process, block if not running"
echo "# (This would be combined with a monitoring script)"
echo "sudo iptables -A OUTPUT -m owner --uid-owner debian-tor -j ACCEPT"
echo "sudo iptables -A OUTPUT -j DROP  # Block everything else"
echo ""
echo "RESULT: No internet access if Tor fails"
echo ""

echo "=== ADVANCED ANONYMITY TECHNIQUES ==="
echo ""

echo "🎯 7. PACKET SIZE OBFUSCATION"
echo ""
echo "PROBLEM: Traffic analysis can identify patterns"
echo "SOLUTION: Normalize packet sizes"
echo ""
echo "RULES:"
echo "# Fragment large packets to hide content patterns"
echo "sudo iptables -A OUTPUT -p tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1400:1536 -j TCPMSS --set-mss 1360"
echo ""
echo "RESULT: Harder to analyze traffic patterns"
echo ""

echo "⏰ 8. TIMING OBFUSCATION"
echo ""
echo "PROBLEM: Timing analysis can reveal behavior patterns"
echo "SOLUTION: Add delays to normalize traffic"
echo ""
echo "(This usually requires additional tools like 'tc' - traffic control)"
echo "sudo tc qdisc add dev eth0 root netem delay 100ms 10ms"
echo ""
echo "RESULT: Traffic timing patterns obscured"
echo ""

echo "📊 9. TRAFFIC MONITORING"
echo ""
echo "PROBLEM: Need to verify anonymity is working"
echo "SOLUTION: Log and monitor traffic patterns"
echo ""
echo "RULES:"
echo "# Log all outgoing traffic for analysis"
echo "sudo iptables -A OUTPUT -j LOG --log-prefix 'ANONYMITY-LOG: '"
echo ""
echo "# Monitor blocked attempts"
echo "sudo iptables -A OUTPUT -j LOG --log-prefix 'BLOCKED-ATTEMPT: ' --log-level 4"
echo ""
echo "RESULT: Can verify anonymization is working correctly"
echo ""

echo "=== PRACTICAL IMPLEMENTATION ==="
echo ""

echo "🛡️ COMPLETE ANONYMITY RULESET:"
echo ""
cat << 'EOF'
#!/bin/bash
# Complete anonymity iptables rules

# Clear existing rules
iptables -F && iptables -t nat -F && iptables -t mangle -F
iptables -X && ip6tables -F

# Default policies - block everything
iptables -P INPUT DROP && iptables -P OUTPUT DROP && iptables -P FORWARD DROP
ip6tables -P INPUT DROP && ip6tables -P OUTPUT DROP && ip6tables -P FORWARD DROP

# Allow essential local traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow local network (for printer, etc.)
iptables -A OUTPUT -d 192.168.1.0/24 -j ACCEPT

# Force DNS through Tor
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 53

# Force all TCP through Tor
iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040

# Allow Tor to access internet
iptables -A OUTPUT -m owner --uid-owner debian-tor -j ACCEPT

# Block everything else
iptables -A OUTPUT -j REJECT --reject-with icmp-port-unreachable
EOF

echo ""
echo "⚠️ CRITICAL WARNINGS:"
echo ""
echo "🚨 TESTING REQUIREMENTS:"
echo "- Always test in virtual environment first"
echo "- Have backup of network settings"
echo "- Ensure physical access to machine"
echo "- Don't test on production systems"
echo ""

echo "🔧 COMPLEMENTARY TOOLS:"
echo "- Tor Browser for web browsing"
echo "- proxychains for command-line tools"
echo "- VPN for additional layer"
echo "- MAC address spoofing"
echo "- Timezone spoofing"
echo ""

echo "📈 EFFECTIVENESS:"
echo "✅ Prevents DNS leaks"
echo "✅ Forces traffic through anonymity network"
echo "✅ Blocks protocol leaks"
echo "✅ Provides kill switch"
echo "⚠️ Not 100% protection - requires careful configuration"
echo "⚠️ Can be bypassed by sophisticated attacks"
echo "⚠️ May break legitimate applications"
echo ""

echo "🎯 KEY TAKEAWAY:"
echo "iptables is the foundation of digital anonymity, but must be"
echo "combined with other techniques for comprehensive protection."