#!/bin/bash
#===============================================================================
#
#          FILE:  bundle_manager.sh
#
#         USAGE:  bundle_create <name> [type]
#                 bundle_add <name> <file> [files...]
#                 bundle_list [name]
#                 bundle_deploy <name> [destination]
#                 bundle_remove <name> <file> [files...]
#                 bundle_delete <name>
#                 bundle_help
#
#   DESCRIPTION:  Bundle management system for organizing and deploying
#                 collections of scripts, keys, commands, and other objects
#
#       OPTIONS:  name - Bundle name
#                 type - Bundle type (scripts, keys, commands, sql, etc.)
#                 file - Files to add/remove
#                 destination - Where to deploy bundle
#  REQUIREMENTS:  tar, gzip, git
#         NOTES:  Bundles are stored in ~/.bundles/ with metadata
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Configuration
BUNDLE_DIR="${HOME}/.bundles"
BUNDLE_META_DIR="${HOME}/.bundles/meta"
mkdir -p "$BUNDLE_DIR" "$BUNDLE_META_DIR"

# Create a new bundle
bundle_create() {
    local name="${1}"
    local type="${2:-generic}"

    if [[ -z "$name" ]]; then
        echo "Usage: bundle_create <name> [type]"
        echo ""
        echo "Types:"
        echo "  scripts     - Collection of scripts"
        echo "  keys        - SSH/API keys"
        echo "  commands    - Command snippets"
        echo "  sql         - SQL commands"
        echo "  markdown    - Markdown documentation"
        echo "  config      - Configuration files"
        echo "  generic     - Generic bundle"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local bundle_dir="${BUNDLE_DIR}/${name}"
    local meta_file="${BUNDLE_META_DIR}/${name}.json"

    if [[ -d "$bundle_dir" ]]; then
        echo "Bundle already exists: $name"
        return 1
    fi

    # Create bundle directory
    mkdir -p "$bundle_dir"

    # Create metadata
    cat > "$meta_file" << EOF
{
    "name": "$name",
    "type": "$type",
    "created": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
    "updated": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
    "files": [],
    "description": "",
    "hotkey": "",
    "version": "1.0.0"
}
EOF

    echo "Created bundle: $name (type: $type)"
    echo "Bundle directory: $bundle_dir"
    echo "Metadata: $meta_file"
}

