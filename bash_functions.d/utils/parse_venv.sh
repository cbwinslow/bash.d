#!/bin/bash
parse_venv() {
    if [ -n "$VIRTUAL_ENV" ]; then
        echo " ($(basename $VIRTUAL_ENV))"
    fi
}
