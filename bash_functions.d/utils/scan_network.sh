#!/bin/bash
scan_network() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: scan_network <host>"
        return 1
    fi
    
    echo "Scanning common ports on $1..."
    for port in 22 80 443 3000 8000 8080; do
        if nc -z -w3 "$1" "$port" 2>/dev/null; then
            echo "Port $port: OPEN"
        else
            echo "Port $port: CLOSED"
        fi
    done
}
