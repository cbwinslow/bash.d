#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  github_api_enhanced.sh
#
#         USAGE:  source github_api_enhanced.sh
#                 gh_create_repo <name> [--public|--private] [--description="desc"]
#                 gh_commit_file <repo> <file_path> [content] [--message="commit msg"]
#                 gh_list_repos [--sort=<field>] [--order=<asc|desc>] [--filter=<filter>]
#                 gh_quick_commit <repo> <file_path> <content>
#
#   DESCRIPTION:  Enhanced GitHub API wrapper with robust error handling,
#                 Bitwarden integration, automatic retries, and file management.
#                 Provides easy-to-use functions for repository creation,
#                 file commits, and repository management with automatic
#                 folder creation and comprehensive error handling.
#
#       OPTIONS:  --public/--private    Repository visibility
#                 --description       Repository description
#                 --sort              Sort field (created, updated, pushed, full_name)
#                 --order             Sort order (asc, desc)
#                 --filter            Filter repositories
#                 --message           Commit message
#                 --backup            Enable backup repositories
#                 --retries           Number of retries (default: 3)
#
#  REQUIREMENTS:  curl, jq, git, Bitwarden CLI (bw)
#                 GITHUB Personal Access Token in Bitwarden (entry: github_pat)
#
#          BUGS:  GitHub API rate limits handled with automatic retries
#         NOTES:  All functions automatically handle authentication via Bitwarden
#                 Uses rate limiting and retries to avoid API abuse
#                 Creates backup repositories for redundancy
#
#        AUTHOR:  bash.d project
#       VERSION:  2.0.0
#       CREATED:  2025-01-08
#      REVISION:  
#===============================================================================

# Ensure script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed" >&2
    exit 1
fi

# Configuration
GITHUB_API_BASE="${GITHUB_API_BASE:-https://api.github.com}"
GITHUB_PAT_ENTRY="${GITHUB_PAT_ENTRY:-github_pat}"
GITHUB_BACKUP_ORG="${GITHUB_BACKUP_ORG:-}"
GITHUB_MAX_RETRIES="${GITHUB_MAX_RETRIES:-3}"
GITHUB_RETRY_DELAY="${GITHUB_RETRY_DELAY:-2}"
GITHUB_RATE_LIMIT_DELAY="${GITHUB_RATE_LIMIT_DELAY:-1}"

# State directories
GITHUB_CACHE_DIR="${HOME}/.cache/github_api"
GITHUB_LOG_DIR="${HOME}/.logs/github_api"
GITHUB_BACKUP_DIR="${HOME}/.backups/github_commits"

# Create required directories
mkdir -p "$GITHUB_CACHE_DIR" "$GITHUB_LOG_DIR" "$GITHUB_BACKUP_DIR"

# Logging function
_github_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${GITHUB_LOG_DIR}/github_$(date +%Y%m%d).log"
    
    echo "[$timestamp] [$level] $message" | tee -a "$log_file"
}

# Error handling with logging
_github_error() {
    _github_log "ERROR" "$*"
    echo "ERROR: $*" >&2
    return 1
}

# Success logging
_github_success() {
    _github_log "SUCCESS" "$*"
    echo "✓ $*"
}

# Warning logging
_github_warning() {
    _github_log "WARNING" "$*"
    echo "⚠ $*"
}

# Rate limit handling with exponential backoff
_github_rate_limit_wait() {
    local retry_count="$1"
    local delay=$((GITHUB_RETRY_DELAY * (2 ** (retry_count - 1))))
    
    _github_warning "Rate limit detected, waiting ${delay}s (attempt $retry_count/$GITHUB_MAX_RETRIES)"
    sleep "$delay"
}

