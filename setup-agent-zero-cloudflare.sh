#!/bin/bash

# Agent Zero + Cloudflare Tunnels Automated Setup Script
# This script automates the deployment of Agent Zero with Cloudflare Tunnels

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
AGENT_ZERO_PORT=50001
CLOUDFLARE_TUNNEL_NAME="agent-zero-tunnel"
CLOUDFLARE_DOMAIN=""
DOCKER_COMPOSE_FILE="docker-compose.yml"
CLOUDFLARED_CONFIG_DIR="$HOME/.cloudflared"
CLOUDFLARED_CONFIG_FILE="$CLOUDFLARED_CONFIG_DIR/config.yml"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies
install_dependencies() {
    print_status "Checking dependencies..."
    
    # Check for Docker
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check for Docker Compose
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        echo "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Check for curl
    if ! command_exists curl; then
        print_status "Installing curl..."
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command_exists yum; then
            sudo yum install -y curl
        elif command_exists brew; then
            brew install curl
        else
            print_error "Cannot install curl automatically. Please install it manually."
            exit 1
        fi
    fi
    
    print_success "All dependencies are installed!"
}

# Function to install cloudflared
install_cloudflared() {
    print_status "Installing cloudflared..."
    
    if command_exists cloudflared; then
        print_success "cloudflared is already installed!"
        return
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        arm*) ARCH="arm" ;;
        *) print_error "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    # Detect OS
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    # Download cloudflared
    CLOUDFLARED_VERSION="2024.12.1"
    DOWNLOAD_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-${OS}-${ARCH}"
    
    print_status "Downloading cloudflared from $DOWNLOAD_URL..."
    curl -L "$DOWNLOAD_URL" -o cloudflared
    chmod +x cloudflared
    
    # Move to system directory
    if command_exists sudo; then
        sudo mv cloudflared /usr/local/bin/
    else
        mkdir -p ~/bin
        mv cloudflared ~/bin/
        echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
    fi
    
    print_success "cloudflared installed successfully!"
}

# Function to create Docker Compose file
create_docker_compose() {
    print_status "Creating Docker Compose configuration..."
    
    cat > "$DOCKER_COMPOSE_FILE" << 'EOF'
version: '3.8'

services:
  agent-zero:
    image: agent0ai/agent-zero:latest
    container_name: agent-zero
    ports:
      - "50001:80"
    environment:
      - NODE_ENV=production
    volumes:
      - agent-zero-data:/app/data
      - agent-zero-logs:/app/logs
    restart: unless-stopped
    networks:
      - agent-zero-network

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared-tunnel
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    environment:
      - CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    restart: unless-stopped
    depends_on:
      - agent-zero
    networks:
      - agent-zero-network

volumes:
  agent-zero-data:
    driver: local
  agent-zero-logs:
    driver: local

networks:
  agent-zero-network:
    driver: bridge
EOF
    
    print_success "Docker Compose file created!"
}

# Function to setup Cloudflare tunnel
setup_cloudflare_tunnel() {
    print_status "Setting up Cloudflare tunnel..."
    
    # Create config directory
    mkdir -p "$CLOUDFLARED_CONFIG_DIR"
    
    # Authenticate with Cloudflare
    print_status "Please authenticate with Cloudflare:"
    cloudflared tunnel login
    
    # Create tunnel
    print_status "Creating tunnel: $CLOUDFLARE_TUNNEL_NAME"
    cloudflared tunnel create "$CLOUDFLARE_TUNNEL_NAME"
    
    # Get tunnel UUID
    TUNNEL_UUID=$(cloudflared tunnel list | grep "$CLOUDFLARE_TUNNEL_NAME" | awk '{print $2}')
    
    # Create config file
    cat > "$CLOUDFLARED_CONFIG_FILE" << EOF
tunnel: $TUNNEL_UUID
credentials-file: $CLOUDFLARED_CONFIG_DIR/$TUNNEL_UUID.json

ingress:
  - hostname: ${CLOUDFLARE_DOMAIN}
    service: http://agent-zero:80
  - service: http_status:404
EOF
    
    print_success "Cloudflare tunnel configured!"
    print_status "Tunnel UUID: $TUNNEL_UUID"
    
    # Generate tunnel token
    TUNNEL_TOKEN=$(cloudflared tunnel token "$CLOUDFLARE_TUNNEL_NAME")
    echo "CLOUDFLARE_TUNNEL_TOKEN=$TUNNEL_TOKEN" > .env
    
    print_success "Tunnel token generated and saved to .env file!"
}

# Function to create .env file template
create_env_template() {
    if [ ! -f .env ]; then
        cat > .env << 'EOF'
# Cloudflare Tunnel Configuration
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token_here

# Agent Zero Configuration
AGENT_ZERO_PORT=50001

# Custom Domain (optional)
CLOUDFLARE_DOMAIN=your-domain.com
EOF
        print_warning "Please edit .env file with your configuration before running."
    fi
}

