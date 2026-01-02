#!/bin/bash
backup() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: backup <file>"
        return 1
    fi
    
    if [ ! -f "$1" ]; then
        echo "Error: '$1' is not a file"
        return 1
    fi
    
    cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
    echo "Backup created: $1.bak.$(date +%Y%m%d_%H%M%S)"
}
