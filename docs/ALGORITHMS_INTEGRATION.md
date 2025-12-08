# Algorithms Integration Guide

## Overview

This guide explains how the code generation and problem-solving algorithms integrate with the multi-agentic system architecture.

## Architecture Integration

```
┌─────────────────────────────────────────────────────────────┐
│                  Agent Orchestrator                          │
│  (Task Distribution, Health Monitoring, Load Balancing)     │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│               Algorithm-Enabled Agents                       │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Code Generation  │  │ Problem Solver   │                │
│  │     Agent        │  │     Agent        │                │
│  └──────────────────┘  └──────────────────┘                │
│  ┌──────────────────┐                                       │
│  │ Algorithm        │                                       │
│  │ Optimizer Agent  │                                       │
│  └──────────────────┘                                       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│            Algorithm Orchestrator                            │
│  (Smart Selection, Performance Tracking, Comparison)        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                  Algorithm Layer                             │
│  ┌───────────────────┐  ┌───────────────────┐              │
│  │ Code Generation   │  │ Problem Solving   │              │
│  │ Algorithms (4)    │  │ Algorithms (5)    │              │
│  └───────────────────┘  └───────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

## Using Algorithms in Existing Agents

### Example 1: Extending an Existing Agent

```python
# In agents/programming/python_backend_developer_agent.py

from ..algorithms.code_generation import TemplateBasedCodeGenerator, PatternBasedCodeGenerator

