#!/usr/bin/env bash
# github_api.sh - GitHub API wrapper functions
# Usage: github_api_call <endpoint> [method] [data]

GITHUB_TOKEN_FILE="$HOME/.bash_secrets.d/github/token"

get_github_token() {
    if [[ -f ~/.bash_secrets.d/github/token.age ]]; then
        age -d -i ~/.bash_secrets.d/age_key.txt ~/.bash_secrets.d/github/token.age 2>/dev/null || echo ""
    else
        # Try Bitwarden
        ~/bash_functions.d/tools/secrets_tool.sh lookup github_pat 2>/dev/null || echo ""
    fi
}

github_api_call() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    local token
    token=$(get_github_token)
    if [[ -z "$token" ]]; then
        echo "GitHub token not found" >&2
        return 1
    fi
    local url="https://api.github.com$endpoint"
    local headers="Authorization: token $token"
    if [[ "$method" == "GET" ]]; then
        curl -s -H "$headers" "$url"
    elif [[ "$method" == "POST" ]]; then
        curl -s -X POST -H "$headers" -H "Content-Type: application/json" -d "$data" "$url"
    elif [[ "$method" == "PUT" ]]; then
        curl -s -X PUT -H "$headers" -H "Content-Type: application/json" -d "$data" "$url"
    elif [[ "$method" == "DELETE" ]]; then
        curl -s -X DELETE -H "$headers" "$url"
    fi
}

# Specific functions
github_list_repos() {
    github_api_call "/user/repos"
}

github_create_repo() {
    local name="$1"
    local data="{\"name\":\"$name\"}"
    github_api_call "/user/repos" "POST" "$data"
}

github_get_user() {
    github_api_call "/user"
}

github_list_issues() {
    local repo="$1"
    github_api_call "/repos/$repo/issues"
}

github_create_issue() {
    local repo="$1"
    local title="$2"
    local body="$3"
    local data="{\"title\":\"$title\",\"body\":\"$body\"}"
    github_api_call "/repos/$repo/issues" "POST" "$data"
}
