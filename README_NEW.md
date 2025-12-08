# bash.d - Modular Bash Configuration with AI Master Agent

A modular bash configuration system featuring an advanced **Master AI Agent** capable of autonomous software development.

## 🤖 Master AI Agent System

The centerpiece of this repository is the **Master AI Agent** - an intelligent system that can create, code, debug, and test complete software applications without human intervention.

### Key Capabilities

- **🎯 Autonomous Development**: Creates complete software projects from requirements
- **👥 Agent Summoning**: Dynamically summons specialized sub-agents (coding, testing, security, DevOps, documentation)
- **🔧 Tool Integration**: Utilizes filesystem, Git, system, and API tools for development
- **🐛 Self-Correction**: Automatically detects errors and summons debugging agents
- **📊 Progress Monitoring**: Tracks project phases and task completion
- **🧠 Learning System**: Learns from successes and failures to improve performance

### Supported Workflows

- **CLI Tool**: Command-line applications
- **API Service**: RESTful API backends
- **Web App**: Full web applications
- **Library**: Reusable code libraries
- **Microservice**: Containerized microservices
- **Full Stack**: Complete full-stack applications
- **Data Pipeline**: Data processing systems
- **ML Model**: Machine learning models

## 🚀 Quick Start

### Installation

```bash
# Clone repository
git clone https://github.com/cbwinslow/bash.d.git
cd bash.d

# Install Python dependencies
pip install -r requirements.txt
```

### Interactive Mode

```bash
# Start interactive mode for guided project creation
python -m agents.main interactive
```

### Command-Line Usage

```bash
# Create a CLI tool
python -m agents.main create \
  --name "File Organizer" \
  --description "Organizes files by extension" \
  --workflow cli_tool \
  --execute

# Create an API service
python -m agents.main create \
  --name "User API" \
  --description "User management REST API" \
  --workflow api_service \
  --requirements api_requirements.json \
  --execute

# Check status
python -m agents.main status

# List projects
python -m agents.main projects
```

### Programmatic Usage

```python
import asyncio
from agents.master_agent import create_autonomous_agent, DevelopmentWorkflow

async def create_my_app():
    # Initialize master agent
    agent = await create_autonomous_agent()
    
    # Create project
    project = await agent.create_project(
        name="File Organizer CLI",
        description="A CLI tool that organizes files by extension",
        workflow=DevelopmentWorkflow.CLI_TOOL,
        requirements={
            "language": "python",
            "features": ["organize_by_extension", "dry_run_mode"],
            "testing": "pytest",
            "cli_framework": "typer"
        }
    )
    
    # Execute autonomously
    success = await agent.execute_project(project.id)
    
    if success:
        print(f"✓ Project completed: {project.name}")
    
    return agent, project

# Run
asyncio.run(create_my_app())
```

## 📚 Documentation

- **[Master Agent User Guide](MASTER_AGENT_GUIDE.md)** - Complete documentation for the AI agent system
- **[Agentic System Overview](README_AGENTIC_SYSTEM.md)** - Multi-agent architecture details
- **[Tools Documentation](docs/TOOLS_README.md)** - Available tools and capabilities
- **[Examples](examples/)** - Example scripts and use cases

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         Master AI Agent                  │
│  • Project Planning                      │
│  • Agent Summoning                       │
│  • Task Coordination                     │
│  • Error Handling                        │
└─────────────────────────────────────────┘
                │
    ┌───────────┼───────────┐
    ▼           ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐
│ Coding │ │Testing │ │Security│
│ Agents │ │ Agents │ │ Agents │
└────────┘ └────────┘ └────────┘
    │           │           │
    └───────────┴───────────┘
                │
        ┌───────────────┐
        │ Tool Registry │
        │ • Filesystem  │
        │ • Git         │
        │ • System      │
        │ • API         │
        └───────────────┘
