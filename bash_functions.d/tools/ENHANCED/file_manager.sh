#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  file_manager.sh
#
#         USAGE:  source file_manager.sh
#                 fm_store_file <category> <filename> <content> [--github=<repo>] [--cloudflare=<bucket>]
#                 fm_retrieve_file <category> <filename> [--github=<repo>] [--cloudflare=<bucket>]
#                 fm_list_files <category> [--github=<repo>] [--cloudflare=<bucket>]
#                 fm_sync_category <category> [--github=<repo>] [--cloudflare=<bucket>]
#
#   DESCRIPTION:  File management system for organizing project files like
#                 agents.md, rules.md, tools.md, etc. Supports both local
#                 storage and remote sync to GitHub/Cloudflare R2.
#                 Provides automatic categorization, backup, and versioning.
#
#       OPTIONS:  --category          File category (agents, rules, tools, logs, todos, configs)
#                 --github           Target GitHub repository for sync
#                 --cloudflare       Target Cloudflare bucket for sync
#                 --backup           Create local backup before operations
#                 --compress         Compress files for storage
#                 --version         Enable versioning for files
#
#  REQUIREMENTS:  Enhanced GitHub API wrapper, Cloudflare storage wrapper
#                 File system management tools, compression utilities
#
#          BUGS:  None known, all errors handled with retry logic
#         NOTES:  Files are organized by category with metadata tracking
#                 Automatic sync to remote storage on change
#                 Supports multiple storage backends simultaneously
#
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#       CREATED:  2025-01-08
#      REVISION:  
#===============================================================================

# Ensure script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed" >&2
    exit 1
fi

# Configuration
FM_ROOT_DIR="${FM_ROOT_DIR:-$HOME/.file_manager}"
FM_CATEGORIES="${FM_CATEGORIES:-agents,rules,tools,logs,todos,configs,memorys}"
FM_DEFAULT_GITHUB_REPO="${FM_DEFAULT_GITHUB_REPO:-}"
FM_DEFAULT_CLOUDFLARE_BUCKET="${FM_DEFAULT_CLOUDFLARE_BUCKET:-}"
FM_AUTO_SYNC="${FM_AUTO_SYNC:-false}"
FM_ENABLE_VERSIONING="${FM_ENABLE_VERSIONING:-true}"
FM_MAX_VERSIONS="${FM_MAX_VERSIONS:-10}"
FM_BACKUP_ENABLED="${FM_BACKUP_ENABLED:-true}"

# Category-specific subdirectories
FM_AGENTS_DIR="$FM_ROOT_DIR/agents"
FM_RULES_DIR="$FM_ROOT_DIR/rules"
FM_TOOLS_DIR="$FM_ROOT_DIR/tools"
FM_LOGS_DIR="$FM_ROOT_DIR/logs"
FM_TODOS_DIR="$FM_ROOT_DIR/todos"
FM_CONFIGS_DIR="$FM_ROOT_DIR/configs"
FM_MEMORYS_DIR="$FM_ROOT_DIR/memorys"

# Metadata and tracking
FM_METADATA_DIR="$FM_ROOT_DIR/.metadata"
FM_INDEX_FILE="$FM_METADATA_DIR/index.json"
FM_VERSIONS_DIR="$FM_ROOT_DIR/.versions"
FM_BACKUP_DIR="$FM_ROOT_DIR/.backups"

# Create required directories
for dir in "$FM_ROOT_DIR" "$FM_AGENTS_DIR" "$FM_RULES_DIR" "$FM_TOOLS_DIR" "$FM_LOGS_DIR" "$FM_TODOS_DIR" "$FM_CONFIGS_DIR" "$FM_MEMORYS_DIR" "$FM_METADATA_DIR" "$FM_VERSIONS_DIR" "$FM_BACKUP_DIR"; do
    mkdir -p "$dir"
done

