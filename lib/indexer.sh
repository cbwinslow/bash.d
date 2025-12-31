#!/bin/bash
# Module indexer for bash.d
# Creates and maintains an index of all available modules

export BASHD_INDEX_FILE="${BASHD_STATE_DIR}/module-index.json"

# Initialize index
bashd_index_init() {
    mkdir -p "${BASHD_STATE_DIR}"
    
    if [[ ! -f "${BASHD_INDEX_FILE}" ]]; then
        echo '{"plugins":[],"aliases":[],"completions":[],"functions":[],"last_updated":""}' > "${BASHD_INDEX_FILE}"
    fi
}

# Extract metadata from file
bashd_extract_metadata() {
    local file="$1"
    local type="$2"
    local name
    name=$(basename "$file" | sed 's/\.\(sh\|bash\)$//')
    
    local description=""
    local author=""
    local version=""
    local dependencies=""
    
    # Extract from header comments
    if [[ -f "$file" ]]; then
        description=$(grep -m1 "^#.*Description:" "$file" | sed 's/^#.*Description: *//' || grep -m1 "about-${type}" "$file" | sed "s/.*about-${type} *'//" | sed "s/'.*//")
        author=$(grep -m1 "^#.*Author:" "$file" | sed 's/^#.*Author: *//')
        version=$(grep -m1 "^#.*Version:" "$file" | sed 's/^#.*Version: *//')
        dependencies=$(grep -m1 "^#.*Dependencies:" "$file" | sed 's/^#.*Dependencies: *//')
    fi
    
    # Output as JSON (simplified)
    cat << EOF
{
  "name": "$name",
  "type": "$type",
  "file": "$file",
  "description": "$description",
  "author": "$author",
  "version": "$version",
  "dependencies": "$dependencies"
}
EOF
}

# Update index for all modules
bashd_index_update() {
    echo "Updating module index..."
    
    bashd_index_init
    
    local temp_file="${BASHD_INDEX_FILE}.tmp"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo '{' > "$temp_file"
    echo '  "last_updated": "'$timestamp'",' >> "$temp_file"
    
    # Index plugins
    echo '  "plugins": [' >> "$temp_file"
    local first=true
    if [[ -d "${BASHD_REPO_ROOT}/plugins" ]]; then
        for plugin in "${BASHD_REPO_ROOT}/plugins"/*.bash "${BASHD_REPO_ROOT}/plugins"/*.sh; do
            if [[ -f "$plugin" ]]; then
                if [[ "$first" != true ]]; then
                    echo ',' >> "$temp_file"
                fi
                local name
                name=$(basename "$plugin" | sed 's/\.\(plugin\.\)\?bash$//' | sed 's/\.sh$//')
                local desc
                desc=$(grep -m1 "about-plugin" "$plugin" | sed "s/.*about-plugin *'//" | sed "s/'.*//")
                echo -n "    {\"name\":\"$name\",\"description\":\"$desc\",\"file\":\"$plugin\"}" >> "$temp_file"
                first=false
            fi
        done
    fi
    echo '' >> "$temp_file"
    echo '  ],' >> "$temp_file"
    
    # Index aliases
    echo '  "aliases": [' >> "$temp_file"
    first=true
    if [[ -d "${BASHD_REPO_ROOT}/aliases" ]]; then
        for alias_file in "${BASHD_REPO_ROOT}/aliases"/*.bash "${BASHD_REPO_ROOT}/aliases"/*.sh; do
            if [[ -f "$alias_file" ]]; then
                if [[ "$first" != true ]]; then
                    echo ',' >> "$temp_file"
                fi
                local name
                name=$(basename "$alias_file" | sed 's/\.aliases\.bash$//' | sed 's/\.sh$//')
                local desc
                desc=$(grep -m1 "about-alias" "$alias_file" | sed "s/.*about-alias *'//" | sed "s/'.*//")
                echo -n "    {\"name\":\"$name\",\"description\":\"$desc\",\"file\":\"$alias_file\"}" >> "$temp_file"
                first=false
            fi
        done
    fi
    echo '' >> "$temp_file"
    echo '  ],' >> "$temp_file"
    
    # Index completions
    echo '  "completions": [' >> "$temp_file"
    first=true
    if [[ -d "${BASHD_REPO_ROOT}/completions" ]]; then
        for completion in "${BASHD_REPO_ROOT}/completions"/*.bash "${BASHD_REPO_ROOT}/completions"/*.sh; do
            if [[ -f "$completion" ]]; then
                if [[ "$first" != true ]]; then
                    echo ',' >> "$temp_file"
                fi
                local name
                name=$(basename "$completion" | sed 's/\.completion\.bash$//' | sed 's/\.sh$//')
                local desc
                desc=$(grep -m1 "^# " "$completion" | sed 's/^# *//' | head -1)
                echo -n "    {\"name\":\"$name\",\"description\":\"$desc\",\"file\":\"$completion\"}" >> "$temp_file"
                first=false
            fi
        done
    fi
    echo '' >> "$temp_file"
    echo '  ],' >> "$temp_file"
    
    # Index functions
    echo '  "functions": [' >> "$temp_file"
    first=true
    if [[ -d "${BASHD_REPO_ROOT}/bash_functions.d" ]]; then
        while IFS= read -r func_file; do
            if [[ -f "$func_file" ]]; then
                if [[ "$first" != true ]]; then
                    echo ',' >> "$temp_file"
                fi
                local name
                name=$(basename "$func_file" | sed 's/\.sh$//')
                local category
                category=$(basename "$(dirname "$func_file")")
                local desc
                desc=$(grep -m1 "^# " "$func_file" | sed 's/^# *//' | head -1)
                echo -n "    {\"name\":\"$name\",\"category\":\"$category\",\"description\":\"$desc\",\"file\":\"$func_file\"}" >> "$temp_file"
                first=false
            fi
        done < <(find "${BASHD_REPO_ROOT}/bash_functions.d" -name "*.sh" -type f 2>/dev/null)
    fi
    echo '' >> "$temp_file"
    echo '  ]' >> "$temp_file"
    echo '}' >> "$temp_file"
    
    mv "$temp_file" "${BASHD_INDEX_FILE}"
    echo "✓ Index updated: ${BASHD_INDEX_FILE}"
}

