#!/usr/bin/env bash

# API Manager - Unified API interface for GitHub, Cloudflare, and more
# Part of bash.d - Central API management system

set -euo pipefail

BASHD_HOME="${BASHD_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONFIG_DIR="$BASHD_HOME/config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================
# Configuration Loading
# ============================================

load_api_config() {
    # Load from config file
    if [[ -f "$CONFIG_DIR/default.yaml" ]]; then
        # Export API tokens from config
        export GITHUB_TOKEN=$(grep -A1 "^github:" "$CONFIG_DIR/default.yaml" | grep "token:" | cut -d'"' -f2 || echo "")
        export CLOUDFLARE_API_TOKEN=$(grep -A1 "^cloudflare:" "$CONFIG_DIR/default.yaml" | grep "api_token:" | cut -d'"' -f2 || echo "")
        export CLOUDFLARE_ACCOUNT_ID=$(grep -A1 "^cloudflare:" "$CONFIG_DIR/default.yaml" | grep "account_id:" | cut -d'"' -f2 || echo "")
        export CLOUDFLARE_ZONE_ID=$(grep -A1 "^cloudflare:" "$CONFIG_DIR/default.yaml" | grep "zone_id:" | cut -d'"' -f2 || echo "")
    fi
    
    # Override with environment variables
    export GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-${github_token:-}}}"
    export CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}"
    export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-${CF_ACCOUNT_ID:-}}"
    export CLOUDFLARE_ZONE_ID="${CLOUDFLARE_ZONE_ID:-${CF_ZONE_ID:-}}"
}

# ============================================
# GitHub API
# ============================================

github_api() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    
    if [[ -z "$GITHUB_TOKEN" ]]; then
        log_error "GitHub token not set. Set GITHUB_TOKEN or configure in config/default.yaml"
        return 1
    fi
    
    local url="https://api.github.com$endpoint"
    
    local curl_args=(
        -s
        -X "$method"
        -H "Authorization: token $GITHUB_TOKEN"
        -H "Accept: application/vnd.github.v3+json"
    )
    
    if [[ -n "$data" ]]; then
        curl_args+=(-H "Content-Type: application/json")
        curl_args+=(-d "$data")
    fi
    
    curl "${curl_args[@]}" "$url"
}

# GitHub: List repositories
github_list_repos() {
    local visibility="${1:-all}"
    local sort="${2:-updated}"
    local per_page="${3:-30}"
    
    github_api "/user/repos?visibility=$visibility&sort=$sort&per_page=$per_page" | jq -r '.[] | "\(.name) |\(.visibility) |\(.html_url) |\(.updated_at)"'
}

# GitHub: Get repo info
github_repo_info() {
    local repo="$1"
    github_api "/repos/$repo" | jq '.'
}

# GitHub: Create issue
github_create_issue() {
    local repo="$1"
    local title="$2"
    local body="${3:-}"
    
    local data=$(jq -n \
        --arg title "$title" \
        --arg body "$body" \
        '{title: $title, body: $body}')
    
    github_api "/repos/$repo/issues" "POST" "$data" | jq '.'
}

# GitHub: List issues
github_list_issues() {
    local repo="$1"
    local state="${2:-open}"
    
    github_api "/repos/$repo/issues?state=$state" | jq -r '.[] | "\(.number) |\(.title) |\(.state) |\(.html_url)"'
}

# GitHub: Create or update file
github_upsert_file() {
    local repo="$1"
    local path="$2"
    local content="$3"
    local message="${4:-Update $path}"
    local branch="${5:-main}"
    
    # Get existing file SHA if it exists
    local sha=""
    local existing=$(github_api "/repos/$repo/contents/$path?ref=$branch" 2>/dev/null)
    if echo "$existing" | jq -e '.sha' > /dev/null 2>&1; then
        sha=$(echo "$existing" | jq -r '.sha')
    fi
    
    # Encode content
    local encoded=$(echo -n "$content" | base64 -w0)
    
    local data
    if [[ -n "$sha" ]]; then
        data=$(jq -n \
            --arg msg "$message" \
            --arg content "$encoded" \
            --arg sha "$sha" \
            --arg branch "$branch" \
            '{message: $msg, content: $content, sha: $sha, branch: $branch}')
    else
        data=$(jq -n \
            --arg msg "$message" \
            --arg content "$encoded" \
            --arg branch "$branch" \
            '{message: $msg, content: $content, branch: $branch}')
    fi
    
    github_api "/repos/$repo/contents/$path" "PUT" "$data" | jq '.'
}

