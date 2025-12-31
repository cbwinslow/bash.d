#!/bin/bash
# Module management system for bash.d
# Provides enable/disable functionality similar to bash-it

export BASHD_ENABLED_DIR="${BASHD_HOME}/enabled"
export BASHD_STATE_FILE="${BASHD_STATE_DIR}/modules.state"

# Initialize module manager
bashd_module_init() {
    mkdir -p "${BASHD_ENABLED_DIR}"
    mkdir -p "${BASHD_STATE_DIR}"
    touch "${BASHD_STATE_FILE}"
}

# List available modules of a specific type
bashd_module_list() {
    local type="${1:-all}"
    local status="${2:-all}"  # all, enabled, disabled
    
    case "$type" in
        aliases)
            local dir="${BASHD_REPO_ROOT}/aliases"
            ;;
        plugins)
            local dir="${BASHD_REPO_ROOT}/plugins"
            ;;
        completions)
            local dir="${BASHD_REPO_ROOT}/completions"
            ;;
        functions)
            local dir="${BASHD_REPO_ROOT}/bash_functions.d"
            ;;
        all)
            echo "=== Available Modules ==="
            bashd_module_list aliases "$status"
            bashd_module_list plugins "$status"
            bashd_module_list completions "$status"
            bashd_module_list functions "$status"
            return 0
            ;;
        *)
            echo "Unknown module type: $type"
            return 1
            ;;
    esac
    
    if [[ ! -d "$dir" ]]; then
        return 0
    fi
    
    echo ""
    echo "[$type]"
    echo "----------------"
    
    find "$dir" -type f -name "*.sh" -o -name "*.bash" 2>/dev/null | while read -r file; do
        local basename_file
        basename_file=$(basename "$file" | sed 's/\.\(sh\|bash\)$//')
        local enabled_link="${BASHD_ENABLED_DIR}/${type}___${basename_file}"
        
        if [[ -L "$enabled_link" ]]; then
            if [[ "$status" == "all" || "$status" == "enabled" ]]; then
                echo "  [✓] $basename_file"
            fi
        else
            if [[ "$status" == "all" || "$status" == "disabled" ]]; then
                echo "  [ ] $basename_file"
            fi
        fi
    done
}

# Enable a module
bashd_module_enable() {
    local type="$1"
    local name="$2"
    
    if [[ -z "$type" || -z "$name" ]]; then
        echo "Usage: bashd_module_enable <type> <name>"
        echo "Types: aliases, plugins, completions, functions"
        return 1
    fi
    
    case "$type" in
        aliases)
            local dir="${BASHD_REPO_ROOT}/aliases"
            ;;
        plugins)
            local dir="${BASHD_REPO_ROOT}/plugins"
            ;;
        completions)
            local dir="${BASHD_REPO_ROOT}/completions"
            ;;
        functions)
            local dir="${BASHD_REPO_ROOT}/bash_functions.d"
            ;;
        *)
            echo "Unknown module type: $type"
            return 1
            ;;
    esac
    
    # Find the module file
    local module_file
    module_file=$(find "$dir" -type f \( -name "${name}.sh" -o -name "${name}.bash" \) 2>/dev/null | head -1)
    
    if [[ -z "$module_file" || ! -f "$module_file" ]]; then
        echo "Module not found: $name (type: $type)"
        return 1
    fi
    
    local enabled_link="${BASHD_ENABLED_DIR}/${type}___${name}"
    
    if [[ -L "$enabled_link" ]]; then
        echo "Module already enabled: $name"
        return 0
    fi
    
    ln -sf "$module_file" "$enabled_link"
    echo "✓ Enabled $type: $name"
    echo "${type}:${name}" >> "${BASHD_STATE_FILE}"
}

# Disable a module
bashd_module_disable() {
    local type="$1"
    local name="$2"
    
    if [[ -z "$type" || -z "$name" ]]; then
        echo "Usage: bashd_module_disable <type> <name>"
        echo "Types: aliases, plugins, completions, functions"
        return 1
    fi
    
    local enabled_link="${BASHD_ENABLED_DIR}/${type}___${name}"
    
    if [[ ! -L "$enabled_link" ]]; then
        echo "Module not enabled: $name"
        return 0
    fi
    
    rm -f "$enabled_link"
    echo "✓ Disabled $type: $name"
    
    # Remove from state file
    if [[ -f "${BASHD_STATE_FILE}" ]]; then
        grep -v "^${type}:${name}$" "${BASHD_STATE_FILE}" > "${BASHD_STATE_FILE}.tmp"
        mv "${BASHD_STATE_FILE}.tmp" "${BASHD_STATE_FILE}"
    fi
}

# Load all enabled modules
bashd_module_load_enabled() {
    if [[ ! -d "${BASHD_ENABLED_DIR}" ]]; then
        return 0
    fi
    
    for enabled_file in "${BASHD_ENABLED_DIR}"/*; do
        if [[ -L "$enabled_file" && -f "$enabled_file" ]]; then
            # shellcheck disable=SC1090
            source "$enabled_file"
        fi
    done
}

# Search for modules
bashd_module_search() {
    local query="$1"
    
    if [[ -z "$query" ]]; then
        echo "Usage: bashd_module_search <query>"
        return 1
    fi
    
    echo "Searching for modules matching: $query"
    echo "========================================"
    
    # Search in all module directories
    for type in aliases plugins completions bash_functions.d; do
        local dir="${BASHD_REPO_ROOT}/${type}"
        if [[ -d "$dir" ]]; then
            echo ""
            echo "[$type]"
            find "$dir" -type f \( -name "*.sh" -o -name "*.bash" \) -exec grep -l "$query" {} \; 2>/dev/null | while read -r file; do
                local name
                name=$(basename "$file" | sed 's/\.\(sh\|bash\)$//')
                echo "  - $name"
            done
        fi
    done
}

# Show module info
bashd_module_info() {
    local type="$1"
    local name="$2"
    
    if [[ -z "$type" || -z "$name" ]]; then
        echo "Usage: bashd_module_info <type> <name>"
        return 1
    fi
    
    case "$type" in
        aliases)
            local dir="${BASHD_REPO_ROOT}/aliases"
            ;;
        plugins)
            local dir="${BASHD_REPO_ROOT}/plugins"
            ;;
        completions)
            local dir="${BASHD_REPO_ROOT}/completions"
            ;;
        functions)
            local dir="${BASHD_REPO_ROOT}/bash_functions.d"
            ;;
        *)
            echo "Unknown module type: $type"
            return 1
            ;;
    esac
    
    local module_file
    module_file=$(find "$dir" -type f \( -name "${name}.sh" -o -name "${name}.bash" \) 2>/dev/null | head -1)
    
    if [[ -z "$module_file" || ! -f "$module_file" ]]; then
        echo "Module not found: $name"
        return 1
    fi
    
    echo "Module: $name"
    echo "Type: $type"
    echo "Path: $module_file"
    echo ""
    echo "Description:"
    echo "------------"
    head -20 "$module_file" | grep "^#" | sed 's/^# *//'
}

# Export functions
export -f bashd_module_init 2>/dev/null
export -f bashd_module_list 2>/dev/null
export -f bashd_module_enable 2>/dev/null
export -f bashd_module_disable 2>/dev/null
export -f bashd_module_load_enabled 2>/dev/null
export -f bashd_module_search 2>/dev/null
export -f bashd_module_info 2>/dev/null
