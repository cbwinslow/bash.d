#!/usr/bin/env bash
#
# Start Autonomous Application Builder
#
# This script starts the complete autonomous application builder system
# including the web UI, API server, and agent orchestrator.
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║        🤖 AUTONOMOUS APPLICATION BUILDER 🤖                  ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║        Multi-Agentic AI System for Full App Development     ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

log_header

log_info "🚀 Starting Autonomous Application Builder System..."

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v python3 &> /dev/null; then
    log_error "Python 3 is not installed!"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed!"
    log_info "Run: ./scripts/install/install_docker.sh"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker is not running!"
    log_info "Please start Docker and try again"
    exit 1
fi

# Check if .env exists
if [[ ! -f ".env" ]]; then
    log_warn ".env file not found!"
    log_info "Creating .env from template..."
    cp .env.example .env
    log_warn "Please edit .env file with your API keys"
fi

# Check if virtual environment exists
if [[ ! -d "venv" ]]; then
    log_info "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
log_info "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
log_info "Installing Python dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt

# Start Docker services
log_info "🐳 Starting Docker services..."
docker compose up -d rabbitmq redis postgres minio prometheus grafana

# Wait for services to be ready
log_info "⏳ Waiting for services to be ready..."
sleep 15

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

if [ "$all_healthy" = false ]; then
    log_error "Some services failed to start. Check logs with: docker compose logs"
    exit 1
fi

# Start API server in background
log_info "🌐 Starting API server..."
python -m agents.api_server &
API_PID=$!
echo $API_PID > /tmp/app_builder_api.pid

# Wait for API to be ready
log_info "⏳ Waiting for API server to be ready..."
sleep 5

# Check if API is running
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    log_error "API server failed to start"
    exit 1
fi

log_info "✓ API server is running"

# Display information
echo ""
log_info "═══════════════════════════════════════════════════════════"
log_info "✨ Autonomous Application Builder is ready! ✨"
log_info "═══════════════════════════════════════════════════════════"
echo ""
log_info "🌐 Access Points:"
log_info "  Web UI:        http://localhost:8080"
log_info "  API Server:    http://localhost:8000"
log_info "  API Docs:      http://localhost:8000/docs"
log_info "  Grafana:       http://localhost:3000"
log_info "  Prometheus:    http://localhost:9090"
log_info "  RabbitMQ:      http://localhost:15672"
log_info "  MinIO:         http://localhost:9001"
echo ""
log_info "📖 Documentation:"
log_info "  Quick Start:   AUTONOMOUS_APP_BUILDER.md"
log_info "  Full Docs:     README_AGENTIC_SYSTEM.md"
echo ""
log_info "🎯 Quick Start:"
log_info "  1. Open http://localhost:8080 in your browser"
log_info "  2. Describe your application idea"
log_info "  3. Click '🚀 GO - Build My Application'"
log_info "  4. Watch the agents build it autonomously!"
echo ""
log_info "💻 CLI Usage:"
log_info "  Interactive:   python scripts/build_app.py interactive"
log_info "  Demo:          python scripts/build_app.py demo"
log_info "  From file:     python scripts/build_app.py from-file spec.json"
echo ""
log_info "🛠️ Useful Commands:"
log_info "  View logs:     docker compose logs -f"
log_info "  Stop system:   ./scripts/stop_app_builder.sh"
log_info "  Status:        docker compose ps"
echo ""
log_info "═══════════════════════════════════════════════════════════"

# Keep script running to show logs
log_info "Press Ctrl+C to stop the system"
echo ""

# Trap Ctrl+C
trap 'echo ""; log_info "Shutting down..."; kill $API_PID 2>/dev/null; docker compose down; log_info "System stopped"; exit 0' INT

# Follow API logs
tail -f /dev/null
