#!/bin/bash
#===============================================================================
#
#          FILE:  git_utils.sh
#
#         USAGE:  Automatically sourced by .bashrc
#
#   DESCRIPTION:  Git utility functions for common git operations
#
#       OPTIONS:  ---
#  REQUIREMENTS:  git
#         NOTES:  Enhances git workflow
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Check if git is available
if ! command -v git >/dev/null 2>&1; then
    return 0
fi

#===============================================================================
# GIT STATUS AND INFO
#===============================================================================

# Enhanced git status
gs() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Git Status                                                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    git status -sb
}

# Git log with graph
glog() {
    git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit -n "${1:-20}"
}

# Git log for a specific file
glogf() {
    if [[ -z "$1" ]]; then
        echo "Usage: glogf <file>"
        return 1
    fi
    git log --follow --pretty=format:'%Cred%h%Creset - %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' -- "$1"
}

# Show recent commits by current user
mycommits() {
    local count="${1:-10}"
    git log --author="$(git config user.name)" --oneline -n "$count"
}

# Show contributors
contributors() {
    git shortlog -sn --all
}

#===============================================================================
# GIT BRANCHES
#===============================================================================

# List branches sorted by last commit date
gbdate() {
    git for-each-ref --sort=-committerdate refs/heads/ --format='%(committerdate:short) %(refname:short)' | head -20
}

# Create and checkout new branch
gnew() {
    if [[ -z "$1" ]]; then
        echo "Usage: gnew <branch_name>"
        return 1
    fi
    git checkout -b "$1"
}

# Delete merged branches (except main/master/develop)
gclean() {
    echo "Branches that would be deleted:"
    git branch --merged | grep -vE '(^\*|main|master|develop)' || echo "  (none)"
    echo ""
    echo "Delete these branches? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy] ]]; then
        git branch --merged | grep -vE '(^\*|main|master|develop)' | xargs -r git branch -d
        echo "Merged branches deleted."
    fi
}

# Switch branch with fzf
gco() {
    if [[ -n "$1" ]]; then
        git checkout "$1"
    elif command -v fzf >/dev/null 2>&1; then
        local branch
        branch=$(git branch --all | fzf --preview 'git log --oneline -n 10 {}' | sed 's/^[* ]*//;s/remotes\/origin\///')
        [[ -n "$branch" ]] && git checkout "$branch"
    else
        git branch
        echo -n "Enter branch name: "
        read -r branch
        git checkout "$branch"
    fi
}

#===============================================================================
# GIT COMMITS AND STAGING
#===============================================================================

# Quick commit with message
gcm() {
    if [[ -z "$1" ]]; then
        echo "Usage: gcm <commit message>"
        return 1
    fi
    git commit -m "$1"
}

# Add all and commit
gac() {
    if [[ -z "$1" ]]; then
        echo "Usage: gac <commit message>"
        return 1
    fi
    git add -A && git commit -m "$1"
}

# Add all, commit, and push
gacp() {
    if [[ -z "$1" ]]; then
        echo "Usage: gacp <commit message>"
        return 1
    fi
    git add -A && git commit -m "$1" && git push
}

# Amend last commit
gamend() {
    git commit --amend --no-edit
}

# Amend with new message
gamendm() {
    if [[ -z "$1" ]]; then
        git commit --amend
    else
        git commit --amend -m "$1"
    fi
}

# Interactive staging
gadd() {
    if command -v fzf >/dev/null 2>&1; then
        git status -s | fzf -m --preview 'git diff --color=always {2}' | awk '{print $2}' | xargs -r git add
    else
        git add -i
    fi
}

# Unstage files
gunstage() {
    if [[ -z "$1" ]]; then
        git reset HEAD
    else
        git reset HEAD "$@"
    fi
}

#===============================================================================
# GIT DIFF AND COMPARISON
#===============================================================================

# Show diff with word highlighting
gdiff() {
    git diff --word-diff=color "$@"
}

# Show staged changes
gstaged() {
    git diff --cached --word-diff=color
}

# Compare branches
gcompare() {
    local branch1="${1:-main}"
    local branch2="${2:-HEAD}"
    git log --oneline "$branch1".."$branch2"
}

# Show what changed between two commits
gchanged() {
    local commit1="${1:-HEAD~1}"
    local commit2="${2:-HEAD}"
    git diff --stat "$commit1" "$commit2"
}

#===============================================================================
# GIT STASH
#===============================================================================

# Quick stash
gstash() {
    local message="${1:-WIP}"
    git stash push -m "$message"
}

# List stashes
gstashlist() {
    git stash list
}

# Apply stash with fzf
gstashpop() {
    if command -v fzf >/dev/null 2>&1; then
        local stash
        stash=$(git stash list | fzf | cut -d: -f1)
        [[ -n "$stash" ]] && git stash pop "$stash"
    else
        git stash pop
    fi
}

