# Master AI Agent - User Guide

## Overview

The Master AI Agent is an autonomous software development system that can create, code, debug, and test complete software applications without human intervention. It achieves this by:

1. **Summoning specialized sub-agents** for specific tasks (coding, testing, security, etc.)
2. **Coordinating agent teams** to work together on complex projects
3. **Using available tools** for code manipulation, testing, and deployment
4. **Self-correcting** through debugging and retry mechanisms
5. **Learning** from successes and failures to improve over time

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Master AI Agent                          │
│  • Project Planning                                          │
│  • Agent Summoning                                           │
│  • Task Coordination                                         │
│  • Progress Monitoring                                       │
│  • Error Handling                                            │
└─────────────────────────────────────────────────────────────┘
                           │
                           ├─────────────┬─────────────┬──────────
                           ▼             ▼             ▼
                    ┌──────────┐  ┌──────────┐  ┌──────────┐
                    │ Coding   │  │ Testing  │  │ Security │
                    │ Agents   │  │ Agents   │  │ Agents   │
                    └──────────┘  └──────────┘  └──────────┘
                           │             │             │
                           └─────────────┴─────────────┘
                                      │
                           ┌──────────────────────┐
                           │   Tool Registry      │
                           │  • Filesystem        │
                           │  • Git               │
                           │  • System            │
                           │  • API               │
                           └──────────────────────┘
```

## Key Concepts

### 1. Master Agent
The central orchestrator that manages the entire development process. It:
- Analyzes requirements
- Creates development plans
- Summons and coordinates sub-agents
- Monitors progress and quality
- Handles errors and failures

### 2. Sub-Agents
Specialized agents summoned by the Master Agent for specific tasks:
- **Programming Agents**: Write code in various languages
- **Testing Agents**: Create and run tests
- **Security Agents**: Perform security analysis
- **DevOps Agents**: Handle deployment and infrastructure
- **Documentation Agents**: Generate documentation

### 3. Development Workflows
Pre-defined workflows for common project types:
- **web_app**: Full web application with frontend and backend
- **api_service**: RESTful API service
- **cli_tool**: Command-line tool
- **library**: Reusable library/package
- **microservice**: Containerized microservice
- **full_stack**: Complete full-stack application
- **data_pipeline**: Data processing pipeline
- **ml_model**: Machine learning model

### 4. Project Phases
Every project goes through these phases:
1. **Planning**: Requirement analysis
2. **Design**: Architecture and planning
3. **Implementation**: Code development
4. **Testing**: Test creation and execution
5. **Debugging**: Error fixing
6. **Documentation**: Documentation generation
7. **Deployment**: Deployment preparation
8. **Completed**: Project finished

## Installation

### Prerequisites
```bash
# Python 3.11+
python --version

# Install dependencies
pip install -r requirements.txt
```

### Verify Installation
```bash
# Test the master agent
python -m agents.main --help
```

## Usage

### Interactive Mode

The easiest way to use the Master Agent is through interactive mode:

```bash
python -m agents.main interactive
```

This will launch an interactive menu where you can:
1. Create new projects
2. Execute projects
3. View status
4. List projects

### Command-Line Mode

#### Create a Project

```bash
# Basic project creation
python -m agents.main create \
  --name "My REST API" \
  --description "A RESTful API for user management" \
  --workflow api_service

# With requirements file
python -m agents.main create \
  --name "E-commerce API" \
  --description "Full-featured e-commerce backend" \
  --workflow api_service \
  --requirements requirements.json \
  --execute
```

#### Requirements File Format

Create a `requirements.json` file:

```json
{
  "language": "python",
  "framework": "fastapi",
  "database": "postgresql",
  "features": [
    "authentication",
    "user_management",
    "product_catalog",
    "order_processing",
    "payment_integration"
  ],
  "endpoints": [
    "/users",
    "/products",
    "/orders",
    "/payments"
  ],
  "authentication": "jwt",
  "testing": "pytest",
  "documentation": "openapi"
}
```

#### Execute a Project

```bash
# Execute by project ID
python -m agents.main execute project_20231208_143052
```

#### Check Status

```bash
# View master agent and all projects status
python -m agents.main status
```

#### List Projects

```bash
# List all active and completed projects
python -m agents.main projects
```

## Examples

### Example 1: Create a Simple CLI Tool

```bash
python -m agents.main create \
  --name "File Organizer" \
  --description "CLI tool to organize files by type" \
  --workflow cli_tool \
  --execute
