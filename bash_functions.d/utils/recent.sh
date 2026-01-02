#!/bin/bash
recent() {
    if [ "$#" -ne 1 ]; then
        ls -lt | head -10
    else
        ls -lt "$1" | head -10
    fi
}
