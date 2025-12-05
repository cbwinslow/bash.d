#!/usr/bin/env bash
#
# Docker Installation Script
#
# Installs Docker and Docker Compose using official .deb packages
# for Debian/Ubuntu systems.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "This script should not be run as root. Please run as a regular user with sudo privileges."
    exit 1
fi

log_info "Starting Docker installation..."

# Check OS
if [[ ! -f /etc/os-release ]]; then
    log_error "Unable to determine OS. /etc/os-release not found."
    exit 1
fi

source /etc/os-release

if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
    log_error "This script only supports Ubuntu and Debian. Detected: $ID"
    exit 1
fi

log_info "Detected OS: $PRETTY_NAME"

# Update package index
log_info "Updating package index..."
sudo apt-get update

# Install prerequisites
log_info "Installing prerequisites..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
log_info "Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$ID/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the Docker repository
log_info "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
log_info "Updating package index with Docker repository..."
sudo apt-get update

# Install Docker Engine
log_info "Installing Docker Engine..."
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Start and enable Docker
log_info "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
log_info "Adding user $USER to docker group..."
sudo usermod -aG docker $USER

# Verify installation
log_info "Verifying Docker installation..."
docker_version=$(docker --version)
compose_version=$(docker compose version)

log_info "Docker installed successfully!"
log_info "  $docker_version"
log_info "  $compose_version"

log_warn "You may need to log out and back in for group changes to take effect."
log_info "Alternatively, run: newgrp docker"

# Test Docker
log_info "Testing Docker with hello-world..."
if sudo docker run hello-world > /dev/null 2>&1; then
    log_info "Docker test successful!"
else
    log_warn "Docker test failed. You may need to troubleshoot."
fi

log_info "Docker installation complete!"
log_info ""
log_info "Next steps:"
log_info "  1. Log out and back in (or run 'newgrp docker')"
log_info "  2. Run 'docker run hello-world' to verify"
log_info "  3. Navigate to your project directory"
log_info "  4. Run 'docker compose up -d' to start services"