class PythonBackendDeveloperAgent(BaseAgent):
    def __init__(self, **data):
        super().__init__(**data)
        
        # Add code generation capability
        self.template_generator = TemplateBasedCodeGenerator()
        self.pattern_generator = PatternBasedCodeGenerator()
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute Python backend development task"""
        
        if task.input_data.get("action") == "generate_api":
            # Use template generator for API boilerplate
            result = self.template_generator.execute({
                "template_name": "api_endpoint",
                "language": "python",
                "variables": task.input_data.get("variables", {})
            })
            return {"generated_code": result.result_data["generated_code"]}
        
        elif task.input_data.get("action") == "implement_pattern":
            # Use pattern generator for design patterns
            result = self.pattern_generator.execute({
                "pattern": task.input_data.get("pattern"),
                "class_name": task.input_data.get("class_name"),
                "language": "python"
            })
            return {"generated_code": result.result_data["generated_code"]}
        
        # ... existing logic
```

### Example 2: Creating Task-Specific Workflows

```python
# In agents/orchestrator.py - Add algorithm-aware task routing

from .algorithms.optimization import AlgorithmOrchestrator

class AgentOrchestrator:
    def __init__(self):
        # ... existing init
        self.algorithm_orchestrator = AlgorithmOrchestrator()
    
    def assign_task(self, task: Task) -> Optional[BaseAgent]:
        """Enhanced task assignment with algorithm awareness"""
        
        # For code generation tasks, recommend best algorithm
        if "generate" in task.title.lower() or "code" in task.title.lower():
            recommendation = self.algorithm_orchestrator.recommend_algorithm({
                "task": "code_generation",
                "requirements": task.input_data
            })
            
            # Add recommendation to task metadata
            task.metadata["recommended_algorithm"] = recommendation
        
        # For optimization/problem-solving tasks
        elif any(keyword in task.title.lower() for keyword in ["solve", "optimize", "calculate"]):
            recommendation = self.algorithm_orchestrator.recommend_algorithm({
                "task": task.title,
                "requirements": task.input_data
            })
            
            task.metadata["recommended_algorithm"] = recommendation
        
        # Continue with existing assignment logic
        return super().assign_task(task)
```

## Task Examples for Multi-Agentic System

### Code Generation Tasks

```python
# Task 1: Generate REST API
task1 = Task(
    title="Generate User Management API",
    description="Create REST API for user management",
    agent_type=AgentType.AUTOMATION,
    input_data={
        "generation_type": "template",
        "template_name": "api_endpoint",
        "language": "python",
        "variables": {
            "method": "post",
            "path": "/users",
            "endpoint_name": "create_user",
            "parameters": "user_data: dict",
            "description": "Create a new user",
            "body": "user = User(**user_data)\ndb.add(user)\nresult = user.to_dict()"
        }
    }
)

# Task 2: Implement Design Pattern
task2 = Task(
    title="Implement Factory Pattern",
    description="Create factory for data processors",
    agent_type=AgentType.AUTOMATION,
    input_data={
        "generation_type": "pattern",
        "pattern": "factory",
        "language": "python",
        "factory_name": "DataProcessorFactory",
        "product_interface": "DataProcessor",
        "concrete_products": ["CSVProcessor", "JSONProcessor", "XMLProcessor"]
    }
)
```

### Problem-Solving Tasks

```python
# Task 3: Optimize Resource Allocation
task3 = Task(
    title="Optimize Server Resource Allocation",
    description="Allocate tasks to servers optimally",
    agent_type=AgentType.AUTOMATION,
    input_data={
        "solver_type": "dynamic_programming",
        "problem_type": "knapsack",
        "items": [
            {"weight": 100, "value": 50},  # Task 1: CPU 100, Value 50
            {"weight": 200, "value": 120}, # Task 2: CPU 200, Value 120
            {"weight": 150, "value": 90},  # Task 3: CPU 150, Value 90
        ],
        "capacity": 300  # Total CPU available
    }
)

# Task 4: Schedule Jobs
task4 = Task(
    title="Schedule Build Jobs",
    description="Schedule CI/CD build jobs optimally",
    agent_type=AgentType.AUTOMATION,
    input_data={
        "solver_type": "greedy",
        "problem_type": "job_sequencing",
        "jobs": [
            {"id": "build-1", "deadline": 3, "profit": 40},
            {"id": "build-2", "deadline": 1, "profit": 35},
            {"id": "build-3", "deadline": 2, "profit": 30},
            {"id": "test-1", "deadline": 2, "profit": 25},
        ]
    }
)
```

## Agent Collaboration Patterns

### Pattern 1: Sequential Algorithm Application

```python
async def complex_code_generation_workflow(orchestrator: AgentOrchestrator):
    """Generate code using multiple algorithms in sequence"""
    
    # Step 1: Code Generation Agent generates base class
    task1 = Task(
        title="Generate Base Class",
        input_data={
            "generation_type": "pattern",
            "pattern": "singleton"
        }
    )
    base_code = await orchestrator.execute_task(task1)
    
    # Step 2: Code Generation Agent adds methods via templates
    task2 = Task(
        title="Add Methods",
        input_data={
            "generation_type": "template",
            "template_name": "function_definition",
            "base_code": base_code
        }
    )
    enhanced_code = await orchestrator.execute_task(task2)
    
    # Step 3: Algorithm Optimizer validates and suggests improvements
    task3 = Task(
        title="Optimize Generated Code",
        input_data={
            "action": "analyze",
            "code": enhanced_code
        }
    )
    analysis = await orchestrator.execute_task(task3)
    
    return enhanced_code, analysis
```

### Pattern 2: Parallel Algorithm Comparison

```python
async def find_best_solution(orchestrator: AlgorithmOrchestrator, problem: Dict):
    """Try multiple algorithms and pick the best"""
    
    # Run algorithms in parallel (conceptually)
    algorithms = ["divide_conquer", "dynamic_programming", "greedy"]
    
    results = orchestrator.compare_algorithms(problem, algorithms)
    
    # Pick fastest successful result
    best_result = min(
        [r for r in results.values() if r.success],
        key=lambda r: r.execution_time_ms
    )
    
    return best_result
```

### Pattern 3: Agent Recommendation System

```python
class SmartTaskRouter:
    """Routes tasks to best agent based on algorithm capabilities"""
    
    def __init__(self, orchestrator: AgentOrchestrator):
        self.orchestrator = orchestrator
        self.algorithm_orchestrator = AlgorithmOrchestrator()
    
    def route_task(self, task: Task) -> BaseAgent:
        """Route task to agent with best algorithm for the job"""
        
        # Get algorithm recommendation
        recommendation = self.algorithm_orchestrator.recommend_algorithm({
            "task": task.title,
            "requirements": task.input_data
        })
        
        # Find agents with this capability
        capable_agents = [
            agent for agent in self.orchestrator.agents.values()
            if recommendation["algorithm"] in agent.metadata.get("algorithms_available", [])
        ]
        
        # Return best available agent
        return self.orchestrator.select_best_agent(capable_agents, task)
```

## Performance Monitoring Integration

```python
# In agents/orchestrator.py - Enhanced monitoring

class EnhancedAgentOrchestrator(AgentOrchestrator):
    def __init__(self):
        super().__init__()
        self.algorithm_orchestrator = AlgorithmOrchestrator()
    
    def get_system_metrics(self) -> Dict[str, Any]:
        """Get comprehensive system metrics including algorithms"""
        
        base_metrics = super().get_status()
        
        # Add algorithm metrics
        base_metrics["algorithms"] = {
            "total_executions": sum(
                m["executions"] 
                for m in self.algorithm_orchestrator.get_algorithm_metrics().values()
            ),
            "algorithm_performance": self.algorithm_orchestrator.get_algorithm_metrics(),
            "recommendations_made": len(self.algorithm_orchestrator.get_execution_history())
        }
        
        return base_metrics
```

## Best Practices

### 1. Use Algorithm Orchestrator for Unknown Problems

```python
# Good: Let orchestrator choose
orchestrator = AlgorithmOrchestrator()
result = orchestrator.execute_with_best_algorithm(problem)

# Avoid: Hardcoding algorithm choice unless specific requirement
generator = TemplateBasedCodeGenerator()
result = generator.execute(problem)  # Only if you know template is best
```

### 2. Cache Results for Repeated Problems

```python
class CachedAlgorithmAgent(BaseAgent):
    def __init__(self):
        super().__init__()
        self.cache = {}
    
    async def execute_task(self, task: Task):
        cache_key = hash(str(task.input_data))
        
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        result = await self.algorithm.execute(task.input_data)
        self.cache[cache_key] = result
        return result
```

### 3. Monitor Algorithm Performance

```python
# Regularly check algorithm metrics
def health_check_algorithms():
    orchestrator = AlgorithmOrchestrator()
    metrics = orchestrator.get_algorithm_metrics()
    
    for algo, metric in metrics.items():
        if metric["success_rate"] < 0.8:
            logger.warning(f"{algo} has low success rate: {metric['success_rate']}")
        
        if metric["avg_execution_time_ms"] > 1000:
            logger.warning(f"{algo} has high latency: {metric['avg_execution_time_ms']}ms")
```

## Migration Path for Existing Agents

1. **Identify algorithmic tasks** in your agents
2. **Import appropriate algorithm** from `agents.algorithms`
3. **Replace manual logic** with algorithm calls
4. **Test performance** with metrics
5. **Iterate and optimize** based on results

## OpenAI API Integration

All agents support OpenAI function calling:

```python
from agents.automation import CodeGenerationAgent

agent = CodeGenerationAgent()
schema = agent.get_openai_function_schema()

# Use in OpenAI API
functions = [schema]
response = openai.ChatCompletion.create(
    model="gpt-4",
    messages=[...],
    functions=functions
)
```

## Conclusion

The algorithms module seamlessly integrates with the existing multi-agentic system:

- ✅ **Plug-and-play**: Easy to add to existing agents
- ✅ **Orchestrated**: Smart algorithm selection
- ✅ **Monitored**: Full performance metrics
- ✅ **Scalable**: Multiple algorithms can run in parallel
- ✅ **OpenAI Compatible**: Standard function schemas

For detailed algorithm documentation, see `agents/algorithms/README.md`.
For example usage, see `examples/algorithm_examples.py`.