# Enhanced curl with retries and error handling
_github_curl() {
    local url="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    local headers="${4:-}"
    local retry_count=0
    local response=""
    local http_code=""
    
    while [[ $retry_count -lt $GITHUB_MAX_RETRIES ]]; do
        ((retry_count++))
        
        # Build curl command
        local curl_cmd="curl -s -w '%{http_code}'"
        curl_cmd+=" -X $method"
        curl_cmd+=" -H 'Authorization: token $GITHUB_TOKEN'"
        curl_cmd+=" -H 'Accept: application/vnd.github.v3+json'"
        curl_cmd+=" -H 'User-Agent: bash.d-github-api/2.0.0'"
        
        if [[ -n "$headers" ]]; then
            curl_cmd+=" $headers"
        fi
        
        if [[ -n "$data" && "$method" != "GET" ]]; then
            curl_cmd+=" -H 'Content-Type: application/json'"
            curl_cmd+=" -d '$data'"
        fi
        
        curl_cmd+=" '$url'"
        
        # Execute request
        local full_response
        full_response=$(eval "$curl_cmd" 2>/dev/null)
        http_code="${full_response: -3}"
        response="${full_response%???}"
        
        _github_log "DEBUG" "Request: $method $url (attempt $retry_count)"
        _github_log "DEBUG" "Response code: $http_code"
        
        # Check for success
        if [[ "$http_code" =~ ^[23] ]]; then
            echo "$response"
            return 0
        fi
        
        # Handle specific error codes
        case "$http_code" in
            401)
                _github_error "Authentication failed. Please check your GitHub PAT in Bitwarden."
                return 1
                ;;
            403)
                # Check if it's rate limiting
                if echo "$response" | jq -e '.message | test("API rate limit exceeded")' >/dev/null 2>&1; then
                    if [[ $retry_count -lt $GITHUB_MAX_RETRIES ]]; then
                        _github_rate_limit_wait "$retry_count"
                        continue
                    else
                        _github_error "Rate limit exceeded after $GITHUB_MAX_RETRIES attempts"
                        return 1
                    fi
                else
                    _github_error "Forbidden: $(echo "$response" | jq -r '.message // "Unknown error"')"
                    return 1
                fi
                ;;
            404)
                _github_error "Resource not found: $(echo "$response" | jq -r '.message // "Unknown error"')"
                return 1
                ;;
            422)
                _github_error "Validation error: $(echo "$response" | jq -r '.message // "Unknown error"')"
                return 1
                ;;
            *)
                _github_error "HTTP $http_code: $(echo "$response" | jq -r '.message // "Unknown error"')"
                return 1
                ;;
        esac
        
        # General retry for other errors
        if [[ $retry_count -lt $GITHUB_MAX_RETRIES ]]; then
            _github_rate_limit_wait "$retry_count"
        fi
    done
    
    _github_error "Request failed after $GITHUB_MAX_RETRIES attempts"
    return 1
}

# Get GitHub token from Bitwarden with fallback
_get_github_token() {
    local token=""
    
    # Try to get from Bitwarden
    if command -v bw >/dev/null 2>&1; then
        if [[ -n "${BW_SESSION:-}" ]] || BW_SESSION=$(bw unlock --raw 2>/dev/null); then
            token=$(bw get password "$GITHUB_PAT_ENTRY" 2>/dev/null || echo "")
        fi
    fi
    
    # Fallback to environment variable
    if [[ -z "$token" && -n "${GITHUB_TOKEN:-}" ]]; then
        token="$GITHUB_TOKEN"
    fi
    
    # Fallback to encrypted file
    if [[ -z "$token" && -f "$HOME/.bash_secrets.d/github/token.age" ]]; then
        if command -v age >/dev/null 2>&1 && [[ -f "$HOME/.bash_secrets.d/age_key.txt" ]]; then
            token=$(age -d -i "$HOME/.bash_secrets.d/age_key.txt" "$HOME/.bash_secrets.d/github/token.age" 2>/dev/null || echo "")
        fi
    fi
    
    if [[ -z "$token" ]]; then
        _github_error "GitHub token not found. Please store it in Bitwarden as '$GITHUB_PAT_ENTRY' or set GITHUB_TOKEN environment variable."
        return 1
    fi
    
    echo "$token"
}

