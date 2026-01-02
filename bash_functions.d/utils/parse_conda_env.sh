#!/bin/bash
parse_conda_env() {
    if [ -n "$CONDA_DEFAULT_ENV" ]; then
        echo " (conda:$CONDA_DEFAULT_ENV)"
    fi
}