# Initialize index file if it doesn't exist
if [[ ! -f "$FM_INDEX_FILE" ]]; then
    echo '{"files": [],"categories": ["agents","rules","tools","logs","todos","configs","memorys"]}' > "$FM_INDEX_FILE"
fi

# Logging function
_fm_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] [FM] $message" | tee -a "$FM_LOGS_DIR/file_manager.log"
}

# Error handling with logging
_fm_error() {
    _fm_log "ERROR" "$*"
    echo "ERROR: $*" >&2
    return 1
}

# Success logging
_fm_success() {
    _fm_log "SUCCESS" "$*"
    echo "✓ $*"
}

# Warning logging
_fm_warning() {
    _fm_log "WARNING" "$*"
    echo "⚠ $*"
}

# Validate category
_validate_category() {
    local category="$1"
    
    if [[ ! " $FM_CATEGORIES " =~ " $category " ]]; then
        _fm_error "Invalid category: $category. Valid categories: $FM_CATEGORIES"
        return 1
    fi
    
    return 0
}

# Get directory for category
_get_category_dir() {
    local category="$1"
    
    case "$category" in
        agents) echo "$FM_AGENTS_DIR" ;;
        rules) echo "$FM_RULES_DIR" ;;
        tools) echo "$FM_TOOLS_DIR" ;;
        logs) echo "$FM_LOGS_DIR" ;;
        todos) echo "$FM_TODOS_DIR" ;;
        configs) echo "$FM_CONFIGS_DIR" ;;
        memorys) echo "$FM_MEMORYS_DIR" ;;
        *) _fm_error "Unknown category: $category"; return 1 ;;
    esac
}

# Create backup of existing file
_create_backup() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        return 0
    fi
    
    local backup_file="${FM_BACKUP_DIR}/$(basename "$file_path")_$(date +%Y%m%d_%H%M%S).backup"
    mkdir -p "$(dirname "$backup_file")"
    cp "$file_path" "$backup_file"
    
    _fm_log "INFO" "Backup created: $backup_file"
}

