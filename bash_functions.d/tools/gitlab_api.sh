#!/usr/bin/env bash
# gitlab_api.sh - GitLab API wrapper functions
# Usage: gitlab_api_call <endpoint> [method] [data]

GITLAB_TOKEN_FILE="$HOME/.bash_secrets.d/gitlab/token"

get_gitlab_token() {
    if [[ -f ~/.bash_secrets.d/gitlab/token.age ]]; then
        age -d -i ~/.bash_secrets.d/age_key.txt ~/.bash_secrets.d/gitlab/token.age 2>/dev/null || echo ""
    else
        # Try Bitwarden
        ~/bash_functions.d/tools/secrets_tool.sh lookup gitlab_pat 2>/dev/null || echo ""
    fi
}

gitlab_api_call() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    local token
    token=$(get_gitlab_token)
    if [[ -z "$token" ]]; then
        echo "GitLab token not found" >&2
        return 1
    fi
    local url="https://gitlab.com/api/v4$endpoint"
    local headers="PRIVATE-TOKEN: $token"
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
gitlab_list_projects() {
    gitlab_api_call "/projects"
}

gitlab_create_project() {
    local name="$1"
    local data="{\"name\":\"$name\"}"
    gitlab_api_call "/projects" "POST" "$data"
}

gitlab_get_user() {
    gitlab_api_call "/user"
}

gitlab_list_issues() {
    local project_id="$1"
    gitlab_api_call "/projects/$project_id/issues"
}

gitlab_create_issue() {
    local project_id="$1"
    local title="$2"
    local description="$3"
    local data="{\"title\":\"$title\",\"description\":\"$description\"}"
    gitlab_api_call "/projects/$project_id/issues" "POST" "$data"
}
