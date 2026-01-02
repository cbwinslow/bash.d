#!/bin/bash
mcp-github-reload() {
    if [ -f ~/.cbw-github-mcp-setup.sh ]; then
        source ~/.cbw-github-mcp-setup.sh
        echo "GitHub MCP environment reloaded"
    else
        echo "GitHub MCP setup script not found"
    fi