# GitHub: List workflows
github_list_workflows() {
    local repo="$1"
    github_api "/repos/$repo/actions/workflows" | jq -r '.workflows[] | "\(.id) |\(.name) |\(.state)"'
}

# GitHub: Trigger workflow
github_trigger_workflow() {
    local repo="$1"
    local workflow_id="$2"
    local ref="${3:-main}"
    
    local data=$(jq -n --arg ref "$ref" '{ref: $ref}')
    github_api "/repos/$repo/actions/workflows/$workflow_id/dispatch" "POST" "$data"
    log_info "Workflow triggered"
}

# ============================================
# Cloudflare API
# ============================================

cloudflare_api() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    
    if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
        log_error "Cloudflare API token not set. Set CLOUDFLARE_API_TOKEN"
        return 1
    fi
    
    if [[ -z "$CLOUDFLARE_ACCOUNT_ID" ]]; then
        log_error "Cloudflare account ID not set. Set CLOUDFLARE_ACCOUNT_ID"
        return 1
    fi
    
    local url="https://api.cloudflare.com/client/v4$endpoint"
    
    local curl_args=(
        -s
        -X "$method"
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
        -H "Content-Type: application/json"
    )
    
    if [[ -n "$data" ]]; then
        curl_args+=(-d "$data")
    fi
    
    curl "${curl_args[@]}" "$url" | jq '.'
}

# Cloudflare: List zones
cloudflare_list_zones() {
    cloudflare_api "/zones?per_page=100" | jq -r '.result[] | "\(.id) |\(.name) |\(.status)"'
}

# Cloudflare: Get zone info
cloudflare_zone_info() {
    local zone_id="${1:-$CLOUDFLARE_ZONE_ID}"
    cloudflare_api "/zones/$zone_id" | jq '.result'
}

# Cloudflare: List DNS records
cloudflare_list_dns() {
    local zone_id="${1:-$CLOUDFLARE_ZONE_ID}"
    cloudflare_api "/zones/$zone_id/dns_records?per_page=100" | jq -r '.result[] | "\(.id) |\(.type) |\(.name) |\(.content)"'
}

# Cloudflare: Add DNS record
cloudflare_add_dns() {
    local zone_id="${1:-$CLOUDFLARE_ZONE_ID}"
    local type="$2"
    local name="$3"
    local content="$4"
    local ttl="${5:-3600}"
    
    local data=$(jq -n \
        --arg type "$type" \
        --arg name "$name" \
        --arg content "$content" \
        --argjson ttl "$ttl" \
        '{type: $type, name: $name, content: $content, ttl: $ttl}')
    
    cloudflare_api "/zones/$zone_id/dns_records" "POST" "$data" | jq '.result'
}

# Cloudflare: Delete DNS record
cloudflare_delete_dns() {
    local zone_id="${1:-$CLOUDFLARE_ZONE_ID}"
    local record_id="$2"
    
    cloudflare_api "/zones/$zone_id/dns_records/$record_id" "DELETE" | jq '.result'
}

# Cloudflare: List workers
cloudflare_list_workers() {
    cloudflare_api "/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/scripts" | jq -r '.[] | .'
}

# Cloudflare: Deploy worker
cloudflare_deploy_worker() {
    local name="$1"
    local script="$2"
    
    local data=$(jq -n --arg script "$script" '{script: $script}')
    cloudflare_api "/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/scripts/$name" "PUT" "$data" | jq '.'
}

# Cloudflare: List Pages projects
cloudflare_list_pages() {
    cloudflare_api "/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects" | jq -r '.result[] | "\(.name) |\(.created_on)"'
}

