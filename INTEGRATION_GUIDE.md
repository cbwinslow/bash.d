# Integration Guide: Autonomous Application Builder

This guide explains how to integrate the Autonomous Application Builder into your workflow and extend it with custom agents and capabilities.

## Table of Contents

- [Getting Started](#getting-started)
- [Architecture Overview](#architecture-overview)
- [Creating Custom Agents](#creating-custom-agents)
- [Adding New Capabilities](#adding-new-capabilities)
- [Extending the Build Process](#extending-the-build-process)
- [API Integration](#api-integration)
- [WebSocket Events](#websocket-events)
- [Testing Your Extensions](#testing-your-extensions)

## Getting Started

### Prerequisites

- Python 3.11+
- Docker and Docker Compose
- Node.js 18+ (for UI development)
- Basic understanding of async Python

### Installation

```bash
# Clone the repository
git clone https://github.com/cbwinslow/bash.d.git
cd bash.d

# Install dependencies
pip install -r requirements.txt

# Start the system
./scripts/start_app_builder.sh
```

## Architecture Overview

The system consists of several key components:

```
┌─────────────────────────────────────────────────────────────┐
│                  Application Builder                         │
│  - Democratic decision making                                │
│  - Task decomposition                                        │
│  - Phase orchestration                                       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                  Agent Orchestrator                          │
│  - Agent registration                                        │
│  - Task distribution                                         │
│  - Health monitoring                                         │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│              Specialized Agents (100+)                       │
│  Programming | DevOps | Testing | Security | etc.           │
└─────────────────────────────────────────────────────────────┘
```

## Creating Custom Agents

### Basic Agent Structure

```python
from agents.base import BaseAgent, AgentType, AgentCapability, Task
from typing import Dict, Any

class MyCustomAgent(BaseAgent):
    """
    Custom agent for specific functionality
    """
    
    def __init__(self, **data):
        # Set default values
        if "name" not in data:
            data["name"] = "My Custom Agent"
        if "type" not in data:
            data["type"] = AgentType.PROGRAMMING  # or other type
        if "description" not in data:
            data["description"] = "Description of what this agent does"
        
        # Initialize parent
        super().__init__(**data)
        
        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="custom_capability",
                description="What this capability does",
                parameters={"param1": "value1"},
                required=True
            )
        )
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """
        Execute a task assigned to this agent
        
        Args:
            task: The task to execute
            
        Returns:
            Dict with execution results
        """
        # Your custom logic here
        result = {
            "status": "completed",
            "agent": self.name,
            "output": "Task completed successfully"
        }
        
        return result
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """
        Return OpenAI function calling schema
        """
        return {
            "name": "my_custom_agent",
            "description": "Custom agent functionality",
            "parameters": {
                "type": "object",
                "properties": {
                    "input": {
                        "type": "string",
                        "description": "Input parameter"
                    }
                },
                "required": ["input"]
            }
        }
```

### Registering Your Agent

```python
from agents.orchestrator import AgentOrchestrator

# Initialize orchestrator
orchestrator = AgentOrchestrator()

# Create and register your agent
custom_agent = MyCustomAgent()
orchestrator.register_agent(custom_agent)
```

## Adding New Capabilities

### Define a Capability

```python
from agents.base import AgentCapability

capability = AgentCapability(
    name="code_generation",
    description="Generate code based on specifications",
    parameters={
        "language": "python",
        "framework": "fastapi",
        "style_guide": "pep8"
    },
    required=True
)

# Add to agent
agent.capabilities.append(capability)
```

### Query Agents by Capability

```python
# Find all agents with a specific capability
def get_agents_with_capability(orchestrator, capability_name):
    matching_agents = []
    for agent in orchestrator.agents.values():
        if any(cap.name == capability_name for cap in agent.capabilities):
            matching_agents.append(agent)
    return matching_agents

# Usage
code_generators = get_agents_with_capability(orchestrator, "code_generation")
```

## Extending the Build Process

### Add a Custom Phase

```python
from agents.application_builder import ApplicationPhase, ApplicationBuilder

class ExtendedApplicationBuilder(ApplicationBuilder):
    """
    Extended builder with custom phases
    """
    
    async def _execute_custom_phase(self, plan):
        """
        Custom phase implementation
        """
        console.print("[yellow]Executing custom phase...[/yellow]")
        
        # Your custom logic
        result = {
            "status": "completed",
            "custom_data": "Custom phase result"
        }
        
        return result
    
    async def _execute_development_lifecycle(self, plan, autonomous):
        """
        Override to add custom phases
        """
        # Call parent method first
        result = await super()._execute_development_lifecycle(plan, autonomous)
        
        # Add custom phase
        custom_result = await self._execute_custom_phase(plan)
        result["custom_phase"] = custom_result
        
        return result
```

### Custom Task Decomposition

```python
async def custom_task_decomposition(idea):
    """
    Custom task decomposition logic
    """
    tasks = []
    
    # Your custom decomposition logic
    for requirement in idea.requirements:
        task = Task(
            title=f"Implement {requirement}",
            description=f"Implementation task for {requirement}",
            priority=TaskPriority.HIGH,
            input_data={"requirement": requirement}
        )
        tasks.append(task)
    
    return tasks
```

## API Integration

### REST API Endpoints

```python
# Submit a build
import requests

response = requests.post(
    "http://localhost:8000/api/v1/builds",
    json={
        "title": "My Application",
        "description": "Application description",
        "requirements": ["req1", "req2"],
        "autonomous": True
    }
)

build_id = response.json()["build_id"]

# Check status
status = requests.get(f"http://localhost:8000/api/v1/builds/{build_id}")
print(status.json())
```

### WebSocket Integration

```javascript
// JavaScript WebSocket client
const ws = new WebSocket('ws://localhost:8000/ws');

ws.onopen = () => {
    console.log('Connected to build system');
};

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    
    switch(data.type) {
        case 'build_started':
            console.log('Build started:', data.build_id);
            break;
        
        case 'phase_started':
            console.log('Phase started:', data.phase);
            break;
        
        case 'phase_completed':
            console.log('Phase completed:', data.phase);
            break;
        
        case 'build_completed':
            console.log('Build completed!');
            break;
    }
};
```

### Python WebSocket Client

```python
import asyncio
import websockets
import json

async def listen_to_builds():
    uri = "ws://localhost:8000/ws"
    async with websockets.connect(uri) as websocket:
        while True:
            message = await websocket.recv()
            data = json.loads(message)
            print(f"Received: {data}")

asyncio.run(listen_to_builds())
```

## WebSocket Events

The system emits the following WebSocket events:

### `build_started`
```json
{
  "type": "build_started",
  "build_id": "build_123",
  "title": "Application Title"
}
```

### `phase_started`
```json
{
  "type": "phase_started",
  "build_id": "build_123",
  "phase": "development",
  "phase_name": "Development Phase",
  "progress": 45.5
}
```

### `phase_completed`
```json
{
  "type": "phase_completed",
  "build_id": "build_123",
  "phase": "development",
  "phase_name": "Development Phase",
  "progress": 54.5
}
```

### `build_completed`
```json
{
  "type": "build_completed",
  "build_id": "build_123",
  "title": "Application Title"
}
```

### `build_failed`
```json
{
  "type": "build_failed",
  "build_id": "build_123",
  "error": "Error message"
}
```

## Testing Your Extensions

### Unit Testing Agents

```python
import pytest
from agents.base import Task, TaskPriority

@pytest.mark.asyncio
async def test_custom_agent():
    """Test custom agent execution"""
    agent = MyCustomAgent()
    
    task = Task(
        title="Test Task",
        description="Test task description",
        priority=TaskPriority.HIGH,
        input_data={"test": "data"}
    )
    
    result = await agent.execute_task(task)
    
    assert result["status"] == "completed"
    assert "output" in result
```

### Integration Testing

```python
@pytest.mark.asyncio
async def test_build_process():
    """Test complete build process"""
    orchestrator = AgentOrchestrator()
    builder = ApplicationBuilder(orchestrator)
    
    idea = ApplicationIdea(
        title="Test App",
        description="Test application",
        requirements=["req1"]
    )
    
    result = await builder.build_application(idea, autonomous=False)
    
    assert result["status"] == "completed"
    assert len(result["phases_completed"]) > 0
```

### Testing with Mock Agents

```python
class MockAgent(BaseAgent):
    """Mock agent for testing"""
    
    def __init__(self):
        super().__init__(
            name="Mock Agent",
            type=AgentType.PROGRAMMING,
            description="Mock agent for testing"
        )
    
    async def execute_task(self, task):
        return {"status": "completed", "mock": True}

# Use in tests
@pytest.mark.asyncio
async def test_with_mock():
    orchestrator = AgentOrchestrator()
    orchestrator.register_agent(MockAgent())
    
    # Test with mock agent
    # ...
```

## Advanced Customization

### Custom Voting Strategy

```python
from agents.application_builder import Vote, DemocraticDecision

class CustomVotingStrategy:
    """
    Custom voting strategy with weighted votes
    """
    
    def calculate_winner(
        self,
        decision: DemocraticDecision,
        agent_weights: Dict[str, float]
    ) -> str:
        """
        Calculate winner with weighted votes
        
        Args:
            decision: The decision with votes
            agent_weights: Weight for each agent
            
        Returns:
            Winning option
        """
        weighted_scores = {}
        
        for vote in decision.votes:
            weight = agent_weights.get(vote.agent_id, 1.0)
            score = vote.confidence * weight
            
            if vote.option not in weighted_scores:
                weighted_scores[vote.option] = 0
            weighted_scores[vote.option] += score
        
        winner = max(weighted_scores.keys(), key=lambda x: weighted_scores[x])
        return winner
```

### Custom Phase Handlers

```python
async def custom_security_phase(plan):
    """
    Custom security scanning phase
    """
    security_tasks = [
        "Scan for vulnerabilities",
        "Check dependencies",
        "Validate authentication",
        "Test authorization",
        "Review API security"
    ]
    
    results = []
    for task in security_tasks:
        # Execute task
        result = await execute_security_task(task)
        results.append(result)
    
    return {
        "vulnerabilities_found": 0,
        "security_score": 95,
        "tasks_completed": len(results)
    }
```

## Environment Variables

Configure the system using environment variables:

```bash
# API Keys
OPENROUTER_API_KEY=your_key
OPENAI_API_KEY=your_key
ANTHROPIC_API_KEY=your_key

# Service Configuration
RABBITMQ_PASSWORD=secure_password
POSTGRES_PASSWORD=secure_password
MINIO_PASSWORD=secure_password

# Builder Configuration
BUILDER_AUTONOMOUS=true
BUILDER_MAX_ITERATIONS=10
BUILDER_TEST_COVERAGE_THRESHOLD=85
BUILDER_PHASE_TIMEOUT=300

# API Server
API_HOST=0.0.0.0
API_PORT=8000
```

## Best Practices

1. **Agent Design**
   - Keep agents focused on single responsibilities
   - Implement proper error handling
   - Add comprehensive docstrings
   - Use type hints consistently

2. **Task Decomposition**
   - Break down complex tasks into smaller units
   - Define clear dependencies
   - Set appropriate priorities
   - Include validation criteria

3. **Democratic Voting**
   - Include diverse agent perspectives
   - Set reasonable confidence thresholds
   - Document voting rationale
   - Handle tie-breaking scenarios

4. **Testing**
   - Test agents in isolation
   - Test integration between agents
   - Test complete build workflows
   - Use mocks for external dependencies

5. **Performance**
   - Execute tasks in parallel where possible
   - Cache results when appropriate
   - Monitor agent resource usage
   - Set reasonable timeouts

## Troubleshooting

### Agent Not Executing Tasks

```python
# Check if agent is registered
if agent_id in orchestrator.agents:
    print("Agent is registered")
else:
    print("Agent not found - register it first")

# Check agent status
agent = orchestrator.agents[agent_id]
print(f"Status: {agent.status}")
```

### Build Getting Stuck

```python
# Check active tasks
active_tasks = orchestrator.active_tasks
print(f"Active tasks: {len(active_tasks)}")

# Check for errors
for task_id, task in active_tasks.items():
    if task.status == TaskStatus.FAILED:
        print(f"Failed task: {task.title}")
        print(f"Error: {task.error}")
```

### WebSocket Connection Issues

```bash
# Test WebSocket connection
curl -i -N -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Version: 13" \
     -H "Sec-WebSocket-Key: test" \
     http://localhost:8000/ws
```

## Contributing

To contribute your custom agents or capabilities:

1. Fork the repository
2. Create your feature branch
3. Add tests for your changes
4. Submit a pull request
5. Update documentation

## Support

- GitHub Issues: [Report bugs](https://github.com/cbwinslow/bash.d/issues)
- Documentation: See README files
- Examples: Check `examples/` directory

---

**Happy building with AI agents! 🤖**