# Validate repository name
_validate_repo_name() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        _github_error "Repository name cannot be empty"
        return 1
    fi
    
    # GitHub repo name rules: 1-100 chars, no spaces, special chars limited
    if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        _github_error "Repository name contains invalid characters. Use only letters, numbers, dots, hyphens, and underscores."
        return 1
    fi
    
    if [[ ${#name} -gt 100 ]]; then
        _github_error "Repository name too long (max 100 characters)"
        return 1
    fi
    
    return 0
}

# Check if repository exists
_repo_exists() {
    local owner="$1"
    local repo="$2"
    
    local response
    response=$(_github_curl "${GITHUB_API_BASE}/repos/$owner/$repo" "GET")
    
    [[ $? -eq 0 ]]
}

# Create backup repository if configured
_create_backup_repo() {
    local original_name="$1"
    local is_private="$2"
    local description="$3"
    
    if [[ -z "$GITHUB_BACKUP_ORG" ]]; then
        return 0
    fi
    
    local backup_name="${original_name}_backup_$(date +%Y%m%d_%H%M%S)"
    
    _github_log "INFO" "Creating backup repository: $backup_name"
    
    local visibility="false"
    if [[ "$is_private" == "true" ]]; then
        visibility="true"
    fi
    
    local data="{\"name\":\"$backup_name\",\"private\":$visibility,\"description\":\"Backup of $original_name - $description\"}"
    
    local response
    response=$(_github_curl "${GITHUB_API_BASE}/orgs/$GITHUB_BACKUP_ORG/repos" "POST" "$data")
    
    if [[ $? -eq 0 ]]; then
        local clone_url=$(echo "$response" | jq -r '.clone_url')
        _github_success "Backup repository created: $clone_url"
        echo "$clone_url"
        return 0
    else
        _github_warning "Failed to create backup repository"
        return 1
    fi
}

# Main function to create repository
gh_create_repo() {
    local name=""
    private=false
    description=""
    auto_init=true
    backup_enabled=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --public)
                private=false
                shift
                ;;
            --private)
                private=true
                shift
                ;;
            --description=*)
                description="${1#*=}"
                shift
                ;;
            --description)
                description="$2"
                shift 2
                ;;
            --backup)
                backup_enabled=true
                shift
                ;;
            --no-auto-init)
                auto_init=false
                shift
                ;;
            -*)
                _github_error "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$name" ]]; then
                    name="$1"
                else
                    _github_error "Multiple repository names provided"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate repository name
    if ! _validate_repo_name "$name"; then
        return 1
    fi
    
    # Get authentication token
    if ! GITHUB_TOKEN=$(_get_github_token); then
        return 1
    fi
    
    # Get current user
    local user_response
    user_response=$(_github_curl "${GITHUB_API_BASE}/user" "GET")
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local username=$(echo "$user_response" | jq -r '.login')
    
    # Check if repository already exists
    if _repo_exists "$username" "$name"; then
        _github_warning "Repository '$username/$name' already exists"
        return 1
    fi
    
    # Create backup if enabled
    if [[ "$backup_enabled" == true ]]; then
        _create_backup_repo "$name" "$private" "$description"
    fi
    
    # Build repository data
    local visibility="false"
    if [[ "$private" == true ]]; then
        visibility="true"
    fi
    
    local init_flag="false"
    if [[ "$auto_init" == true ]]; then
        init_flag="true"
    fi
    
    local data="{\"name\":\"$name\",\"private\":$visibility,\"auto_init\":$init_flag"
    
    if [[ -n "$description" ]]; then
        data+=",\"description\":\"$description\""
    fi
    
    data+="}"
    
    _github_log "INFO" "Creating repository: $name (private: $private)"
    
    # Create repository
    local response
    response=$(_github_curl "${GITHUB_API_BASE}/user/repos" "POST" "$data")
    
    if [[ $? -eq 0 ]]; then
        local repo_url=$(echo "$response" | jq -r '.html_url')
        local clone_url=$(echo "$response" | jq -r '.clone_url')
        
        _github_success "Repository created: $repo_url"
        echo "Repository: $repo_url"
        echo "Clone URL: $clone_url"
        echo "Username: $username"
        echo "Repository: $name"
        
        return 0
    else
        return 1
    fi
}

