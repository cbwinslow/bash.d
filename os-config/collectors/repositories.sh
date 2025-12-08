#!/bin/bash
# Git Repositories Collector Script
# Finds and catalogs Git repositories on the system
# Outputs JSON format for AI agent consumption

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

command_exists() {
    command -v "$1" &> /dev/null
}

# Search paths for repositories
SEARCH_PATHS=(
    "$HOME/projects"
    "$HOME/code"
    "$HOME/src"
    "$HOME/git"
    "$HOME/repos"
    "$HOME/workspace"
    "$HOME/dev"
    "$HOME/Documents"
)

# Find git repositories
find_repositories() {
    local search_depth="${1:-3}"
    local repos=()
    
    log_info "Searching for Git repositories..."
    
    # Add current directory if it exists in search paths
    for search_path in "${SEARCH_PATHS[@]}"; do
        if [ ! -d "$search_path" ]; then
            continue
        fi
        
        log_info "Searching in $search_path..."
        
        # Find all .git directories
        while IFS= read -r git_dir; do
            local repo_path=$(dirname "$git_dir")
            
            # Get repo information
            cd "$repo_path" 2>/dev/null || continue
            
            local repo_name=$(basename "$repo_path")
            local remote_url=$(git remote get-url origin 2>/dev/null || echo "none")
            local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
            local last_commit=$(git log -1 --format="%H" 2>/dev/null || echo "none")
            local last_commit_date=$(git log -1 --format="%ai" 2>/dev/null || echo "unknown")
            local status=$(git status --porcelain 2>/dev/null | wc -l)
            local unpushed=$(git log @{u}.. --oneline 2>/dev/null | wc -l || echo 0)
            
            # Escape JSON special characters
            repo_path=$(echo "$repo_path" | sed 's/"/\\"/g')
            remote_url=$(echo "$remote_url" | sed 's/"/\\"/g')
            
            repos+=("{
                \"name\": \"$repo_name\",
                \"path\": \"$repo_path\",
                \"remote\": \"$remote_url\",
                \"branch\": \"$branch\",
                \"last_commit\": \"$last_commit\",
                \"last_commit_date\": \"$last_commit_date\",
                \"uncommitted_changes\": $status,
                \"unpushed_commits\": $unpushed
            }")
            
            cd - > /dev/null 2>&1
        done < <(find "$search_path" -maxdepth "$search_depth" -type d -name ".git" 2>/dev/null)
    done
    
    echo "${repos[@]}"
}

# Get Git configuration
get_git_config() {
    if ! command_exists git; then
        echo "{}"
        return
    fi
    
    local user_name=$(git config --global user.name 2>/dev/null || echo "not set")
    local user_email=$(git config --global user.email 2>/dev/null || echo "not set")
    local git_version=$(git --version 2>/dev/null | awk '{print $3}')
    
    cat << EOF
{
    "version": "$git_version",
    "user_name": "$user_name",
    "user_email": "$user_email"
}
EOF
}

# Main function
main() {
    local search_depth="${1:-3}"
    
    if ! command_exists git; then
        log_warn "Git is not installed"
        echo '{"error": "git not installed"}'
        exit 0
    fi
    
    log_info "Starting Git repository collection..."
    
    local repos_array=($(find_repositories "$search_depth"))
    local git_config=$(get_git_config)
    
    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$(hostname)",
    "git_config": $git_config,
    "repositories": [$(IFS=,; echo "${repos_array[*]}")],
    "total_repositories": ${#repos_array[@]}
}
EOF
    
    log_info "Found ${#repos_array[@]} repositories"
    log_info "Repository collection complete!"
}

main "$@"
