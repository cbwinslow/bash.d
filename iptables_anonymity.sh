#!/bin/bash
# Anonymity iptables Configuration Script
# Educational purposes only - understand what you're doing!

echo "=== ANONYMITY IPTABLES SETUP ==="
echo "WARNING: This will change your network configuration!"
echo ""
read -p "Continue? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "Cancelled."
    exit 1
fi

# Clear existing rules
echo "Clearing existing iptables rules..."
iptables -F          # Flush all rules
iptables -t nat -F    # Flush NAT rules  
iptables -t mangle -F # Flush mangle rules
iptables -X          # Delete custom chains

# Set default policies - DROP everything by default
echo "Setting default policies to DROP..."
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# Allow loopback (critical for system processes)
echo "Allowing loopback traffic..."
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established/related connections
echo "Allowing established connections..."
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ===== TOR FORCING RULES =====
echo "Setting up Tor forcing rules..."

# Variables
TOR_UID="debian-tor"
TOR_PORT="9050"
TRANS_PORT="9040"
DNS_PORT="53"

# Allow local networks (don't route through Tor)
LOCAL_NETS="127.0.0.0/8 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12"
for NET in $LOCAL_NETS; do
    iptables -t nat -A OUTPUT -d $NET -j RETURN
    iptables -A OUTPUT -d $NET -j ACCEPT
done

# Allow Tor user to access internet directly
iptables -t nat -A OUTPUT -m owner --uid-owner $TOR_UID -j RETURN
iptables -A OUTPUT -m owner --uid-owner $TOR_UID -j ACCEPT

# Redirect DNS through Tor (prevents DNS leaks)
echo "Redirecting DNS through Tor..."
iptables -t nat -A OUTPUT -p udp --dport $DNS_PORT -j REDIRECT --to-ports $DNS_PORT
iptables -t nat -A OUTPUT -p tcp --dport $DNS_PORT -j REDIRECT --to-ports $DNS_PORT

# Redirect all TCP traffic through Tor
echo "Redirecting TCP traffic through Tor..."
iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports $TRANS_PORT

# Allow outbound traffic to Tor ports
iptables -A OUTPUT -p tcp --dport $TOR_PORT -j ACCEPT
iptables -A OUTPUT -p tcp --dport $TRANS_PORT -j ACCEPT

# Block everything else
echo "Blocking remaining traffic..."
iptables -A OUTPUT -j REJECT --reject-with icmp-port-unreachable

echo ""
echo "=== RULES SUMMARY ==="
echo "✓ Loopback traffic allowed"
echo "✓ Local networks bypass Tor"  
echo "✓ DNS forced through Tor"
echo "✓ All TCP traffic forced through Tor"
echo "✓ Only Tor user can access internet directly"
echo ""
echo "🔒 ANONYMITY MODE ENABLED"
echo ""
echo "To check your IP: curl https://check.torproject.org"
echo "To save these rules: iptables-save > /etc/iptables.rules"
echo ""
echo "⚠️  WARNING: Only use Tor Browser or Tor-aware applications!"