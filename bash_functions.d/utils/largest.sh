#!/bin/bash
largest() {
    if [ "$#" -ne 1 ]; then
        du -ah . | sort -rh | head -10
    else
        du -ah "$1" | sort -rh | head -10
    fi
}
