#!/usr/bin/env bash
# test_setup_secrets.sh - Tests for setup_secrets.sh

# Enable test mode
export TEST_MODE=1
export DEBUG_BASH=1

# Source the script
source ~/bash_functions.d/tools/setup_secrets.sh

# Test functions
test_setup_github_token() {
    # Mock the lookup
    ~/bash_functions.d/tools/secrets_tool.sh() {
        echo "mock_github_token"
    }
    setup_github_token
    [[ -f ~/.bash_secrets.d/github/token ]] && [[ "$(cat ~/.bash_secrets.d/github/token)" == "mock_github_token" ]]
}

test_setup_gitlab_token() {
    ~/bash_functions.d/tools/secrets_tool.sh() {
        echo "mock_gitlab_token"
    }
    setup_gitlab_token
    [[ -f ~/.bash_secrets.d/gitlab/token ]] && [[ "$(cat ~/.bash_secrets.d/gitlab/token)" == "mock_gitlab_token" ]]
}

# Run tests
run_tests test_setup_github_token test_setup_gitlab_token
