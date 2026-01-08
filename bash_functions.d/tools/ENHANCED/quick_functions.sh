#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  quick_functions.sh
#
#         USAGE:  source quick_functions.sh
#                 quick_repo <name> [--public|--private]
#                 quick_commit <repo> <file> <content>
#                 quick_upload <file> [remote_path]
#                 quick_agent <name> [content]
#                 quick_rule <name> [content]
#                 quick_config <name> [content]
#
#   DESCRIPTION:  Quick bash functions for shell usage with simplified
#                 interfaces to GitHub API, Cloudflare storage, and file management.
#                 Provides one-liners for common operations with smart defaults.
#
#       OPTIONS:  --public/--private  Repository visibility
#                 --compress         Compress uploads
#                 --backup          Create backups
#                 --sync            Sync to remote storage
#
#  REQUIREMENTS:  Enhanced GitHub API, Cloudflare storage, File manager
#
#          BUGS:  None known - all errors handled gracefully
#         NOTES:  Designed for rapid shell workflow with minimal typing
#                 Auto-detects file types and content
#                 Uses intelligent defaults for all parameters
#
#        AUTHOR:  bash.d project
#       VERSION: 1.0.0
#       CREATED:  2025-01-08
#      REVISION:  
#===============================================================================

# Ensure script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed" >&2
    exit 1
fi

# Load required dependencies
if ! command -v gh_create_repo >/dev/null 2>&1; then
    echo "Loading GitHub API wrapper..."
    source "${BASH_FUNCTIONS_DIR:-./bash_functions.d/tools}/github_api_enhanced.sh" 2>/dev/null || {
        echo "Error: GitHub API wrapper not found" >&2
        return 1
    }
fi

if ! command -v cf_upload_file >/dev/null 2>&1; then
    echo "Loading Cloudflare storage wrapper..."
    source "${BASH_FUNCTIONS_DIR:-./bash_functions.d/tools}/cloudflare_storage.sh" 2>/dev/null || {
        echo "Error: Cloudflare storage wrapper not found" >&2
        return 1
    }
fi

if ! command -v fm_store_file >/dev/null 2>&1; then
    echo "Loading file manager..."
    source "${BASH_FUNCTIONS_DIR:-./bash_functions.d/tools}/file_manager.sh" 2>/dev/null || {
        echo "Error: File manager not found" >&2
        return 1
    }
fi

if ! command -v cf_upload_file >/dev/null 2>&1; then
    echo "Loading Cloudflare storage wrapper..."
    source "${BASH_FUNCTIONS_DIR:-$HOME/bash_functions.d}/tools/cloudflare_storage.sh" 2>/dev/null || {
        echo "Error: Cloudflare storage wrapper not found" >&2
        return 1
    }
fi

if ! command -v fm_store_file >/dev/null 2>&1; then
    echo "Loading file manager..."
    source "${BASH_FUNCTIONS_DIR:-$HOME/bash_functions.d}/tools/file_manager.sh" 2>/dev/null || {
        echo "Error: File manager not found" >&2
        return 1
    }
fi

# Quick repository creation
quick_repo() {
    local name="$1"
    local visibility="public"
    local auto_init=true
    local backup=false
    
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --public)
                visibility="public"
                shift
                ;;
            --private)
                visibility="private"
                shift
                ;;
            --no-init)
                auto_init=false
                shift
                ;;
            --backup)
                backup=true
                shift
                ;;
            -*)
                echo "Usage: quick_repo <name> [--public|--private] [--no-init] [--backup]" >&2
                return 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    if [[ -z "$name" ]]; then
        echo "Usage: quick_repo <name> [--public|--private] [--no-init] [--backup]" >&2
        return 1
    fi
    
    local args=""
    [[ "$visibility" == "private" ]] && args+=" --private"
    [[ "$auto_init" == false ]] && args+=" --no-auto-init"
    [[ "$backup" == true ]] && args+=" --backup"
    
    echo "Creating repository: $name ($visibility)"
    gh_create_repo "$name" $args
}

