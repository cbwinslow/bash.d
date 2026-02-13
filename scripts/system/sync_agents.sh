#!/bin/bash
set -euo pipefail

# This script synchronizes the master agents.md template to all directories.

# Get the root directory of the project
ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

TEMPLATE_FILE="docs/agents.template.md"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

# Find all directories in the project, excluding .git and node_modules
find . -type d -not -path "./.git*" -not -path "./node_modules*" | while read -r dir; do
    if [ -d "$dir" ]; then
        cp "$TEMPLATE_FILE" "$dir/agents.md"
        echo "Copied agents.md to $dir"
    fi
done

echo "Agent templates synchronized successfully."