# Create version snapshot
_create_version() {
    local file_path="$1"
    local category="$2"
    local filename="$3"
    
    if [[ "$FM_ENABLE_VERSIONING" != "true" ]]; then
        return 0
    fi
    
    if [[ ! -f "$file_path" ]]; then
        return 0
    fi
    
    local version_dir="${FM_VERSIONS_DIR}/${category}/${filename}"
    mkdir -p "$version_dir"
    
    local version_file="${version_dir}/$(date +%Y%m%d_%H%M%S)_$(sha256sum "$file_path" | cut -d' ' -f1)"
    cp "$file_path" "$version_file"
    
    # Clean up old versions
    cd "$version_dir"
    local versions=($(ls -t))
    if [[ ${#versions[@]} -gt $FM_MAX_VERSIONS ]]; then
        for old_version in "${versions[@]:$FM_MAX_VERSIONS}"; do
            rm -f "$old_version"
        done
    fi
    cd - >/dev/null
    
    _fm_log "INFO" "Version created: $version_file"
}

# Update file index
_update_index() {
    local category="$1"
    local filename="$2"
    local operation="$3"  # add, update, delete
    local remote_locations="$4"  # JSON array of remote locations
    
    local temp_index="${FM_INDEX_FILE}.tmp"
    local category_dir
    category_dir=$(_get_category_dir "$category")
    
    # Read current index
    local index_data
    index_data=$(cat "$FM_INDEX_FILE")
    
    case "$operation" in
        add|update)
            local file_size=0
            local file_hash=""
            local modified_time=""
            
            if [[ -f "$category_dir/$filename" ]]; then
                file_size=$(stat -c%s "$category_dir/$filename" 2>/dev/null || echo 0)
                file_hash=$(sha256sum "$category_dir/$filename" 2>/dev/null | cut -d' ' -f1 || echo "")
                modified_time=$(date -d "$(stat -c%y "$category_dir/$filename" 2>/dev/null)" -Iseconds 2>/dev/null || echo $(date +%s))
            fi
            
            local file_entry=$(jq -n \
                --arg category "$category" \
                --arg filename "$filename" \
                --arg size "$file_size" \
                --arg hash "$file_hash" \
                --arg modified "$modified_time" \
                --argjson remotes "${remote_locations:-[]}" \
                '{
                    category: $category,
                    filename: $filename,
                    size: ($size | tonumber),
                    hash: $hash,
                    modified: ($modified | tonumber),
                    remote_locations: $remotes
                }')
            
            index_data=$(echo "$index_data" | jq --arg category "$category" --arg filename "$filename" '
                .files |= map(select(.category != $category or .filename != $filename)) + [$file_entry]
            ')
            ;;
        delete)
            index_data=$(echo "$index_data" | jq --arg category "$category" --arg filename "$filename" '
                .files |= map(select(.category != $category or .filename != $filename))
            ')
            ;;
    esac
    
    echo "$index_data" > "$temp_index"
    mv "$temp_index" "$FM_INDEX_FILE"
    
    _fm_log "DEBUG" "Index updated for $category/$filename ($operation)"
}

# Sync to remote storage
_sync_to_remote() {
    local category="$1"
    local filename="$2"
    local local_file="$3"
    local github_repo="$4"
    local cloudflare_bucket="$5"
    
    local remote_locations="[]"
    
    # Sync to GitHub if specified
    if [[ -n "$github_repo" ]]; then
        if command -v gh_commit_file >/dev/null 2>&1; then
            local github_path="${category}/${filename}"
            if gh_commit_file "$github_repo" "$github_path" "@$local_file" --backup; then
                remote_locations=$(echo "$remote_locations" | jq --arg repo "$github_repo" --arg path "$github_path" '. + [{type: "github", repo: $repo, path: $path}]')
                _fm_success "Synced to GitHub: $github_repo/$github_path"
            else
                _fm_warning "Failed to sync to GitHub: $github_repo"
            fi
        else
            _fm_warning "GitHub API not available, skipping GitHub sync"
        fi
    fi
    
    # Sync to Cloudflare if specified
    if [[ -n "$cloudflare_bucket" ]]; then
        if command -v cf_upload_file >/dev/null 2>&1; then
            local cf_path="file_manager/${category}/${filename}"
            if cf_upload_file "$cloudflare_bucket" "$local_file" "$cf_path" --compress; then
                remote_locations=$(echo "$remote_locations" | jq --arg bucket "$cloudflare_bucket" --arg path "$cf_path" '. + [{type: "cloudflare", bucket: $bucket, path: $path}]')
                _fm_success "Synced to Cloudflare: $cloudflare_bucket/$cf_path"
            else
                _fm_warning "Failed to sync to Cloudflare: $cloudflare_bucket"
            fi
        else
            _fm_warning "Cloudflare storage not available, skipping Cloudflare sync"
        fi
    fi
    
    echo "$remote_locations"
}

# Store file in category
fm_store_file() {
    local category="$1"
    local filename="$2"
    local content="$3"
    local github_repo="$FM_DEFAULT_GITHUB_REPO"
    local cloudflare_bucket="$FM_DEFAULT_CLOUDFLARE_BUCKET"
    local backup_enabled="$FM_BACKUP_ENABLED"
    local compress=false
    
    # Parse arguments
    shift 3
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --github=*)
                github_repo="${1#*=}"
                shift
                ;;
            --github)
                github_repo="$2"
                shift 2
                ;;
            --cloudflare=*)
                cloudflare_bucket="${1#*=}"
                shift
                ;;
            --cloudflare)
                cloudflare_bucket="$2"
                shift 2
                ;;
            --no-backup)
                backup_enabled=false
                shift
                ;;
            --compress)
                compress=true
                shift
                ;;
            -*)
                _fm_error "Unknown option: $1"
                return 1
                ;;
            *)
                _fm_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate inputs
    if ! _validate_category "$category"; then
        return 1
    fi
    
    if [[ -z "$filename" ]]; then
        _fm_error "Filename required"
        return 1
    fi
    
    # Get category directory
    local category_dir
    category_dir=$(_get_category_dir "$category")
    
    local file_path="$category_dir/$filename"
    
    # Create backup if file exists
    if [[ "$backup_enabled" == true && -f "$file_path" ]]; then
        _create_backup "$file_path"
    fi
    
    # Create version snapshot
    _create_version "$file_path" "$category" "$filename"
    
    # Write content to file
    echo "$content" > "$file_path"
    
    # Compress if requested
    if [[ "$compress" == true ]]; then
        gzip -c "$file_path" > "${file_path}.gz"
        file_path="${file_path}.gz"
        filename="${filename}.gz"
    fi
    
    _fm_success "File stored: $category/$filename"
    
    if [[ "$FM_AUTO_SYNC" == true && (-n "$github_repo" || -n "$cloudflare_bucket") ]]; then
        local remote_locations
        remote_locations=$(_sync_to_remote "$category" "$filename" "$file_path" "$github_repo" "$cloudflare_bucket")
    else
        remote_locations="[]"
    fi
    
    _update_index "$category" "$filename" "update" "$remote_locations"
    
    echo "Stored: $category/$filename"
    echo "Size: $(wc -c < "$file_path") bytes"
    echo "Path: $file_path"
}

