#!/bin/bash
#===============================================================================
#
#          FILE:  network_utils.sh
#
#         USAGE:  Automatically sourced by .bashrc
#
#   DESCRIPTION:  Network utility functions for troubleshooting and analysis
#
#       OPTIONS:  ---
#  REQUIREMENTS:  curl, dig (optional), nmap (optional)
#         NOTES:  Helpful for network debugging
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

#===============================================================================
# DNS UTILITIES
#===============================================================================

# DNS lookup with all record types
dnslookup() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        echo "Usage: dnslookup <domain>"
        return 1
    fi
    
    echo "DNS Lookup: $domain"
    echo "===================="
    
    if command -v dig >/dev/null 2>&1; then
        echo ""
        echo "A Records:"
        dig +short A "$domain"
        
        echo ""
        echo "AAAA Records:"
        dig +short AAAA "$domain"
        
        echo ""
        echo "MX Records:"
        dig +short MX "$domain"
        
        echo ""
        echo "NS Records:"
        dig +short NS "$domain"
        
        echo ""
        echo "TXT Records:"
        dig +short TXT "$domain"
        
        echo ""
        echo "CNAME Records:"
        dig +short CNAME "$domain"
    elif command -v nslookup >/dev/null 2>&1; then
        nslookup "$domain"
    else
        echo "Neither dig nor nslookup is installed."
    fi
}

# Reverse DNS lookup
rdns() {
    local ip="$1"
    
    if [[ -z "$ip" ]]; then
        echo "Usage: rdns <ip_address>"
        return 1
    fi
    
    if command -v dig >/dev/null 2>&1; then
        dig +short -x "$ip"
    elif command -v host >/dev/null 2>&1; then
        host "$ip"
    else
        echo "dig or host not installed."
    fi
}

# Get domain WHOIS info
whoisinfo() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        echo "Usage: whoisinfo <domain>"
        return 1
    fi
    
    if command -v whois >/dev/null 2>&1; then
        whois "$domain"
    else
        echo "whois not installed."
    fi
}

#===============================================================================
# CONNECTION TESTING
#===============================================================================

# Test HTTP/HTTPS endpoint
httptest() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo "Usage: httptest <url>"
        return 1
    fi
    
    # Add protocol if missing
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="https://$url"
    fi
    
    echo "Testing: $url"
    echo ""
    
    curl -sI -o /dev/null -w "HTTP Status: %{http_code}\n\
Response Time: %{time_total}s\n\
DNS Lookup: %{time_namelookup}s\n\
TCP Connect: %{time_connect}s\n\
TLS Handshake: %{time_appconnect}s\n\
Content Size: %{size_download} bytes\n" "$url"
}

# Test port connectivity
testport() {
    local host="$1"
    local port="$2"
    
    if [[ -z "$host" || -z "$port" ]]; then
        echo "Usage: testport <host> <port>"
        return 1
    fi
    
    echo -n "Testing $host:$port... "
    
    if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        echo "✓ Open"
        return 0
    else
        echo "✗ Closed/Filtered"
        return 1
    fi
}

# Test multiple common ports
portscan() {
    local host="$1"
    
    if [[ -z "$host" ]]; then
        echo "Usage: portscan <host>"
        return 1
    fi
    
    echo "Scanning common ports on $host..."
    echo ""
    
    local ports=(21 22 23 25 53 80 110 143 443 465 587 993 995 3306 3389 5432 6379 8080 8443)
    
    for port in "${ports[@]}"; do
        if timeout 2 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            echo "  Port $port: Open"
        fi
    done
    
    echo ""
    echo "Scan complete."
}

# Traceroute with timing
tracepath() {
    local host="$1"
    
    if [[ -z "$host" ]]; then
        echo "Usage: tracepath <host>"
        return 1
    fi
    
    if command -v mtr >/dev/null 2>&1; then
        mtr --report-wide --report-cycles 3 "$host"
    elif command -v traceroute >/dev/null 2>&1; then
        traceroute "$host"
    elif command -v tracepath >/dev/null 2>&1; then
        command tracepath "$host"
    else
        echo "No traceroute tool available."
    fi
}

#===============================================================================
# NETWORK INFORMATION
#===============================================================================

# Show all network interfaces with IPs
netinfo() {
    echo "Network Interfaces:"
    echo "==================="
    
    if command -v ip >/dev/null 2>&1; then
        ip -br addr show
    else
        ifconfig 2>/dev/null | grep -E 'inet|^[a-z]'
    fi
    
    echo ""
    echo "Default Gateway:"
    ip route | grep default 2>/dev/null || netstat -rn | grep -E '^0.0.0.0|default'
    
    echo ""
    echo "DNS Servers:"
    cat /etc/resolv.conf 2>/dev/null | grep nameserver
}

# Show active network connections
connections() {
    if command -v ss >/dev/null 2>&1; then
        ss -tunapl
    else
        netstat -tunapl
    fi
}

# Show listening ports
listening() {
    if command -v ss >/dev/null 2>&1; then
        ss -tlnp
    else
        netstat -tlnp
    fi
}

# Bandwidth test (requires speedtest-cli)
speedtest() {
    if command -v speedtest-cli >/dev/null 2>&1; then
        speedtest-cli
    elif command -v speedtest >/dev/null 2>&1; then
        command speedtest
    else
        echo "speedtest-cli not installed."
        echo "Install with: pip install speedtest-cli"
    fi
}

#===============================================================================
# DOWNLOAD UTILITIES
#===============================================================================

