# Multi-Agent Problem-Solving System

A fully-featured, intelligent multi-agent system with swarm intelligence, hierarchical organization, autonomous crews, and advanced problem-solving algorithms.

## 🎯 Overview

This implementation provides a **complete multi-agent system** capable of solving complex problems through:

- **Swarm Intelligence** - PSO, ACO, and Bee Colony algorithms
- **Hierarchical Organization** - Manager, Coordinator, and Worker agents
- **Autonomous Crews** - Self-organizing teams that work until completion
- **Intelligent Problem Solving** - Multiple algorithms including genetic, democratic voting, and consensus building
- **Fully Autonomous Operation** - No human intervention required once started

## ✨ Key Features

### 1. Swarm Intelligence (`agents/swarm.py`)

Multiple swarm algorithms for distributed coordination:

```python
from agents.swarm import SwarmCoordinator, SwarmStrategy

# Particle Swarm Optimization
swarm = SwarmCoordinator(strategy=SwarmStrategy.PARTICLE_SWARM)
swarm.add_agents(agents)
best_solution, fitness = await swarm.optimize_pso(fitness_func)

# Ant Colony Optimization for path finding
path = await swarm.optimize_aco(graph, start, goal)

# Bee Colony for resource allocation
allocation, value = await swarm.optimize_bee_colony(objective_func)
```

**Implemented Algorithms:**
- Particle Swarm Optimization (PSO)
- Ant Colony Optimization (ACO)
- Artificial Bee Colony (ABC)
- Emergent behavior through decentralized coordination

### 2. Hierarchical Organization (`agents/hierarchy.py`)

Multi-level agent structure for complex task management:

```python
from agents.hierarchy import ManagerAgent, CoordinatorAgent, WorkerAgent

# Create hierarchy
manager = ManagerAgent(name="Team Lead", type=AgentType.GENERAL)
coordinator = CoordinatorAgent(name="Coordinator", type=AgentType.GENERAL)
workers = [WorkerAgent(name=f"Worker {i}", type=AgentType.PROGRAMMING) for i in range(5)]

# Decompose complex task
decomposition = await manager.decompose_task(complex_task)
print(f"Created {len(decomposition.subtasks)} subtasks")

# Coordinate parallel execution
result = await coordinator.coordinate_parallel_execution(tasks, agents)
```

**Features:**
- Automatic task decomposition
- Dependency analysis
- Parallel execution with synchronization
- Dynamic delegation

### 3. Autonomous Crews (`agents/autonomous_crew.py`)

Self-organizing agent teams that work independently:

```python
from agents.autonomous_crew import AutonomousCrew, CrewStrategy

# Create autonomous crew
crew = AutonomousCrew(
    name="Development Crew",
    strategy=CrewStrategy.DEMOCRATIC,  # or COMPETITIVE, COLLABORATIVE, ADAPTIVE
    max_iterations=100,
    auto_recovery=True,
    learning_enabled=True
)

crew.add_agents(agents)

# Execute until completion (no human intervention)
result = await crew.execute_autonomously(task)
```

**Capabilities:**
- Democratic voting on decisions
- Consensus building
- Automatic error recovery
- Learning and adaptation
- Strategy optimization

### 4. Problem-Solving Algorithms (`agents/problem_solving.py`)

Multiple approaches for different problem types:

```python
from agents.problem_solving import IntelligentProblemSolver, Problem

solver = IntelligentProblemSolver()

problem = Problem(
    id="optimization_1",
    description="Optimize distributed system architecture",
    complexity=30,
    requirements=["high availability", "low latency", "cost efficiency"]
)

# Automatically select best method
solution = await solver.solve(problem, agents)

# Or specify method
solution = await solver.solve(problem, agents, method=ProblemSolvingMethod.GENETIC_ALGORITHM)
```

**Available Methods:**
- **Divide and Conquer** - Recursive problem decomposition
- **Democratic Voting** - Collective solution selection
- **Consensus Building** - Iterative refinement
- **Competitive Solving** - Best solution wins
- **Genetic Algorithms** - Evolution-based optimization
- **Hybrid** - Combines multiple methods