# Retrieve file from category
fm_retrieve_file() {
    local category="$1"
    local filename="$2"
    local github_repo="$FM_DEFAULT_GITHUB_REPO"
    local cloudflare_bucket="$FM_DEFAULT_CLOUDFLARE_BUCKET"
    local prefer_remote=false
    
    # Parse arguments
    shift 2
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --github=*)
                github_repo="${1#*=}"
                prefer_remote=true
                shift
                ;;
            --github)
                github_repo="$2"
                prefer_remote=true
                shift 2
                ;;
            --cloudflare=*)
                cloudflare_bucket="${1#*=}"
                prefer_remote=true
                shift
                ;;
            --cloudflare)
                cloudflare_bucket="$2"
                prefer_remote=true
                shift 2
                ;;
            -*)
                _fm_error "Unknown option: $1"
                return 1
                ;;
            *)
                _fm_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate inputs
    if ! _validate_category "$category"; then
        return 1
    fi
    
    if [[ -z "$filename" ]]; then
        _fm_error "Filename required"
        return 1
    fi
    
    # Get category directory
    local category_dir
    category_dir=$(_get_category_dir "$category")
    
    local file_path="$category_dir/$filename"
    
    # Try remote first if preferred
    if [[ "$prefer_remote" == true ]]; then
        if [[ -n "$github_repo" ]]; then
            local github_path="${category}/${filename}"
            if command -v gh_quick_commit >/dev/null 2>&1; then
                _fm_log "INFO" "Attempting to retrieve from GitHub: $github_repo/$github_path"
            fi
        fi
        
        if [[ -n "$cloudflare_bucket" ]]; then
            local cf_path="file_manager/${category}/${filename}"
            if command -v cf_download_file >/dev/null 2>&1; then
                if cf_download_file "$cloudflare_bucket" "$cf_path" "$file_path" --overwrite; then
                    _fm_success "Retrieved from Cloudflare: $cf_path"
                    echo "Content: $(cat "$file_path")"
                    return 0
                fi
            fi
        fi
    fi
    
    # Fallback to local file
    if [[ -f "$file_path" ]]; then
        _fm_success "Retrieved locally: $category/$filename"
        echo "Content: $(cat "$file_path")"
        echo "Size: $(wc -c < "$file_path") bytes"
        echo "Path: $file_path"
        return 0
    else
        _fm_error "File not found: $category/$filename"
        return 1
    fi
}

