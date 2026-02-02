#!/bin/bash
# ============================================================================
# Network Utilities
# ============================================================================
# Network tools for connectivity, API testing, and diagnostics

# Get external IP address
myip() {
    echo -e "${COLOR_YELLOW}Public IP:${COLOR_RESET}"
    curl -s ifconfig.me
    echo ""
}

# Get local IP address
localip() {
    echo -e "${COLOR_YELLOW}Local IP Address(es):${COLOR_RESET}"
    hostname -I 2>/dev/null || ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
}

# Check if port is open
portcheck() {
    if [ -z "$1" ]; then
        echo "Usage: portcheck <port> [host]"
        return 1
    fi
    
    local port="$1"
    local host="${2:-localhost}"
    
    if timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        echo -e "${COLOR_GREEN}Port $port on $host is OPEN${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}Port $port on $host is CLOSED${COLOR_RESET}"
        return 1
    fi
}

# Show listening ports
listening() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Listening Ports:${COLOR_RESET}"
    echo ""
    
    if command -v netstat &> /dev/null; then
        netstat -tuln | grep LISTEN
    elif command -v ss &> /dev/null; then
        ss -tuln | grep LISTEN
    else
        echo "Error: netstat or ss command not found"
        return 1
    fi
}

# Find process using a port
whichport() {
    if [ -z "$1" ]; then
        echo "Usage: whichport <port>"
        return 1
    fi
    
    local port="$1"
    
    if command -v lsof &> /dev/null; then
        lsof -i :"$port"
    else
        netstat -tulpn 2>/dev/null | grep ":$port"
    fi
}

# Simple ping with count
pingtest() {
    local host="${1:-8.8.8.8}"
    local count="${2:-5}"
    
    ping -c "$count" "$host"
}

# Test HTTP endpoint with curl
httptest() {
    if [ -z "$1" ]; then
        echo "Usage: httptest <url> [method]"
        return 1
    fi
    
    local url="$1"
    local method="${2:-GET}"
    
    echo -e "${COLOR_CYAN}Testing: $method $url${COLOR_RESET}"
    curl -X "$method" -i -s "$url"
}

# GET request with JSON response formatting
httpget() {
    if [ -z "$1" ]; then
        echo "Usage: httpget <url>"
        return 1
    fi
    
    curl -s "$1" | python3 -m json.tool 2>/dev/null || curl -s "$1"
}

# POST request with JSON data
httppost() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: httppost <url> <json_data>"
        return 1
    fi
    
    local url="$1"
    local data="$2"
    
    curl -X POST -H "Content-Type: application/json" -d "$data" "$url"
}

# Show HTTP headers
headers() {
    if [ -z "$1" ]; then
        echo "Usage: headers <url>"
        return 1
    fi
    
    curl -I -s "$1"
}

# Download file with progress bar
download() {
    if [ -z "$1" ]; then
        echo "Usage: download <url> [output_file]"
        return 1
    fi
    
    local url="$1"
    local output="${2:-$(basename "$url")}"
    
    curl -L -o "$output" --progress-bar "$url"
    echo -e "${COLOR_GREEN}Downloaded: $output${COLOR_RESET}"
}

# Speedtest using curl
speedtest() {
    echo -e "${COLOR_CYAN}Testing download speed...${COLOR_RESET}"
    curl -o /dev/null http://speedtest.tele2.net/10MB.zip
}

# DNS lookup
dnslookup() {
    if [ -z "$1" ]; then
        echo "Usage: dnslookup <domain>"
        return 1
    fi
    
    echo -e "${COLOR_YELLOW}DNS Lookup for: $1${COLOR_RESET}"
    echo ""
    
    if command -v dig &> /dev/null; then
        dig "$1" +short
    elif command -v nslookup &> /dev/null; then
        nslookup "$1"
    else
        host "$1"
    fi
}

# Reverse DNS lookup
reversedns() {
    if [ -z "$1" ]; then
        echo "Usage: reversedns <ip_address>"
        return 1
    fi
    
    host "$1"
}

# Check website response time
responsetime() {
    if [ -z "$1" ]; then
        echo "Usage: responsetime <url>"
        return 1
    fi
    
    local url="$1"
    
    echo -e "${COLOR_CYAN}Checking response time for: $url${COLOR_RESET}"
    
    curl -o /dev/null -s -w "\
    ${COLOR_YELLOW}Time Statistics:${COLOR_RESET}\n\
    DNS Lookup:     %{time_namelookup}s\n\
    TCP Connect:    %{time_connect}s\n\
    TLS Handshake:  %{time_appconnect}s\n\
    Pre-Transfer:   %{time_pretransfer}s\n\
    Redirect:       %{time_redirect}s\n\
    Start Transfer: %{time_starttransfer}s\n\
    ${COLOR_BOLD}Total Time:     %{time_total}s${COLOR_RESET}\n\
    \n\
    ${COLOR_YELLOW}Response:${COLOR_RESET}\n\
    HTTP Status:    %{http_code}\n\
    Size:           %{size_download} bytes\n" "$url"
}

# Show network interfaces
netinterfaces() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Network Interfaces:${COLOR_RESET}"
    echo ""
    
    if command -v ip &> /dev/null; then
        ip addr show
    else
        ifconfig
    fi
}

# Scan local network for devices
netscan() {
    local network="${1:-192.168.1.0/24}"
    
    echo -e "${COLOR_CYAN}Scanning network: $network${COLOR_RESET}"
    echo ""
    
    if command -v nmap &> /dev/null; then
        nmap -sn "$network"
    else
        echo "Error: nmap not installed. Install with: sudo apt-get install nmap"
        return 1
    fi
}

# Test connection to multiple hosts
multiping() {
    local hosts=("$@")
    
    if [ ${#hosts[@]} -eq 0 ]; then
        hosts=("8.8.8.8" "1.1.1.1" "google.com")
    fi
    
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Testing connectivity to multiple hosts:${COLOR_RESET}"
    echo ""
    
    for host in "${hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &> /dev/null; then
            echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $host is reachable"
        else
            echo -e "  ${COLOR_RED}✗${COLOR_RESET} $host is unreachable"
        fi
    done
}

# Show routing table
routes() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Routing Table:${COLOR_RESET}"
    echo ""
    
    if command -v ip &> /dev/null; then
        ip route
    else
        netstat -rn
    fi
}

# Measure bandwidth to a host
bandwidth() {
    if [ -z "$1" ]; then
        echo "Usage: bandwidth <host>"
        return 1
    fi
    
    local host="$1"
    echo -e "${COLOR_CYAN}Measuring bandwidth to: $host${COLOR_RESET}"
    
    if command -v iperf3 &> /dev/null; then
        iperf3 -c "$host"
    else
        echo "Error: iperf3 not installed. Install with: sudo apt-get install iperf3"
        return 1
    fi
}

# Get SSL certificate information
sslinfo() {
    if [ -z "$1" ]; then
        echo "Usage: sslinfo <domain>"
        return 1
    fi
    
    local domain="$1"
    echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -text
}

# Check if website is up
isup() {
    if [ -z "$1" ]; then
        echo "Usage: isup <url>"
        return 1
    fi
    
    local url="$1"
    
    if curl -s --head --request GET "$url" | grep "200 OK" > /dev/null; then
        echo -e "${COLOR_GREEN}$url is UP${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}$url is DOWN${COLOR_RESET}"
        return 1
    fi
}