```

The Master Agent will:
1. Analyze the requirements
2. Summon a Programming Agent and Testing Agent
3. Create project structure
4. Implement the CLI functionality
5. Generate tests
6. Create documentation
7. Complete the project autonomously

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

# Create and execute project
python -m agents.main create \
  --name "User Management API" \
  --description "API for user CRUD operations with authentication" \
  --workflow api_service \
  --requirements api_requirements.json \
  --execute
```

The Master Agent will:
1. Summon Programming, Testing, Security, and Documentation Agents
2. Set up FastAPI project structure
3. Implement authentication
4. Create CRUD endpoints
5. Add input validation
6. Write unit and integration tests
7. Perform security audit
8. Generate API documentation

### Example 3: Create a Microservice

```bash
cat > microservice_requirements.json << EOF
{
  "language": "python",
  "framework": "fastapi",
  "containerization": "docker",
  "features": ["health_checks", "metrics", "logging"],
  "deployment": "kubernetes"
}
EOF

python -m agents.main create \
  --name "Payment Service" \
  --description "Microservice for payment processing" \
  --workflow microservice \
  --requirements microservice_requirements.json \
  --execute
```

The Master Agent will:
1. Summon Programming, Testing, Security, DevOps, and Documentation Agents
2. Create microservice with FastAPI
3. Add health checks and metrics
4. Implement payment logic
5. Create Dockerfile
6. Set up Kubernetes manifests
7. Write tests
8. Generate documentation

## Advanced Features

### Agent Summoning

The Master Agent automatically determines which agents to summon based on the workflow type. You can also customize this:

```python
from agents.master_agent import MasterAgent, create_autonomous_agent
from agents.base import AgentType

# Create master agent
agent = await create_autonomous_agent()

# Manually summon additional agents
coding_agents = agent.summon_agent(AgentType.PROGRAMMING, count=3)
testing_agents = agent.summon_agent(AgentType.TESTING, count=2)
```

### Project Monitoring

Monitor project progress programmatically:

```python
# Get project status
project = agent.active_projects['project_id']
progress = project.get_progress()

print(f"Phase: {progress['phase']}")
print(f"Progress: {progress['progress_percent']}%")
print(f"Tasks: {progress['tasks_completed']}/{progress['tasks_total']}")
```

### Error Handling

The Master Agent automatically handles failures:

1. **Detection**: Monitors task execution for failures
2. **Analysis**: Summons debugging agents to analyze errors
3. **Correction**: Creates debugging tasks to fix issues
4. **Retry**: Retries failed tasks after debugging
5. **Learning**: Records failure patterns for future improvement

### Learning System

The Master Agent learns from each project:

```python
# View success patterns
for pattern in agent.success_patterns:
    print(f"Workflow: {pattern['workflow']}")
    print(f"Duration: {pattern['duration']}s")
    print(f"Tasks: {pattern['tasks_count']}")

# View failure patterns
for pattern in agent.failure_patterns:
    print(f"Workflow: {pattern['workflow']}")
    print(f"Errors: {pattern['errors']}")
```

## Tool Integration

The Master Agent uses various tools for development tasks:

### Available Tool Categories

1. **Filesystem Tools**: File creation, reading, writing
2. **Git Tools**: Version control operations
3. **System Tools**: Command execution, process management
4. **API Tools**: HTTP requests, API integrations
5. **Data Tools**: Data processing and transformation
6. **Docker Tools**: Container management
7. **Text Tools**: Text processing and manipulation

### Using Tools Programmatically

```python
from tools.registry import get_tool

# Get a specific tool
file_tool = get_tool("write_file")

# Use the tool
result = await file_tool.execute(
    path="src/main.py",
    content="print('Hello World')"
)
```

## Best Practices

### 1. Clear Requirements

Provide clear, detailed requirements in your requirements file:

