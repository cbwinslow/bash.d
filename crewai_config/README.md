# CrewAI Configuration System

A comprehensive multi-agent crew configuration system for parallel execution, democratic decision-making, and collaborative problem-solving.

## Overview

This system implements advanced multi-agent coordination patterns based on:
- **CrewAI Framework**: Parallel crews and hierarchical workflows
- **CodeSim Research**: Multi-agent code generation with simulation-driven planning
- **MapCoder**: Specialized agents working collaboratively
- **Swarm Intelligence**: Distributed consensus and democratic decision-making

## Features

### 🚀 Parallel Execution
- Execute multiple agents concurrently
- Task dependency management
- Parallel crew orchestration
- Asynchronous task processing

### 🗳️ Democratic Governance
- Multiple voting strategies (simple majority, supermajority, unanimous, weighted, ranked choice, approval)
- Consensus building mechanisms
- Conflict resolution protocols
- Peer-to-peer decision-making

### 🏢 Governance Models
- **Hierarchical**: Manager-led coordination
- **Democratic**: Peer voting and consensus
- **Consensus**: Unanimous agreement required
- **Majority**: Majority voting
- **Weighted**: Expertise-based voting weights
- **Hybrid**: Combined hierarchical and democratic

### 📡 Communication Protocols
- **RabbitMQ**: Message queue for async communication
- **Redis Pub/Sub**: Publish-subscribe pattern
- **WebSocket**: Real-time bidirectional communication
- **Agent-to-Agent**: Direct peer communication

### 🔄 Process Types
- **Sequential**: Tasks executed in order
- **Parallel**: Tasks executed concurrently
- **Hierarchical**: Manager coordinates agents
- **Democratic**: Agents vote on decisions
- **Hybrid**: Combined approaches

## Directory Structure

```
crewai_config/
├── schemas/              # Pydantic models for crew configuration
│   ├── crew_models.py   # Core data models
│   └── __init__.py
├── governance/           # Democratic voting and consensus
│   ├── democratic_voting.py
│   └── __init__.py
├── communication/        # Inter-agent messaging
│   ├── messaging.py
│   └── __init__.py
├── crews/               # Crew orchestration
│   ├── crew_orchestrator.py
│   ├── code_generation_crew.yaml
│   ├── devops_automation_crew.yaml
│   ├── security_audit_crew.yaml
│   ├── documentation_crew.yaml
│   └── __init__.py
├── examples/            # Example swarm configurations
│   └── democratic_code_swarm.yaml
├── docs/                # Documentation
│   └── MULTI_AGENT_RESEARCH.md
└── README.md
```

## Pre-configured Crews

### 1. Code Generation Crew (Democratic)
**Purpose**: Collaborative code development with planning, implementation, review, and testing

**Members**:
- Code Planner
- Python Backend Developer
- JavaScript Full Stack Developer
- Code Security Reviewer
- Unit Test Developer
- Integration Test Engineer

**Governance**: Democratic with consensus voting
**Process**: Democratic with 4 voting points
**Best For**: Complex code generation requiring multiple perspectives

### 2. DevOps Automation Crew (Hierarchical)
**Purpose**: Infrastructure management, deployment automation, and monitoring

**Members**:
- DevOps Manager (coordinator)
- Docker Container Expert
- Kubernetes Orchestration Specialist
- CI/CD Orchestrator
- Infrastructure Security Auditor
- Performance Monitor

**Governance**: Hierarchical with manager coordination
**Process**: Hierarchical with parallel task execution
**Best For**: Infrastructure and deployment automation

### 3. Security Audit Crew (Peer-to-Peer Democratic)
**Purpose**: Comprehensive security scanning, analysis, and remediation

**Members**:
- Code Security Reviewer
- Vulnerability Scanner
- Infrastructure Security Auditor
- Dependency Security Analyst

**Governance**: Consensus-based peer democracy
**Process**: Democratic with supermajority voting
**Best For**: Security audits requiring expert consensus

### 4. Documentation Crew (Hybrid)
**Purpose**: Collaborative documentation creation

**Members**:
- Technical Writer Manager
- API Documentation Expert
- Code Documentation Specialist
- User Guide Author
- Documentation Reviewer

**Governance**: Hybrid (hierarchical + democratic input)
**Process**: Hybrid with weighted voting
**Best For**: Documentation requiring both coordination and diverse input

## Usage Examples

### Basic Crew Execution

```python
import asyncio
import yaml
from crewai_config import CrewConfig, CrewOrchestrator

# Load crew configuration
with open('crewai_config/crews/code_generation_crew.yaml', 'r') as f:
    crew_dict = yaml.safe_load(f)

# Create crew config
crew_config = CrewConfig(**crew_dict)

# Create orchestrator
orchestrator = CrewOrchestrator(crew_config)

# Execute crew
results = await orchestrator.execute()

print(f"Crew Status: {results['status']}")
print(f"Tasks Completed: {results['tasks']['completed']}")
print(f"Success Rate: {results['metrics']['success_rate']}")
```

### Democratic Voting

```python
from crewai_config import DemocraticVotingSystem, VotingSession, VotingStrategy

# Create voting session
voting_session = VotingSession(
    proposal_id="approve_solution",
    proposal_description="Approve the proposed architecture",
    strategy=VotingStrategy.SUPERMAJORITY,
    threshold=0.66
)

# Initialize voting system
voting_system = DemocraticVotingSystem(voting_session, crew_members)

# Cast votes
for member in crew_members:
    voting_system.cast_vote(
        agent_id=member.agent_id,
        vote=True,
        reasoning="Solution meets all requirements"
    )

# Check result
if voting_session.passed:
    print("Proposal approved!")
else:
    print("Proposal rejected")
```