# Show stash contents
gstashshow() {
    local stash="${1:-0}"
    git stash show -p "stash@{$stash}"
}

#===============================================================================
# GIT REMOTE AND SYNC
#===============================================================================

# Pull with rebase
gpull() {
    git pull --rebase origin "$(git rev-parse --abbrev-ref HEAD)"
}

# Push to current branch
gpush() {
    git push origin "$(git rev-parse --abbrev-ref HEAD)"
}

# Force push with lease (safer than force push)
gpushf() {
    git push --force-with-lease origin "$(git rev-parse --abbrev-ref HEAD)"
}

# Sync fork with upstream
gsync() {
    local branch="${1:-main}"
    git fetch upstream
    git checkout "$branch"
    git merge "upstream/$branch"
    git push origin "$branch"
}

# Show remotes
gremotes() {
    git remote -v
}

#===============================================================================
# GIT UNDO AND RECOVERY
#===============================================================================

# Undo last commit (keep changes staged)
gundo() {
    git reset --soft HEAD~1
}

# Undo last commit (keep changes unstaged)
gundou() {
    git reset HEAD~1
}

# Discard all changes
gdiscard() {
    echo "This will discard ALL uncommitted changes. Are you sure? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy] ]]; then
        git checkout -- .
        git clean -fd
        echo "All changes discarded."
    fi
}

# Restore a deleted file
grestore() {
    if [[ -z "$1" ]]; then
        echo "Usage: grestore <filename>"
        return 1
    fi
    git checkout "$(git rev-list -n 1 HEAD -- "$1")"^ -- "$1"
}

#===============================================================================
# GIT WORKFLOW HELPERS
#===============================================================================

# Start a new feature branch
gfeature() {
    local feature_name="$1"
    if [[ -z "$feature_name" ]]; then
        echo "Usage: gfeature <feature_name>"
        return 1
    fi
    git checkout -b "feature/$feature_name"
}

# Start a bugfix branch
gbugfix() {
    local fix_name="$1"
    if [[ -z "$fix_name" ]]; then
        echo "Usage: gbugfix <fix_name>"
        return 1
    fi
    git checkout -b "bugfix/$fix_name"
}

# Show today's commits
gtoday() {
    git log --since='00:00:00' --all --oneline --author="$(git config user.name)"
}

# Interactive rebase
grebase() {
    local count="${1:-5}"
    git rebase -i "HEAD~$count"
}

# Show git configuration
gconfig() {
    echo "=== Global Config ==="
    git config --global --list
    echo ""
    echo "=== Local Config ==="
    git config --local --list 2>/dev/null || echo "(no local config)"
}

# Git aliases defined in this file
galiases() {
    echo "Git Functions Available:"
    echo "========================"
    echo ""
    echo "Status/Info:"
    echo "  gs            - Enhanced git status"
    echo "  glog [n]      - Git log with graph (default 20)"
    echo "  glogf <file>  - Git log for a file"
    echo "  mycommits [n] - Show my recent commits"
    echo ""
    echo "Branches:"
    echo "  gbdate        - Branches by last commit date"
    echo "  gnew <name>   - Create and checkout new branch"
    echo "  gclean        - Delete merged branches"
    echo "  gco [name]    - Checkout branch (fzf if no name)"
    echo ""
    echo "Commits:"
    echo "  gcm <msg>     - Commit with message"
    echo "  gac <msg>     - Add all and commit"
    echo "  gacp <msg>    - Add, commit, and push"
    echo "  gamend        - Amend last commit"
    echo "  gadd          - Interactive staging (fzf)"
    echo ""
    echo "Stash:"
    echo "  gstash [msg]  - Quick stash"
    echo "  gstashlist    - List stashes"
    echo "  gstashpop     - Pop stash (fzf)"
    echo ""
    echo "Remote:"
    echo "  gpull         - Pull with rebase"
    echo "  gpush         - Push current branch"
    echo "  gpushf        - Force push with lease"
    echo ""
    echo "Undo:"
    echo "  gundo         - Undo last commit (keep staged)"
    echo "  gundou        - Undo last commit (unstaged)"
    echo "  gdiscard      - Discard all changes"
}

# Export functions
export -f gs glog glogf mycommits contributors 2>/dev/null
export -f gbdate gnew gclean gco 2>/dev/null
export -f gcm gac gacp gamend gamendm gadd gunstage 2>/dev/null
export -f gdiff gstaged gcompare gchanged 2>/dev/null
export -f gstash gstashlist gstashpop gstashshow 2>/dev/null
export -f gpull gpush gpushf gsync gremotes 2>/dev/null
export -f gundo gundou gdiscard grestore 2>/dev/null
export -f gfeature gbugfix gtoday grebase gconfig galiases 2>/dev/null