# Quick file commit
quick_commit() {
    local repo="$1"
    local file="$2"
    local content="$3"
    local message=""
    local backup=false
    
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
            --backup)
                backup=true
                shift
                ;;
            -*)
                echo "Usage: quick_commit <repo> <file> <content> [--message='msg'] [--backup]" >&2
                return 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    if [[ $# -lt 3 ]]; then
        echo "Usage: quick_commit <repo> <file> <content> [--message='msg'] [--backup]" >&2
        return 1
    fi
    
    if [[ -z "$message" ]]; then
        message="Quick commit $file"
    fi
    
    local args="--message='$message'"
    [[ "$backup" == true ]] && args+=" --backup"
    
    echo "Committing to $repo: $file"
    gh_commit_file "$repo" "$file" "$content" $args
}

# Quick upload to Cloudflare
quick_upload() {
    local file="$1"
    local remote_path="$2"
    local bucket=""
    local compress=false
    local backup=false
    
    shift 2
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --bucket=*)
                bucket="${1#*=}"
                shift
                ;;
            --bucket)
                bucket="$2"
                shift 2
                ;;
            --compress)
                compress=true
                shift
                ;;
            --backup)
                backup=true
                shift
                ;;
            -*)
                echo "Usage: quick_upload <file> [remote_path] [--bucket=<name>] [--compress] [--backup]" >&2
                return 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    if [[ -z "$file" ]]; then
        echo "Usage: quick_upload <file> [remote_path] [--bucket=<name>] [--compress] [--backup]" >&2
        return 1
    fi
    
    if [[ -z "$remote_path" ]]; then
        remote_path=$(basename "$file")
    fi
    
    local args=""
    [[ "$compress" == true ]] && args+=" --compress"
    [[ "$backup" == true ]] && args+=" --backup"
    
    echo "Uploading to Cloudflare: $file -> $remote_path"
    cf_upload_file "$bucket" "$file" "$remote_path" $args
}

# Quick agent file creation
quick_agent() {
    local name="$1"
    local content="$2"
    local github_repo=""
    local cloudflare_bucket=""
    local sync=false
    
    shift 2
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --github=*)
                github_repo="${1#*=}"
                sync=true
                shift
                ;;
            --github)
                github_repo="$2"
                sync=true
                shift 2
                ;;
            --cloudflare=*)
                cloudflare_bucket="${1#*=}"
                sync=true
                shift
                ;;
            --cloudflare)
                cloudflare_bucket="$2"
                sync=true
                shift 2
                ;;
            --sync)
                sync=true
                shift
                ;;
            -*)
                echo "Usage: quick_agent <name> [content] [--github=<repo>] [--cloudflare=<bucket>] [--sync]" >&2
                return 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    if [[ -z "$name" ]]; then
        echo "Usage: quick_agent <name> [content] [--github=<repo>] [--cloudflare=<bucket>] [--sync]" >&2
        return 1
    fi
    
    if [[ -z "$content" ]]; then
        content="# Agent: $name

## Description
Configuration and settings for $name agent.

