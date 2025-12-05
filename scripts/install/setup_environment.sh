#!/usr/bin/env bash
#
# Environment Setup Script
#
# Sets up the complete environment for the multi-agentic system including:
# - Python virtual environment
# - Dependencies
# - Configuration files
# - Database initialization
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

log_info "Setting up multi-agentic system environment..."
log_info "Project root: $PROJECT_ROOT"

# Check Python version
log_info "Checking Python version..."
python_version=$(python3 --version | cut -d' ' -f2)
log_info "Python version: $python_version"

# Create virtual environment
log_info "Creating Python virtual environment..."
if [[ ! -d "venv" ]]; then
    python3 -m venv venv
    log_info "Virtual environment created"
else
    log_warn "Virtual environment already exists"
fi

# Activate virtual environment
log_info "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
log_info "Upgrading pip..."
pip install --upgrade pip setuptools wheel

# Install dependencies
log_info "Installing Python dependencies..."
pip install -r requirements.txt

# Create necessary directories
log_info "Creating directory structure..."
mkdir -p {
    logs,
    data,
    configs/agents,
    configs/tools,
    configs/crews,
    configs/workflows,
    configs/prometheus,
    configs/grafana/dashboards,
    configs/grafana/datasources,
    configs/postgres,
    configs/nginx,
    web
}

# Copy environment file if it doesn't exist
if [[ ! -f ".env" ]]; then
    log_info "Creating .env file from template..."
    cp .env.example .env
    log_warn "Please edit .env file with your actual configuration values"
else
    log_warn ".env file already exists"
fi

# Generate agents
log_info "Generating AI agents..."
python3 scripts/simple_agent_generator.py

# Create PostgreSQL initialization script
log_info "Creating database initialization script..."
cat > configs/postgres/init.sql << 'EOF'
-- Create agents database schema

-- Agents table
CREATE TABLE IF NOT EXISTS agents (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    config JSONB,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id VARCHAR(255) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    agent_id VARCHAR(255),
    priority VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    input_data JSONB,
    output_data JSONB,
    error TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);

-- Agent metrics table
CREATE TABLE IF NOT EXISTS agent_metrics (
    id SERIAL PRIMARY KEY,
    agent_id VARCHAR(255) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value NUMERIC,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_agents_type ON agents(type);
CREATE INDEX IF NOT EXISTS idx_agents_status ON agents(status);
CREATE INDEX IF NOT EXISTS idx_tasks_agent_id ON tasks(agent_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_agent_metrics_agent_id ON agent_metrics(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_metrics_recorded_at ON agent_metrics(recorded_at);
EOF

# Create Prometheus configuration
log_info "Creating Prometheus configuration..."
cat > configs/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'agent_orchestrator'
    static_configs:
      - targets: ['agent_orchestrator:8000']
  
  - job_name: 'rabbitmq'
    static_configs:
      - targets: ['rabbitmq:15692']
  
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:9187']
  
  - job_name: 'redis'
    static_configs:
      - targets: ['redis:9121']
EOF

# Create Grafana datasource
log_info "Creating Grafana datasources..."
cat > configs/grafana/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
EOF

# Create simple web UI
log_info "Creating basic web UI..."
cat > web/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Multi-Agentic AI System</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 800px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1.1em;
        }
        .status {
            background: #f0f4ff;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .status-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #ddd;
        }
        .status-item:last-child {
            border-bottom: none;
        }
        .badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: 600;
        }
        .badge-success {
            background: #10b981;
            color: white;
        }
        .services {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        .service-card {
            background: #f8fafc;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            transition: transform 0.2s;
        }
        .service-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 20px rgba(0,0,0,0.1);
        }
        .service-card h3 {
            color: #667eea;
            margin-bottom: 10px;
        }
        .service-card a {
            color: #764ba2;
            text-decoration: none;
            font-weight: 600;
        }
        .service-card a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🤖 Multi-Agentic AI System</h1>
        <p class="subtitle">Distributed AI Agents for Collaborative Problem Solving</p>
        
        <div class="status">
            <div class="status-item">
                <span>System Status</span>
                <span class="badge badge-success">Running</span>
            </div>
            <div class="status-item">
                <span>Active Agents</span>
                <span><strong>10</strong></span>
            </div>
            <div class="status-item">
                <span>Tasks Completed</span>
                <span><strong>0</strong></span>
            </div>
        </div>

        <h2 style="margin-top: 30px; color: #667eea;">📊 Services</h2>
        <div class="services">
            <div class="service-card">
                <h3>RabbitMQ</h3>
                <p><a href="http://localhost:15672" target="_blank">Management UI</a></p>
                <small>User: admin</small>
            </div>
            <div class="service-card">
                <h3>Grafana</h3>
                <p><a href="http://localhost:3000" target="_blank">Dashboards</a></p>
                <small>User: admin</small>
            </div>
            <div class="service-card">
                <h3>Prometheus</h3>
                <p><a href="http://localhost:9090" target="_blank">Metrics</a></p>
            </div>
            <div class="service-card">
                <h3>MinIO</h3>
                <p><a href="http://localhost:9001" target="_blank">Console</a></p>
                <small>User: minioadmin</small>
            </div>
        </div>

        <div style="margin-top: 30px; padding: 20px; background: #fef3c7; border-radius: 10px;">
            <strong>⚠️ Getting Started:</strong>
            <p style="margin-top: 10px; line-height: 1.6;">
                This is a basic web interface. For full functionality, configure your API keys in <code>.env</code>
                and access the individual services above.
            </p>
        </div>
    </div>
</body>
</html>
EOF

log_info "✅ Environment setup complete!"
log_info ""
log_info "Next steps:"
log_info "  1. Edit .env file with your API keys and passwords"
log_info "  2. Run: docker compose up -d"
log_info "  3. Access web UI: http://localhost:8080"
log_info "  4. Access Grafana: http://localhost:3000"
log_info "  5. Access RabbitMQ: http://localhost:15672"
log_info ""
log_info "To start the system: ./scripts/install/start_system.sh"
