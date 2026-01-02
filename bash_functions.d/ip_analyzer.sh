#!/usr/bin/env bash

# ip_analyzer - A tool to analyze IP addresses from traceroute or log files
# Usage: ip_analyzer [input_file] [options]
# If no input file is provided, reads from stdin

# Configuration
OUTPUT_DIR="${HOME}/ip_analysis_reports"
REPORT_FILE="${OUTPUT_DIR}/ip_analysis_$(date +%Y%m%d_%H%M%S).txt"
API_TIMEOUT=10  # seconds

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to extract IPs from input
extract_ips() {
    local input_file="$1"

    if [ -f "$input_file" ]; then
        # Extract IPs from file
        grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$input_file" | sort -u
    else
        # Read from stdin
        grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort -u
    fi
}

# Function to check if IP is private
is_private_ip() {
    local ip=$1

    # Check for private IP ranges
    if [[ $ip =~ ^10\. ]] || \
       [[ $ip =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || \
       [[ $ip =~ ^192\.168\. ]] || \
       [[ $ip =~ ^127\. ]]; then
        return 0  # True, is private
    fi
    return 1  # False, is public
}

# Function to get IP information
get_ip_info() {
    local ip=$1

    if is_private_ip "$ip"; then
        echo -e "\n${YELLOW}IP: $ip (Private)${NC}"
        echo "  Type: Private IP Address"
        return
    fi

    echo -e "\n${GREEN}IP: $ip${NC}"

    # Get IP information using curl and jq
    local result
    if command -v jq >/dev/null 2>&1; then
        result=$(curl -s "http://ip-api.com/json/$ip?fields=status,message,country,countryCode,region,regionName,city,isp,org,as,asname,reverse,mobile,proxy,hosting,query" 2>/dev/null)

        if [ $? -eq 0 ] && [ -n "$result" ]; then
            local status=$(echo "$result" | jq -r '.status // ""')

            if [ "$status" = "success" ]; then
                local country=$(echo "$result" | jq -r '.country // "N/A"')
                local city=$(echo "$result" | jq -r '.city // "N/A"')
                local isp=$(echo "$result" | jq -r '.isp // "N/A"')
                local org=$(echo "$result" | jq -r '.org // "N/A"')
                local asn=$(echo "$result" | jq -r '.as // "N/A"')
                local reverse_dns=$(echo "$result" | jq -r '.reverse // "N/A"')
                local is_proxy=$(echo "$result" | jq -r '.proxy // "false"')
                local is_hosting=$(echo "$result" | jq -r '.hosting // "false"')

                echo "  Location: $city, $country"
                echo "  ISP: $isp"
                echo "  Organization: $org"
                echo "  ASN: $asn"
                echo "  Reverse DNS: $reverse_dns"
                echo "  Proxy/VPN: $([ "$is_proxy" = "true" ] && echo "Yes" || echo "No")"
                echo "  Hosting/Datacenter: $([ "$is_hosting" = "true" ] && echo "Yes" || echo "No")"

                # Check for known VPN/Proxy services
                if [[ "$isp" == *"VPN"* ]] || [[ "$org" == *"VPN"* ]] ||
                   [[ "$isp" == *"Proxy"* ]] || [[ "$org" == *"Proxy"* ]]; then
                    echo -e "  ${RED}WARNING: This IP may belong to a VPN/Proxy service${NC}"
                fi

                return
            fi
        fi
    fi

    # Fallback to whois if available
    if command -v whois >/dev/null 2>&1; then
        echo "  Getting information from whois..."
        whois "$ip" | grep -i -E '^org|^netname|^country|^descr' | head -5 | sed 's/^/  /'
    else
        echo "  Could not retrieve detailed information. Install 'jq' for better results."
    fi
}

# Function to check IP against public blocklists
check_blocklists() {
    local ip=$1

    if is_private_ip "$ip"; then
        return
    fi

    echo -e "\n  [Blocklist Check]"

    # Check DNSBLs (DNS-based Blackhole Lists)
    local dnsbls=(
        "zen.spamhaus.org"
        "bl.spamcop.net"
        "b.barracudacentral.org"
        "dnsbl.sorbs.net"
        "spam.dnsbl.sorbs.net"
    )

    local listed=0

    for dnsbl in "${dnsbls[@]}"; do
        # Reverse the IP for DNSBL lookup
        local reversed_ip=$(echo "$ip" | awk -F. '{print $4"."$3"."$2"."$1}')

        # Check if the IP is listed
        if nslookup "$reversed_ip.$dnsbl" >/dev/null 2>&1; then
            echo -e "  ${RED}LISTED${NC} on $dnsbl"
            listed=$((listed + 1))
        else
            echo -e "  ${GREEN}CLEAN${NC} on $dnsbl"
        fi
    done

    if [ $listed -gt 0 ]; then
        echo -e "\n  ${RED}WARNING: This IP is listed on $listed blocklist(s)${NC}"
    else
        echo -e "\n  ${GREEN}No blocklist matches found${NC}"
    fi
}

# Main function
ip_analyzer() {
    local input_file="$1"

    # Check if input is from pipe or file
    if [ $# -eq 0 ] && [ -t 0 ]; then
        echo "Usage: ip_analyzer [input_file]"
        echo "If no input file is provided, reads from stdin"
        echo "Examples:"
        echo "  ip_analyzer traceroute.log"
        echo "  cat logfile.txt | ip_analyzer"
        echo "  ip_analyzer <(some_command)"
        return 1
    fi

    # Create a temporary file for the report
    local temp_report=$(mktemp)

    # Process each IP
    local count=0
    local private_ips=0

    while read -r ip; do
        # Skip empty lines and invalid IPs
        if [[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            continue
        fi

        # Process the IP
        count=$((count + 1))

        if is_private_ip "$ip"; then
            private_ips=$((private_ips + 1))
        fi

        # Get IP info and save to temp file
        {
            echo ""
            echo "$(get_ip_info "$ip")"
            echo "$(check_blocklists "$ip")"
            echo ""
            echo "----------------------------------------"
        } | tee -a "$temp_report"

        # Be nice to the API
        sleep 0.5

    done < <(extract_ips "$input_file")

    # Generate final report
    {
        echo "IP Analysis Report"
        echo "Generated: $(date)"
        echo "Total IPs processed: $count"
        echo "- Public IPs: $((count - private_ips))"
        echo "- Private IPs: $private_ips"
        echo ""
        echo "Detailed Results:"
        echo "================="
        cat "$temp_report"
    } > "$REPORT_FILE"

    # Clean up
    rm -f "$temp_report"

    echo -e "\n${GREEN}Analysis complete! Report saved to:${NC} $REPORT_FILE"

    # Check if xdg-open is available to open the report
    if command -v xdg-open >/dev/null 2>&1; then
        read -p "Would you like to view the report now? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            xdg-open "$REPORT_FILE"
        fi
    fi
}

# Make the function available in the current shell
export -f ip_analyzer

# If script is executed directly, run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ip_analyzer "$@"
fi
