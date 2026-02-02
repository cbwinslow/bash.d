#!/bin/bash
# ============================================================================
# Docker and Container Utilities
# ============================================================================
# Helper functions for Docker and container management

# Docker cleanup - remove stopped containers
dcleanc() {
    echo -e "${COLOR_CYAN}Removing stopped containers...${COLOR_RESET}"
    docker container prune -f
}

# Docker cleanup - remove unused images
dcleani() {
    echo -e "${COLOR_CYAN}Removing unused images...${COLOR_RESET}"
    docker image prune -f
}

# Docker cleanup - remove unused volumes
dcleanv() {
    echo -e "${COLOR_CYAN}Removing unused volumes...${COLOR_RESET}"
    docker volume prune -f
}

# Docker cleanup - full cleanup
dcleanall() {
    echo -e "${COLOR_CYAN}Performing full Docker cleanup...${COLOR_RESET}"
    docker system prune -af --volumes
}

# Stop all running containers
dstopall() {
    echo -e "${COLOR_CYAN}Stopping all running containers...${COLOR_RESET}"
    docker stop $(docker ps -q) 2>/dev/null || echo "No running containers"
}

# Remove all containers
drmall() {
    echo -e "${COLOR_CYAN}Removing all containers...${COLOR_RESET}"
    docker rm $(docker ps -aq) 2>/dev/null || echo "No containers to remove"
}

# Show Docker disk usage
ddiskusage() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Docker Disk Usage:${COLOR_RESET}"
    docker system df
}

# Enter running container
denter() {
    if [ -z "$1" ]; then
        echo "Usage: denter <container_name_or_id>"
        return 1
    fi
    
    docker exec -it "$1" /bin/bash 2>/dev/null || docker exec -it "$1" /bin/sh
}

# Show container logs with tail
dlogs() {
    if [ -z "$1" ]; then
        echo "Usage: dlogs <container_name_or_id> [lines]"
        return 1
    fi
    
    local container="$1"
    local lines="${2:-100}"
    
    docker logs --tail "$lines" -f "$container"
}

# List Docker networks
dnetworks() {
    docker network ls
}

# Inspect container
dinspect() {
    if [ -z "$1" ]; then
        echo "Usage: dinspect <container_name_or_id>"
        return 1
    fi
    
    docker inspect "$1" | less
}

# Show container resource usage
dstats() {
    docker stats --no-stream
}

# Build Docker image with tag
dbuild() {
    if [ -z "$1" ]; then
        echo "Usage: dbuild <image_name> [dockerfile_path]"
        return 1
    fi
    
    local image="$1"
    local dockerfile="${2:-.}"
    
    docker build -t "$image" "$dockerfile"
}

# Run Docker container with common options
drun() {
    if [ -z "$1" ]; then
        echo "Usage: drun <image_name> [command]"
        return 1
    fi
    
    local image="$1"
    shift
    
    docker run --rm -it "$image" "$@"
}

# Docker compose up
dcup() {
    docker-compose up -d "$@"
}

# Docker compose down
dcdown() {
    docker-compose down "$@"
}

# Docker compose restart
dcrestart() {
    docker-compose restart "$@"
}

# Docker compose logs
dclogs() {
    docker-compose logs -f "$@"
}

# Show images by size
dimages_size() {
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | sort -k 3 -h
}

# Find containers by name pattern
dfind() {
    if [ -z "$1" ]; then
        echo "Usage: dfind <pattern>"
        return 1
    fi
    
    docker ps -a | grep "$1"
}

# Export container as tarball
dexport() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: dexport <container_name> <output.tar>"
        return 1
    fi
    
    docker export "$1" > "$2"
    echo "Exported container to $2"
}

# Import image from tarball
dimport() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: dimport <input.tar> <image_name>"
        return 1
    fi
    
    docker import "$1" "$2"
    echo "Imported image as $2"
}

# Tag image
dtag() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: dtag <source_image> <target_image>"
        return 1
    fi
    
    docker tag "$1" "$2"
    echo "Tagged $1 as $2"
}

# Push image to registry
dpush() {
    if [ -z "$1" ]; then
        echo "Usage: dpush <image_name>"
        return 1
    fi
    
    docker push "$1"
}

# Pull image from registry
dpull() {
    if [ -z "$1" ]; then
        echo "Usage: dpull <image_name>"
        return 1
    fi
    
    docker pull "$1"
}

# Show container IP address
dip() {
    if [ -z "$1" ]; then
        echo "Usage: dip <container_name_or_id>"
        return 1
    fi
    
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
}

# Show Docker version information
dversion() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Docker Version Information:${COLOR_RESET}"
    docker version
}

# Show running containers in formatted view
dps_format() {
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Copy file from container
dcopy_from() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: dcopy_from <container> <source_path> <dest_path>"
        return 1
    fi
    
    docker cp "$1:$2" "$3"
    echo "Copied $2 from container $1 to $3"
}

# Copy file to container
dcopy_to() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: dcopy_to <source_path> <container> <dest_path>"
        return 1
    fi
    
    docker cp "$1" "$2:$3"
    echo "Copied $1 to container $2 at $3"
}
