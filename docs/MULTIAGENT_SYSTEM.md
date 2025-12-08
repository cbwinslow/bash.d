# Multi-Agent Problem-Solving System

A comprehensive, intelligent multi-agent system featuring swarm intelligence, hierarchical organization, autonomous crews, and various problem-solving algorithms.

## 🌟 Features

### Swarm Intelligence Coordination
- **Particle Swarm Optimization (PSO)** - Optimize task assignments and solutions through swarm behavior
- **Ant Colony Optimization (ACO)** - Find optimal paths through task dependency graphs
- **Bee Colony Algorithm** - Efficient resource allocation across agents
- **Emergent Behavior** - Complex solutions emerge from simple agent interactions

### Hierarchical Organization
- **Manager Agents** - High-level planning and task decomposition
- **Coordinator Agents** - Parallel execution and synchronization
- **Worker Agents** - Specialized task execution
- **Dynamic Delegation** - Intelligent work distribution across hierarchies

### Autonomous Crews
- **Self-Organization** - Crews form and adapt without human intervention
- **Democratic Decision Making** - Agents vote on strategies and assignments
- **Consensus Building** - Iterative refinement until consensus is reached
- **Auto-Recovery** - Automatic error detection and recovery
- **Learning & Adaptation** - Crews learn from experience and optimize strategies

### Problem-Solving Methods
- **Divide and Conquer** - Recursive problem decomposition
- **Democratic Voting** - Collective solution selection
- **Consensus Building** - Iterative refinement to agreement
- **Competitive Solving** - Multiple solutions, best one wins
- **Genetic Algorithms** - Evolve solutions through selection and mutation
- **Monte Carlo Methods** - Probabilistic decision making
- **Hybrid Approaches** - Combine multiple methods intelligently

### Collaboration Patterns
- **Sequential** - Pipeline execution of dependent tasks
- **Parallel** - Concurrent execution of independent tasks
- **Hierarchical** - Tree-structured task breakdown
- **Swarm** - Decentralized, emergent collaboration

## 🚀 Quick Start

### Basic Usage

```python
from agents.base import BaseAgent, Task, TaskPriority, AgentType
from agents.autonomous_crew import AutonomousCrew, CrewStrategy

# Create agents
agents = [
    BaseAgent(
        name="Python Developer",
        type=AgentType.PROGRAMMING,
        description="Expert Python developer"
    ),
    BaseAgent(
        name="Test Engineer",
        type=AgentType.TESTING,
        description="Testing specialist"
    )
]

# Create autonomous crew
crew = AutonomousCrew(
    name="Dev Crew",
    strategy=CrewStrategy.DEMOCRATIC
)
crew.add_agents(agents)

# Define complex task
task = Task(
    title="Build REST API",
    description="Create a complete REST API with tests and documentation",
    priority=TaskPriority.HIGH
)

# Execute autonomously until completion
result = await crew.execute_autonomously(task)
print(f"Success rate: {result['tasks']['success_rate']}")
```

### Swarm Intelligence

```python
from agents.swarm import SwarmCoordinator, SwarmStrategy

# Create swarm with PSO
swarm = SwarmCoordinator(
    strategy=SwarmStrategy.PARTICLE_SWARM,
    population_size=20
)

swarm.add_agents(agents)

# Optimize task assignment
tasks = [Task(...), Task(...), Task(...)]
result = await swarm.coordinate_swarm(tasks)
```

### Hierarchical Organization

```python
from agents.hierarchy import ManagerAgent, CoordinatorAgent, WorkerAgent

# Create hierarchy
manager = ManagerAgent(
    name="Team Lead",
    type=AgentType.GENERAL,
    description="Manages and decomposes tasks"
)

workers = [
    WorkerAgent(name="Worker 1", type=AgentType.PROGRAMMING),
    WorkerAgent(name="Worker 2", type=AgentType.TESTING)
]

for worker in workers:
    manager.add_subordinate(worker.id)

# Decompose complex task
decomposition = await manager.decompose_task(complex_task)
print(f"Created {len(decomposition.subtasks)} subtasks")
```

### Intelligent Problem Solving