### Inter-Crew Communication

```python
from crewai_config import CrewMessagingHub, Message, MessageType, CrewCommunication

# Create communication config
comm_config = CrewCommunication(
    crew_id="code_generation_crew",
    rabbitmq_enabled=True,
    rabbitmq_exchange="crew_exchange"
)

# Initialize messaging hub
messaging_hub = CrewMessagingHub(
    crew_id="code_generation_crew",
    config=comm_config
)

messaging_hub.connect()

# Send message to agent
message = Message(
    message_type=MessageType.TASK_REQUEST,
    sender_id="crew_manager",
    sender_name="Crew Manager",
    content={"task": "Review code", "priority": "high"}
)

messaging_hub.send_to_agent(message, "code_security_reviewer")

# Broadcast to all crew members
messaging_hub.broadcast(message)
```

### Multi-Crew Swarm

```python
from crewai_config import SwarmConfig

# Load swarm configuration
with open('crewai_config/examples/democratic_code_swarm.yaml', 'r') as f:
    swarm_dict = yaml.safe_load(f)

swarm_config = SwarmConfig(**swarm_dict)

# Execute all crews in swarm
for crew_id in swarm_config.crews:
    crew_config = load_crew_config(crew_id)
    orchestrator = CrewOrchestrator(crew_config)
    results = await orchestrator.execute()
    print(f"{crew_id}: {results['status']}")
```

## Voting Strategies

### Simple Majority (>50%)
```python
VotingStrategy.SIMPLE_MAJORITY
# Passes if more than 50% vote yes
```

### Supermajority (>=66%)
```python
VotingStrategy.SUPERMAJORITY
# Passes if 66% or more vote yes
```

### Unanimous (100%)
```python
VotingStrategy.UNANIMOUS
# Passes only if all vote yes
```

### Weighted Vote
```python
VotingStrategy.WEIGHTED_VOTE
# Votes weighted by expertise_weight
# Passes if weighted percentage > threshold
```

### Ranked Choice
```python
VotingStrategy.RANKED_CHOICE
# Voters rank options
# Winner determined by instant runoff
```

### Approval Voting
```python
VotingStrategy.APPROVAL
# Voters approve multiple options
# Winner has most approvals
```

## Configuration Reference

### CrewConfig
```yaml
id: unique_crew_id
name: "Crew Name"
description: "Crew purpose"
process_type: democratic  # sequential, parallel, hierarchical, democratic, hybrid
governance_model: consensus  # hierarchical, democratic, consensus, majority, weighted, hybrid
voting_strategy: supermajority  # Optional
conflict_resolution: expert_decides
parallel_execution: true
max_concurrent_tasks: 5
communication_protocol: rabbitmq
shared_memory: true
members: [...]  # List of CrewMember
tasks: [...]    # List of CrewTask
```

### CrewMember
```yaml
- agent_id: agent_identifier
  agent_name: "Agent Name"
  role: specialist  # manager, specialist, reviewer, coordinator, executor, observer
  expertise_weight: 2.5  # 0.0 to 10.0
  can_vote: true
  can_delegate: false
  capabilities: [...]
```

### CrewTask
```yaml
- id: task_id
  name: "Task Name"
  description: "Task description"
  assigned_agent_ids: [...]
  dependencies: [...]  # Task IDs this depends on
  dependency_type: sequential  # sequential, parallel, conditional, optional
  requires_vote: true
  voting_strategy: weighted_vote
  expected_output: "Description of output"
  tools: [...]
  timeout_seconds: 300
```

## Best Practices

1. **Task Dependencies**: Clearly define dependencies to enable parallel execution
2. **Voting Thresholds**: Use appropriate voting strategies for decision importance
3. **Expertise Weights**: Assign weights based on agent specialization
4. **Timeout Management**: Set realistic timeouts for complex tasks
5. **Memory Isolation**: Use when agents need independent contexts
6. **Monitoring**: Enable metrics for performance tracking
7. **Communication**: Choose protocols based on latency requirements
8. **Conflict Resolution**: Define clear resolution strategies

## Integration with Existing Agents

The crew system integrates with agents in `/agents/` directory:

```python
from agents.programming.python_backend_developer_agent import PythonBackendDeveloperAgent
from crewai_config import CrewMember

# Create crew member from existing agent
agent = PythonBackendDeveloperAgent()

crew_member = CrewMember(
    agent_id=agent.id,
    agent_name=agent.name,
    role=CrewRole.SPECIALIST,
    expertise_weight=2.5,
    can_vote=True,
    capabilities=["python_backend", "api_development"]
)
```

## Research References

- **CrewAI Documentation**: https://docs.crewai.com/
- **CodeSim Paper**: Multi-Agent Code Generation through Simulation-Driven Planning
- **MapCoder**: Multi-Agent Code Generation for Competitive Problem Solving
- **SwarmAgents**: Distributed Consensus Protocols
- **PBFT**: Practical Byzantine Fault Tolerance

## Contributing

To add new crews:
1. Create YAML configuration in `crews/`
2. Define members with appropriate roles and capabilities
3. Structure tasks with clear dependencies
4. Choose governance model and voting strategies
5. Test with orchestrator

## License

Same as parent repository.
