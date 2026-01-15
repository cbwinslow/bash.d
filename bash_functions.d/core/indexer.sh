#!/bin/bash
#===============================================================================
#
#          FILE:  indexer.sh
#
#         USAGE:  bashd_index_build
#                 bashd_index_update
#                 bashd_index_query <term>
#
#   DESCRIPTION:  Master indexer for bash.d repository that creates a searchable
#                 database of all functions, scripts, aliases, and documentation.
#                 Provides fast search, location, and metadata retrieval.
#
#       OPTIONS:  See individual function help
#  REQUIREMENTS:  jq, find, grep
#         NOTES:  Creates index in $BASHD_HOME/.index/
#        AUTHOR:  bash.d project
#       VERSION:  2.0.0
#       CREATED:  $(date +'%Y-%m-%d')
#===============================================================================

# Configuration
export BASHD_INDEX_DIR="${BASHD_HOME:-$HOME/.bash.d}/.index"
export BASHD_INDEX_FILE="${BASHD_INDEX_DIR}/master_index.json"
export BASHD_INDEX_CACHE="${BASHD_INDEX_DIR}/cache"
export BASHD_INDEX_STATS="${BASHD_INDEX_DIR}/stats.json"

# Initialize index directory structure
bashd_index_init() {
    mkdir -p "${BASHD_INDEX_DIR}"
    mkdir -p "${BASHD_INDEX_CACHE}"
    
    if [[ ! -f "${BASHD_INDEX_FILE}" ]]; then
        cat > "${BASHD_INDEX_FILE}" << 'EOF'
{
  "version": "2.0.0",
  "last_updated": "",
  "repository": "",
  "statistics": {
    "total_functions": 0,
    "total_aliases": 0,
    "total_scripts": 0,
    "total_categories": 0
  },
  "functions": {},
  "aliases": {},
  "scripts": {},
  "categories": {},
  "tags": {}
}
EOF
    fi
}

# Extract metadata from a bash function/script file
_bashd_extract_metadata() {
    local file="$1"
    local relative_path="${file#${BASHD_HOME:-$HOME/.bash.d}/}"
    local filename=$(basename "$file")
    local name="${filename%.sh}"
    local category=$(basename "$(dirname "$file")")
    
    # Extract header information
    local description=""
    local usage=""
    local requirements=""
    local version=""
    local author=""
    
    # Parse header block
    if [[ -f "$file" ]]; then
        # Get description (limited to avoid special chars)
        description=$(sed -n '/^#.*DESCRIPTION:/,/^#.*[A-Z]*:/p' "$file" | \
            grep -v "^#.*[A-Z]*:" | sed 's/^#[ ]*//' | tr '\n' ' ' | sed 's/  */ /g' | head -c 150)
        
        # Get usage (first line only to avoid issues)
        usage=$(grep -m1 "^#.*USAGE:" "$file" | sed 's/^#.*USAGE:[ ]*//' | head -c 150)
        
        # Get requirements
        requirements=$(grep -m1 "^#.*REQUIREMENTS:" "$file" | sed 's/^#.*REQUIREMENTS:[ ]*//')
        
        # Get version
        version=$(grep -m1 "^#.*VERSION:" "$file" | sed 's/^#.*VERSION:[ ]*//')
        
        # Get author
        author=$(grep -m1 "^#.*AUTHOR:" "$file" | sed 's/^#.*AUTHOR:[ ]*//')
        
        # Extract function names defined in file
        local functions_defined
        functions_defined=$(grep -oP '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$file" | sed 's/()$//' | tr '\n' ',' | sed 's/,$//')
        
        # Get file stats
        local line_count=$(wc -l < "$file")
        local last_modified=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
        local file_size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)
    fi
    
    # Generate JSON entry using jq to properly escape strings
    jq -n \
        --arg name "$name" \
        --arg file "$relative_path" \
        --arg full_path "$file" \
        --arg category "$category" \
        --arg description "$description" \
        --arg usage "$usage" \
        --arg requirements "$requirements" \
        --arg version "$version" \
        --arg author "$author" \
        --arg functions "$functions_defined" \
        --argjson line_count "${line_count:-0}" \
        --argjson file_size "${file_size:-0}" \
        --argjson last_modified "${last_modified:-0}" \
        '{
            name: $name,
            file: $file,
            full_path: $full_path,
            category: $category,
            description: $description,
            usage: $usage,
            requirements: $requirements,
            version: $version,
            author: $author,
            functions: $functions,
            line_count: $line_count,
            file_size: $file_size,
            last_modified: $last_modified
        }'
}

