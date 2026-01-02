#!/bin/bash
docker_clean() {
    echo "Cleaning up Docker resources..."
    docker system prune -af
    docker volume prune -f
    echo "Docker cleanup complete!"
}