```python
from agents.problem_solving import (
    IntelligentProblemSolver,
    Problem,
    ProblemSolvingMethod
)

solver = IntelligentProblemSolver()

problem = Problem(
    id="optimization_1",
    description="Optimize distributed system",
    complexity=30,
    requirements=["high availability", "low latency"]
)

# Automatically select best method
solution = await solver.solve(problem, agents)

# Or specify method
solution = await solver.solve(
    problem, 
    agents, 
    method=ProblemSolvingMethod.GENETIC_ALGORITHM
)
```

## 📖 Architecture

### System Components

```
┌─────────────────────────────────────────────────────────┐
│                   Autonomous Crew                        │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Democratic Voting │ Consensus │ Competitive    │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│              Swarm Intelligence Coordinator              │
│  ┌──────────────────────────────────────────────────┐   │
│  │  PSO │ ACO │ Bee Colony │ Firefly │ Wolf Pack  │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│              Hierarchical Organization                   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Manager → Coordinator → Workers                 │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│              Problem Solving Algorithms                  │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Divide & Conquer │ Genetic │ Democratic         │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                    Base Agents                           │
│  Programming │ Testing │ DevOps │ Security │ Docs      │
└─────────────────────────────────────────────────────────┘
```

## 🎯 Use Cases

### Complex Code Generation

```python
# Task: Build a complete microservice
task = Task(
    title="Create User Service",
    description="""
    Build a complete user management microservice with:
    - RESTful API endpoints
    - Database integration
    - Authentication/Authorization
    - Input validation
    - Error handling
    - Comprehensive tests
    - API documentation
    - Docker containerization
    """,
    priority=TaskPriority.CRITICAL
)

# Autonomous crew handles everything
crew = AutonomousCrew(
    name="Microservice Crew",
    strategy=CrewStrategy.COLLABORATIVE
)
crew.add_agents([
    python_dev, api_designer, test_engineer,
    security_expert, devops_engineer, doc_writer
])

result = await crew.execute_autonomously(task)
# Crew works until complete without human intervention
```

### Distributed System Optimization

```python
# Use swarm intelligence to optimize architecture
swarm = SwarmCoordinator(strategy=SwarmStrategy.PARTICLE_SWARM)
swarm.add_agents(architecture_agents)

def fitness(architecture):
    # Score based on latency, cost, availability
    return calculate_score(architecture)

best_architecture, score = await swarm.optimize_pso(fitness)
```

### Multi-Step Problem Solving

```python
# Complex problem requiring multiple approaches
problem = Problem(
    id="system_design",
    description="Design scalable e-commerce platform",
    complexity=50,
    requirements=[
        "Handle 1M concurrent users",
        "99.99% uptime",
        "Global CDN",
        "Real-time inventory",
        "PCI compliance"
    ]
)

# Try multiple methods and compare
solver = IntelligentProblemSolver()
solutions = []

for method in [
    ProblemSolvingMethod.DIVIDE_CONQUER,
    ProblemSolvingMethod.GENETIC_ALGORITHM,
    ProblemSolvingMethod.CONSENSUS_BUILD
]:
    solution = await solver.solve(problem, agents, method)
    solutions.append(solution)

# Select best solution
best = max(solutions, key=lambda s: s.score)
```

## 🔧 Configuration

### Agent Configuration

```python
from agents.base import AgentConfig

config = AgentConfig(
    model_provider="openai",
    model_name="gpt-4",
    temperature=0.7,
    max_tokens=4096,
    concurrency_limit=5,
    mcp_enabled=True,
    a2a_enabled=True,
    tools=["code_analyzer", "test_runner", "linter"]
)

agent = BaseAgent(
    name="Senior Developer",
    type=AgentType.PROGRAMMING,
    description="Expert developer",
    config=config
)
```

### Crew Configuration

```python
crew = AutonomousCrew(
    name="Production Crew",
    strategy=CrewStrategy.ADAPTIVE,      # Adapts based on performance
    max_iterations=100,                  # Max work iterations
    consensus_threshold=0.8,             # 80% agreement needed
    auto_recovery=True,                  # Auto-recover from errors
    learning_enabled=True                # Learn and improve
)
```

