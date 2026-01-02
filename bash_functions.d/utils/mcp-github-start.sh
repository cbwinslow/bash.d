#!/bin/bash
mcp-github-start() {
    if [ -z "$GITHUB_PAT" ]; then
        echo "Error: GITHUB_PAT not set. Please source your environment file first."
        return 1
    fi

    echo "Starting GitHub MCP server..."
    docker run -i --rm \
        -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PAT" \
        ghcr.io/github/github-mcp-server
}
