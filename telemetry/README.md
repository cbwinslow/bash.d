# Telemetry & Monitoring System

Comprehensive system for collecting hardware metrics, network traffic, and AI conversation data for analysis and potential training data.

## Features

- **Hardware Monitoring**: CPU, RAM, disk, temperature, GPU
- **Network Monitoring**: Bandwidth, connections, traffic analysis  
- **AI Conversation Storage**: Store AI terminal conversations with responses
- **OpenTelemetry Integration**: Standard metrics collection
- **PostgreSQL Database**: Long-term storage
- **Dashboard UI**: Terminal-based dashboard (Textual)

## Quick Start

```bash
# Install dependencies
cd telemetry
pip install -r requirements.txt

# Setup database
python -m telemetry.db init

# Start collector (runs in background)
python -m telemetry.collector start

# Start dashboard
python -m telemetry.dashboard
```

## Components

| Component | Purpose |
|-----------|---------|
| `telemetry/collector.py` | Background service collecting metrics |
| `telemetry/db.py` | Database models and connections |
| `telemetry/metrics/` | Hardware and network collectors |
| `telemetry/conversations/` | AI conversation storage |
| `telemetry/dashboard.py` | Terminal UI dashboard |

## Configuration

Edit `config.yaml`:

```yaml
database:
  host: localhost
  port: 5432
  name: telemetry
  user: your_user
  password: your_password

collectors:
  hardware:
    enabled: true
    interval: 10
  network:
    enabled: true
    interval: 30

opentelemetry:
  enabled: true
  endpoint: http://localhost:4317
```

## Database Schema

### conversations
- id, tool, model, prompt, response, timestamp, metadata

### hardware_metrics
- id, timestamp, cpu_percent, memory_percent, disk_percent, temperature, gpu_percent

### network_metrics
- id, timestamp, bytes_sent, bytes_recv, connections, bandwidth_up, bandwidth_down

### system_events
- id, timestamp, event_type, severity, message

## Requirements

- Python 3.10+
- PostgreSQL 14+
- psutil, sqlalchemy, asyncpg, opentelemetry-api, textual
