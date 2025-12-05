# Multi-Agentic AI System

A comprehensive, distributed multi-agent AI system for collaborative problem-solving, automation, and intelligent task execution. This system features 100+ specialized AI agents, OpenAI compatibility, MCP protocol support, and democratic agent communication via RabbitMQ.

## 🌟 Features

- **100+ Specialized AI Agents** across 10 categories (Programming, DevOps, Testing, Security, Documentation, Data, Design, Communication, Monitoring, Automation)
- **OpenAI API Compatible** - All agents support OpenAI function calling
- **MCP Protocol** - Model Context Protocol for standardized agent communication
- **A2A Protocol** - Agent-to-Agent communication for collaborative problem solving
- **RabbitMQ Message Queue** - Reliable, scalable message passing between agents
- **Docker-based Infrastructure** - Complete containerized deployment
- **Real-time Monitoring** - Prometheus + Grafana dashboards
- **Pydantic Models** - Type-safe agent definitions with full validation
- **Task Orchestration** - Intelligent task distribution and load balancing
- **Continuous Operation** - Agents loop continuously, always working on available tasks
- **Cloud-ready** - Designed for Cloudflare Workers deployment

## 📋 Table of Contents

- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Agent Categories](#agent-categories)
- [Configuration](#configuration)
- [Usage](#usage)
- [Development](#development)
- [Deployment](#deployment)
- [API Reference](#api-reference)
- [Contributing](#contributing)

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Agent Orchestrator                           │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Task Distribution │ Health Monitoring │ Load Balancing  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Message Queue (RabbitMQ)                      │
│  A2A Protocol │ Task Queue │ Event Bus │ Pub/Sub              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│                         AI Agent Layer                            │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
│  │Programming DevOps │  Testing │  Security│  ...    │            │
│  │ Agents  │  │ Agents  │  │ Agents  │  │ Agents  │            │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘            │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│                      Infrastructure Layer                         │
│  PostgreSQL │ Redis │ MinIO │ Prometheus │ Grafana            │
└──────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/cbwinslow/bash.d.git
cd bash.d

# 2. Install Docker (if not already installed)
./scripts/install/install_docker.sh

# 3. Set up environment
./scripts/install/setup_environment.sh

# 4. Configure API keys
cp .env.example .env
# Edit .env with your API keys

# 5. Start the system
docker compose up -d

# 6. Access the web UI
open http://localhost:8080
```

## 💻 Installation

### Prerequisites

- Ubuntu 20.04+ or Debian 11+ (for Linux)
- Python 3.11+
- Docker 24.0+
- Docker Compose 2.20+
- 4GB+ RAM recommended
- 10GB+ disk space

### Detailed Installation

#### 1. Install Docker

```bash
./scripts/install/install_docker.sh
```

This script will:
- Install Docker Engine from official .deb packages
- Install Docker Compose plugin
- Configure Docker to start on boot
- Add your user to the docker group

#### 2. Setup Environment

```bash
./scripts/install/setup_environment.sh
```

This script will:
- Create Python virtual environment
- Install Python dependencies
- Generate AI agent files
- Create configuration files
- Set up database schemas
- Create monitoring configurations

#### 3. Configure API Keys

Edit the `.env` file with your API keys:

```bash
# AI Provider Keys
OPENROUTER_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here

# Service Passwords
RABBITMQ_PASSWORD=secure_password
POSTGRES_PASSWORD=secure_password
MINIO_PASSWORD=secure_password
GRAFANA_PASSWORD=secure_password
```

#### 4. Start Services

```bash
docker compose up -d
```

This starts:
- RabbitMQ (message queue)
- Redis (caching)
- PostgreSQL (database)
- MinIO (object storage)
- Prometheus (metrics)
- Grafana (dashboards)
- Agent Orchestrator
- Web UI

## 🤖 Agent Categories

### Programming Agents (20)
- Python Backend Developer
- JavaScript Full Stack Developer
- TypeScript Architect
- Rust Systems Programmer
- Go Microservices Developer
- Java Enterprise Developer
- And 14 more...

### DevOps Agents (15)
- Kubernetes Orchestration Specialist
- Docker Container Expert
- Terraform Infrastructure Engineer
- CI/CD Pipeline Architect
- And 11 more...

### Documentation Agents (10)
- Technical Writer
- API Documentation Expert
- Tutorial Creator
- Architecture Documentation Specialist
- And 6 more...

### Testing Agents (10)
- Unit Test Developer
- Integration Test Engineer
- End-to-End Test Specialist
- Performance Test Engineer
- And 6 more...

### Security Agents (10)
- Vulnerability Scanner
- Code Security Reviewer
- Secrets Detection Specialist
- Container Security Expert
- And 6 more...

### Data Agents (10)
- ETL Pipeline Developer
- Data Warehouse Architect
- Stream Processing Engineer
- Data Scientist
- And 6 more...

### Design Agents (5)
- UI/UX Designer
- System Architecture Designer
- Database Schema Designer
- API Design Specialist
- Microservices Architect

### Communication Agents (5)
- Slack Bot Manager
- Email Notification System
- Webhook Manager
- Report Generator
- Chat Interface Manager

### Monitoring Agents (5)
- Application Performance Monitor
- Infrastructure Health Monitor
- Log Aggregation Specialist
- Alert Manager
- Metrics Dashboard Creator

### Automation Agents (10)
- Workflow Orchestrator
- Code Generator
- Release Automation Specialist
- Database Migration Manager
- And 6 more...

## ⚙️ Configuration

### Agent Configuration

Agents are configured via pydantic models in `agents/base.py`:

```python
from agents.base import BaseAgent, AgentType, Task

# Create an agent
agent = BaseAgent(
    name="My Custom Agent",
    type=AgentType.PROGRAMMING,
    description="Custom agent for specific tasks"
)

# Configure
agent.config.model_provider = "openai"
agent.config.model_name = "gpt-4"
agent.config.temperature = 0.7
agent.config.max_tokens = 4096
```

### Orchestration Strategies

Configure in `agents/orchestrator.py`:

```python
from agents.orchestrator import AgentOrchestrator, OrchestrationStrategy

orchestrator = AgentOrchestrator(
    strategy=OrchestrationStrategy.SPECIALIZED,  # or LEAST_BUSY, ROUND_ROBIN, etc.
    max_concurrent_tasks=100,
    health_check_interval=30
)
```

## 📖 Usage

### Submit a Task

```python
from agents.base import Task, TaskPriority
from agents.orchestrator import AgentOrchestrator

# Create orchestrator
orchestrator = AgentOrchestrator()

# Register agents (done automatically on startup)

# Submit task
task = Task(
    title="Build REST API",
    description="Create a RESTful API with authentication",
    priority=TaskPriority.HIGH,
    input_data={
        "language": "python",
        "framework": "fastapi",
        "features": ["auth", "crud", "docs"]
    }
)

task_id = orchestrator.submit_task(task)
```

### Monitor Status

```bash
# Check agent status
docker compose ps

# View logs
docker compose logs -f agent_orchestrator

# Access monitoring
open http://localhost:3000  # Grafana
open http://localhost:9090  # Prometheus
```

### Web UI

Access the web interface at `http://localhost:8080`:

- View active agents
- Monitor task execution
- Check system health
- Access service dashboards

## 🛠️ Development

### Adding New Agents

1. Define agent in `scripts/generate_agents.py`
2. Run generator: `python scripts/simple_agent_generator.py`
3. Implement specific logic in agent file
4. Restart orchestrator

### Running Tests

```bash
# Activate virtual environment
source venv/bin/activate

# Run tests
pytest tests/

# With coverage
pytest --cov=agents tests/
```

### Local Development

```bash
# Start only infrastructure
docker compose up -d rabbitmq redis postgres minio

# Run orchestrator locally
source venv/bin/activate
python -m agents.main
```

## 🚢 Deployment

### Docker Deployment

```bash
# Production build
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Scale agents
docker compose up -d --scale agent_orchestrator=3
```

### Cloudflare Workers

See `docs/cloudflare_deployment.md` for detailed Cloudflare deployment instructions.

Key components:
- Cloudflare Workers for API endpoints
- Cloudflare D1 for database
- Cloudflare R2 for object storage
- Cloudflare Pages for web UI
- Cloudflare Queues for task management

### Kubernetes

See `docs/kubernetes_deployment.md` for Kubernetes deployment with Helm charts.

## 📚 API Reference

### REST API

Base URL: `http://localhost:8000/api/v1`

#### Agents

```
GET    /agents              List all agents
GET    /agents/{id}         Get agent details
POST   /agents              Create agent
PUT    /agents/{id}         Update agent
DELETE /agents/{id}         Delete agent
GET    /agents/{id}/health  Get agent health
```

#### Tasks

```
GET    /tasks               List all tasks
GET    /tasks/{id}          Get task details
POST   /tasks               Submit task
PUT    /tasks/{id}          Update task
DELETE /tasks/{id}          Cancel task
GET    /tasks/{id}/status   Get task status
```

#### Orchestrator

```
GET    /orchestrator/status Get orchestrator status
GET    /orchestrator/metrics Get metrics
POST   /orchestrator/start  Start orchestration
POST   /orchestrator/stop   Stop orchestration
```

### WebSocket API

Connect to: `ws://localhost:8000/ws`

```javascript
const ws = new WebSocket('ws://localhost:8000/ws');

// Subscribe to agent updates
ws.send(JSON.stringify({
    type: 'subscribe',
    channel: 'agents'
}));

// Receive updates
ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log('Agent update:', data);
};
```

## 📊 Monitoring

### Grafana Dashboards

Pre-configured dashboards available at `http://localhost:3000`:

1. **Agent Overview** - All agents status and metrics
2. **Task Execution** - Task completion rates and performance
3. **System Health** - Infrastructure metrics
4. **Performance** - Response times and throughput

### Prometheus Metrics

Available at `http://localhost:9090`:

- `agent_tasks_completed` - Tasks completed per agent
- `agent_tasks_failed` - Failed tasks per agent
- `agent_response_time` - Average response time
- `orchestrator_queue_length` - Pending tasks
- `system_cpu_usage` - CPU usage
- `system_memory_usage` - Memory usage

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- OpenRouter for AI model access
- Cloudflare for edge computing platform
- RabbitMQ for message queue
- The open-source community

## 📧 Support

- GitHub Issues: [Report bugs or request features](https://github.com/cbwinslow/bash.d/issues)
- Documentation: [Full documentation](https://docs.example.com)
- Discord: [Join our community](https://discord.gg/example)

## 🗺️ Roadmap

### Current Status
- [x] Core agent infrastructure
- [x] Task orchestration system
- [x] Docker deployment
- [x] Basic monitoring

### Next Steps
- [ ] Complete all 100 agent implementations
- [ ] Web UI enhancements
- [ ] Cloudflare Workers deployment
- [ ] Advanced agent collaboration patterns
- [ ] Machine learning for task routing
- [ ] Agent performance optimization
- [ ] Comprehensive test suite
- [ ] Production hardening
- [ ] Documentation expansion

---

**Built with ❤️ by the bash.d community**