# Function to commit file to repository with automatic folder creation
gh_commit_file() {
    local repo="$1"
    local file_path="$2"
    local content="${3:-}"
    local message="Update $file_path"
    local branch="main"
    local backup_enabled=false
    
    # Parse arguments
    shift 3
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --message=*)
                message="${1#*=}"
                shift
                ;;
            --message)
                message="$2"
                shift 2
                ;;
            --branch=*)
                branch="${1#*=}"
                shift
                ;;
            --branch)
                branch="$2"
                shift 2
                ;;
            --backup)
                backup_enabled=true
                shift
                ;;
            -*)
                _github_error "Unknown option: $1"
                return 1
                ;;
            *)
                _github_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate inputs
    if [[ -z "$repo" ]]; then
        _github_error "Repository name is required"
        return 1
    fi
    
    if [[ -z "$file_path" ]]; then
        _github_error "File path is required"
        return 1
    fi
    
    # Validate file path (no absolute paths, no directory traversal)
    if [[ "$file_path" =~ ^/ ]] || [[ "$file_path" =~ \.\. ]]; then
        _github_error "Invalid file path: $file_path. Use relative paths without directory traversal."
        return 1
    fi
    
    # Get authentication token
    if ! GITHUB_TOKEN=$(_get_github_token); then
        return 1
    fi
    
    # Parse repository (owner/repo or just repo name)
    local owner
    local repo_name
    
    if [[ "$repo" =~ ^[^/]+/[^/]+$ ]]; then
        owner="${repo%/*}"
        repo_name="${repo#*/}"
    else
        # Get current user
        local user_response
        user_response=$(_github_curl "${GITHUB_API_BASE}/user" "GET")
        
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        
        owner=$(echo "$user_response" | jq -r '.login')
        repo_name="$repo"
    fi
    
    # Check if repository exists
    if ! _repo_exists "$owner" "$repo_name"; then
        _github_error "Repository '$owner/$repo_name' does not exist"
        return 1
    fi
    
    # If content not provided, read from file
    if [[ -z "$content" ]]; then
        if [[ -f "$file_path" ]]; then
            content=$(cat "$file_path")
        else
            _github_error "File '$file_path' not found and no content provided"
            return 1
        fi
    fi
    
    # Encode content to base64
    local content_base64
    content_base64=$(echo -n "$content" | base64 -w 0)
    
    # Check if file already exists
    local file_response
    file_response=$(_github_curl "${GITHUB_API_BASE}/repos/$owner/$repo_name/contents/$file_path?ref=$branch" "GET")
    local sha=""
    
    if [[ $? -eq 0 ]]; then
        sha=$(echo "$file_response" | jq -r '.sha // empty')
        if [[ -n "$sha" ]]; then
            _github_log "INFO" "File exists, updating with SHA: $sha"
            message="Update $file_path"
        else
            message="Create $file_path"
        fi
    else
        message="Create $file_path"
    fi
    
    # Create backup if enabled
    if [[ "$backup_enabled" == true ]]; then
        local backup_file="${GITHUB_BACKUP_DIR}/${repo_name}_${file_path//\//_}_$(date +%Y%m%d_%H%M%S).backup"
        mkdir -p "$(dirname "$backup_file")"
        echo "$content" > "$backup_file"
        _github_success "Backup created: $backup_file"
    fi
    
    # Build file data
    local data="{\"message\":\"$message\",\"content\":\"$content_base64\""
    
    if [[ -n "$sha" ]]; then
        data+=",\"sha\":\"$sha\""
    fi
    
    data+="}"
    
    _github_log "INFO" "Committing file: $file_path to $owner/$repo_name:$branch"
    
    # Create/update file
    local response
    response=$(_github_curl "${GITHUB_API_BASE}/repos/$owner/$repo_name/contents/$file_path" "PUT" "$data")
    
    if [[ $? -eq 0 ]]; then
        local commit_sha=$(echo "$response" | jq -r '.commit.sha')
        local download_url=$(echo "$response" | jq -r '.content.download_url')
        
        _github_success "File committed successfully"
        echo "Repository: $owner/$repo_name"
        echo "File: $file_path"
        echo "Branch: $branch"
        echo "Commit SHA: $commit_sha"
        echo "Download URL: $download_url"
        
        return 0
    else
        return 1
    fi
}

