#!/bin/bash
#===============================================================================
#
#          FILE:  func_add.sh
#
#         USAGE:  func_add <function_name> [category]
#
#   DESCRIPTION:  Add a new function to the bash_functions.d repository
#                 This utility helps manage and organize bash functions
#
#       OPTIONS:  function_name - Name of the function to create
#                 category - Category folder (utilities, system, git, etc.)
#  REQUIREMENTS:  git
#         NOTES:  Creates a new .sh file with a template
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Add a new function to the bash_functions.d repository
func_add() {
    local func_name="${1}"
    local category="${2:-utilities}"
    local repo_dir="${BASH_D_REPO:-$HOME/bash.d}"
    local functions_dir="${repo_dir}/bash_functions.d"
    
    # Validate input
    if [[ -z "$func_name" ]]; then
        echo "Usage: func_add <function_name> [category]"
        echo ""
        echo "Categories available:"
        if [[ -d "$functions_dir" ]]; then
            find "$functions_dir" -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
                [[ "$dir" != "$functions_dir" ]] && echo "  - $(basename "$dir")"
            done
        fi
        return 1
    fi
    
    # Sanitize function name
    func_name=$(echo "$func_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')
    
    # Create category directory if it doesn't exist
    local target_dir="${functions_dir}/${category}"
    if [[ ! -d "$target_dir" ]]; then
        echo "Creating category directory: $category"
        mkdir -p "$target_dir"
    fi
    
    local target_file="${target_dir}/${func_name}.sh"
    
    # Check if file already exists
    if [[ -f "$target_file" ]]; then
        echo "Error: Function file already exists: $target_file"
        echo "Do you want to edit it instead? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy] ]]; then
            "${EDITOR:-vim}" "$target_file"
        fi
        return 1
    fi
    
    # Create the function file with template
    cat > "$target_file" << 'TEMPLATE'
#!/bin/bash
#===============================================================================
#
#          FILE:  FUNC_NAME.sh
#
#         USAGE:  FUNC_NAME [options] [arguments]
#
#   DESCRIPTION:  Brief description of what this function does
#
#       OPTIONS:  -h, --help    Show this help message
#                 -v, --verbose Enable verbose output
#  REQUIREMENTS:  List any dependencies here
#         NOTES:  Additional notes about the function
#        AUTHOR:  Your Name
#       VERSION:  1.0.0
#       CREATED:  CREATED_DATE
#===============================================================================

# FUNC_NAME - Description of the function
# Usage: FUNC_NAME [options] [arguments]
#
# Examples:
#   FUNC_NAME                    # Basic usage
#   FUNC_NAME -v arg            # With verbose flag
#
FUNC_NAME() {
    local verbose=false
    local OPTIND opt
    
    # Parse options
    while getopts "hv" opt; do
        case ${opt} in
            h)
                echo "Usage: FUNC_NAME [options] [arguments]"
                echo ""
                echo "Options:"
                echo "  -h    Show this help message"
                echo "  -v    Enable verbose output"
                return 0
                ;;
            v)
                verbose=true
                ;;
            *)
                echo "Usage: FUNC_NAME [options] [arguments]"
                return 1
                ;;
        esac
    done
    shift $((OPTIND - 1))
    
    # Main function logic here
    if [[ "$verbose" == true ]]; then
        echo "[FUNC_NAME] Running with verbose output..."
    fi
    
    # TODO: Implement function logic
    echo "FUNC_NAME function called with args: $*"
}

# Export the function for use in subshells
export -f FUNC_NAME 2>/dev/null
TEMPLATE
    
    # Replace placeholders
    sed -i "s/FUNC_NAME/${func_name}/g" "$target_file"
    sed -i "s/CREATED_DATE/$(date '+%Y-%m-%d')/g" "$target_file"
    
    # Make executable
    chmod +x "$target_file"
    
    echo "Created function: $target_file"
    echo ""
    
    # Open in editor
    echo "Opening in editor..."
    "${EDITOR:-vim}" "$target_file"
    
    # Ask to commit
    echo ""
    echo "Do you want to commit this function to git? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy] ]]; then
        cd "$repo_dir" || return 1
        git add "$target_file"
        git commit -m "Add function: ${func_name}"
        echo "Function committed. Use 'git push' to push to remote."
    fi
}

# List all available functions
func_list() {
    local repo_dir="${BASH_D_REPO:-$HOME/bash.d}"
    local functions_dir="${repo_dir}/bash_functions.d"
    local category="${1}"
    
    if [[ ! -d "$functions_dir" ]]; then
        echo "Functions directory not found: $functions_dir"
        return 1
    fi
    
    echo "Available functions in bash_functions.d:"
    echo "========================================="
    
    if [[ -n "$category" ]]; then
        local cat_dir="${functions_dir}/${category}"
        if [[ -d "$cat_dir" ]]; then
            echo ""
            echo "[$category]"
            find "$cat_dir" -name "*.sh" -type f 2>/dev/null | while read -r file; do
                echo "  - $(basename "$file" .sh)"
            done
        else
            echo "Category not found: $category"
            return 1
        fi
    else
        # List all categories and their functions
        for cat_dir in "$functions_dir"/*/; do
            if [[ -d "$cat_dir" ]]; then
                local cat_name
                cat_name=$(basename "$cat_dir")
                echo ""
                echo "[$cat_name]"
                find "$cat_dir" -name "*.sh" -type f 2>/dev/null | while read -r file; do
                    echo "  - $(basename "$file" .sh)"
                done
            fi
        done
    fi
}

# Edit an existing function
func_edit() {
    local func_name="${1}"
    local repo_dir="${BASH_D_REPO:-$HOME/bash.d}"
    local functions_dir="${repo_dir}/bash_functions.d"
    
    if [[ -z "$func_name" ]]; then
        echo "Usage: func_edit <function_name>"
        return 1
    fi
    
    # Search for the function file
    local found_file
    found_file=$(find "$functions_dir" -name "${func_name}.sh" -type f 2>/dev/null | head -1)
    
    if [[ -z "$found_file" ]]; then
        echo "Function not found: $func_name"
        echo ""
        echo "Available functions:"
        func_list
        return 1
    fi
    
    "${EDITOR:-vim}" "$found_file"
}

# Remove a function
func_remove() {
    local func_name="${1}"
    local repo_dir="${BASH_D_REPO:-$HOME/bash.d}"
    local functions_dir="${repo_dir}/bash_functions.d"
    
    if [[ -z "$func_name" ]]; then
        echo "Usage: func_remove <function_name>"
        return 1
    fi
    
    # Search for the function file
    local found_file
    found_file=$(find "$functions_dir" -name "${func_name}.sh" -type f 2>/dev/null | head -1)
    
    if [[ -z "$found_file" ]]; then
        echo "Function not found: $func_name"
        return 1
    fi
    
    echo "Are you sure you want to remove: $found_file? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy] ]]; then
        rm "$found_file"
        echo "Function removed: $func_name"
        
        # Ask to commit
        echo "Do you want to commit this change to git? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy] ]]; then
            cd "$repo_dir" || return 1
            git add -A
            git commit -m "Remove function: ${func_name}"
            echo "Change committed."
        fi
    else
        echo "Cancelled."
    fi
}

# Export functions
export -f func_add 2>/dev/null
export -f func_list 2>/dev/null
export -f func_edit 2>/dev/null
export -f func_remove 2>/dev/null
