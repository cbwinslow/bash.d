# CrewAI Configuration System - Usage Guide

## Quick Start

### 1. Load and Run a Pre-configured Crew

```python
import asyncio
import yaml
from crewai_config import CrewConfig, CrewOrchestrator

async def run_crew():
    # Load crew configuration
    with open('crewai_config/crews/code_generation_crew.yaml', 'r') as f:
        crew_dict = yaml.safe_load(f)
    
    # Create crew config
    crew_config = CrewConfig(**crew_dict)
    
    # Create orchestrator and execute
    orchestrator = CrewOrchestrator(crew_config)
    results = await orchestrator.execute()
    
    print(f"Success Rate: {results['metrics']['success_rate']:.1%}")
    print(f"Votes Conducted: {results['governance']['votes_conducted']}")

asyncio.run(run_crew())
```

### 2. Validate Crew Configurations

```python
from crewai_config.examples.crew_loader import CrewLoader

# Load and validate all crews
loader = CrewLoader()
crews = loader.load_all_crews()

# Validate specific crew
for crew_id, crew_config in crews.items():
    issues = loader.validate_crew(crew_config)
    if issues:
        print(f"{crew_config.name}: {len(issues)} issues")
        for issue in issues:
            print(f"  - {issue}")
    else:
        print(f"{crew_config.name}: ✓ Valid")
```

### 3. Test Democratic Voting

```python
from crewai_config import (
    DemocraticVotingSystem,
    VotingSession,
    VotingStrategy,
    CrewMember,
    CrewRole
)

# Create members
members = [
    CrewMember(
        agent_id="agent_1",
        agent_name="Senior Dev",
        role=CrewRole.SPECIALIST,
        expertise_weight=3.0,
        can_vote=True,
        capabilities=["coding"]
    ),
    # ... more members
]

# Create voting session
voting_session = VotingSession(
    proposal_id="use_framework",
    proposal_description="Adopt new framework",
    strategy=VotingStrategy.SUPERMAJORITY
)

# Initialize voting system
voting_system = DemocraticVotingSystem(voting_session, members)

# Cast votes
voting_system.cast_vote("agent_1", True, "Better performance")

# Check result
if voting_session.passed:
    print("Proposal passed!")
```

## Available Crews

### 1. Code Generation Crew
- **Type**: Democratic
- **Members**: 6 agents (planner, backend dev, frontend dev, security, testers)
- **Governance**: Consensus-based
- **Voting Points**: 4 democratic decisions
- **Use Case**: Collaborative code development with quality checks

### 2. DevOps Automation Crew
- **Type**: Hierarchical
- **Members**: 6 agents (manager, docker expert, k8s specialist, CI/CD, security, monitor)
- **Governance**: Manager-led
- **Voting Points**: 0 (hierarchical decisions)
- **Use Case**: Infrastructure deployment and management

### 3. Security Audit Crew
- **Type**: Democratic Peer-to-Peer
- **Members**: 4 security specialists
- **Governance**: Consensus-based
- **Voting Points**: 3 democratic decisions
- **Use Case**: Comprehensive security audits

### 4. Documentation Crew
- **Type**: Hybrid
- **Members**: 5 documentation specialists
- **Governance**: Weighted voting with manager coordination
- **Voting Points**: 2 democratic decisions
- **Use Case**: Technical documentation creation

## Voting Strategies

### Simple Majority
```yaml
voting_strategy: simple_majority
```
Passes with >50% yes votes. Good for routine decisions.

### Supermajority
```yaml
voting_strategy: supermajority
```
Requires ≥66% yes votes. Use for important decisions.

### Unanimous
```yaml
voting_strategy: unanimous
```
Requires 100% agreement. Use for critical decisions.

### Weighted Vote
```yaml
voting_strategy: weighted_vote
```
Votes weighted by expertise. Use when expertise matters.

### Ranked Choice
```yaml
voting_strategy: ranked_choice
```
Voters rank options. Uses instant runoff for winner.

### Approval Voting
```yaml
voting_strategy: approval
```
Voters approve multiple options. Winner has most approvals.

## Creating Custom Crews

### Step 1: Define Crew Configuration

```yaml
id: my_custom_crew
name: "My Custom Crew"
description: "Custom crew for specific task"
version: "1.0.0"

process_type: democratic  # sequential, parallel, hierarchical, democratic, hybrid
governance_model: consensus
voting_strategy: weighted_vote
conflict_resolution: expert_decides

communication_protocol: rabbitmq
parallel_execution: true
max_concurrent_tasks: 3

members:
  - agent_id: specialist_001
    agent_name: "Specialist Agent"
    role: specialist
    expertise_weight: 2.5
    can_vote: true
    capabilities:
      - domain_expertise
      - problem_solving

tasks:
  - id: task_001
    name: "Analysis Task"
    description: "Analyze the problem"
    assigned_agent_ids:
      - specialist_001
    dependencies: []
    requires_vote: true
    voting_strategy: simple_majority
```

### Step 2: Load and Execute

```python
import asyncio
import yaml
from crewai_config import CrewConfig, CrewOrchestrator

async def run_custom_crew():
    with open('path/to/custom_crew.yaml', 'r') as f:
        crew_dict = yaml.safe_load(f)
    
    crew_config = CrewConfig(**crew_dict)
    orchestrator = CrewOrchestrator(crew_config)
    results = await orchestrator.execute()
    
    return results

results = asyncio.run(run_custom_crew())
```