# Quick commit function for ease of use
gh_quick_commit() {
    local repo="$1"
    local file_path="$2"
    local content="$3"
    
    if [[ $# -lt 3 ]]; then
        echo "Usage: gh_quick_commit <repo> <file_path> <content>"
        return 1
    fi
    
    gh_commit_file "$repo" "$file_path" "$content" --message="Quick commit $file_path"
}

# Function to list repositories with sorting and filtering
gh_list_repos() {
    local sort="created"
    local order="desc"
    local type="all"
    local per_page=30
    local filter=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sort=*)
                sort="${1#*=}"
                shift
                ;;
            --sort)
                sort="$2"
                shift 2
                ;;
            --order=*)
                order="${1#*=}"
                shift
                ;;
            --order)
                order="$2"
                shift 2
                ;;
            --type=*)
                type="${1#*=}"
                shift
                ;;
            --type)
                type="$2"
                shift 2
                ;;
            --filter=*)
                filter="${1#*=}"
                shift
                ;;
            --filter)
                filter="$2"
                shift 2
                ;;
            --limit=*)
                per_page="${1#*=}"
                shift
                ;;
            --limit)
                per_page="$2"
                shift 2
                ;;
            -*)
                _github_error "Unknown option: $1"
                return 1
                ;;
            *)
                _github_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate parameters
    case "$sort" in
        created|updated|pushed|full_name) ;;
        *)
            _github_error "Invalid sort field. Use: created, updated, pushed, full_name"
            return 1
            ;;
    esac
    
    case "$order" in
        asc|desc) ;;
        *)
            _github_error "Invalid order. Use: asc, desc"
            return 1
            ;;
    esac
    
    case "$type" in
        all|owner|member) ;;
        *)
            _github_error "Invalid type. Use: all, owner, member"
            return 1
            ;;
    esac
    
    # Get authentication token
    if ! GITHUB_TOKEN=$(_get_github_token); then
        return 1
    fi
    
    # Build URL
    local url="${GITHUB_API_BASE}/user/repos?type=$type&sort=$sort&direction=$order&per_page=$per_page"
    
    _github_log "INFO" "Listing repositories (sort: $sort, order: $order, type: $type)"
    
    # Get repositories
    local response
    response=$(_github_curl "$url" "GET")
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Apply filter if provided
    if [[ -n "$filter" ]]; then
        response=$(echo "$response" | jq --arg filter "$filter" '[.[] | select(.name | test($filter; "i"))]')
    fi
    
    # Format and display results
    echo "Repositories ($(echo "$response" | jq 'length')):"
    echo "─"$(printf '─%.0s' {1..50})
    
    echo "$response" | jq -r '
        .[] | 
        "\(.name) 
  Visibility: \(.visibility // "unknown")
  Created: \(.created_at[0:10])
  Updated: \(.updated_at[0:10])
  Language: \(.language // "none")
  Stars: \(.stargazers_count)
  URL: \(.html_url)"
    ' | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            if [[ "$line" =~ ^[a-zA-Z0-9._-]+$ ]]; then
                echo "📁 $line"
            else
                echo "   $line"
            fi
        fi
    done
    
    echo ""
    echo "Total: $(echo "$response" | jq 'length') repositories"
}

# Function to get repository information
gh_repo_info() {
    local repo="$1"
    
    if [[ -z "$repo" ]]; then
        echo "Usage: gh_repo_info <owner/repo>"
        return 1
    fi
    
    # Get authentication token
    if ! GITHUB_TOKEN=$(_get_github_token); then
        return 1
    fi
    
    local response
    response=$(_github_curl "${GITHUB_API_BASE}/repos/$repo" "GET")
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    echo "Repository Information:"
    echo "─"$(printf '─%.0s' {1..40})
    echo "$response" | jq -r '
        "Name: \(.name)
  Full Name: \(.full_name)
  Description: \(.description // "No description")
  Owner: \(.owner.login)
  Visibility: \(.visibility // .private // "unknown")
  Language: \(.language // "none")
  Created: \(.created_at)
  Updated: \(.updated_at)
  Pushed: \(.pushed_at)
  Size: \(.size) KB
  Stars: \(.stargazers_count)
  Watchers: \(.watchers_count)
  Forks: \(.forks_count)
  Open Issues: \(.open_issues_count)
  Default Branch: \(.default_branch)
  Clone URL: \(.clone_url)
  SSH URL: \(.ssh_url)
  HTML URL: \(.html_url)"
    '
}

# Function to create or update multiple files
gh_commit_files() {
    local repo="$1"
    shift
    local files=()
    local message="Batch commit"
    local backup_enabled=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --message=*)
                message="${1#*=}"
                shift
                ;;
            --message)
                message="$2"
                shift 2
                ;;
            --backup)
                backup_enabled=true
                shift
                ;;
            --file=*)
                files+=("${1#*=}")
                shift
                ;;
            --file)
                files+=("$2")
                shift 2
                ;;
            *)
                _github_error "Unknown option: $1"
                return 1
                ;;
        esac
    done
    
    if [[ ${#files[@]} -eq 0 ]]; then
        _github_error "No files specified. Use --file=path=content"
        return 1
    fi
    
    _github_log "INFO" "Committing ${#files[@]} files to $repo"
    
    # Process each file
    for file_spec in "${files[@]}"; do
        local path="${file_spec%%=*}"
        local content="${file_spec#*=}"
        
        gh_commit_file "$repo" "$path" "$content" --message="$message" --backup="$backup_enabled"
        
        if [[ $? -ne 0 ]]; then
            _github_error "Failed to commit $path"
            return 1
        fi
        
        # Small delay between commits to avoid rate limiting
        sleep "$GITHUB_RATE_LIMIT_DELAY"
    done
    
    _github_success "All files committed successfully"
}

# Function to manage GitHub API configuration
gh_config() {
    echo "GitHub API Configuration:"
    echo "─"$(printf '─%.0s' {1..40})
    echo "API Base: $GITHUB_API_BASE"
    echo "PAT Entry: $GITHUB_PAT_ENTRY"
    echo "Backup Org: ${GITHUB_BACKUP_ORG:-'Not set'}"
    echo "Max Retries: $GITHUB_MAX_RETRIES"
    echo "Retry Delay: ${GITHUB_RETRY_DELAY}s"
    echo "Rate Limit Delay: ${GITHUB_RATE_LIMIT_DELAY}s"
    echo "Cache Dir: $GITHUB_CACHE_DIR"
    echo "Log Dir: $GITHUB_LOG_DIR"
    echo "Backup Dir: $GITHUB_BACKUP_DIR"
    echo ""
    
    # Test authentication
    echo "Testing authentication..."
    if GITHUB_TOKEN=$(_get_github_token); then
        local user_response
        user_response=$(_github_curl "${GITHUB_API_BASE}/user" "GET")
        
        if [[ $? -eq 0 ]]; then
            local username=$(echo "$user_response" | jq -r '.login')
            local name=$(echo "$user_response" | jq -r '.name // "No name"')
            echo "✓ Authenticated as: $username ($name)"
        else
            echo "✗ Authentication failed"
            return 1
        fi
    else
        echo "✗ Failed to get GitHub token"
        return 1
    fi
}

# Function to show help
gh_help() {
    cat << 'EOF'
Enhanced GitHub API Wrapper Functions

Repository Management:
  gh_create_repo <name> [--public|--private] [--description="desc"] [--backup] [--no-auto-init]
  gh_repo_info <owner/repo>
  gh_list_repos [--sort=<field>] [--order=<asc|desc>] [--type=<all|owner|member>] [--filter=<pattern>]

File Operations:
  gh_commit_file <repo> <file_path> [content] [--message="msg"] [--branch=<name>] [--backup]
  gh_quick_commit <repo> <file_path> <content>
  gh_commit_files <repo> [--file=path=content]... [--message="msg"] [--backup]

Configuration:
  gh_config                    Show current configuration and test auth
  gh_help                      Show this help

Examples:
  gh_create_repo my-awesome-project --public --description="My new project"
  gh_commit_file username/my-repo docs/readme.md "# My Project" --message="Add README"
  gh_quick_commit my-repo config/settings.json '{"debug": true}'
  gh_list_repos --sort=updated --order=desc --filter=project
  gh_repo_info octocat/Hello-World

Authentication:
  Store your GitHub PAT in Bitwarden with entry name 'github_pat'
  or set the GITHUB_TOKEN environment variable.

For more information, see the GitHub API documentation:
https://docs.github.com/en/rest
EOF
}

# Auto-complete function for enhanced user experience
if command -v complete >/dev/null 2>&1; then
    _gh_complete() {
        local cur prev words cword
        _init_completion || return
        
        case "$prev" in
            gh_create_repo)
                COMPREPLY=($(compgen -W "--public --private --description --backup --no-auto-init" -- "$cur"))
                ;;
            gh_commit_file)
                COMPREPLY=($(compgen -W "--message --branch --backup" -- "$cur"))
                ;;
            gh_list_repos)
                COMPREPLY=($(compgen -W "--sort --order --type --filter --limit" -- "$cur"))
                ;;
            gh_repo_info|gh_config|gh_help)
                # No arguments
                ;;
            *)
                case "$cur" in
                    -*)
                        COMPREPLY=($(compgen -W "--help --version" -- "$cur"))
                        ;;
                    *)
                        COMPREPLY=($(compgen -W "gh_create_repo gh_commit_file gh_quick_commit gh_list_repos gh_repo_info gh_config gh_help" -- "$cur"))
                        ;;
                esac
                ;;
        esac
    }
    
    complete -F _gh_complete gh_create_repo gh_commit_file gh_quick_commit gh_list_repos gh_repo_info gh_config gh_help
fi

# Export functions
export -f gh_create_repo gh_commit_file gh_quick_commit gh_list_repos gh_repo_info gh_commit_files gh_config gh_help

_github_log "INFO" "Enhanced GitHub API wrapper loaded successfully"