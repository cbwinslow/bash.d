#!/bin/bash
# ============================================================================
# Text Processing Utilities
# ============================================================================
# Tools for text manipulation, search, and formatting

# Count lines in file
countlines() {
    if [ -z "$1" ]; then
        echo "Usage: countlines <file>"
        return 1
    fi
    
    wc -l < "$1"
}

# Count words in file
countwords() {
    if [ -z "$1" ]; then
        echo "Usage: countwords <file>"
        return 1
    fi
    
    wc -w < "$1"
}

# Count characters in file
countchars() {
    if [ -z "$1" ]; then
        echo "Usage: countchars <file>"
        return 1
    fi
    
    wc -m < "$1"
}

# Remove duplicate lines from file
dedup() {
    if [ -z "$1" ]; then
        echo "Usage: dedup <file>"
        return 1
    fi
    
    sort "$1" | uniq
}

# Remove blank lines from file
rmblank() {
    if [ -z "$1" ]; then
        echo "Usage: rmblank <file>"
        return 1
    fi
    
    grep -v '^[[:space:]]*$' "$1"
}

# Convert file to lowercase
tolower() {
    if [ -z "$1" ]; then
        echo "Usage: tolower <file>"
        return 1
    fi
    
    tr '[:upper:]' '[:lower:]' < "$1"
}

# Convert file to uppercase
toupper() {
    if [ -z "$1" ]; then
        echo "Usage: toupper <file>"
        return 1
    fi
    
    tr '[:lower:]' '[:upper:]' < "$1"
}

# Replace text in file
replace() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: replace <search> <replace> <file>"
        return 1
    fi
    
    local search="$1"
    local replace="$2"
    local file="$3"
    
    sed -i.bak "s/$search/$replace/g" "$file"
    echo "Replaced '$search' with '$replace' in $file (backup: ${file}.bak)"
}

# Show first N lines
head_n() {
    local lines="${1:-10}"
    local file="$2"
    
    if [ -z "$file" ]; then
        head -n "$lines"
    else
        head -n "$lines" "$file"
    fi
}

# Show last N lines
tail_n() {
    local lines="${1:-10}"
    local file="$2"
    
    if [ -z "$file" ]; then
        tail -n "$lines"
    else
        tail -n "$lines" "$file"
    fi
}

# Follow file updates
tailf() {
    if [ -z "$1" ]; then
        echo "Usage: tailf <file>"
        return 1
    fi
    
    tail -f "$1"
}

# Extract column from CSV
csvcolumn() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: csvcolumn <column_number> <file>"
        return 1
    fi
    
    local col="$1"
    local file="$2"
    
    cut -d',' -f"$col" "$file"
}

# Sort file by column
sortcolumn() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: sortcolumn <column_number> <file>"
        return 1
    fi
    
    local col="$1"
    local file="$2"
    
    sort -t',' -k"$col" "$file"
}

# Find and replace across multiple files
findreplace() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: findreplace <search> <replace> <pattern>"
        return 1
    fi
    
    local search="$1"
    local replace="$2"
    local pattern="$3"
    
    find . -type f -name "$pattern" -exec sed -i "s/$search/$replace/g" {} +
    echo "Replaced '$search' with '$replace' in files matching $pattern"
}

# Show line numbers in file
linenum() {
    if [ -z "$1" ]; then
        cat -n
    else
        cat -n "$1"
    fi
}

# Remove line numbers from file
rmlinenum() {
    if [ -z "$1" ]; then
        sed 's/^[[:space:]]*[0-9]*[[:space:]]*//'
    else
        sed 's/^[[:space:]]*[0-9]*[[:space:]]*//' "$1"
    fi
}

# Trim whitespace from beginning and end of lines
trim() {
    if [ -z "$1" ]; then
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
    else
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' "$1"
    fi
}

# Convert tabs to spaces
tab2space() {
    if [ -z "$1" ]; then
        expand
    else
        expand "$1"
    fi
}

# Convert spaces to tabs
space2tab() {
    if [ -z "$1" ]; then
        unexpand
    else
        unexpand "$1"
    fi
}

# Get unique words from file
uniquewords() {
    if [ -z "$1" ]; then
        echo "Usage: uniquewords <file>"
        return 1
    fi
    
    tr -cs '[:alnum:]' '\n' < "$1" | tr '[:upper:]' '[:lower:]' | sort | uniq
}

# Count word frequency
wordfreq() {
    if [ -z "$1" ]; then
        echo "Usage: wordfreq <file>"
        return 1
    fi
    
    tr -cs '[:alnum:]' '\n' < "$1" | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -rn | head -20
}

# Extract URLs from text
extracturls() {
    if [ -z "$1" ]; then
        grep -oP 'https?://[^\s]+'
    else
        grep -oP 'https?://[^\s]+' "$1"
    fi
}

# Extract email addresses from text
extractemails() {
    if [ -z "$1" ]; then
        grep -oP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    else
        grep -oP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$1"
    fi
}

# Convert DOS line endings to Unix
dos2unix_convert() {
    if [ -z "$1" ]; then
        echo "Usage: dos2unix_convert <file>"
        return 1
    fi
    
    sed -i 's/\r$//' "$1"
    echo "Converted DOS line endings to Unix in $1"
}

# Convert Unix line endings to DOS
unix2dos_convert() {
    if [ -z "$1" ]; then
        echo "Usage: unix2dos_convert <file>"
        return 1
    fi
    
    sed -i 's/$/\r/' "$1"
    echo "Converted Unix line endings to DOS in $1"
}

# Show file encoding
fileencoding() {
    if [ -z "$1" ]; then
        echo "Usage: fileencoding <file>"
        return 1
    fi
    
    file -b --mime-encoding "$1"
}

# Convert file encoding
convertencoding() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: convertencoding <from_encoding> <to_encoding> <file>"
        return 1
    fi
    
    local from="$1"
    local to="$2"
    local file="$3"
    
    iconv -f "$from" -t "$to" "$file" > "${file}.converted"
    echo "Converted $file from $from to $to (output: ${file}.converted)"
}

# Pretty print XML
xmlformat() {
    if [ -z "$1" ]; then
        xmllint --format -
    else
        xmllint --format "$1"
    fi
}

# Show file differences with color
colordiff() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: colordiff <file1> <file2>"
        return 1
    fi
    
    diff -u "$1" "$2" | sed 's/^-/\x1b[31m-/;s/^+/\x1b[32m+/;s/^@/\x1b[36m@/;s/$/\x1b[0m/'
}
