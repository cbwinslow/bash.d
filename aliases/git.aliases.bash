#!/bin/bash
# Git aliases for bash.d
# Common git shortcuts and utilities

cite about-alias
about-alias 'Git shortcuts and utilities'

# Basic git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate'
alias gll='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
alias gb='git branch'
alias gba='git branch -a'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gm='git merge'
alias gr='git remote'
alias grv='git remote -v'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'

# Advanced git aliases
alias gclean='git clean -fd'
alias greset='git reset --hard'
alias gundo='git reset --soft HEAD~1'
alias gamend='git commit --amend --no-edit'
alias gpf='git push --force-with-lease'
alias grbm='git rebase main'
alias grbma='git rebase main --autostash'

# Git info functions
galiases() {
    echo "Git Aliases:"
    echo "============"
    alias | grep "^alias g" | sed 's/^alias /  /'
}