## 🚀 Quick Start

### Installation

```bash
# Install dependencies
pip install pydantic pydantic-ai

# Clone or navigate to repository
cd bash.d
```

### Basic Example

```python
import asyncio
from agents.base import BaseAgent, Task, TaskPriority, AgentType
from agents.autonomous_crew import AutonomousCrew, CrewStrategy

async def main():
    # Create specialized agents
    agents = [
        BaseAgent(name="Python Dev", type=AgentType.PROGRAMMING, 
                 description="Expert Python developer"),
        BaseAgent(name="Test Engineer", type=AgentType.TESTING,
                 description="Testing specialist"),
        BaseAgent(name="Doc Writer", type=AgentType.DOCUMENTATION,
                 description="Technical writer")
    ]
    
    # Form autonomous crew
    crew = AutonomousCrew(name="Dev Crew", strategy=CrewStrategy.DEMOCRATIC)
    crew.add_agents(agents)
    
    # Define complex task
    task = Task(
        title="Build REST API",
        description="Create complete REST API with tests and documentation",
        priority=TaskPriority.HIGH
    )
    
    # Execute autonomously until complete
    result = await crew.execute_autonomously(task)
    
    print(f"Success rate: {result['tasks']['success_rate']:.0%}")
    print(f"Iterations: {result['iterations']}")
    print(f"Status: {result['final_status']}")

asyncio.run(main())
```

## 📊 System Architecture

```
┌────────────────────────────────────────────────────────────┐
│                  Autonomous Crew Layer                      │
│  • Democratic Decision Making                               │
│  • Self-Organization & Adaptation                           │
│  • Auto-Recovery & Learning                                 │
└────────────────────────────────────────────────────────────┘
                           ↓
┌────────────────────────────────────────────────────────────┐
│            Swarm Intelligence Coordinator                   │
│  • PSO: Optimization through particle movement              │
│  • ACO: Path finding through pheromone trails               │
│  • ABC: Resource allocation through bee foraging            │
└────────────────────────────────────────────────────────────┘
                           ↓
┌────────────────────────────────────────────────────────────┐
│           Hierarchical Organization                         │
│  • Managers: Task decomposition & planning                  │
│  • Coordinators: Synchronization & communication            │
│  • Workers: Specialized execution                           │
└────────────────────────────────────────────────────────────┘
                           ↓
┌────────────────────────────────────────────────────────────┐
│          Problem-Solving Algorithms                         │
│  • Divide & Conquer                                         │
│  • Genetic Algorithms                                       │
│  • Democratic Voting                                        │
│  • Consensus Building                                       │
│  • Competitive Selection                                    │
└────────────────────────────────────────────────────────────┘
                           ↓
┌────────────────────────────────────────────────────────────┐
│                  Base Agent Framework                       │
│  Programming • Testing • DevOps • Security • Documentation  │
└────────────────────────────────────────────────────────────┘
```

## 🎯 Use Cases

### 1. Complex Code Generation

```python
task = Task(
    title="Build Microservice",
    description="""
    Create a complete user management microservice:
    - REST API endpoints
    - Database integration
    - Authentication
    - Tests (90% coverage)
    - API documentation
    - Docker containerization
    """
)

# Crew handles everything autonomously
result = await crew.execute_autonomously(task)
```

### 2. System Optimization

```python
# Use swarm intelligence to optimize architecture
swarm = SwarmCoordinator(strategy=SwarmStrategy.PARTICLE_SWARM)

def evaluate_architecture(params):
    # Score based on latency, cost, availability
    return calculate_performance_score(params)

best_architecture, score = await swarm.optimize_pso(evaluate_architecture)
```

### 3. Distributed Problem Solving

```python
# Use divide and conquer for large problems
solver = IntelligentProblemSolver()

problem = Problem(
    id="large_scale_system",
    description="Design system for 1M concurrent users",
    complexity=50
)

solution = await solver.solve(problem, agents, 
                              method=ProblemSolvingMethod.DIVIDE_CONQUER)
```