## Multi-Crew Swarms

### Configure Swarm

```yaml
id: my_swarm
name: "Multi-Crew Swarm"
description: "Coordinated multi-crew operation"
governance_model: democratic
inter_crew_voting: true

crews:
  - code_generation_crew
  - security_audit_crew
  - devops_automation_crew

coordinator_crew_id: code_generation_crew
```

### Execute Swarm

```python
from crewai_config import SwarmConfig, CrewOrchestrator

# Load swarm config
with open('examples/democratic_code_swarm.yaml', 'r') as f:
    swarm_dict = yaml.safe_load(f)

swarm_config = SwarmConfig(**swarm_dict)

# Execute each crew in swarm
for crew_id in swarm_config.crews:
    crew_config = load_crew_config(crew_id)
    orchestrator = CrewOrchestrator(crew_config)
    results = await orchestrator.execute()
```

## Inter-Agent Communication

### Setup RabbitMQ Messaging

```python
from crewai_config import CrewMessagingHub, CrewCommunication, Message, MessageType

# Create communication config
comm_config = CrewCommunication(
    crew_id="my_crew",
    rabbitmq_enabled=True,
    rabbitmq_exchange="crew_exchange",
    redis_enabled=False
)

# Initialize messaging hub
messaging_hub = CrewMessagingHub(
    crew_id="my_crew",
    config=comm_config,
    rabbitmq_config={
        "host": "localhost",
        "port": 5672,
        "username": "guest",
        "password": "guest"
    }
)

messaging_hub.connect()

# Send message to specific agent
message = Message(
    message_type=MessageType.TASK_REQUEST,
    sender_id="crew_manager",
    sender_name="Manager",
    content={"task": "Review code"}
)

messaging_hub.send_to_agent(message, "code_reviewer")

# Broadcast to all crew members
messaging_hub.broadcast(message)
```

## Best Practices

### 1. Task Dependencies
Define clear dependencies to enable parallel execution:

```yaml
tasks:
  - id: task_a
    dependencies: []  # Can run immediately
    
  - id: task_b
    dependencies: [task_a]  # Waits for task_a
    dependency_type: sequential
    
  - id: task_c
    dependencies: []  # Can run with task_a
    dependency_type: parallel
```

### 2. Expertise Weights
Assign weights based on domain expertise:

```yaml
members:
  - agent_id: security_expert
    expertise_weight: 3.0  # High weight for security votes
    
  - agent_id: junior_dev
    expertise_weight: 1.5  # Lower weight
```

### 3. Voting Thresholds
Choose appropriate thresholds for decision importance:

- Routine: `simple_majority` (>50%)
- Important: `supermajority` (≥66%)
- Critical: `unanimous` (100%)

### 4. Conflict Resolution
Define clear resolution strategies:

```yaml
conflict_resolution: expert_decides  # Expert breaks tie
# OR
conflict_resolution: revote  # Vote again
# OR
conflict_resolution: manager_decides  # Manager decides
```

### 5. Timeout Management
Set realistic timeouts for complex tasks:

```yaml
timeout_seconds: 1800  # 30 minutes for complex tasks
```

### 6. Monitoring
Enable metrics for performance tracking:

```yaml
metrics_enabled: true
verbose: true
log_level: INFO
```

## Troubleshooting

### Issue: "Agent not found in crew"
**Solution**: Ensure agent_id in tasks matches a member's agent_id.

### Issue: Circular dependencies
**Solution**: Check task dependencies don't form cycles. Use validation.

### Issue: Votes not passing
**Solution**: Check voting strategy and thresholds are appropriate.

### Issue: Communication errors
**Solution**: Verify RabbitMQ/Redis are running and accessible.

### Issue: Tasks not executing in parallel
**Solution**: Set `parallel_execution: true` and use appropriate `dependency_type`.

## Examples

All examples are in `crewai_config/examples/`:

- `crew_loader.py` - Load and validate crew configurations
- `democratic_voting_example.py` - Demonstrate voting strategies
- `run_code_generation_crew.py` - Run complete crew workflow
- `democratic_code_swarm.yaml` - Multi-crew swarm configuration

Run examples:
```bash
python3 crewai_config/examples/crew_loader.py
python3 crewai_config/examples/democratic_voting_example.py
python3 crewai_config/examples/run_code_generation_crew.py
```

## Integration with Existing Agents

The crew system integrates with agents in `/agents/`:

```python
from agents.programming.python_backend_developer_agent import PythonBackendDeveloperAgent
from crewai_config import CrewMember, CrewRole

# Create agent
agent = PythonBackendDeveloperAgent()

# Use in crew
crew_member = CrewMember(
    agent_id=agent.id,
    agent_name=agent.name,
    role=CrewRole.SPECIALIST,
    expertise_weight=2.5,
    can_vote=True,
    capabilities=list(agent.capabilities)
)
```

## Further Reading

- [Research Documentation](MULTI_AGENT_RESEARCH.md)
- [Main README](../README.md)
- CrewAI Documentation: https://docs.crewai.com/
- CodeSim Paper: https://arxiv.org/abs/2502.05664
- MapCoder: https://arxiv.org/abs/2405.11403
