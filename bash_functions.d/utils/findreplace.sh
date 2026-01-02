#!/bin/bash
findreplace() {
    if [ "$#" -ne 2 ]; then
        echo "Usage: findreplace <find_pattern> <replace_pattern>"
        return 1
    fi
    
    grep -rl "$1" . | xargs sed -i "s/$1/$2/g"
    echo "Replaced '$1' with '$2' in all files"
}
