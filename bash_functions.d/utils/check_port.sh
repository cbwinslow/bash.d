#!/bin/bash
check_port() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: check_port <port>"
        return 1
    fi
    
    if nc -z localhost "$1" 2>/dev/null; then
        echo "Port $1 is OPEN"
    else
        echo "Port $1 is CLOSED"
    fi
}
