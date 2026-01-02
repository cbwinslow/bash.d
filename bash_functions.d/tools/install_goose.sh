#!/bin/bash
# ==============================================================================
# FILENAME: install_goose.sh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-11-05
#
# TYPE: Bash Function
#
# PURPOSE:
#   Installs Goose, a terminal coding agent.
#
# SUMMARY:
#   This script defines a Bash function that sources the shared core logic
#   for Goose installation and executes it. It's the shell-specific entry point
#   for installing Goose.
#
# ==============================================================================

# Source the shared core logic
# source "${HOME}/.local/share/chezmoi/scripts/shared/install_goose_core.sh"

# Placeholder function since core file was removed
_install_goose_core() {
    echo "Goose installation core logic removed. Please install manually."
}

# ==============================================================================
# FUNCTION: install_goose
#
# DESCRIPTION:
#   This function calls the shared core logic to install Goose.
#
# USAGE:
#   install_goose
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   - Installation status messages.
#   - Instructions for user to configure Goose.
#
# ==============================================================================
install_goose() {
    _install_goose_core
}