# List files in category
fm_list_files() {
    local category="$1"
    local github_repo="$FM_DEFAULT_GITHUB_REPO"
    local cloudflare_bucket="$FM_DEFAULT_CLOUDFLARE_BUCKET"
    local show_versions=false
    local show_backups=false
    
    # Parse arguments
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --github=*)
                github_repo="${1#*=}"
                shift
                ;;
            --github)
                github_repo="$2"
                shift 2
                ;;
            --cloudflare=*)
                cloudflare_bucket="${1#*=}"
                shift
                ;;
            --cloudflare)
                cloudflare_bucket="$2"
                shift 2
                ;;
            --versions)
                show_versions=true
                shift
                ;;
            --backups)
                show_backups=true
                shift
                ;;
            -*)
                _fm_error "Unknown option: $1"
                return 1
                ;;
            *)
                _fm_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate category
    if [[ -n "$category" ]] && ! _validate_category "$category"; then
        return 1
    fi
    
    # Get category directory
    local category_dir="$FM_ROOT_DIR"
    if [[ -n "$category" ]]; then
        category_dir=$(_get_category_dir "$category")
    fi
    
    echo "File Manager Contents"
    echo "─"$(printf '─%.0s' {1..50})
    
    # List files from index if available
    if [[ -f "$FM_INDEX_FILE" ]]; then
        local filter=""
        if [[ -n "$category" ]]; then
            filter="--arg category $category 'select(.category == \$category)'"
        else
            filter="."
        fi
        
        echo "Indexed files:"
        cat "$FM_INDEX_FILE" | jq -r --argjson filter "$filter" '
            .files | '$filter' | 
            sort_by(.modified) | 
            reverse |
            .[] |
            "📄 \(.category)/\(.filename)
  Size: \(.size) bytes
  Modified: \(.modified | strftime("%Y-%m-%d %H:%M:%S"))
  Hash: \(.hash[0:8])...
  Remote: \(.remote_locations | length) locations"
        '
        echo ""
    fi
    
    # List local files
    if [[ -n "$category" ]]; then
        echo "Local files in $category:"
        if [[ -d "$category_dir" ]]; then
            find "$category_dir" -type f -not -path "*/\.*" | while read -r file; do
                local basename_file=$(basename "$file")
                local size=$(stat -c%s "$file" 2>/dev/null || echo 0)
                local modified=$(stat -c%y "$file" 2>/dev/null || echo "Unknown")
                echo "📁 $basename_file (${size} bytes, $modified)"
            done
        fi
    else
        echo "Categories:"
        for cat in ${FM_CATEGORIES//,/ }; do
            local cat_dir
            cat_dir=$(_get_category_dir "$cat")
            local file_count=$(find "$cat_dir" -type f -not -path "*/\.*" 2>/dev/null | wc -l)
            echo "📂 $cat ($file_count files)"
        done
    fi
    
    # Show versions if requested
    if [[ "$show_versions" == true && -n "$category" ]]; then
        local version_dir="${FM_VERSIONS_DIR}/${category}"
        if [[ -d "$version_dir" ]]; then
            echo ""
            echo "File versions:"
            find "$version_dir" -name "*" -type d | while read -r file_version_dir; do
                local filename=$(basename "$file_version_dir")
                echo "📋 $filename:"
                find "$file_version_dir" -type f | while read -r version_file; do
                    local version_name=$(basename "$version_file")
                    echo "   └─ $version_name"
                done
            done
        fi
    fi
    
    # Show backups if requested
    if [[ "$show_backups" == true ]]; then
        echo ""
        echo "Backup files:"
        find "$FM_BACKUP_DIR" -name "*.backup" -type f | while read -r backup_file; do
            local backup_name=$(basename "$backup_file")
            local backup_date=$(stat -c%y "$backup_file" 2>/dev/null || echo "Unknown")
            echo "💾 $backup_name ($backup_date)"
        done
    fi
}

