#!/bin/bash
# Development Tools Collector Script
# Detects installed development tools, SDKs, and utilities
# Outputs JSON format

set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

command_exists() {
    command -v "$1" &> /dev/null
}

get_version() {
    local cmd="$1"
    local version_flag="${2:---version}"
    
    if command_exists "$cmd"; then
        $cmd $version_flag 2>/dev/null | head -1 | sed 's/^[^0-9]*//' || echo "installed"
    else
        echo "not installed"
    fi
}

main() {
    log_info "Collecting development tools information..."
    
    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$(hostname)",
    "programming_languages": {
        "python": "$(get_version python3)",
        "python2": "$(get_version python)",
        "node": "$(get_version node)",
        "ruby": "$(get_version ruby)",
        "perl": "$(get_version perl)",
        "php": "$(get_version php)",
        "java": "$(get_version java)",
        "go": "$(get_version go version)",
        "rust": "$(get_version rustc)",
        "gcc": "$(get_version gcc)",
        "clang": "$(get_version clang)"
    },
    "version_control": {
        "git": "$(get_version git)",
        "svn": "$(get_version svn)",
        "hg": "$(get_version hg)"
    },
    "build_tools": {
        "make": "$(get_version make)",
        "cmake": "$(get_version cmake)",
        "gradle": "$(get_version gradle)",
        "maven": "$(get_version mvn)",
        "ant": "$(get_version ant)"
    },
    "editors": {
        "vim": "$(get_version vim)",
        "nvim": "$(get_version nvim)",
        "emacs": "$(get_version emacs)",
        "nano": "$(get_version nano)",
        "code": "$(get_version code)"
    },
    "shells": {
        "bash": "$(get_version bash)",
        "zsh": "$(get_version zsh)",
        "fish": "$(get_version fish)"
    },
    "containers": {
        "docker": "$(get_version docker)",
        "podman": "$(get_version podman)",
        "kubectl": "$(get_version kubectl)"
    },
    "utilities": {
        "curl": "$(get_version curl)",
        "wget": "$(get_version wget)",
        "jq": "$(get_version jq)",
        "tmux": "$(get_version tmux)",
        "screen": "$(get_version screen)",
        "htop": "$(get_version htop)",
        "tree": "$(get_version tree)"
    }
}
EOF
    
    log_info "Tools collection complete!"
}

main "$@"