# Add files to a bundle
bundle_add() {
    local name="${1}"
    local files=("${@:2}")

    if [[ -z "$name" || ${#files[@]} -eq 0 ]]; then
        echo "Usage: bundle_add <name> <file> [files...]"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local bundle_dir="${BUNDLE_DIR}/${name}"
    local meta_file="${BUNDLE_META_DIR}/${name}.json"

    if [[ ! -d "$bundle_dir" ]]; then
        echo "Bundle not found: $name"
        echo "Available bundles:"
        bundle_list
        return 1
    fi

    if [[ ! -f "$meta_file" ]]; then
        echo "Bundle metadata not found: $meta_file"
        return 1
    fi

    local added_count=0
    local failed_count=0

    for file in "${files[@]}"; do
        if [[ ! -f "$file" && ! -d "$file" ]]; then
            echo "File/directory not found: $file"
            ((failed_count++))
            continue
        fi

        local dest_file="${bundle_dir}/$(basename "$file")"

        # Copy file to bundle
        if cp -r "$file" "$dest_file"; then
            echo "✓ Added to bundle: $file -> $dest_file"
            ((added_count++))

            # Update metadata
            local filename=$(basename "$file")
            jq --arg file "$filename" \
               '.files += [$file] | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
               "$meta_file" > "${meta_file}.tmp" && mv "${meta_file}.tmp" "$meta_file"
        else
            echo "✗ Failed to add: $file"
            ((failed_count++))
        fi
    done

    echo "Added $added_count files to bundle, failed $failed_count files"
}

# List bundles and their contents
bundle_list() {
    local name="${1}"

    if [[ -z "$name" ]]; then
        # List all bundles
        echo "Available Bundles:"
        echo "════════════════════════════════════════════════════════════════"

        for meta_file in "$BUNDLE_META_DIR"/*.json; do
            if [[ -f "$meta_file" ]]; then
                local name
                name=$(jq -r '.name' "$meta_file")
                local type
                type=$(jq -r '.type' "$meta_file")
                local file_count
                file_count=$(jq '.files | length' "$meta_file")
                local created
                created=$(jq -r '.created' "$meta_file")

                echo ""
                echo "[$name]"
                echo "  Type: $type"
                echo "  Files: $file_count"
                echo "  Created: $created"
            fi
        done

        echo ""
        echo "Total bundles: $(ls "$BUNDLE_META_DIR"/*.json 2>/dev/null | wc -l)"
    else
        # List specific bundle contents
        local meta_file="${BUNDLE_META_DIR}/${name}.json"

        if [[ ! -f "$meta_file" ]]; then
            echo "Bundle not found: $name"
            return 1
        fi

        local bundle_dir="${BUNDLE_DIR}/${name}"

        echo "Bundle: $name"
        echo "════════════════════════════════════════════════════════════════"

        # Show metadata
        jq '.' "$meta_file"

        echo ""
        echo "Files:"
        echo "─────────────────────────────────────────────────────────────────"

        if [[ -d "$bundle_dir" ]]; then
            find "$bundle_dir" -type f | while read -r file; do
                local rel_file
                rel_file=$(echo "$file" | sed "s|$bundle_dir/||")
                local size
                size=$(du -h "$file" | cut -f1)
                echo "  $rel_file ($size)"
            done
        else
            echo "  (no files)"
        fi
    fi
}

# Deploy a bundle to a destination
bundle_deploy() {
    local name="${1}"
    local destination="${2:-./}"

    if [[ -z "$name" ]]; then
        echo "Usage: bundle_deploy <name> [destination]"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local bundle_dir="${BUNDLE_DIR}/${name}"
    local meta_file="${BUNDLE_META_DIR}/${name}.json"

    if [[ ! -d "$bundle_dir" ]]; then
        echo "Bundle not found: $name"
        return 1
    fi

    if [[ ! -f "$meta_file" ]]; then
        echo "Bundle metadata not found: $meta_file"
        return 1
    fi

    # Create destination directory
    mkdir -p "$destination"

    echo "Deploying bundle: $name to $destination"

    # Copy all files
    local deployed_count=0
    local failed_count=0

    find "$bundle_dir" -type f | while read -r file; do
        local rel_file
        rel_file=$(echo "$file" | sed "s|$bundle_dir/||")
        local dest_file="${destination}/${rel_file}"

        # Create subdirectories if needed
        mkdir -p "$(dirname "$dest_file")"

        if cp "$file" "$dest_file"; then
            echo "✓ Deployed: $rel_file"
            ((deployed_count++))
        else
            echo "✗ Failed to deploy: $rel_file"
            ((failed_count++))
        fi
    done

    echo "Deployed $deployed_count files, failed $failed_count files"
    echo "Bundle deployed to: $destination"
}

# Remove files from a bundle
bundle_remove() {
    local name="${1}"
    local files=("${@:2}")

    if [[ -z "$name" || ${#files[@]} -eq 0 ]]; then
        echo "Usage: bundle_remove <name> <file> [files...]"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local bundle_dir="${BUNDLE_DIR}/${name}"
    local meta_file="${BUNDLE_META_DIR}/${name}.json"

    if [[ ! -d "$bundle_dir" ]]; then
        echo "Bundle not found: $name"
        return 1
    fi

    if [[ ! -f "$meta_file" ]]; then
        echo "Bundle metadata not found: $meta_file"
        return 1
    fi

    local removed_count=0
    local failed_count=0

    for file in "${files[@]}"; do
        local bundle_file="${bundle_dir}/$(basename "$file")"

        if [[ ! -f "$bundle_file" ]]; then
            echo "File not found in bundle: $file"
            ((failed_count++))
            continue
        fi

        if rm "$bundle_file"; then
            echo "✓ Removed from bundle: $file"

            # Update metadata
            local filename=$(basename "$file")
            jq --arg file "$filename" \
               '.files -= [$file] | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
               "$meta_file" > "${meta_file}.tmp" && mv "${meta_file}.tmp" "$meta_file"

            ((removed_count++))
        else
            echo "✗ Failed to remove: $file"
            ((failed_count++))
        fi
    done

    echo "Removed $removed_count files from bundle, failed $failed_count files"
}

# Delete a bundle completely
bundle_delete() {
    local name="${1}"

    if [[ -z "$name" ]]; then
        echo "Usage: bundle_delete <name>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local bundle_dir="${BUNDLE_DIR}/${name}"
    local meta_file="${BUNDLE_META_DIR}/${name}.json"

    if [[ ! -d "$bundle_dir" && ! -f "$meta_file" ]]; then
        echo "Bundle not found: $name"
        return 1
    fi

    echo "Are you sure you want to delete bundle: $name? (y/n)"
    read -r response

    if [[ "$response" =~ ^[Yy] ]]; then
        if [[ -d "$bundle_dir" ]]; then
            rm -rf "$bundle_dir"
            echo "✓ Deleted bundle directory"
        fi

        if [[ -f "$meta_file" ]]; then
            rm "$meta_file"
            echo "✓ Deleted bundle metadata"
        fi

        echo "Bundle deleted: $name"
    else
        echo "Cancelled bundle deletion"
    fi
}

# Set bundle description
bundle_describe() {
    local name="${1}"
    local description="${2}"

    if [[ -z "$name" ]]; then
        echo "Usage: bundle_describe <name> <description>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local meta_file="${BUNDLE_META_DIR}/${name}.json"

    if [[ ! -f "$meta_file" ]]; then
        echo "Bundle not found: $name"
        return 1
    fi

    if [[ -z "$description" ]]; then
        # Interactive description
        echo "Enter description for bundle '$name':"
        read -r description
    fi

    jq --arg desc "$description" \
       '.description = $desc | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$meta_file" > "${meta_file}.tmp" && mv "${meta_file}.tmp" "$meta_file"

    echo "✓ Updated description for bundle: $name"
}

# Set bundle hotkey
bundle_hotkey() {
    local name="${1}"
    local hotkey="${2}"

    if [[ -z "$name" ]]; then
        echo "Usage: bundle_hotkey <name> <hotkey>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local meta_file="${BUNDLE_META_DIR}/${name}.json"

    if [[ ! -f "$meta_file" ]]; then
        echo "Bundle not found: $name"
        return 1
    fi

    if [[ -z "$hotkey" ]]; then
        echo "Current hotkey: $(jq -r '.hotkey' "$meta_file")"
        echo "Enter new hotkey for bundle '$name':"
        read -r hotkey
    fi

    jq --arg key "$hotkey" \
       '.hotkey = $key | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$meta_file" > "${meta_file}.tmp" && mv "${meta_file}.tmp" "$meta_file"

    echo "✓ Updated hotkey for bundle: $name -> $hotkey"
}

# Create a markdown documentation bundle
bundle_create_markdown() {
    local name="${1}"

    if [[ -z "$name" ]]; then
        echo "Usage: bundle_create_markdown <name>"
        return 1
    fi

    # Create the bundle
    bundle_create "$name" "markdown"

    local bundle_dir="${BUNDLE_DIR}/${name}"

    # Create standard markdown files
    cat > "${bundle_dir}/rules.md" << 'EOF'
# Rules

## Project Rules
- Rule 1
- Rule 2
- Rule 3

## Coding Standards
- Standard 1
- Standard 2
- Standard 3
EOF

    cat > "${bundle_dir}/agents.md" << 'EOF'
# Agents

## Available Agents
- Agent 1: Description
- Agent 2: Description
- Agent 3: Description

## Agent Usage
```bash
agent_command example
```
EOF

    cat > "${bundle_dir}/srs.md" << 'EOF'
# Software Requirements Specification

## Functional Requirements
- Requirement 1
- Requirement 2
- Requirement 3

## Non-Functional Requirements
- Performance
- Security
- Scalability
EOF

    cat > "${bundle_dir}/features.md" << 'EOF'
# Features

## Current Features
- Feature 1
- Feature 2
- Feature 3

## Planned Features
- Feature 4
- Feature 5
EOF

    cat > "${bundle_dir}/tasks.md" << 'EOF'
# Tasks

## Current Tasks
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Completed Tasks
- [x] Task 4
- [x] Task 5
EOF

    cat > "${bundle_dir}/journal.md" << 'EOF'
# Development Journal

## 2025-12-05
- Started project
- Created initial structure

## 2025-12-04
- Research phase
- Planning
EOF

    cat > "${bundle_dir}/log.md" << 'EOF'
# Development Log

## 2025-12-05 10:00
- Initial commit
- Setup complete

## 2025-12-05 09:00
- Project started
EOF

    echo "Created markdown documentation bundle: $name"
    echo "Files created:"
    ls -1 "${bundle_dir}/"
}

# Bundle help
bundle_help() {
    cat << 'EOF'
Bundle Management Commands:

  bundle_create <name> [type]    - Create a new bundle
  bundle_add <name> <file>...    - Add files to a bundle
  bundle_list [name]             - List bundles or bundle contents
  bundle_deploy <name> [dest]    - Deploy bundle to destination
  bundle_remove <name> <file>... - Remove files from bundle
  bundle_delete <name>           - Delete a bundle completely
  bundle_describe <name> <desc>  - Set bundle description
  bundle_hotkey <name> <key>     - Set bundle hotkey
  bundle_create_markdown <name> - Create markdown documentation bundle
  bundle_help                    - Show this help message

Bundle Types:
  scripts     - Collection of scripts
  keys        - SSH/API keys
  commands    - Command snippets
  sql         - SQL commands
  markdown    - Markdown documentation
  config      - Configuration files
  generic     - Generic bundle

Examples:
  bundle_create project_docs markdown
  bundle_add project_docs rules.md agents.md
  bundle_list project_docs
  bundle_deploy project_docs ~/projects/new_project/
  bundle_create_markdown project_docs
  bundle_hotkey project_docs "Ctrl+Alt+D"
EOF
}

# Export functions
export -f bundle_create 2>/dev/null
export -f bundle_add 2>/dev/null
export -f bundle_list 2>/dev/null
export -f bundle_deploy 2>/dev/null
export -f bundle_remove 2>/dev/null
export -f bundle_delete 2>/dev/null
export -f bundle_describe 2>/dev/null
export -f bundle_hotkey 2>/dev/null
export -f bundle_create_markdown 2>/dev/null
export -f bundle_help 2>/dev/null
