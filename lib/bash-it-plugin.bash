#!/bin/bash
# bash.d plugin for bash-it
# This allows bash.d to be loaded as a bash-it custom plugin

cite about-plugin
about-plugin 'bash.d modular bash configuration system'

# Load bash.d if not already loaded
if [[ -z "${BASHD_HOME}" ]]; then
    # Determine bash.d location
    if [[ -n "${BASH_D_REPO}" ]]; then
        export BASHD_REPO_ROOT="${BASH_D_REPO}"
    elif [[ -d "$HOME/.bash.d" ]]; then
        export BASHD_REPO_ROOT="$HOME/.bash.d"
    elif [[ -d "$HOME/bash.d" ]]; then
        export BASHD_REPO_ROOT="$HOME/bash.d"
    fi
    
    # Source bash.d bashrc if found
    if [[ -n "${BASHD_REPO_ROOT}" && -f "${BASHD_REPO_ROOT}/bashrc" ]]; then
        source "${BASHD_REPO_ROOT}/bashrc"
    fi
fi
