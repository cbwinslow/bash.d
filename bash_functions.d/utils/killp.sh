#!/bin/bash
killp() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: killp <process_name>"
        return 1
    fi
    
    pkill -f "$1"
    echo "Killed process: $1"
}