# Function to start services
start_services() {
    print_status "Starting Agent Zero and Cloudflare tunnel..."
    
    # Load environment variables
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
    fi
    
    # Start services
    docker-compose up -d
    
    print_success "Services started successfully!"
    print_status "Agent Zero is accessible at: http://localhost:$AGENT_ZERO_PORT"
    
    if [ ! -z "$CLOUDFLARE_DOMAIN" ]; then
        print_status "Remote access: https://$CLOUDFLARE_DOMAIN"
    fi
}

# Function to verify setup
verify_setup() {
    print_status "Verifying setup..."
    
    # Check if containers are running
    if docker ps | grep -q "agent-zero"; then
        print_success "Agent Zero container is running!"
    else
        print_error "Agent Zero container is not running!"
        return 1
    fi
    
    if docker ps | grep -q "cloudflared-tunnel"; then
        print_success "Cloudflare tunnel container is running!"
    else
        print_error "Cloudflare tunnel container is not running!"
        return 1
    fi
    
    # Check if port is accessible
    sleep 10
    if curl -s "http://localhost:$AGENT_ZERO_PORT" > /dev/null; then
        print_success "Agent Zero is responding on port $AGENT_ZERO_PORT!"
    else
        print_warning "Agent Zero is not yet responding (this may be normal during startup)"
    fi
    
    print_success "Setup verification completed!"
}

# Function to show next steps
show_next_steps() {
    print_success "Setup completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Access Agent Zero at: http://localhost:$AGENT_ZERO_PORT"
    echo "2. Configure your AI provider in the Agent Zero settings"
    echo "3. Start using Agent Zero!"
    echo
    echo "Useful commands:"
    echo "- View logs: docker-compose logs -f"
    echo "- Stop services: docker-compose down"
    echo "- Restart services: docker-compose restart"
    echo "- Check status: docker-compose ps"
    echo
    echo "For Cloudflare tunnel management:"
    echo "- List tunnels: cloudflared tunnel list"
    echo "- Tunnel status: cloudflared tunnel info $CLOUDFLARE_TUNNEL_NAME"
}

# Main function
main() {
    echo "=========================================="
    echo "Agent Zero + Cloudflare Tunnels Setup"
    echo "=========================================="
    echo
    
    # Check if running as root (warn against it)
    if [ "$EUID" -eq 0 ]; then
        print_warning "This script should not be run as root for security reasons."
        print_warning "Please run as a regular user with sudo privileges."
        exit 1
    fi
    
    # Parse command line arguments
    case "${1:-}" in
        "deps"|"dependencies")
            install_dependencies
            exit 0
            ;;
        "cloudflared")
            install_cloudflared
            exit 0
            ;;
        "tunnel")
            setup_cloudflare_tunnel
            exit 0
            ;;
        "start")
            start_services
            exit 0
            ;;
        "verify")
            verify_setup
            exit 0
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  deps, dependencies  - Install dependencies only"
            echo "  cloudflared         - Install cloudflared only"
            echo "  tunnel              - Setup Cloudflare tunnel only"
            echo "  start               - Start services only"
            echo "  verify              - Verify setup only"
            echo "  help                - Show this help message"
            echo
            echo "If no command is specified, the full setup process will run."
            exit 0
            ;;
    esac
    
    # Full setup process
    install_dependencies
    install_cloudflared
    create_docker_compose
    create_env_template
    
    echo
    print_warning "Before proceeding with tunnel setup, please ensure:"
    echo "1. You have a Cloudflare account"
    echo "2. Your domain is pointing to Cloudflare nameservers"
    echo "3. You have edited the .env file with your domain (optional)"
    echo
    read -p "Do you want to continue with Cloudflare tunnel setup? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_cloudflare_tunnel
        start_services
        verify_setup
        show_next_steps
    else
        print_status "Skipping Cloudflare tunnel setup."
        print_status "You can run '$0 tunnel' later to set it up."
        echo
        read -p "Do you want to start Agent Zero without Cloudflare tunnel? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Create a simple docker-compose without cloudflared
            cat > "$DOCKER_COMPOSE_FILE" << 'EOF'
version: '3.8'

services:
  agent-zero:
    image: agent0ai/agent-zero:latest
    container_name: agent-zero
    ports:
      - "50001:80"
    environment:
      - NODE_ENV=production
    volumes:
      - agent-zero-data:/app/data
      - agent-zero-logs:/app/logs
    restart: unless-stopped

volumes:
  agent-zero-data:
    driver: local
  agent-zero-logs:
    driver: local
EOF
            start_services
            verify_setup
            show_next_steps
        fi
    fi
}

# Run main function
main "$@"