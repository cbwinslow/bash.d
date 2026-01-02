# Aliases for common workflows
# Place this file in your bash rc to load aliases for the bash_functions.d collection.

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'

# Navigation
alias proj='cd ~/bash_functions.d'

# Tools
alias bfdocs='bash ~/bash_functions.d/bf_docs.sh'
alias bfdeploy='bash ~/bash_functions.d/deploy_to_github.sh'

# Bitwarden helpers (use the bw CLI)
alias bwlogin='bw login --raw'
alias bwunlock='bw unlock --raw'

# TUI launcher
alias go-term='~/bash_functions.d/tui/go-term/term || true'

# Misc
alias ll='ls -la'

