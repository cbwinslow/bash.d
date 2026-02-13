#!/bin/bash

# Comprehensive function catalog analysis
echo "=== COMPREHENSIVE FUNCTION CATALOG ANALYSIS ==="
echo ""

# Function safety classification
classify_safety() {
    local func_name="$1"
    local file_path="$2"
    local content="$3"
    
    # Check for dangerous patterns
    if echo "$content" | grep -qE "(rm\s+-rf|sudo|chmod\s+777|>\s*/dev/|curl.*\|.*sh|wget.*\|.*sh|eval|exec)"; then
        echo "unsafe"
    elif echo "$content" | grep -qE "(git\s+push|git\s+commit|docker.*rm|kill\s+-9)"; then
        echo "supervision"
    else
        echo "safe"
    fi
}

# Determine function category
categorize_function() {
    local func_name="$1"
    local file_path="$2"
    
    case "$file_path" in
        */git/*) echo "git" ;;
        */docker/*|*/network/*) echo "system" ;;
        */ai*|*/tools/*) echo "ai_tools" ;;
        */system/*) echo "system" ;;
        */utils/*) echo "utilities" ;;
        */help/*) echo "help" ;;
        */core/*) echo "core" ;;
        */tui/*) echo "interface" ;;
        */completions/*) echo "completion" ;;
        *) echo "misc" ;;
    esac
}

# Check documentation quality
check_documentation() {
    local content="$1"
    
    if echo "$content" | grep -qE "(#.*DESCRIPTION|#.*USAGE|#.*PARAMETERS|#.*RETURN)"; then
        echo "well_documented"
    elif echo "$content" | grep -qE "(#.*:|#.*=)"; then
        echo "partially_documented"
    else
        echo "needs_docs"
    fi
}

# Extract function parameters
extract_params() {
    local func_name="$1"
    local file_path="$2"
    
    # Simple parameter extraction from function usage patterns
    if grep -q "Usage:" "$file_path"; then
        grep "Usage:" "$file_path" | head -1 | sed 's/.*Usage:[[:space:]]*//' | sed "s/$func_name//"
    else
        echo "unknown"
    fi
}

echo "FUNCTION ANALYSIS RESULTS:"
echo "========================="
echo ""

# Initialize counters
declare -A categories
declare -A safety_levels
declare -A doc_quality
total_functions=0

# Find and analyze all functions
find bash_functions.d -name "*.sh" -type f | while read file; do
    # Skip if file is too large or binary
    if [[ ! -f "$file" ]] || [[ $(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null) -gt 100000 ]]; then
        continue
    fi
    
    # Extract function definitions
    grep -n "^[[:space:]]*function[[:space:]]\+\|[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*()[[:space:]]*{" "$file" | while read line; do
        line_num=$(echo "$line" | cut -d: -f1)
        func_def=$(echo "$line" | cut -d: -f2-)
        
        # Extract function name
        func_name=$(echo "$func_def" | sed -E 's/^[[:space:]]*function[[:space:]]+//' | sed -E 's/[[:space:]]*\([[:space:]]*\).*//' | sed -E 's/^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\([[:space:]]*\).*$/\1/')
        
        if [[ -n "$func_name" ]]; then
            # Get function content (simplified)
            func_content=$(sed -n "${line_num},/^}/p" "$file" | head -20)
            
            # Analyze function
            category=$(categorize_function "$func_name" "$file")
            safety=$(classify_safety "$func_name" "$file" "$func_content")
            doc_status=$(check_documentation "$func_content")
            params=$(extract_params "$func_name" "$file")
            
            echo "$func_name|$file|$line_num|$category|$safety|$doc_status|$params"
            ((total_functions++))
        fi
    done
done | sort > /tmp/functions_analysis.txt

# Display summary statistics
echo ""
echo "=== SUMMARY STATISTICS ==="
echo "Total functions analyzed: $(wc -l < /tmp/functions_analysis.txt)"
echo ""

echo "=== BY CATEGORY ==="
awk -F'|' '{print $4}' /tmp/functions_analysis.txt | sort | uniq -c | sort -rn

echo ""
echo "=== BY SAFETY LEVEL ==="
awk -F'|' '{print $5}' /tmp/functions_analysis.txt | sort | uniq -c | sort -rn

echo ""
echo "=== BY DOCUMENTATION QUALITY ==="
awk -F'|' '{print $6}' /tmp/functions_analysis.txt | sort | uniq -c | sort -rn

echo ""
echo "=== IMMEDIATE AI TOOL CONVERSION CANDIDATES ==="
echo "(Safe, well-documented functions)"
awk -F'|' '$5=="safe" && $6=="well_documented" {print $1 " (" $4 ") - " $2}' /tmp/functions_analysis.txt | head -20

echo ""
echo "=== FUNCTIONS NEEDING IMMEDIATE DOCUMENTATION ==="
awk -F'|' '$6=="needs_docs" {print $1 " (" $4 ") - " $2}' /tmp/functions_analysis.txt | head -20

echo ""
echo "=== UNSAFE FUNCTIONS - REQUIRE SUPERVISION ==="
awk -F'|' '$5=="unsafe" {print $1 " (" $4 ") - " $2}' /tmp/functions_analysis.txt

# Clean up
rm -f /tmp/functions_analysis.txt
