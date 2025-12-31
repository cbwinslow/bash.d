#!/bin/bash
# Git command completions for bash.d

# Enable git completion if available
if [[ -f /usr/share/bash-completion/completions/git ]]; then
    source /usr/share/bash-completion/completions/git
elif [[ -f /etc/bash_completion.d/git ]]; then
    source /etc/bash_completion.d/git
fi

# Add completions for our git aliases
if type -t __git_complete &>/dev/null; then
    __git_complete g __git_main
    __git_complete gs _git_status
    __git_complete ga _git_add
    __git_complete gc _git_commit
    __git_complete gp _git_push
    __git_complete gpl _git_pull
    __git_complete gf _git_fetch
    __git_complete gd _git_diff
    __git_complete gl _git_log
    __git_complete gb _git_branch
    __git_complete gco _git_checkout
    __git_complete gm _git_merge
    __git_complete gr _git_remote
fi