### Swarm Configuration

```python
swarm = SwarmCoordinator(
    strategy=SwarmStrategy.PARTICLE_SWARM,
    population_size=30,
    max_iterations=100
)

# PSO parameters
await swarm.optimize_pso(
    fitness_func=your_fitness,
    w=0.7,    # Inertia weight
    c1=1.5,   # Cognitive parameter
    c2=1.5    # Social parameter
)
```

## 📊 Monitoring & Metrics

### Crew Status

```python
status = crew.get_status()
print(f"Running: {status['running']}")
print(f"Iterations: {status['iterations']}")
print(f"Completed: {status['subtasks']['completed']}")
print(f"Failed: {status['subtasks']['failed']}")
```

### Swarm Metrics

```python
metrics = swarm.get_swarm_metrics()
print(f"Strategy: {metrics['strategy']}")
print(f"Best fitness: {metrics['global_best_fitness']}")
print(f"Convergence: {metrics['convergence_history']}")
```

### Performance Statistics

```python
stats = solver.get_performance_stats()
for method, data in stats.items():
    print(f"{method}:")
    print(f"  Average: {data['avg_score']}")
    print(f"  Best: {data['best_score']}")
    print(f"  Uses: {data['uses']}")
```

## 🧪 Testing

### Run Demonstration

```bash
# Run complete demonstration
python -m agents.demo_multiagent

# Run specific demo
python -m agents.demo_multiagent --demo swarm
python -m agents.demo_multiagent --demo autonomous
python -m agents.demo_multiagent --demo problem_solving
```

### Unit Tests

```bash
# Run all tests
pytest tests/agents/

# Test specific component
pytest tests/agents/test_swarm.py
pytest tests/agents/test_autonomous_crew.py
pytest tests/agents/test_problem_solving.py
```

## 🎓 Advanced Topics

### Custom Problem Solving Methods

```python
class CustomSolver:
    async def solve(self, problem, agents):
        # Your custom algorithm
        pass

# Integrate with intelligent solver
solver = IntelligentProblemSolver()
solver.custom = CustomSolver()
```

### Custom Swarm Strategies

```python
from agents.swarm import SwarmCoordinator

class CustomSwarm(SwarmCoordinator):
    async def optimize_custom(self, ...):
        # Your custom swarm algorithm
        pass
```

### Learning and Adaptation

```python
# Crews learn from experience
crew = AutonomousCrew(learning_enabled=True)

# After each task, crew updates strategy scores
await crew.execute_autonomously(task1)
await crew.execute_autonomously(task2)

# View learned preferences
print(crew.strategy_scores)
print(crew.performance_history)
```

## 📚 API Reference

### Core Classes

- **`BaseAgent`** - Base agent class with task execution
- **`ManagerAgent`** - Hierarchical manager with decomposition
- **`CoordinatorAgent`** - Synchronization and coordination
- **`WorkerAgent`** - Specialized task execution
- **`AutonomousCrew`** - Self-organizing agent crew
- **`SwarmCoordinator`** - Swarm intelligence coordinator
- **`IntelligentProblemSolver`** - Adaptive problem solver

### Key Methods

- **`crew.execute_autonomously(task)`** - Run until completion
- **`manager.decompose_task(task)`** - Break down complex tasks
- **`swarm.coordinate_swarm(tasks)`** - Optimize with swarm
- **`solver.solve(problem, agents, method)`** - Solve intelligently
- **`coordinator.coordinate_parallel_execution(tasks)`** - Parallel execution

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

1. Additional swarm algorithms (Firefly, Wolf Pack)
2. More problem-solving methods (Simulated Annealing, Tabu Search)
3. Advanced learning algorithms
4. Performance optimizations
5. Additional collaboration patterns

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Related Documentation

- [Agent Architecture](./AGENTS.md)
- [Orchestration System](./ORCHESTRATION.md)
- [Problem Solving Algorithms](./ALGORITHMS.md)
- [Swarm Intelligence](./SWARM.md)

## 💡 Examples

See the `agents/demo_multiagent.py` file for comprehensive examples of all features.

---

**Built with intelligence, collaboration, and emergence in mind.**