```

## 🎯 How It Works

1. **Requirement Analysis**: Master Agent analyzes project requirements
2. **Agent Summoning**: Summons appropriate specialized agents (coding, testing, etc.)
3. **Task Decomposition**: Breaks down project into manageable tasks
4. **Parallel Execution**: Agents work on tasks concurrently
5. **Quality Assurance**: Testing and security agents verify quality
6. **Error Handling**: Debugging agents fix issues automatically
7. **Documentation**: Documentation agents generate docs
8. **Completion**: Project delivered with code, tests, and documentation

## 🔧 Project Structure

```
bash.d/
├── agents/                    # AI Agent System
│   ├── master_agent.py       # Master orchestrator
│   ├── base.py               # Base agent classes
│   ├── orchestrator.py       # Task coordination
│   ├── main.py               # CLI entry point
│   ├── programming/          # Coding agents
│   ├── testing/              # Testing agents
│   ├── security/             # Security agents
│   ├── devops/               # DevOps agents
│   └── documentation/        # Documentation agents
├── tools/                     # Tool Registry
│   ├── base.py               # Base tool classes
│   ├── registry.py           # Tool discovery
│   ├── filesystem_tools.py   # File operations
│   ├── git_tools.py          # Version control
│   ├── system_tools.py       # System commands
│   └── ...                   # More tools
├── examples/                  # Usage examples
│   └── master_agent_example.py
├── docs/                      # Documentation
├── MASTER_AGENT_GUIDE.md     # User guide
├── README_AGENTIC_SYSTEM.md  # Architecture docs
└── requirements.txt          # Dependencies
```

## 💡 Examples

### Example 1: Create a CLI Tool

```bash
python -m agents.main create \
  --name "File Organizer" \
  --description "CLI tool to organize files by type" \
  --workflow cli_tool \
  --execute
```

**What happens:**
- Master Agent analyzes requirements
- Summons Programming and Testing agents
- Creates project structure
- Implements CLI functionality
- Generates tests
- Creates documentation
- Completes project autonomously

### Example 2: Build a REST API

```bash
# Create requirements file
cat > api_requirements.json << EOF
{
  "language": "python",
  "framework": "fastapi",
  "features": ["auth", "crud", "validation"],
  "database": "postgresql"
}
EOF

# Create and execute
python -m agents.main create \
  --name "User Management API" \
  --description "API for user CRUD with authentication" \
  --workflow api_service \
  --requirements api_requirements.json \
  --execute
```

**What happens:**
- Summons Programming, Testing, Security, and Documentation agents
- Sets up FastAPI project
- Implements authentication (JWT)
- Creates CRUD endpoints
- Adds input validation
- Writes unit and integration tests
- Performs security audit
- Generates OpenAPI documentation

### Example 3: See It In Action

```bash
# Run the demo
python examples/master_agent_example.py
```

This demonstrates:
- Agent initialization
- Project creation
- Agent summoning
- Task coordination
- Progress tracking

## 🔐 Configuration

### Environment Variables

```bash
# Required: AI model API key
export OPENROUTER_API_KEY="your-key-here"

# Optional: Specific model
export BASHD_AI_MODEL="anthropic/claude-3-sonnet"

# Optional: State directory
export BASHD_STATE_DIR="$HOME/.bash.d/state"
```

### Agent Configuration

```python
from agents.master_agent import MasterAgent
from agents.orchestrator import OrchestrationStrategy

# Create master agent
agent = MasterAgent()

# Customize orchestration
agent.orchestrator.strategy = OrchestrationStrategy.LEAST_BUSY
agent.orchestrator.max_concurrent_tasks = 100
agent.orchestrator.health_check_interval = 60
```

## 📊 Features in Detail

### Agent Types

1. **Programming Agents**: Write code in Python, JavaScript, TypeScript, Rust, Go, etc.
2. **Testing Agents**: Create unit, integration, and E2E tests
3. **Security Agents**: Perform vulnerability scanning and code review
4. **DevOps Agents**: Handle CI/CD, Docker, Kubernetes
5. **Documentation Agents**: Generate README, API docs, tutorials

### Tool Categories

1. **Filesystem Tools**: File creation, reading, writing, deletion
2. **Git Tools**: Version control operations
3. **System Tools**: Command execution, process management
4. **API Tools**: HTTP requests, integrations
5. **Data Tools**: Data processing and transformation
6. **Docker Tools**: Container management

### Development Phases

1. **Planning**: Requirement analysis and resource allocation
2. **Design**: Architecture and technical planning
3. **Implementation**: Code development
4. **Testing**: Test creation and execution
5. **Debugging**: Error detection and fixing
6. **Documentation**: Documentation generation
7. **Deployment**: Deployment preparation
8. **Completed**: Project finished

## 🤝 Contributing

Contributions welcome! Areas for contribution:

- New agent types and specializations
- Additional tools and integrations
- New development workflows
- Documentation improvements
- Bug fixes and optimizations

## 📝 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

- Built on top of OpenRouter for AI model access
- Uses Pydantic for data validation
- Powered by asyncio for concurrent operations
- Inspired by autonomous agent research

## 📧 Support

- **Issues**: [GitHub Issues](https://github.com/cbwinslow/bash.d/issues)
- **Documentation**: [Full Docs](MASTER_AGENT_GUIDE.md)
- **Examples**: [Examples Directory](examples/)

---

**Ready for autonomous software development! 🚀**

Built with ❤️ by the bash.d community
