#!/bin/bash
# ============================================================================
# Help and Documentation System
# ============================================================================
# Provides man/tldr-like functionality for bash helper functions

# Main help function - displays help for all functions or a specific function
bash_help() {
    local function_name="$1"
    local docs_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bash_documents.d" && pwd)"
    
    if [ -z "$function_name" ]; then
        # Display list of all available functions
        echo -e "${COLOR_BOLD}${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
        echo -e "${COLOR_BOLD}${COLOR_GREEN}  Kingdom Monorepo - Bash Helper Functions${COLOR_RESET}"
        echo -e "${COLOR_BOLD}${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
        echo ""
        echo -e "${COLOR_YELLOW}Usage:${COLOR_RESET} bash_help [function_name]"
        echo ""
        echo -e "${COLOR_YELLOW}Available Functions:${COLOR_RESET}"
        echo ""
        
        # List all documented functions
        if [ -d "$docs_dir" ]; then
            for doc_file in "$docs_dir"/*.md; do
                if [ -f "$doc_file" ]; then
                    local fname=$(basename "$doc_file" .md)
                    local first_line=$(head -n 1 "$doc_file" | sed 's/^# //')
                    printf "  ${COLOR_GREEN}%-30s${COLOR_RESET} %s\n" "$fname" "$first_line"
                fi
            done | sort
        fi
        
        echo ""
        echo -e "${COLOR_CYAN}Tip: Use 'bash_help <function_name>' for detailed help${COLOR_RESET}"
        echo -e "${COLOR_CYAN}Tip: Use 'bash_search <keyword>' to search functions${COLOR_RESET}"
        echo ""
    else
        # Display help for specific function
        local doc_file="$docs_dir/${function_name}.md"
        
        if [ -f "$doc_file" ]; then
            # Display the documentation with formatting
            echo -e "${COLOR_BOLD}${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
            echo -e "${COLOR_BOLD}${COLOR_GREEN}  $function_name${COLOR_RESET}"
            echo -e "${COLOR_BOLD}${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
            echo ""
            
            # Parse and display the markdown file with basic formatting
            while IFS= read -r line; do
                if [[ $line =~ ^#\ (.+) ]]; then
                    # Main heading (already shown above)
                    continue
                elif [[ $line =~ ^##\ (.+) ]]; then
                    # Section heading
                    echo -e "${COLOR_BOLD}${COLOR_YELLOW}${BASH_REMATCH[1]}${COLOR_RESET}"
                elif [[ $line =~ ^\*\*(.+)\*\*:\ (.+) ]]; then
                    # Bold key-value pair
                    echo -e "${COLOR_BOLD}${BASH_REMATCH[1]}:${COLOR_RESET} ${BASH_REMATCH[2]}"
                elif [[ $line =~ ^\`\`\`(.*)$ ]]; then
                    # Code block delimiter
                    echo -e "${COLOR_DIM}────────────────────────────────────────────${COLOR_RESET}"
                elif [[ $line =~ ^-\ (.+) ]]; then
                    # List item
                    echo -e "  • ${BASH_REMATCH[1]}"
                else
                    echo "$line"
                fi
            done < "$doc_file"
            
            echo ""
        else
            echo -e "${COLOR_RED}Error: No documentation found for '$function_name'${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}Use 'bash_help' to see all available functions${COLOR_RESET}"
            return 1
        fi
    fi
}

# Search for functions by keyword
bash_search() {
    local keyword="$1"
    local docs_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bash_documents.d" && pwd)"
    
    if [ -z "$keyword" ]; then
        echo -e "${COLOR_RED}Error: Please provide a search keyword${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Usage:${COLOR_RESET} bash_search <keyword>"
        return 1
    fi
    
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Searching for functions matching: ${COLOR_GREEN}$keyword${COLOR_RESET}"
    echo -e "${COLOR_CYAN}════════════════════════════════════════${COLOR_RESET}"
    echo ""
    
    local found=0
    if [ -d "$docs_dir" ]; then
        for doc_file in "$docs_dir"/*.md; do
            if [ -f "$doc_file" ]; then
                if grep -qi "$keyword" "$doc_file"; then
                    local fname=$(basename "$doc_file" .md)
                    local first_line=$(head -n 1 "$doc_file" | sed 's/^# //')
                    printf "  ${COLOR_GREEN}%-30s${COLOR_RESET} %s\n" "$fname" "$first_line"
                    found=1
                fi
            fi
        done
    fi
    
    if [ $found -eq 0 ]; then
        echo -e "${COLOR_YELLOW}No functions found matching '$keyword'${COLOR_RESET}"
    fi
    
    echo ""
}

# List all available function categories
bash_categories() {
    local funcs_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Function Categories:${COLOR_RESET}"
    echo -e "${COLOR_CYAN}════════════════════${COLOR_RESET}"
    echo ""
    
    for func_file in "$funcs_dir"/*.sh; do
        if [ -f "$func_file" ]; then
            local fname=$(basename "$func_file" .sh)
            local category=$(echo "$fname" | sed 's/^[0-9]*_//' | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
            local first_comment=$(grep -m 1 "^#" "$func_file" | sed 's/^# *//')
            
            printf "  ${COLOR_GREEN}%-40s${COLOR_RESET} %s\n" "$category" "$first_comment"
        fi
    done | sort
    
    echo ""
}

# Quick reference - show all functions with one-line descriptions
bash_quickref() {
    bash_help
}

# Alias for bash_help
alias bh='bash_help'
alias bs='bash_search'
