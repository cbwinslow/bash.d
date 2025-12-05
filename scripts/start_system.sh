#!/usr/bin/env bash
"""
Quick Start Script for Multi-Agentic System

This script provides an easy way to start the entire system.
"""

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

log_info "🚀 Starting Multi-Agentic AI System..."

# Check if .env exists
if [[ ! -f ".env" ]]; then
    log_error ".env file not found!"
    log_info "Creating .env from template..."
    cp .env.example .env
    log_warn "Please edit .env file with your API keys before continuing"
    log_info "Then run this script again"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed!"
    log_info "Run: ./scripts/install/install_docker.sh"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    log_error "Docker is not running!"
    log_info "Please start Docker and try again"
    exit 1
fi

# Pull latest images
log_info "📦 Pulling Docker images..."
docker compose pull

# Start services
log_info "🐳 Starting Docker containers..."
docker compose up -d

# Wait for services to be ready
log_info "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
log_info "🔍 Checking service health..."

services=("rabbitmq" "redis" "postgres" "minio" "prometheus" "grafana")
all_healthy=true

for service in "${services[@]}"; do
    if docker compose ps | grep "$service" | grep -q "Up"; then
        log_info "  ✓ $service is running"
    else
        log_warn "  ✗ $service is not running"
        all_healthy=false
    fi
done

if [ "$all_healthy" = true ]; then
    log_info "✅ All services are running!"
else
    log_warn "Some services may not be running properly"
    log_info "Check logs with: docker compose logs"
fi

# Display access information
log_info ""
log_info "🌐 Access Points:"
log_info "  Web UI:        http://localhost:8080"
log_info "  Grafana:       http://localhost:3000 (admin/admin)"
log_info "  Prometheus:    http://localhost:9090"
log_info "  RabbitMQ:      http://localhost:15672 (admin/[password from .env])"
log_info "  MinIO:         http://localhost:9001 (minioadmin/[password from .env])"
log_info ""
log_info "📊 Useful Commands:"
log_info "  View logs:     docker compose logs -f"
log_info "  Stop system:   docker compose down"
log_info "  Restart:       docker compose restart"
log_info "  Status:        docker compose ps"
log_info ""
log_info "📖 Documentation: README_AGENTIC_SYSTEM.md"
log_info ""
log_info "✨ System started successfully!"
