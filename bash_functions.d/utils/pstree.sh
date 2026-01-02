#!/bin/bash
pstree() {
    if [ "$#" -ne 1 ]; then
        command pstree -p
    else
        command pstree -p "$1"
    fi
}