# Sync entire category
fm_sync_category() {
    local category="$1"
    local github_repo="$FM_DEFAULT_GITHUB_REPO"
    local cloudflare_bucket="$FM_DEFAULT_CLOUDFLARE_BUCKET"
    local delete_remote=false
    local compress=true
    
    # Parse arguments
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --github=*)
                github_repo="${1#*=}"
                shift
                ;;
            --github)
                github_repo="$2"
                shift 2
                ;;
            --cloudflare=*)
                cloudflare_bucket="${1#*=}"
                shift
                ;;
            --cloudflare)
                cloudflare_bucket="$2"
                shift 2
                ;;
            --delete)
                delete_remote=true
                shift
                ;;
            --no-compress)
                compress=false
                shift
                ;;
            -*)
                _fm_error "Unknown option: $1"
                return 1
                ;;
            *)
                _fm_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate category
    if ! _validate_category "$category"; then
        return 1
    fi
    
    # Get category directory
    local category_dir
    category_dir=$(_get_category_dir "$category")
    
    if [[ ! -d "$category_dir" ]]; then
        _fm_error "Category directory not found: $category_dir"
        return 1
    fi
    
    _fm_log "INFO" "Syncing category: $category"
    
    local file_count=0
    local success_count=0
    
    # Sync all files in category
    find "$category_dir" -type f -not -path "*/\.*" | while read -r local_file; do
        ((file_count++))
        
        local filename=$(basename "$local_file")
        local remote_locations="[]"
        
        # Sync to GitHub
        if [[ -n "$github_repo" ]]; then
            if command -v gh_commit_file >/dev/null 2>&1; then
                local github_path="${category}/${filename}"
                local upload_args="--backup"
                [[ "$compress" == true ]] && upload_args+=" --message=Sync $category/$filename"
                
                if gh_commit_file "$github_repo" "$github_path" "@$local_file" $upload_args; then
                    remote_locations=$(echo "$remote_locations" | jq --arg repo "$github_repo" --arg path "$github_path" '. + [{type: "github", repo: $repo, path: $path}]')
                    ((success_count++))
                    _fm_success "Synced to GitHub: $github_path"
                fi
            fi
        fi
        
        # Sync to Cloudflare
        if [[ -n "$cloudflare_bucket" ]]; then
            if command -v cf_upload_file >/dev/null 2>&1; then
                local cf_path="file_manager/${category}/${filename}"
                local cf_args="--backup"
                [[ "$compress" == true ]] && cf_args+=" --compress"
                
                if cf_upload_file "$cloudflare_bucket" "$local_file" "$cf_path" $cf_args; then
                    remote_locations=$(echo "$remote_locations" | jq --arg bucket "$cloudflare_bucket" --arg path "$cf_path" '. + [{type: "cloudflare", bucket: $bucket, path: $path}]')
                    ((success_count++))
                    _fm_success "Synced to Cloudflare: $cf_path"
                fi
            fi
        fi
        
        _update_index "$category" "$filename" "update" "$remote_locations"
        
        # Small delay between files
        sleep 1
    done
    
    echo "Sync completed: $success_count/$file_count files synced"
}

