#!/usr/bin/env bash
#
# Stop Autonomous Application Builder
#

set -e

GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

log_info "🛑 Stopping Autonomous Application Builder System..."

# Stop API server
if [ -f /tmp/app_builder_api.pid ]; then
    API_PID=$(cat /tmp/app_builder_api.pid)
    if kill -0 $API_PID 2>/dev/null; then
        log_info "Stopping API server (PID: $API_PID)..."
        kill $API_PID
        rm /tmp/app_builder_api.pid
    fi
fi

# Stop Docker services
log_info "Stopping Docker services..."
docker compose down

log_info "✓ System stopped successfully"