# ============================================
# Utility Functions
# ============================================

# Show API status
show_api_status() {
    echo "=========================================="
    echo "  API Manager Status"
    echo "=========================================="
    echo ""
    
    echo "GitHub:"
    if [[ -n "$GITHUB_TOKEN" ]]; then
        local user=$(github_api "/user" | jq -r '.login' 2>/dev/null || echo "unknown")
        echo "  ✓ Connected as: $user"
    else
        echo "  ✗ Not configured (set GITHUB_TOKEN)"
    fi
    echo ""
    
    echo "Cloudflare:"
    if [[ -n "$CLOUDFLARE_API_TOKEN" ]]; then
        echo "  ✓ Token configured"
        [[ -n "$CLOUDFLARE_ACCOUNT_ID" ]] && echo "  Account ID: $CLOUDFLARE_ACCOUNT_ID"
        [[ -n "$CLOUDFLARE_ZONE_ID" ]] && echo "  Zone ID: $CLOUDFLARE_ZONE_ID"
    else
        echo "  ✗ Not configured (set CLOUDFLARE_API_TOKEN)"
    fi
}

# Test all APIs
test_apis() {
    log_info "Testing API connections..."
    
    echo ""
    echo "GitHub:"
    if [[ -n "$GITHUB_TOKEN" ]]; then
        if github_api "/user" > /dev/null 2>&1; then
            echo "  ✓ Connection successful"
        else
            echo "  ✗ Connection failed"
        fi
    else
        echo "  ✗ Not configured"
    fi
    
    echo ""
    echo "Cloudflare:"
    if [[ -n "$CLOUDFLARE_API_TOKEN" ]]; then
        if cloudflare_api "/user/tokens/verify" | jq -e '.result.valid' > /dev/null 2>&1; then
            echo "  ✓ Token valid"
        else
            echo "  ✗ Token invalid"
        fi
    else
        echo "  ✗ Not configured"
    fi
}

# ============================================
# Main
# ============================================

main() {
    load_api_config
    
    local service="${1:-status}"
    shift || true
    
    case "$service" in
        "github")
            local action="${1:-status}"
            shift || true
            case "$action" in
                "repos") github_list_repos "$@" ;;
                "repo") github_repo_info "$1" ;;
                "issues") github_list_issues "$@" ;;
                "create-issue") github_create_issue "$1" "$2" "${3:-}" ;;
                "upsert") github_upsert_file "$1" "$2" "$3" "${4:-Update}" "${5:-main}" ;;
                "workflows") github_list_workflows "$1" ;;
                "trigger") github_trigger_workflow "$1" "$2" "${3:-main}" ;;
                *) echo "Usage: $0 github {repos|repo|issues|create-issue|upsert|workflows|trigger}" ;;
            esac
            ;;
        "cloudflare"|"cf")
            local action="${1:-status}"
            shift || true
            case "$action" in
                "zones") cloudflare_list_zones ;;
                "zone") cloudflare_zone_info "$1" ;;
                "dns") cloudflare_list_dns "$1" ;;
                "add-dns") cloudflare_add_dns "$1" "$2" "$3" "$4" "${5:-3600}" ;;
                "delete-dns") cloudflare_delete_dns "$1" "$2" ;;
                "workers") cloudflare_list_workers ;;
                "deploy-worker") cloudflare_deploy_worker "$1" "$2" ;;
                "pages") cloudflare_list_pages ;;
                *) echo "Usage: $0 cloudflare {zones|zone|dns|add-dns|delete-dns|workers|deploy-worker|pages}" ;;
            esac
            ;;
        "test")
            test_apis
            ;;
        "status"|"")
            show_api_status
            ;;
        *)
            echo "Usage: $0 {github|cloudflare|test|status}"
            echo ""
            echo "Examples:"
            echo "  $0 github repos"
            echo "  $0 github issues cbwinslow/bash.d"
            echo "  $0 cloudflare zones"
            echo "  $0 cloudflare dns"
            echo "  $0 test"
            exit 1
            ;;
    esac
}

main "$@"
