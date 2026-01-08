#!/bin/bash
# Advanced iptables rules for anonymity testing

echo "=== ANONYMITY IPTABLES COMMANDS CHEAT SHEET ==="

# 1. BASIC RULES - View and Clear
echo "1. VIEW CURRENT RULES:"
echo "sudo iptables -L -v -n --line-numbers"
echo "sudo iptables -t nat -L -v -n --line-numbers"
echo ""

echo "CLEAR ALL RULES:"
echo "sudo iptables -F"
echo "sudo iptables -t nat -F"
echo "sudo iptables -t mangle -F"
echo "sudo iptables -X"
echo ""

# 2. ANONYMITY RULES
echo "2. DNS LEAK PREVENTION:"
echo "# Force DNS through Tor (UDP)"
echo "sudo iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53"
echo ""
echo "# Force DNS through Tor (TCP)" 
echo "sudo iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 53"
echo ""

echo "3. TOR FORCING RULES:"
echo "# Allow local networks to bypass Tor"
echo "for net in 127.0.0.0/8 192.168.0.0/16 10.0.0.0/8; do"
echo "  sudo iptables -t nat -A OUTPUT -d \$net -j RETURN"
echo "  sudo iptables -A OUTPUT -d \$net -j ACCEPT"
echo "done"
echo ""

echo "# Allow Tor user to connect directly"
echo "sudo iptables -t nat -A OUTPUT -m owner --uid-owner debian-tor -j RETURN"
echo "sudo iptables -A OUTPUT -m owner --uid-owner debian-tor -j ACCEPT"
echo ""

echo "# Redirect all other TCP traffic through Tor"
echo "sudo iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040"
echo ""

echo "4. APPLICATION BLOCKING:"
echo "# Block problematic applications"
echo "sudo iptables -A OUTPUT -p tcp --dport 80 -m owner --uid-owner \$(id -u firefox) -j DROP"
echo "sudo iptables -A OUTPUT -p tcp --dport 443 -m owner --uid-owner \$(id -u firefox) -j DROP"
echo ""

echo "5. TESTING COMMANDS:"
echo "# Test DNS leak protection"
echo "dig @8.8.8.8 google.com  # Should fail if rules working"
echo ""
echo "# Test IP before/after rules"
echo "curl https://check.torproject.org"
echo ""
echo "# Monitor traffic"
echo "sudo iptables -L -v -n --line-numbers"
echo ""

echo "6. SAFETY COMMANDS:"
echo "# Quick reset if something breaks"
echo "sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F"
echo "sudo iptables -P INPUT ACCEPT && sudo iptables -P OUTPUT ACCEPT && sudo iptables -P FORWARD ACCEPT"
echo ""

echo "7. ADVANCED RULES:"
echo "# Block IPv6 (can leak info)"
echo "sudo ip6tables -P INPUT DROP && sudo ip6tables -P OUTPUT DROP && sudo ip6tables -P FORWARD DROP"
echo ""
echo "# Prevent WebRTC leaks"
echo "sudo iptables -A OUTPUT -p udp --dport 3478:65535 -j DROP"
echo ""
echo "# Block ICMP (can reveal location)"
echo "sudo iptables -A OUTPUT -p icmp --icmp-type echo-request -j DROP"
echo ""

echo "⚠️  WARNING: These rules break normal internet access!"
echo "Only use with Tor Browser or applications configured to use Tor"