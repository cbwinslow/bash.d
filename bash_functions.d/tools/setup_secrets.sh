#!/usr/bin/env bash
# setup_secrets.sh - Setup bash_secrets.d with tokens from Bitwarden or .env

# Use decorators
setup_github_token() {
    debug_log INFO "Setting up GitHub token..."
    if [[ ! -f ~/.bash_secrets.d/github/token.age ]]; then
        token=$(run_delegate debug ~/bash_functions.d/tools/secrets_tool.sh lookup github_pat 2>/dev/null)
        if [[ -n "$token" ]]; then
            echo "$token" | age -r "$(head -1 ~/.bash_secrets.d/age_key.txt)" > ~/.bash_secrets.d/github/token.age
            chmod 600 ~/.bash_secrets.d/github/token.age
            debug_log INFO "GitHub token encrypted."
        else
            debug_log ERROR "GitHub PAT not found in Bitwarden."
        fi
    else
        debug_log INFO "GitHub token already encrypted."
    fi
}

setup_gitlab_token() {
    debug_log INFO "Setting up GitLab token..."
    if [[ ! -f ~/.bash_secrets.d/gitlab/token.age ]]; then
        token=$(run_delegate debug ~/bash_functions.d/tools/secrets_tool.sh lookup gitlab_pat 2>/dev/null)
        if [[ -n "$token" ]]; then
            echo "$token" | age -r "$(head -1 ~/.bash_secrets.d/age_key.txt)" > ~/.bash_secrets.d/gitlab/token.age
            chmod 600 ~/.bash_secrets.d/gitlab/token.age
            debug_log INFO "GitLab token encrypted."
        else
            debug_log ERROR "GitLab PAT not found in Bitwarden."
        fi
    else
        debug_log INFO "GitLab token already encrypted."
    fi
}

mkdir -p ~/.bash_secrets.d/github ~/.bash_secrets.d/gitlab

error_decorator setup_github_token
error_decorator setup_gitlab_token

echo "Secrets setup complete. Tokens stored in ~/.bash_secrets.d/"
