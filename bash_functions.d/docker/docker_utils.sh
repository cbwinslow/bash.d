#!/bin/bash
#===============================================================================
#
#          FILE:  docker_utils.sh
#
#         USAGE:  Automatically sourced by .bashrc
#
#   DESCRIPTION:  Docker utility functions for common docker operations
#
#       OPTIONS:  ---
#  REQUIREMENTS:  docker
#         NOTES:  Enhances docker workflow
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Check if docker is available
if ! command -v docker >/dev/null 2>&1; then
    return 0
fi

#===============================================================================
# DOCKER CONTAINERS
#===============================================================================

# List running containers (nice format)
dps() {
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

# List all containers
dpsa() {
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

# Stop all running containers
dstopall() {
    local containers
    containers=$(docker ps -q)
    
    if [[ -z "$containers" ]]; then
        echo "No running containers."
        return 0
    fi
    
    echo "Stopping all containers..."
    docker stop $containers
}

# Remove all stopped containers
drmall() {
    local containers
    containers=$(docker ps -aq -f status=exited)
    
    if [[ -z "$containers" ]]; then
        echo "No stopped containers to remove."
        return 0
    fi
    
    echo "Removing stopped containers..."
    docker rm $containers
}

# Interactive container selector
dexec() {
    local container="$1"
    local shell="${2:-bash}"
    
    if [[ -z "$container" ]]; then
        if command -v fzf >/dev/null 2>&1; then
            container=$(docker ps --format '{{.Names}}' | fzf --preview 'docker logs --tail 20 {}')
        else
            docker ps --format "{{.ID}}\t{{.Names}}"
            echo -n "Enter container name or ID: "
            read -r container
        fi
    fi
    
    if [[ -n "$container" ]]; then
        docker exec -it "$container" "$shell" 2>/dev/null || docker exec -it "$container" sh
    fi
}

# Container logs
dlogs() {
    local container="$1"
    local lines="${2:-100}"
    
    if [[ -z "$container" ]]; then
        if command -v fzf >/dev/null 2>&1; then
            container=$(docker ps --format '{{.Names}}' | fzf)
        else
            docker ps --format "{{.ID}}\t{{.Names}}"
            echo -n "Enter container name or ID: "
            read -r container
        fi
    fi
    
    if [[ -n "$container" ]]; then
        docker logs --tail "$lines" -f "$container"
    fi
}

# Follow container logs
dlogf() {
    local container="$1"
    
    if [[ -z "$container" ]]; then
        echo "Usage: dlogf <container>"
        return 1
    fi
    
    docker logs -f "$container"
}

# Restart container
drestart() {
    local container="$1"
    
    if [[ -z "$container" ]]; then
        echo "Usage: drestart <container>"
        return 1
    fi
    
    docker restart "$container"
}

#===============================================================================
# DOCKER IMAGES
#===============================================================================

# List images (nice format)
dimages() {
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"
}

# Remove dangling images
dcleanimg() {
    local images
    images=$(docker images -f "dangling=true" -q)
    
    if [[ -z "$images" ]]; then
        echo "No dangling images to remove."
        return 0
    fi
    
    echo "Removing dangling images..."
    docker rmi $images
}

# Pull latest image
dpull() {
    if [[ -z "$1" ]]; then
        echo "Usage: dpull <image>"
        return 1
    fi
    docker pull "$1"
}

# Build image from current directory
dbuild() {
    local tag="${1:-$(basename "$(pwd)")}"
    docker build -t "$tag" .
}

#===============================================================================
# DOCKER CLEANUP
#===============================================================================

# Full docker cleanup (careful!)
dcleanall() {
    echo "This will remove:"
    echo "  - All stopped containers"
    echo "  - All networks not used by containers"
    echo "  - All dangling images"
    echo "  - All build cache"
    echo ""
    echo "Are you sure? (y/n)"
    read -r response
    
    if [[ "$response" =~ ^[Yy] ]]; then
        docker system prune -a -f
        echo "Cleanup complete."
    fi
}

# Show docker disk usage
dspace() {
    docker system df
}

# Detailed space usage
dspacedetail() {
    docker system df -v
}

#===============================================================================
# DOCKER COMPOSE
#===============================================================================

# Docker compose shortcuts
if command -v docker-compose >/dev/null 2>&1 || docker compose version >/dev/null 2>&1; then
    # Detect compose command
    if docker compose version >/dev/null 2>&1; then
        _compose_cmd="docker compose"
    else
        _compose_cmd="docker-compose"
    fi
    
    dcup() {
        $_compose_cmd up -d "$@"
    }
    
    dcdown() {
        $_compose_cmd down "$@"
    }
    
    dcrestart() {
        $_compose_cmd restart "$@"
    }
    
    dclogs() {
        $_compose_cmd logs -f "$@"
    }
    
    dcps() {
        $_compose_cmd ps
    }
    
    dcbuild() {
        $_compose_cmd build "$@"
    }
    
    dcpull() {
        $_compose_cmd pull "$@"
    }
    
    # Export compose functions
    export -f dcup dcdown dcrestart dclogs dcps dcbuild dcpull 2>/dev/null
fi

#===============================================================================
# DOCKER NETWORKING
#===============================================================================

# List networks
dnets() {
    docker network ls
}

# Inspect network
dnetinspect() {
    if [[ -z "$1" ]]; then
        echo "Usage: dnetinspect <network>"
        return 1
    fi
    docker network inspect "$1"
}

# Show containers in a network
dnetcontainers() {
    if [[ -z "$1" ]]; then
        echo "Usage: dnetcontainers <network>"
        return 1
    fi
    docker network inspect "$1" -f '{{range .Containers}}{{.Name}} {{end}}'
}

#===============================================================================
# DOCKER VOLUMES
#===============================================================================

# List volumes
dvols() {
    docker volume ls
}

# Remove dangling volumes
dcleanvols() {
    local volumes
    volumes=$(docker volume ls -f dangling=true -q)
    
    if [[ -z "$volumes" ]]; then
        echo "No dangling volumes to remove."
        return 0
    fi
    
    echo "Removing dangling volumes..."
    docker volume rm $volumes
}

#===============================================================================
# DOCKER UTILITIES
#===============================================================================

# Run temporary container
drun() {
    local image="${1:-ubuntu}"
    local shell="${2:-bash}"
    
    docker run --rm -it "$image" "$shell"
}

# Run temporary container with current dir mounted
drunmount() {
    local image="${1:-ubuntu}"
    local shell="${2:-bash}"
    
    docker run --rm -it -v "$(pwd):/work" -w /work "$image" "$shell"
}

# Get container IP
dip() {
    local container="$1"
    
    if [[ -z "$container" ]]; then
        echo "Usage: dip <container>"
        return 1
    fi
    
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container"
}

# Show container stats
dstats() {
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Live stats
dstatslive() {
    docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

# Copy file from container
dcopy() {
    local container="$1"
    local src="$2"
    local dest="${3:-.}"
    
    if [[ -z "$container" || -z "$src" ]]; then
        echo "Usage: dcopy <container> <source_path> [dest_path]"
        return 1
    fi
    
    docker cp "$container:$src" "$dest"
}

# Copy file to container
dcopyto() {
    local src="$1"
    local container="$2"
    local dest="${3:-/}"
    
    if [[ -z "$src" || -z "$container" ]]; then
        echo "Usage: dcopyto <source_file> <container> [dest_path]"
        return 1
    fi
    
    docker cp "$src" "$container:$dest"
}

#===============================================================================
# DOCKER HELP
#===============================================================================

daliases() {
    echo "Docker Functions Available:"
    echo "==========================="
    echo ""
    echo "Containers:"
    echo "  dps           - List running containers"
    echo "  dpsa          - List all containers"
    echo "  dstopall      - Stop all containers"
    echo "  drmall        - Remove stopped containers"
    echo "  dexec [name]  - Exec into container (fzf)"
    echo "  dlogs [name]  - Show container logs (fzf)"
    echo "  drestart      - Restart container"
    echo ""
    echo "Images:"
    echo "  dimages       - List images"
    echo "  dcleanimg     - Remove dangling images"
    echo "  dpull <img>   - Pull image"
    echo "  dbuild [tag]  - Build from Dockerfile"
    echo ""
    echo "Cleanup:"
    echo "  dcleanall     - Full system cleanup"
    echo "  dspace        - Show disk usage"
    echo ""
    echo "Compose:"
    echo "  dcup          - docker-compose up -d"
    echo "  dcdown        - docker-compose down"
    echo "  dclogs        - docker-compose logs -f"
    echo ""
    echo "Utilities:"
    echo "  drun <img>    - Run temporary container"
    echo "  drunmount     - Run with current dir mounted"
    echo "  dip <name>    - Get container IP"
    echo "  dstats        - Container resource stats"
}

# Export functions
export -f dps dpsa dstopall drmall dexec dlogs dlogf drestart 2>/dev/null
export -f dimages dcleanimg dpull dbuild 2>/dev/null
export -f dcleanall dspace dspacedetail 2>/dev/null
export -f dnets dnetinspect dnetcontainers 2>/dev/null
export -f dvols dcleanvols 2>/dev/null
export -f drun drunmount dip dstats dstatslive dcopy dcopyto 2>/dev/null
export -f daliases 2>/dev/null
