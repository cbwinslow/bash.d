#!/bin/bash
# Repository management helper functions for bash.d
# Provides utilities for managing the bash.d configuration system

# Get bash.d root directory
bashd_root() {
    if [[ -n "${BASHD_HOME:-}" ]]; then
        echo "$BASHD_HOME"
    elif [[ -f "${HOME}/.bash.d/bashrc" ]]; then
        echo "${HOME}/.bash.d"
    elif [[ -f "./bashrc" ]]; then
        pwd
    else
        echo "${HOME}/.bash.d"
    fi
}

# Navigate to bash.d root
cdbd() {
    local root
    root=$(bashd_root)
    if [[ -d "$root" ]]; then
        cd "$root" || return 1
        echo "📁 Changed to: $root"
    else
        echo "❌ bash.d root not found" >&2
        return 1
    fi
}

# Show bash.d status
bashd_status() {
    local root
    root=$(bashd_root)
    
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    bash.d Status                           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📁 Root: $root"
    echo ""
    
    if [[ -d "$root" ]]; then
        echo "📊 Components:"
        echo "   • Agents:      $(find "$root/agents" -name "*.py" 2>/dev/null | wc -l) files"
        echo "   • Tools:       $(find "$root/tools" -name "*.py" 2>/dev/null | wc -l) files"
        echo "   • Functions:   $(find "$root/bash_functions.d" -name "*.sh" 2>/dev/null | wc -l) files"
        echo "   • Aliases:     $(find "$root/aliases" -name "*.bash" 2>/dev/null | wc -l) files"
        echo "   • Tests:       $(find "$root/tests" -name "test_*.py" 2>/dev/null | wc -l) files"
        echo ""
        
        # Git status
        if [[ -d "$root/.git" ]]; then
            echo "🔀 Git Status:"
            local branch
            branch=$(git -C "$root" branch --show-current 2>/dev/null)
            echo "   • Branch: $branch"
            
            local changes
            changes=$(git -C "$root" status --porcelain 2>/dev/null | wc -l)
            if [[ "$changes" -gt 0 ]]; then
                echo "   • Changes: $changes uncommitted"
            else
                echo "   • Changes: none"
            fi
        fi
    else
        echo "❌ Directory not found: $root"
    fi
    echo ""
}

# Quick reload bash.d
bashd_reload() {
    local root
    root=$(bashd_root)
    
    echo "🔄 Reloading bash.d..."
    
    if [[ -f "$root/bashrc" ]]; then
        # shellcheck source=/dev/null
        source "$root/bashrc"
        echo "✓ Reloaded successfully"
    else
        echo "❌ bashrc not found" >&2
        return 1
    fi
}

# Edit bash.d configuration
bashd_edit() {
    local target="${1:-bashrc}"
    local root
    root=$(bashd_root)
    
    local file="$root/$target"
    
    if [[ -f "$file" ]]; then
        ${EDITOR:-vim} "$file"
    else
        echo "❌ File not found: $file" >&2
        return 1
    fi
}

# List all available functions
bashd_functions() {
    local root
    root=$(bashd_root)
    local filter="${1:-}"
    
    echo "📋 bash.d Functions:"
    echo ""
    
    find "$root/bash_functions.d" -name "*.sh" -type f 2>/dev/null | while read -r file; do
        local category
        category=$(basename "$(dirname "$file")")
        local name
        name=$(basename "$file" .sh)
        
        if [[ -z "$filter" ]] || [[ "$name" == *"$filter"* ]] || [[ "$category" == *"$filter"* ]]; then
            echo "   [$category] $name"
        fi
    done | sort
}

# List all agents
bashd_agents() {
    local root
    root=$(bashd_root)
    local filter="${1:-}"
    
    echo "🤖 bash.d Agents:"
    echo ""
    
    find "$root/agents" -name "*_agent.py" -type f 2>/dev/null | while read -r file; do
        local category
        category=$(basename "$(dirname "$file")")
        local name
        name=$(basename "$file" _agent.py)
        
        if [[ -z "$filter" ]] || [[ "$name" == *"$filter"* ]] || [[ "$category" == *"$filter"* ]]; then
            echo "   [$category] $name"
        fi
    done | sort
}

# List all tools
bashd_tools() {
    local root
    root=$(bashd_root)
    
    echo "🔧 bash.d Tools:"
    echo ""
    
    find "$root/tools" -name "*_tools.py" -type f 2>/dev/null | while read -r file; do
        local name
        name=$(basename "$file" _tools.py)
        echo "   • $name"
    done | sort
}