```json
{
  "language": "python",
  "framework": "fastapi",
  "features": ["feature1", "feature2"],
  "testing": "pytest",
  "coverage_target": 80
}
```

### 2. Appropriate Workflow Selection

Choose the workflow that best matches your project:
- Simple scripts → `cli_tool`
- API services → `api_service`
- Complex applications → `full_stack`
- Containerized services → `microservice`

### 3. Monitor Progress

Regularly check project status:

```bash
# Check status every few minutes
watch -n 60 'python -m agents.main status'
```

### 4. Review Outputs

After completion, review the generated code:
- Check code quality
- Verify tests pass
- Review documentation
- Test functionality

## Troubleshooting

### Project Not Starting

```bash
# Check master agent status
python -m agents.main status

# Verify agents are available
# Look for "Available Agents" in status output
```

### Tasks Failing

The Master Agent should automatically handle failures, but you can:

1. Check error logs
2. Review the project's error_log
3. Manually summon debugging agents

### Performance Issues

If execution is slow:

1. Reduce concurrency: Modify `orchestrator.max_concurrent_tasks`
2. Summon fewer agents: Adjust workflow agent counts
3. Check system resources

## API Reference

### MasterAgent Class

```python
class MasterAgent(BaseAgent):
    """
    Master orchestrator for autonomous development
    
    Methods:
        summon_agent(agent_type, count) -> List[BaseAgent]
            Summon specialized sub-agents
        
        create_project(name, description, workflow, requirements) -> SoftwareProject
            Create and initialize a new project
        
        execute_project(project_id) -> bool
            Execute a project autonomously
        
        get_status() -> Dict
            Get master agent status
    """
```

### SoftwareProject Class

```python
class SoftwareProject:
    """
    Represents a software development project
    
    Attributes:
        id: Unique project identifier
        name: Project name
        phase: Current development phase
        tasks: List of pending tasks
        completed_tasks: List of completed tasks
    
    Methods:
        update_phase(phase)
            Update project phase
        
        get_progress() -> Dict
            Get project progress summary
    """
```

## Configuration

### Environment Variables

```bash
# OpenRouter API key for AI models
export OPENROUTER_API_KEY="your-key"

# Optional: Specific model
export BASHD_AI_MODEL="anthropic/claude-3-sonnet"

# State directory
export BASHD_STATE_DIR="$HOME/.bash.d/state"
```

### Agent Configuration

Modify agent settings in code:

```python
agent = await create_autonomous_agent()

# Adjust orchestration strategy
agent.orchestrator.strategy = OrchestrationStrategy.LEAST_BUSY

# Adjust concurrency
agent.orchestrator.max_concurrent_tasks = 100

# Adjust health check interval
agent.orchestrator.health_check_interval = 60
```

## Security Considerations

1. **API Keys**: Store API keys securely in environment variables
2. **Code Review**: Always review generated code before deployment
3. **Testing**: Ensure all tests pass before using in production
4. **Isolation**: Run projects in isolated environments
5. **Permissions**: Limit file system and network access as needed

## Performance Optimization

1. **Agent Pool Size**: Balance agent count vs. resources
2. **Task Batching**: Group related tasks for efficiency
3. **Caching**: Cache frequently used tools and results
4. **Parallel Execution**: Leverage async for concurrent operations

## Contributing

To extend the Master Agent:

1. Add new workflows in `agents/master_agent.py`
2. Create specialized agents in appropriate subdirectories
3. Add new tools in `tools/`
4. Update documentation

## Support

- GitHub Issues: [Report bugs or request features]
- Documentation: [Full documentation]
- Community: [Join discussions]

## Roadmap

### Current Capabilities
- ✅ Autonomous project creation
- ✅ Agent summoning and coordination
- ✅ Tool integration
- ✅ Error handling and debugging
- ✅ Progress monitoring

### Future Enhancements
- [ ] Advanced learning and optimization
- [ ] Multi-project coordination
- [ ] Code quality metrics
- [ ] Performance profiling
- [ ] Cloud deployment integration
- [ ] Real-time collaboration
- [ ] Plugin system for custom agents

## License

MIT License - See LICENSE file for details

---

**Built with ❤️ by the bash.d community**