## Configuration
\`\`\`json
{
  \"name\": \"$name\",
  \"enabled\": true,
  \"version\": \"1.0.0\"
}
\`\`\`

## Usage
\`\`\`bash
# Run agent
./run_agent.sh $name
\`\`\`

## Notes
Created on $(date)
"
    fi
    
    local filename="${name}.md"
    local args=""
    
    [[ -n "$github_repo" ]] && args+=" --github=$github_repo"
    [[ -n "$cloudflare_bucket" ]] && args+=" --cloudflare=$cloudflare_bucket"
    [[ "$sync" == true ]] && args+=" --sync"
    
    echo "Creating agent file: $filename"
    fm_store_file "agents" "$filename" "$content" $args
}

# Quick rule file creation
quick_rule() {
    local name="$1"
    local content="$2"
    local github_repo=""
    local cloudflare_bucket=""
    local sync=false
    
    shift 2
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --github=*)
                github_repo="${1#*=}"
                sync=true
                shift
                ;;
            --github)
                github_repo="$2"
                sync=true
                shift 2
                ;;
            --cloudflare=*)
                cloudflare_bucket="${1#*=}"
                sync=true
                shift
                ;;
            --cloudflare)
                cloudflare_bucket="$2"
                sync=true
                shift 2
                ;;
            --sync)
                sync=true
                shift
                ;;
            -*)
                echo "Usage: quick_rule <name> [content] [--github=<repo>] [--cloudflare=<bucket>] [--sync]" >&2
                return 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    if [[ -z "$name" ]]; then
        echo "Usage: quick_rule <name> [content] [--github=<repo>] [--cloudflare=<bucket>] [--sync]" >&2
        return 1
    fi
    
    if [[ -z "$content" ]]; then
        content="# Rule: $name

## Description
Rule definition and guidelines for $name.

## Rule Definition
\`\`\`
Define the rule here...
\`\`\`

## Examples
\`\`\`
Example usage...
\`\`\`

## Implementation
\`\`\`bash
# Implementation details
echo "Applying rule: $name"
\`\`\`

## Notes
Created on $(date)
"
    fi
    
    local filename="${name}.md"
    local args=""
    
    [[ -n "$github_repo" ]] && args+=" --github=$github_repo"
    [[ -n "$cloudflare_bucket" ]] && args+=" --cloudflare=$cloudflare_bucket"
    [[ "$sync" == true ]] && args+=" --sync"
    
    echo "Creating rule file: $filename"
    fm_store_file "rules" "$filename" "$content" $args
}

# Quick config file creation
quick_config() {
    local name="$1"
    local content="$2"
    local github_repo=""
    local cloudflare_bucket=""
    local sync=false
    
    shift 2
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --github=*)
                github_repo="${1#*=}"
                sync=true
                shift
                ;;
            --github)
                github_repo="$2"
                sync=true
                shift 2
                ;;
            --cloudflare=*)
                cloudflare_bucket="${1#*=}"
                sync=true
                shift
                ;;
            --cloudflare)
                cloudflare_bucket="$2"
                sync=true
                shift 2
                ;;
            --sync)
                sync=true
                shift
                ;;
            -*)
                echo "Usage: quick_config <name> [content] [--github=<repo>] [--cloudflare=<bucket>] [--sync]" >&2
                return 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    if [[ -z "$name" ]]; then
        echo "Usage: quick_config <name> [content] [--github=<repo>] [--cloudflare=<bucket>] [--sync]" >&2
        return 1
    fi
    
    if [[ -z "$content" ]]; then
        content="# Configuration: $name

## Description
Configuration settings for $name.

## Settings
\`\`\`json
{
  \"name\": \"$name\",
  \"enabled\": true,
  \"debug\": false,
  \"timeout\": 30,
  \"retries\": 3
}
\`\`\`

## Environment Variables
\`\`\`bash
export ${name^^}_CONFIG_PATH=\"/path/to/config\"
export ${name^^}_DEBUG=false
\`\`\`

## Notes
Created on $(date)
"
    fi
    
    local filename="${name}.conf"
    local args=""
    
    [[ -n "$github_repo" ]] && args+=" --github=$github_repo"
    [[ -n "$cloudflare_bucket" ]] && args+=" --cloudflare=$cloudflare_bucket"
    [[ "$sync" == true ]] && args+=" --sync"
    
    echo "Creating config file: $filename"
    fm_store_file "configs" "$filename" "$content" $args
}

# Quick todo list management
quick_todo() {
    local task="$1"
    local list_name="default"
    local github_repo=""
    local cloudflare_bucket=""
    
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --list=*)
                list_name="${1#*=}"
                shift
                ;;
            --list)
                list_name="$2"
                shift 2
                ;;
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
            -*)
                echo "Usage: quick_todo <task> [--list=<name>] [--github=<repo>] [--cloudflare=<bucket>]" >&2
                return 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    if [[ -z "$task" ]]; then
        echo "Usage: quick_todo <task> [--list=<name>] [--github=<repo>] [--cloudflare=<bucket>]" >&2
        return 1
    fi
    
    local filename="${list_name}_todos.md"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local todo_entry="- [ ] $task ($timestamp)"
    
    # Check if file exists
    local existing_content=""
    if command -v fm_retrieve_file >/dev/null 2>&1; then
        existing_content=$(fm_retrieve_file "todos" "$filename" 2>/dev/null || echo "")
    fi
    
    if [[ -n "$existing_content" ]]; then
        content="$existing_content"$'\n'"$todo_entry"
    else
        content="# Todo List: $list_name

$todo_entry"
    fi
    
    local args=""
    [[ -n "$github_repo" ]] && args+=" --github=$github_repo"
    [[ -n "$cloudflare_bucket" ]] && args+=" --cloudflare=$cloudflare_bucket"
    
    echo "Adding task to $list_name: $task"
    fm_store_file "todos" "$filename" "$content" $args
}

# Quick status check
quick_status() {
    echo "System Status"
    echo "─"$(printf '─%.0s' {1..30})
    
    # GitHub API status
    if command -v gh_config >/dev/null 2>&1; then
        echo "🔗 GitHub API:"
        if gh_config >/dev/null 2>&1; then
            echo "   ✓ Connected"
        else
            echo "   ✗ Failed"
        fi
    fi
    
    # Cloudflare status
    if command -v cf_config >/dev/null 2>&1; then
        echo "☁️  Cloudflare R2:"
        if cf_config >/dev/null 2>&1; then
            echo "   ✓ Connected"
        else
            echo "   ✗ Failed"
        fi
    fi
    
    # File manager status
    if command -v fm_config >/dev/null 2>&1; then
        echo "📁 File Manager:"
        if fm_config >/dev/null 2>&1; then
            echo "   ✓ Ready"
        else
            echo "   ✗ Failed"
        fi
    fi
    
    echo ""
    echo "Quick Usage Examples:"
    echo "quick_repo my-project --private"
    echo "quick_commit user/repo README.md '# My Project'"
    echo "quick_upload ./data.json backup/data.json --compress"
    echo "quick_agent web-scraper"
    echo "quick_rule code-style"
    echo "quick_config app-settings"
    echo "quick_todo 'Fix bug in login module' --list=bugs"
}

# Help function
quick_help() {
    cat << 'EOF'
Quick Shell Functions for GitHub, Cloudflare, and File Management

Repository Operations:
  quick_repo <name> [--public|--private] [--no-init] [--backup]
    Create GitHub repository with smart defaults

File Operations:
  quick_commit <repo> <file> <content> [--message='msg'] [--backup]
    Commit file to GitHub repository
  quick_upload <file> [remote_path] [--bucket=<name>] [--compress] [--backup]
    Upload file to Cloudflare R2 storage

File Management:
  quick_agent <name> [content] [--github=<repo>] [--cloudflare=<bucket>] [--sync]
    Create agent configuration file
  quick_rule <name> [content] [--github=<repo>] [--cloudflare=<bucket>] [--sync]
    Create rule definition file
  quick_config <name> [content] [--github=<repo>] [--cloudflare=<bucket>] [--sync]
    Create configuration file
  quick_todo <task> [--list=<name>] [--github=<repo>] [--cloudflare=<bucket>]
    Add task to todo list

Utility:
  quick_status                 Show system status and examples
  quick_help                   Show this help

Examples:
  # Create a private repository with backup
  quick_repo my-private-repo --private --backup
  
  # Quick commit to repository
  quick_commit username/my-repo config.json '{"debug": true}' --message='Add debug config'
  
  # Upload file with compression
  quick_upload ./large-file.zip archives/backup.zip --compress --backup
  
  # Create agent file with template
  quick_agent data-processor --github=configs-repo --sync
  
  # Add todo item
  quick_todo "Implement authentication system" --list=backend-tasks --github=tasks-repo

Notes:
  - All functions use smart defaults and error handling
  - Content auto-generates templates if not provided
  - Remote sync options available for all file types
  - System automatically loads required dependencies
EOF
}

# Auto-complete function
if command -v complete >/dev/null 2>&1; then
    _quick_complete() {
        local cur prev words cword
        _init_completion || return
        
        case "$prev" in
            quick_repo)
                COMPREPLY=($(compgen -W "--public --private --no-init --backup" -- "$cur"))
                ;;
            quick_commit)
                COMPREPLY=($(compgen -W "--message --backup" -- "$cur"))
                ;;
            quick_upload)
                COMPREPLY=($(compgen -W "--bucket --compress --backup" -- "$cur"))
                ;;
            quick_agent|quick_rule|quick_config)
                COMPREPLY=($(compgen -W "--github --cloudflare --sync" -- "$cur"))
                ;;
            quick_todo)
                COMPREPLY=($(compgen -W "--list --github --cloudflare" -- "$cur"))
                ;;
            *)
                case "$cur" in
                    -*)
                        COMPREPLY=($(compgen -W "--help --version" -- "$cur"))
                        ;;
                    *)
                        COMPREPLY=($(compgen -W "quick_repo quick_commit quick_upload quick_agent quick_rule quick_config quick_todo quick_status quick_help" -- "$cur"))
                        ;;
                esac
                ;;
        esac
    }
    
    complete -F _quick_complete quick_repo quick_commit quick_upload quick_agent quick_rule quick_config quick_todo quick_status quick_help
fi

# Export functions
export -f quick_repo quick_commit quick_upload quick_agent quick_rule quick_config quick_todo quick_status quick_help

echo "Quick shell functions loaded. Type 'quick_help' for usage examples."