# Download file with progress
download() {
    local url="$1"
    local output="${2:-$(basename "$url")}"
    
    if [[ -z "$url" ]]; then
        echo "Usage: download <url> [output_filename]"
        return 1
    fi
    
    if command -v wget >/dev/null 2>&1; then
        wget --progress=bar:force "$url" -O "$output"
    elif command -v curl >/dev/null 2>&1; then
        curl -L --progress-bar "$url" -o "$output"
    else
        echo "Neither wget nor curl is installed."
        return 1
    fi
}

# Get headers only
headers() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo "Usage: headers <url>"
        return 1
    fi
    
    curl -sI "$url"
}

# Check if URL is accessible
checkurl() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo "Usage: checkurl <url>"
        return 1
    fi
    
    local status
    status=$(curl -sI -o /dev/null -w "%{http_code}" "$url")
    
    case "$status" in
        2*)
            echo "✓ $url is accessible (HTTP $status)"
            return 0
            ;;
        3*)
            echo "⟳ $url redirects (HTTP $status)"
            return 0
            ;;
        4*)
            echo "✗ $url returns client error (HTTP $status)"
            return 1
            ;;
        5*)
            echo "✗ $url returns server error (HTTP $status)"
            return 1
            ;;
        *)
            echo "? $url status unknown (HTTP $status)"
            return 1
            ;;
    esac
}

#===============================================================================
# SSL/TLS UTILITIES
#===============================================================================

# Check SSL certificate
sslcheck() {
    local host="$1"
    local port="${2:-443}"
    
    if [[ -z "$host" ]]; then
        echo "Usage: sslcheck <host> [port]"
        return 1
    fi
    
    echo "SSL Certificate for $host:$port"
    echo "================================"
    
    echo | openssl s_client -connect "$host:$port" -servername "$host" 2>/dev/null | \
        openssl x509 -noout -text 2>/dev/null | \
        grep -E 'Subject:|Issuer:|Not Before:|Not After:|DNS:'
}

# Get SSL certificate expiry
sslexpiry() {
    local host="$1"
    local port="${2:-443}"
    
    if [[ -z "$host" ]]; then
        echo "Usage: sslexpiry <host> [port]"
        return 1
    fi
    
    echo -n "SSL certificate for $host expires: "
    
    echo | openssl s_client -connect "$host:$port" -servername "$host" 2>/dev/null | \
        openssl x509 -noout -enddate 2>/dev/null | \
        cut -d= -f2
}

#===============================================================================
# SSH UTILITIES
#===============================================================================

# SSH with connection keepalive
sshk() {
    ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 "$@"
}

# SSH tunnel
tunnel() {
    local local_port="$1"
    local remote_host="$2"
    local remote_port="${3:-$local_port}"
    local ssh_host="$4"
    
    if [[ -z "$local_port" || -z "$remote_host" || -z "$ssh_host" ]]; then
        echo "Usage: tunnel <local_port> <remote_host> [remote_port] <ssh_host>"
        echo ""
        echo "Example: tunnel 3306 db.internal 3306 bastion.example.com"
        return 1
    fi
    
    echo "Creating tunnel: localhost:$local_port -> $remote_host:$remote_port via $ssh_host"
    ssh -N -L "$local_port:$remote_host:$remote_port" "$ssh_host"
}

# Copy SSH key to server
copykey() {
    local host="$1"
    
    if [[ -z "$host" ]]; then
        echo "Usage: copykey <user@host>"
        return 1
    fi
    
    if [[ -f ~/.ssh/id_rsa.pub ]]; then
        ssh-copy-id "$host"
    elif [[ -f ~/.ssh/id_ed25519.pub ]]; then
        ssh-copy-id -i ~/.ssh/id_ed25519.pub "$host"
    else
        echo "No public key found. Generate one with: ssh-keygen"
        return 1
    fi
}

#===============================================================================
# HELP
#===============================================================================

netaliases() {
    echo "Network Functions Available:"
    echo "============================"
    echo ""
    echo "DNS:"
    echo "  dnslookup <domain>    - DNS lookup (all types)"
    echo "  rdns <ip>             - Reverse DNS lookup"
    echo "  whoisinfo <domain>    - WHOIS information"
    echo ""
    echo "Testing:"
    echo "  httptest <url>        - Test HTTP endpoint"
    echo "  testport <host> <port> - Test port connectivity"
    echo "  portscan <host>       - Scan common ports"
    echo "  tracepath <host>      - Traceroute with timing"
    echo ""
    echo "Information:"
    echo "  netinfo               - Show network interfaces"
    echo "  connections           - Active connections"
    echo "  listening             - Listening ports"
    echo "  speedtest             - Bandwidth test"
    echo ""
    echo "Download:"
    echo "  download <url>        - Download with progress"
    echo "  headers <url>         - Get HTTP headers"
    echo "  checkurl <url>        - Check URL accessibility"
    echo ""
    echo "SSL:"
    echo "  sslcheck <host>       - Check SSL certificate"
    echo "  sslexpiry <host>      - Get certificate expiry"
    echo ""
    echo "SSH:"
    echo "  sshk                  - SSH with keepalive"
    echo "  tunnel                - Create SSH tunnel"
    echo "  copykey <host>        - Copy SSH key to server"
}

# Export functions
export -f dnslookup rdns whoisinfo 2>/dev/null
export -f httptest testport portscan tracepath 2>/dev/null
export -f netinfo connections listening speedtest 2>/dev/null
export -f download headers checkurl 2>/dev/null
export -f sslcheck sslexpiry 2>/dev/null
export -f sshk tunnel copykey 2>/dev/null
export -f netaliases 2>/dev/null