# Run tests
bashd_test() {
    local root
    root=$(bashd_root)
    local target="${1:-}"
    
    echo "🧪 Running tests..."
    
    if [[ -n "$target" ]]; then
        python3 -m pytest "$root/tests/test_$target.py" -v
    else
        python3 -m pytest "$root/tests/" -v
    fi
}

# Run linting
bashd_lint() {
    local root
    root=$(bashd_root)
    
    echo "🔍 Running linters..."
    
    if command -v ruff &>/dev/null; then
        ruff check "$root/agents" "$root/tools" "$root/tests" --fix
    else
        echo "⚠️ ruff not installed. Run: pip install ruff"
    fi
}

# Check project health
bashd_health() {
    local root
    root=$(bashd_root)
    
    if [[ -f "$root/scripts/project_health.py" ]]; then
        python3 "$root/scripts/project_health.py"
    else
        echo "❌ Health checker not found"
        return 1
    fi
}

# Generate documentation
bashd_docs() {
    local root
    root=$(bashd_root)
    
    if [[ -f "$root/scripts/generate_docs.py" ]]; then
        python3 "$root/scripts/generate_docs.py"
    else
        echo "❌ Documentation generator not found"
        return 1
    fi
}

# Quick commit with conventional commit format
bashd_commit() {
    local type="${1:-feat}"
    local message="${2:-Update}"
    local root
    root=$(bashd_root)
    
    cd "$root" || return 1
    
    git add -A
    git commit -m "$type: $message"
    
    echo "✓ Committed: $type: $message"
}

# Show recent changes
bashd_changes() {
    local root
    root=$(bashd_root)
    local count="${1:-10}"
    
    echo "📝 Recent changes in bash.d:"
    echo ""
    
    git -C "$root" log --oneline -n "$count" 2>/dev/null || echo "Not a git repository"
}

# Update bash.d from remote
bashd_update() {
    local root
    root=$(bashd_root)
    
    echo "⬆️ Updating bash.d..."
    
    cd "$root" || return 1
    
    git pull origin main
    
    echo "✓ Updated successfully"
    echo "💡 Run 'bashd_reload' to apply changes"
}

# Create a backup of current configuration
bashd_backup() {
    local root
    root=$(bashd_root)
    local backup_dir="${HOME}/.bashd_backups"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_dir}/bashd_backup_${timestamp}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    echo "💾 Creating backup..."
    
    tar -czf "$backup_file" \
        -C "$(dirname "$root")" \
        "$(basename "$root")" \
        --exclude=".git" \
        --exclude="__pycache__" \
        --exclude="node_modules" \
        --exclude=".pytest_cache" \
        2>/dev/null
    
    if [[ -f "$backup_file" ]]; then
        echo "✓ Backup created: $backup_file"
        echo "   Size: $(du -h "$backup_file" | cut -f1)"
    else
        echo "❌ Backup failed" >&2
        return 1
    fi
}

# Show help for bash.d commands
bashd_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                    bash.d Help                                  ║
╚════════════════════════════════════════════════════════════════╝

Navigation & Status:
  cdbd              Navigate to bash.d root directory
  bashd_status      Show system status and statistics
  bashd_root        Print bash.d root path

Module Management:
  bashd_functions   List all bash functions
  bashd_agents      List all agents
  bashd_tools       List all tools
  bashd_reload      Reload bash.d configuration

Development:
  bashd_test        Run tests (optional: specific test file)
  bashd_lint        Run code linting
  bashd_health      Check project health
  bashd_docs        Generate documentation

Git Operations:
  bashd_commit      Quick commit with conventional format
  bashd_changes     Show recent commits
  bashd_update      Pull latest changes from remote

Utilities:
  bashd_edit        Edit configuration file (default: bashrc)
  bashd_backup      Create configuration backup
  bashd_help        Show this help message

Examples:
  bashd_functions ai        # List functions containing "ai"
  bashd_agents security     # List security agents
  bashd_test integration    # Run integration tests
  bashd_commit fix "typo"   # Commit with "fix: typo"

EOF
}

# Export all functions
export -f bashd_root cdbd bashd_status bashd_reload bashd_edit
export -f bashd_functions bashd_agents bashd_tools
export -f bashd_test bashd_lint bashd_health bashd_docs
export -f bashd_commit bashd_changes bashd_update bashd_backup
export -f bashd_help
