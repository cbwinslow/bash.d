#!/bin/bash
# bash-it compatibility shims
# Provides stub functions for bash-it commands when bash-it is not installed

# Check if we're running under bash-it
if [[ -z "${BASH_IT}" ]]; then
    # Provide stub functions for bash-it compatibility
    
    cite() {
        # Stub for bash-it's cite function
        :
    }
    
    about-plugin() {
        # Stub for bash-it's about-plugin function
        :
    }
    
    about-alias() {
        # Stub for bash-it's about-alias function
        :
    }
    
    about-completion() {
        # Stub for bash-it's about-completion function
        :
    }
    
    export -f cite 2>/dev/null
    export -f about-plugin 2>/dev/null
    export -f about-alias 2>/dev/null
    export -f about-completion 2>/dev/null
fi
