#!/bin/bash
# Container Information Collector Script
# Collects Docker and Podman container configurations
# Outputs JSON format for AI agent consumption

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

command_exists() {
    command -v "$1" &> /dev/null
}

# Collect Docker information
collect_docker_info() {
    if ! command_exists docker; then
        return
    fi
    
    log_info "Collecting Docker information..."
    
    # Docker version
    local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')
    
    # Running containers
    local containers=()
    if docker ps --format "{{json .}}" 2>/dev/null | head -1 > /dev/null; then
        while IFS= read -r container; do
            containers+=("$container")
        done < <(docker ps -a --format "{{json .}}" 2>/dev/null)
    fi
    
    # Images
    local images=()
    if docker images --format "{{json .}}" 2>/dev/null | head -1 > /dev/null; then
        while IFS= read -r image; do
            images+=("$image")
        done < <(docker images --format "{{json .}}" 2>/dev/null)
    fi
    
    # Networks
    local networks=()
    if docker network ls --format "{{json .}}" 2>/dev/null | head -1 > /dev/null; then
        while IFS= read -r network; do
            networks+=("$network")
        done < <(docker network ls --format "{{json .}}" 2>/dev/null)
    fi
    
    # Volumes
    local volumes=()
    if docker volume ls --format "{{json .}}" 2>/dev/null | head -1 > /dev/null; then
        while IFS= read -r volume; do
            volumes+=("$volume")
        done < <(docker volume ls --format "{{json .}}" 2>/dev/null)
    fi
    
    # Docker Compose files
    local compose_files=()
    while IFS= read -r file; do
        compose_files+=("\"$file\"")
    done < <(find ~ -maxdepth 3 -name "docker-compose.yml" -o -name "docker-compose.yaml" -o -name "compose.yml" -o -name "compose.yaml" 2>/dev/null)
    
    cat << EOF
{
    "engine": "docker",
    "version": "$docker_version",
    "containers": [$(IFS=,; echo "${containers[*]}")],
    "images": [$(IFS=,; echo "${images[*]}")],
    "networks": [$(IFS=,; echo "${networks[*]}")],
    "volumes": [$(IFS=,; echo "${volumes[*]}")],
    "compose_files": [$(IFS=,; echo "${compose_files[*]}")]
}
EOF
}

# Collect Podman information
collect_podman_info() {
    if ! command_exists podman; then
        return
    fi
    
    log_info "Collecting Podman information..."
    
    local podman_version=$(podman --version 2>/dev/null | awk '{print $3}')
    
    # Running containers
    local containers=()
    if podman ps --format json 2>/dev/null | head -1 > /dev/null; then
        while IFS= read -r container; do
            containers+=("$container")
        done < <(podman ps -a --format json 2>/dev/null)
    fi
    
    # Images
    local images=()
    if podman images --format json 2>/dev/null | head -1 > /dev/null; then
        while IFS= read -r image; do
            images+=("$image")
        done < <(podman images --format json 2>/dev/null)
    fi
    
    cat << EOF
{
    "engine": "podman",
    "version": "$podman_version",
    "containers": [$(IFS=,; echo "${containers[*]}")],
    "images": [$(IFS=,; echo "${images[*]}")]
}
EOF
}

# Collect Kubernetes information
collect_k8s_info() {
    if ! command_exists kubectl; then
        return
    fi
    
    log_info "Collecting Kubernetes information..."
    
    local kubectl_version=$(kubectl version --client --short 2>/dev/null | head -1)
    local contexts=()
    
    if kubectl config get-contexts -o name 2>/dev/null | head -1 > /dev/null; then
        while IFS= read -r context; do
            contexts+=("\"$context\"")
        done < <(kubectl config get-contexts -o name 2>/dev/null)
    fi
    
    local current_context=$(kubectl config current-context 2>/dev/null || echo "none")
    
    cat << EOF
{
    "tool": "kubectl",
    "version": "$kubectl_version",
    "current_context": "$current_context",
    "contexts": [$(IFS=,; echo "${contexts[*]}")]
}
EOF
}

# Main function
main() {
    log_info "Starting container information collection..."
    
    local docker_info=$(collect_docker_info)
    local podman_info=$(collect_podman_info)
    local k8s_info=$(collect_k8s_info)
    
    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$(hostname)",
    "container_runtimes": [
EOF
    
    local first=true
    for info in "$docker_info" "$podman_info" "$k8s_info"; do
        if [ -n "$info" ]; then
            if [ "$first" = false ]; then
                echo ","
            fi
            echo "        $info"
            first=false
        fi
    done
    
    cat << EOF
    ]
}
EOF
    
    log_info "Container information collection complete!"
}

main "$@"