## 📁 File Structure

```
agents/
├── base.py                  # Core agent classes and models
├── hierarchy.py             # Hierarchical organization (Manager/Coordinator/Worker)
├── swarm.py                 # Swarm intelligence algorithms (PSO/ACO/ABC)
├── autonomous_crew.py       # Autonomous self-organizing crews
├── problem_solving.py       # Problem-solving algorithms
├── orchestrator.py          # Agent orchestration system
└── demo_multiagent.py      # Comprehensive demonstration

docs/
└── MULTIAGENT_SYSTEM.md    # Detailed documentation

tests/
├── __init__.py
└── test_multiagent_simple.py  # Test suite
```

## 🧪 Testing

### Run Tests

```bash
# Run simple tests
python tests/test_multiagent_simple.py

# Run with pytest (if installed)
pytest tests/ -v

# Run comprehensive demo
python -m agents.demo_multiagent
```

### Test Coverage

- ✅ Agent creation and configuration
- ✅ Task decomposition
- ✅ Swarm optimization (PSO, ACO, ABC)
- ✅ Autonomous crew execution
- ✅ Problem-solving algorithms
- ✅ Democratic decision making
- ✅ Hierarchical coordination

## 📚 Documentation

- [Comprehensive Guide](docs/MULTIAGENT_SYSTEM.md) - Full documentation with examples
- [Architecture Overview](README_AGENTIC_SYSTEM.md) - System architecture
- [API Reference](docs/MULTIAGENT_SYSTEM.md#api-reference) - API documentation

## 🎓 Advanced Features

### Learning and Adaptation

Crews learn from experience and optimize their strategies:

```python
crew = AutonomousCrew(learning_enabled=True, strategy=CrewStrategy.ADAPTIVE)

# After multiple tasks, crew learns which strategies work best
await crew.execute_autonomously(task1)
await crew.execute_autonomously(task2)

# View learned performance
print(crew.strategy_scores)
print(crew.performance_history)
```

### Democratic Decision Making

Agents vote on important decisions:

```python
# Agents vote on best approach
crew = AutonomousCrew(strategy=CrewStrategy.DEMOCRATIC, consensus_threshold=0.8)

# 80% agreement needed for decisions
# Voting happens automatically on:
# - Task decomposition
# - Agent assignments
# - Solution selection
# - Completion verification
```

### Automatic Recovery

Built-in error handling and recovery:

```python
crew = AutonomousCrew(auto_recovery=True)

# Crew automatically:
# - Retries failed tasks
# - Reassigns stuck tasks
# - Requests additional agents if needed
# - Adapts strategies based on failures
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
    a2a_enabled=True
)
```

### Swarm Parameters

```python
# PSO parameters
swarm.optimize_pso(
    fitness_func=objective,
    w=0.7,    # Inertia weight (exploration vs exploitation)
    c1=1.5,   # Cognitive parameter (personal best influence)
    c2=1.5    # Social parameter (global best influence)
)

# ACO parameters
swarm.optimize_aco(
    graph=dependency_graph,
    alpha=1.0,  # Pheromone importance
    beta=2.0,   # Heuristic importance
    evaporation=0.1
)
```

## 📊 Monitoring

### Get Crew Status

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
print(f"Best fitness: {metrics['global_best_fitness']}")
print(f"Convergence: {metrics['convergence_history']}")
```

## 🤝 Contributing

Areas for enhancement:

1. Additional swarm algorithms (Firefly, Wolf Pack)
2. More problem-solving methods (Simulated Annealing, Tabu Search)
3. Advanced learning algorithms
4. Performance optimizations
5. Additional agent types and specializations

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

Built on concepts from:
- Swarm Intelligence research
- Multi-Agent Systems theory
- Distributed Computing
- Genetic Algorithms
- Collective Intelligence

---

**Ready for production use with autonomous, intelligent problem solving!**

For detailed documentation, see [docs/MULTIAGENT_SYSTEM.md](docs/MULTIAGENT_SYSTEM.md)