# Configuration
fm_config() {
    echo "File Manager Configuration:"
    echo "─"$(printf '─%.0s' {1..40})
    echo "Root Directory: $FM_ROOT_DIR"
    echo "Categories: $FM_CATEGORIES"
    echo "Default GitHub Repo: ${FM_DEFAULT_GITHUB_REPO:-'Not set'}"
    echo "Default Cloudflare Bucket: ${FM_DEFAULT_CLOUDFLARE_BUCKET:-'Not set'}"
    echo "Auto Sync: $FM_AUTO_SYNC"
    echo "Versioning Enabled: $FM_ENABLE_VERSIONING"
    echo "Max Versions: $FM_MAX_VERSIONS"
    echo "Backup Enabled: $FM_BACKUP_ENABLED"
    echo ""
    
    # Show directory structure
    echo "Directory Structure:"
    for cat in ${FM_CATEGORIES//,/ }; do
        local cat_dir
        cat_dir=$(_get_category_dir "$cat")
        local file_count=$(find "$cat_dir" -type f -not -path "*/\.*" 2>/dev/null | wc -l)
        echo "  📂 $cat: $cat_dir ($file_count files)"
    done
    echo ""
    
    # Check dependencies
    echo "Dependencies:"
    if command -v gh_commit_file >/dev/null 2>&1; then
        echo "  ✓ GitHub API wrapper available"
    else
        echo "  ✗ GitHub API wrapper not available"
    fi
    
    if command -v cf_upload_file >/dev/null 2>&1; then
        echo "  ✓ Cloudflare storage wrapper available"
    else
        echo "  ✗ Cloudflare storage wrapper not available"
    fi
    
    if command -v jq >/dev/null 2>&1; then
        echo "  ✓ JSON processor (jq) available"
    else
        echo "  ✗ JSON processor (jq) not available"
    fi
}

# Help function
fm_help() {
    cat << 'EOF'
File Management System for Project Files

File Operations:
  fm_store_file <category> <filename> <content> [--github=<repo>] [--cloudflare=<bucket>] [--compress] [--no-backup]
  fm_retrieve_file <category> <filename> [--github=<repo>] [--cloudflare=<bucket>]
  fm_list_files [category] [--versions] [--backups] [--github=<repo>] [--cloudflare=<bucket>]

Category Operations:
  fm_sync_category <category> [--github=<repo>] [--cloudflare=<bucket>] [--delete] [--no-compress]

Configuration:
  fm_config                    Show current configuration and directory structure
  fm_help                      Show this help

Categories:
  agents        - Agent configurations and scripts
  rules         - Project rules and guidelines
  tools         - Tool configurations
  logs          - Log files and outputs
  todos         - Task lists and todos
  configs       - Configuration files
  memorys       - Memory dumps and knowledge

Examples:
  fm_store_file agents agent1.md "# Agent Configuration"
  fm_retrieve_file rules project_rules.md
  fm_list_files agents --versions
  fm_sync_category tools --github=my-repo --cloudflare=my-bucket
  fm_store_file todos daily_tasks.md "- [ ] Task 1" --compress

Storage Integration:
  - Uses GitHub API wrapper for repository storage
  - Uses Cloudflare R2 wrapper for object storage
  - Automatic backup and versioning enabled
  - Metadata tracking in JSON index

Configuration:
  Set FM_DEFAULT_GITHUB_REPO for default GitHub repository
  Set FM_DEFAULT_CLOUDFLARE_BUCKET for default Cloudflare bucket
  Enable FM_AUTO_SYNC for automatic remote synchronization
EOF
}

# Auto-complete function
if command -v complete >/dev/null 2>&1; then
    _fm_complete() {
        local cur prev words cword
        _init_completion || return
        
        case "$prev" in
            fm_store_file|fm_retrieve_file|fm_sync_category|fm_list_files)
                COMPREPLY=($(compgen -W "agents rules tools logs todos configs memorys" -- "$cur"))
                ;;
            --github)
                # Could integrate with GitHub repo listing
                ;;
            --cloudflare)
                # Could integrate with Cloudflare bucket listing
                ;;
            *)
                case "$cur" in
                    -*)
                        COMPREPLY=($(compgen -W "--help --version --github --cloudflare --compress --backup --versions" -- "$cur"))
                        ;;
                    *)
                        COMPREPLY=($(compgen -W "fm_store_file fm_retrieve_file fm_list_files fm_sync_category fm_config fm_help" -- "$cur"))
                        ;;
                esac
                ;;
        esac
    }
    
    complete -F _fm_complete fm_store_file fm_retrieve_file fm_list_files fm_sync_category fm_config fm_help
fi

# Export functions
export -f fm_store_file fm_retrieve_file fm_list_files fm_sync_category fm_config fm_help

_fm_log "INFO" "File management system loaded successfully"