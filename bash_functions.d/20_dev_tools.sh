#!/bin/bash
# ============================================================================
# Development Tools
# ============================================================================
# Helpful functions for software development, git, and code management

# Quick git commit with message
gcm() {
    if [ -z "$1" ]; then
        echo "Usage: gcm <commit_message>"
        return 1
    fi
    
    git add .
    git commit -m "$*"
}

# Git commit and push
gcp() {
    if [ -z "$1" ]; then
        echo "Usage: gcp <commit_message>"
        return 1
    fi
    
    git add .
    git commit -m "$*"
    git push
}

# Create new git branch and switch to it
gnb() {
    if [ -z "$1" ]; then
        echo "Usage: gnb <branch_name>"
        return 1
    fi
    
    git checkout -b "$1"
}

# Show git log in pretty format
glog() {
    local count="${1:-10}"
    git log --oneline --graph --decorate --all -n "$count"
}

# Show git status with short format
gss() {
    git status -sb
}

# Undo last git commit (keep changes)
gundo() {
    git reset --soft HEAD~1
}

# Show git diff with word highlighting
gdiff() {
    git diff --word-diff=color "$@"
}

# Find git repositories in directory
findrepos() {
    local dir="${1:-.}"
    find "$dir" -name ".git" -type d -prune | sed 's/\/.git$//'
}

# Clone repository and cd into it
gclone() {
    if [ -z "$1" ]; then
        echo "Usage: gclone <repository_url>"
        return 1
    fi
    
    git clone "$1" && cd "$(basename "$1" .git)"
}

# Search for text in code files (excluding common directories)
codesearch() {
    if [ -z "$1" ]; then
        echo "Usage: codesearch <pattern> [directory]"
        return 1
    fi
    
    local pattern="$1"
    local dir="${2:-.}"
    
    grep -r --color=auto --exclude-dir={.git,node_modules,.venv,venv,__pycache__,dist,build} \
         --exclude="*.pyc" --exclude="*.min.js" --exclude="*.map" \
         "$pattern" "$dir"
}

# Count lines of code in project
loc() {
    local dir="${1:-.}"
    
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Lines of Code Summary${COLOR_RESET}"
    echo -e "${COLOR_CYAN}═════════════════════${COLOR_RESET}"
    
    find "$dir" -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" \
         -o -name "*.c" -o -name "*.cpp" -o -name "*.go" -o -name "*.rs" -o -name "*.sh" \) \
         ! -path "*/node_modules/*" ! -path "*/.venv/*" ! -path "*/venv/*" \
         ! -path "*/dist/*" ! -path "*/build/*" \
         -exec wc -l {} + | sort -rn | head -20
}

# Find TODO/FIXME comments in code
todos() {
    local dir="${1:-.}"
    
    echo -e "${COLOR_BOLD}${COLOR_YELLOW}TODO/FIXME Items:${COLOR_RESET}"
    echo ""
    
    grep -rn --color=always -E "TODO|FIXME|XXX|HACK|BUG" "$dir" \
         --exclude-dir={.git,node_modules,.venv,venv,__pycache__,dist,build} \
         --exclude="*.pyc" 2>/dev/null || echo "No TODO/FIXME items found"
}

# Format JSON beautifully
jsonformat() {
    if [ -z "$1" ]; then
        python3 -m json.tool
    else
        python3 -m json.tool < "$1"
    fi
}

# Start simple HTTP server for current directory
serve() {
    local port="${1:-8000}"
    echo -e "${COLOR_GREEN}Starting HTTP server on port $port...${COLOR_RESET}"
    echo -e "${COLOR_CYAN}http://localhost:$port${COLOR_RESET}"
    python3 -m http.server "$port"
}

# Generate random password
genpass() {
    local length="${1:-16}"
    openssl rand -base64 32 | cut -c1-"$length"
}

# Generate UUID
genuuid() {
    python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null
}

# URL encode string
urlencode() {
    if [ -z "$1" ]; then
        echo "Usage: urlencode <string>"
        return 1
    fi
    
    python3 -c "import urllib.parse; print(urllib.parse.quote('$*'))"
}

# URL decode string
urldecode() {
    if [ -z "$1" ]; then
        echo "Usage: urldecode <encoded_string>"
        return 1
    fi
    
    python3 -c "import urllib.parse; print(urllib.parse.unquote('$*'))"
}

# Base64 encode
b64encode() {
    if [ -z "$1" ]; then
        echo "Usage: b64encode <string>"
        return 1
    fi
    
    echo -n "$*" | base64
}

# Base64 decode
b64decode() {
    if [ -z "$1" ]; then
        echo "Usage: b64decode <encoded_string>"
        return 1
    fi
    
    echo -n "$*" | base64 -d
}

# Calculate MD5 hash
md5sum_str() {
    if [ -z "$1" ]; then
        echo "Usage: md5sum_str <string>"
        return 1
    fi
    
    echo -n "$*" | md5sum | awk '{print $1}'
}

# Calculate SHA256 hash
sha256sum_str() {
    if [ -z "$1" ]; then
        echo "Usage: sha256sum_str <string>"
        return 1
    fi
    
    echo -n "$*" | sha256sum | awk '{print $1}'
}

# Compare two files side by side
diffside() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: diffside <file1> <file2>"
        return 1
    fi
    
    diff -y "$1" "$2" | less
}

# Show file in hexadecimal format
hexdump_file() {
    if [ -z "$1" ]; then
        echo "Usage: hexdump_file <file>"
        return 1
    fi
    
    hexdump -C "$1" | less
}

# Create new project directory with common structure
mkproject() {
    if [ -z "$1" ]; then
        echo "Usage: mkproject <project_name>"
        return 1
    fi
    
    local project="$1"
    mkdir -p "$project"/{src,tests,docs,bin}
    touch "$project"/{README.md,.gitignore}
    
    echo "# $project" > "$project/README.md"
    echo "node_modules/" > "$project/.gitignore"
    echo ".venv/" >> "$project/.gitignore"
    echo "*.pyc" >> "$project/.gitignore"
    echo "__pycache__/" >> "$project/.gitignore"
    
    echo -e "${COLOR_GREEN}Created project structure: $project${COLOR_RESET}"
    tree "$project" 2>/dev/null || ls -R "$project"
}

# Quick Python virtual environment
pyvenv() {
    local venv_name="${1:-.venv}"
    python3 -m venv "$venv_name"
    source "$venv_name/bin/activate"
    echo -e "${COLOR_GREEN}Virtual environment activated: $venv_name${COLOR_RESET}"
}

# Deactivate Python virtual environment (alias)
alias pydeactivate='deactivate'

# Install requirements from requirements.txt
pyreqs() {
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    else
        echo "Error: requirements.txt not found"
        return 1
    fi
}

# Create requirements.txt from current environment
pysave() {
    pip freeze > requirements.txt
    echo -e "${COLOR_GREEN}Saved requirements to requirements.txt${COLOR_RESET}"
}
