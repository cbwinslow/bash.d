#!/bin/bash
# bash-it integration module
# This module provides compatibility with bash-it framework

# Detect if bash-it is installed
bashd_detect_bash_it() {
    if [[ -n "${BASH_IT}" && -d "${BASH_IT}" ]]; then
        return 0
    fi
    return 1
}

# Initialize bash-it integration
bashd_init_bash_it() {
    if bashd_detect_bash_it; then
        export BASHD_BASH_IT_MODE=1
        echo "bash.d: bash-it integration enabled"
        
        # Set up custom directory in bash-it
        local bash_it_custom="${BASH_IT}/custom"
        if [[ ! -d "$bash_it_custom/bash.d" ]]; then
            mkdir -p "$bash_it_custom/bash.d"
        fi
        
        # Link bash.d as a bash-it custom module
        if [[ ! -L "$bash_it_custom/bash.d/bashd.plugin.bash" ]]; then
            ln -sf "${BASHD_REPO_ROOT}/lib/bash-it-plugin.bash" \
                   "$bash_it_custom/bash.d/bashd.plugin.bash"
        fi
    fi
}

# Export for use in other modules
export -f bashd_detect_bash_it 2>/dev/null
export -f bashd_init_bash_it 2>/dev/null