# Build complete index from scratch
bashd_index_build() {
    echo "Building master index for bash.d repository..."
    echo "This may take a moment..."
    
    bashd_index_init
    
    local repo_root="${BASHD_HOME:-$HOME/.bash.d}"
    local temp_dir="${BASHD_INDEX_DIR}/tmp"
    mkdir -p "$temp_dir"
    local start_time=$(date +%s)
    
    # Index all bash functions
    echo "  Indexing functions..."
    local func_count=0
    local func_json_file="${temp_dir}/functions.json"
    
    # Create empty functions object
    echo "{}" > "$func_json_file"
    
    if [[ -d "${repo_root}/bash_functions.d" ]]; then
        while IFS= read -r func_file; do
            if [[ -f "$func_file" ]]; then
                local func_name=$(basename "$func_file" .sh)
                local metadata=$(_bashd_extract_metadata "$func_file")
                
                # Add to JSON using jq
                jq --argjson meta "$metadata" \
                   --arg name "$func_name" \
                   '.[$name] = $meta' \
                   "$func_json_file" > "${func_json_file}.new" && \
                   mv "${func_json_file}.new" "$func_json_file"
                
                ((func_count++))
                
                # Progress indicator
                if (( func_count % 50 == 0 )); then
                    echo -n "."
                fi
            fi
        done < <(find "${repo_root}/bash_functions.d" -name "*.sh" -type f 2>/dev/null | sort)
    fi
    
    echo "" # newline after progress dots
    echo "  Found $func_count functions"
    
    # Index aliases
    echo "  Indexing aliases..."
    local alias_count=0
    local alias_json_file="${temp_dir}/aliases.json"
    echo "{}" > "$alias_json_file"
    
    if [[ -d "${repo_root}/aliases" ]]; then
        for alias_file in "${repo_root}/aliases"/*.bash "${repo_root}/aliases"/*.sh; do
            if [[ -f "$alias_file" ]]; then
                local alias_name=$(basename "$alias_file" | sed 's/\.aliases\.bash$//' | sed 's/\.sh$//')
                local alias_desc=$(grep -m1 "about-alias" "$alias_file" | sed "s/.*about-alias *'//" | sed "s/'.*//")
                local alias_count_in_file=$(grep -c "^alias " "$alias_file" 2>/dev/null || echo 0)
                
                jq -n \
                    --arg file "$(basename "$alias_file")" \
                    --arg full_path "$alias_file" \
                    --arg description "$alias_desc" \
                    --argjson alias_count "$alias_count_in_file" \
                    '{file: $file, full_path: $full_path, description: $description, alias_count: $alias_count}' | \
                jq --arg name "$alias_name" \
                   '. as $data | input | .[$name] = $data' \
                   "$alias_json_file" - > "${alias_json_file}.new" && \
                   mv "${alias_json_file}.new" "$alias_json_file"
                
                ((alias_count++))
            fi
        done
    fi
    
    echo "  Found $alias_count alias files"
    
    # Index standalone scripts
    echo "  Indexing standalone scripts..."
    local script_count=0
    local script_json_file="${temp_dir}/scripts.json"
    echo "{}" > "$script_json_file"
    
    for script_dir in "${repo_root}/scripts" "${repo_root}/bin"; do
        if [[ -d "$script_dir" ]]; then
            for script in "$script_dir"/*.sh "$script_dir"/*.bash; do
                if [[ -f "$script" && -x "$script" ]]; then
                    local script_name=$(basename "$script")
                    local script_desc=$(head -20 "$script" | grep -m1 "^#.*DESCRIPTION:" | sed 's/^#.*DESCRIPTION:[ ]*//' | head -c 150)
                    
                    jq -n \
                        --arg file "$script_name" \
                        --arg full_path "$script" \
                        --arg description "$script_desc" \
                        '{file: $file, full_path: $full_path, description: $description, executable: true}' | \
                    jq --arg name "$script_name" \
                       '. as $data | input | .[$name] = $data' \
                       "$script_json_file" - > "${script_json_file}.new" && \
                       mv "${script_json_file}.new" "$script_json_file"
                    
                    ((script_count++))
                fi
            done
        fi
    done
    
    echo "  Found $script_count scripts"
    
    # Build category index
    echo "  Organizing categories..."
    local category_json_file="${temp_dir}/categories.json"
    echo "{}" > "$category_json_file"
    
    # Get unique categories
    if [[ -d "${repo_root}/bash_functions.d" ]]; then
        for cat_dir in "${repo_root}/bash_functions.d"/*/; do
            if [[ -d "$cat_dir" ]]; then
                local cat_name=$(basename "$cat_dir")
                local cat_count=$(find "$cat_dir" -name "*.sh" -type f 2>/dev/null | wc -l)
                
                jq -n \
                    --arg path "$cat_dir" \
                    --argjson function_count "$cat_count" \
                    '{path: $path, function_count: $function_count}' | \
                jq --arg name "$cat_name" \
                   '. as $data | input | .[$name] = $data' \
                   "$category_json_file" - > "${category_json_file}.new" && \
                   mv "${category_json_file}.new" "$category_json_file"
            fi
        done
    fi
    
    # Assemble final JSON
    local end_time=$(date +%s)
    local build_time=$((end_time - start_time))
    local total_categories=$(find "${repo_root}/bash_functions.d" -maxdepth 1 -type d 2>/dev/null | wc -l)
    
    jq -n \
        --arg version "2.0.0" \
        --arg last_updated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --arg repository "$repo_root" \
        --argjson functions "$(cat "$func_json_file")" \
        --argjson aliases "$(cat "$alias_json_file")" \
        --argjson scripts "$(cat "$script_json_file")" \
        --argjson categories "$(cat "$category_json_file")" \
        --argjson total_functions "$func_count" \
        --argjson total_aliases "$alias_count" \
        --argjson total_scripts "$script_count" \
        --argjson total_categories "$total_categories" \
        --argjson build_time_seconds "$build_time" \
        '{
            version: $version,
            last_updated: $last_updated,
            repository: $repository,
            functions: $functions,
            aliases: $aliases,
            scripts: $scripts,
            categories: $categories,
            tags: {},
            statistics: {
                total_functions: $total_functions,
                total_aliases: $total_aliases,
                total_scripts: $total_scripts,
                total_categories: $total_categories,
                build_time_seconds: $build_time_seconds
            }
        }' > "${BASHD_INDEX_FILE}"
    
    # Create stats file
    jq -n \
        --arg last_build "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --argjson total_items "$((func_count + alias_count + script_count))" \
        --argjson build_time_seconds "$build_time" \
        '{
            last_build: $last_build,
            total_items: $total_items,
            build_time_seconds: $build_time_seconds
        }' > "${BASHD_INDEX_STATS}"
    
    # Clean up temp files
    rm -rf "$temp_dir"
    
    echo ""
    echo "✓ Index built successfully!"
    echo "  Location: ${BASHD_INDEX_FILE}"
    echo "  Total items indexed: $((func_count + alias_count + script_count))"
    echo "  Build time: ${build_time}s"
    echo ""
    echo "You can now use: bashd_search, bashd_find, bashd_locate"
}

# Update index incrementally (for changed files only)
bashd_index_update() {
    if [[ ! -f "${BASHD_INDEX_FILE}" ]]; then
        echo "Index not found. Building from scratch..."
        bashd_index_build
        return
    fi
    
    echo "Updating index with recent changes..."
    
    local repo_root="${BASHD_HOME:-$HOME/.bash.d}"
    local last_update=$(jq -r '.last_updated' "${BASHD_INDEX_FILE}" 2>/dev/null || echo "1970-01-01T00:00:00Z")
    
    # Find files modified since last update
    local modified_files=$(find "${repo_root}/bash_functions.d" -name "*.sh" -type f -newer "${BASHD_INDEX_FILE}" 2>/dev/null)
    
    if [[ -z "$modified_files" ]]; then
        echo "✓ Index is up to date"
        return 0
    fi
    
    local update_count=0
    echo "$modified_files" | while read -r file; do
        if [[ -f "$file" ]]; then
            ((update_count++))
        fi
    done
    
    echo "Found $update_count modified files"
    echo "Rebuilding index..."
    
    # For now, rebuild entire index when changes detected
    # TODO: Implement true incremental updates with jq
    bashd_index_build
}

# Show index statistics
bashd_index_stats() {
    if [[ ! -f "${BASHD_INDEX_FILE}" ]]; then
        echo "Index not found. Run: bashd_index_build"
        return 1
    fi
    
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              bash.d Repository Index Statistics              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    local last_updated=$(jq -r '.last_updated' "${BASHD_INDEX_FILE}")
    local total_functions=$(jq -r '.statistics.total_functions' "${BASHD_INDEX_FILE}")
    local total_aliases=$(jq -r '.statistics.total_aliases' "${BASHD_INDEX_FILE}")
    local total_scripts=$(jq -r '.statistics.total_scripts' "${BASHD_INDEX_FILE}")
    local total_categories=$(jq -r '.statistics.total_categories' "${BASHD_INDEX_FILE}")
    local repo=$(jq -r '.repository' "${BASHD_INDEX_FILE}")
    
    echo "Repository:     $repo"
    echo "Last Updated:   $last_updated"
    echo ""
    echo "Indexed Items:"
    echo "  Functions:    $total_functions"
    echo "  Aliases:      $total_aliases"
    echo "  Scripts:      $total_scripts"
    echo "  Categories:   $total_categories"
    echo "  ────────────────────"
    echo "  Total:        $((total_functions + total_aliases + total_scripts))"
    echo ""
    
    # Show top categories
    echo "Top Categories:"
    jq -r '.categories | to_entries | sort_by(.value.function_count) | reverse | .[0:5] | .[] | "  \(.key): \(.value.function_count) functions"' "${BASHD_INDEX_FILE}"
    echo ""
}

# Query the index
bashd_index_query() {
    local query="$1"
    
    if [[ ! -f "${BASHD_INDEX_FILE}" ]]; then
        echo "Index not found. Run: bashd_index_build"
        return 1
    fi
    
    if [[ -z "$query" ]]; then
        echo "Usage: bashd_index_query <search_term>"
        return 1
    fi
    
    echo "Searching index for: '$query'"
    echo ""
    
    # Search in function names, descriptions, and categories
    jq -r --arg query "$query" '
        .functions | to_entries | 
        map(select(
            (.key | ascii_downcase | contains($query | ascii_downcase)) or
            (.value.description | ascii_downcase | contains($query | ascii_downcase)) or
            (.value.category | ascii_downcase | contains($query | ascii_downcase))
        )) |
        .[] | 
        "\(.key) [\(.value.category)]\n  \(.value.description)\n  File: \(.value.file)\n"
    ' "${BASHD_INDEX_FILE}"
}

# Export functions
export -f bashd_index_init 2>/dev/null
export -f bashd_index_build 2>/dev/null
export -f bashd_index_update 2>/dev/null
export -f bashd_index_stats 2>/dev/null
export -f bashd_index_query 2>/dev/null
export -f _bashd_extract_metadata 2>/dev/null
