#!/bin/bash
# bash.d core plugin
# Provides core bash.d functionality

cite about-plugin
about-plugin 'Core bash.d functionality and utilities'

# Core bash.d commands
alias bashd-reload='bashd_reload'
alias bashd-edit='bashd_edit_local'
alias bashd-status='bashd_snapshot_state'
alias bashd-install-omb='bashd_install_oh_my_bash'

# Module management commands
alias bashd-list='bashd_module_list'
alias bashd-enable='bashd_module_enable'
alias bashd-disable='bashd_module_disable'
alias bashd-search='bashd_module_search'
alias bashd-info='bashd_module_info'

# Quick navigation
alias cdbd='cd "$BASHD_REPO_ROOT"'
alias cdbdf='cd "$BASHD_REPO_ROOT/bash_functions.d"'
alias cdbdp='cd "$BASHD_REPO_ROOT/plugins"'
alias cdbda='cd "$BASHD_REPO_ROOT/aliases"'
