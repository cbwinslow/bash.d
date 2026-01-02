#!/bin/bash
dsize() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: dsize <directory>"
        return 1
    fi
    
    if [ ! -d "$1" ]; then
        echo "Error: '$1' is not a directory"
        return 1
    fi
    
    du -sh "$1"
}
