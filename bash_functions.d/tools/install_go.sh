#!/bin/bash
# ==============================================================================
# FILENAME: install_go.sh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-11-05
#
# TYPE: Bash Function
#
# PURPOSE:
#   Installs the latest stable version of Go (Go-lang) on a Linux x64 system.
#
# SUMMARY:
#   This script defines a Bash function that sources the shared core logic
#   for Go installation and executes it. It's the shell-specific entry point
#   for installing Go.
#
# ==============================================================================

# Source the shared core logic
# source "${HOME}/.local/share/chezmoi/scripts/shared/install_go_core.sh"

# Placeholder function since core file was removed
_install_go_core() {
    echo "Go installation core logic removed. Please install manually."
}

# ==============================================================================
# FUNCTION: install_go
#
# DESCRIPTION:
#   This function calls the shared core logic to install Go-lang.
#
# USAGE:
#   install_go
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   - Installation status messages.
#   - Instructions for user to update their shell configuration.
#
# ==============================================================================
install_go() {
    _install_go_core
}