# Search index
bashd_index_search() {
    local query="$1"
    
    if [[ ! -f "${BASHD_INDEX_FILE}" ]]; then
        echo "Index not found. Run: bashd_index_update"
        return 1
    fi
    
    if [[ -z "$query" ]]; then
        echo "Usage: bashd_index_search <query>"
        return 1
    fi
    
    echo "Searching index for: $query"
    echo "=============================="
    grep -i "$query" "${BASHD_INDEX_FILE}" | head -20
}

# Show index stats
bashd_index_stats() {
    if [[ ! -f "${BASHD_INDEX_FILE}" ]]; then
        echo "Index not found. Run: bashd_index_update"
        return 1
    fi
    
    echo "Module Index Statistics"
    echo "======================="
    echo ""
    
    local last_updated
    last_updated=$(grep "last_updated" "${BASHD_INDEX_FILE}" | sed 's/.*: "//' | sed 's/".*//')
    echo "Last Updated: $last_updated"
    echo ""
    
    local plugin_count
    plugin_count=$(grep -o '"name"' "${BASHD_INDEX_FILE}" | grep -c . || echo 0)
    echo "Total Modules Indexed: $plugin_count"
    echo ""
    
    echo "By Type:"
    echo "  Plugins: $(grep -c "\"plugins\"" "${BASHD_INDEX_FILE}" 2>/dev/null || echo 0)"
    echo "  Aliases: $(grep -c "\"aliases\"" "${BASHD_INDEX_FILE}" 2>/dev/null || echo 0)"
    echo "  Completions: $(grep -c "\"completions\"" "${BASHD_INDEX_FILE}" 2>/dev/null || echo 0)"
    echo "  Functions: $(grep -c "\"functions\"" "${BASHD_INDEX_FILE}" 2>/dev/null || echo 0)"
}

# Export functions
export -f bashd_index_init 2>/dev/null
export -f bashd_extract_metadata 2>/dev/null
export -f bashd_index_update 2>/dev/null
export -f bashd_index_search 2>/dev/null
export -f bashd_index_stats 2>/dev/null
