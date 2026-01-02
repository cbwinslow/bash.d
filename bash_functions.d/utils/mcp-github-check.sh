#!/bin/bash
mcp-github-check() {
    if [ -n "$GITHUB_PAT" ]; then
        echo "GitHub PAT is loaded (length: ${#GITHUB_PAT})"
        # Show only last 4 characters for security
        echo "Last 4 chars: ...${GITHUB_PAT: -4}"
    else
        echo "GitHub PAT is not loaded"
    fi
}
