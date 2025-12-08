# Algorithms Module for Multi-Agentic Systems

This module provides comprehensive code generation and problem-solving algorithms designed for multi-agentic systems to solve complex problems.

## 📚 Overview

The algorithms module consists of three main categories:

1. **Code Generation Algorithms** - Generate code from various sources
2. **Problem Solving Algorithms** - Solve computational problems efficiently
3. **Optimization** - Orchestrate and optimize algorithm selection

## 🎯 Code Generation Algorithms

### 1. Template-Based Code Generator
Generates code using predefined templates with variable substitution.

**Use Cases:**
- Boilerplate code generation
- Standardized code patterns
- Quick scaffolding

**Example:**
```python
from agents.algorithms.code_generation import TemplateBasedCodeGenerator

generator = TemplateBasedCodeGenerator()
result = generator.execute({
    "template_name": "class_definition",
    "language": "python",
    "variables": {
        "class_name": "UserManager",
        "base_class": "BaseManager",
        "description": "Manages user operations",
        "init_params": "db_connection",
        "init_body": "self.db = db_connection",
        "methods": "    def get_user(self, user_id):\n        pass"
    }
})
print(result.result_data["generated_code"])
```

### 2. AST-Based Code Generator
Generates code by building and manipulating Abstract Syntax Trees.

**Use Cases:**
- Syntactically valid code generation
- Code transformation
- Refactoring automation

**Example:**
```python
from agents.algorithms.code_generation import ASTBasedCodeGenerator

generator = ASTBasedCodeGenerator()
result = generator.execute({
    "ast_type": "function",
    "name": "calculate_total",
    "parameters": ["items", "tax_rate"],
    "body": [
        {"type": "assign", "target": "subtotal", "value": "sum(items)"},
        {"type": "assign", "target": "tax", "value": "subtotal * tax_rate"},
        {"type": "return", "value": "subtotal + tax"}
    ]
})
print(result.result_data["generated_code"])
```

### 3. Pattern-Based Code Generator
Implements common software design patterns.

**Supported Patterns:**
- Singleton
- Factory
- Observer
- Strategy
- Builder
- Adapter

**Example:**
```python
from agents.algorithms.code_generation import PatternBasedCodeGenerator

generator = PatternBasedCodeGenerator()
result = generator.execute({
    "pattern": "singleton",
    "class_name": "DatabaseConnection",
    "language": "python",
    "additional_methods": ["connect", "disconnect", "query"]
})
print(result.result_data["generated_code"])
```

### 4. AI-Assisted Code Generator
Uses AI models for intelligent, context-aware code generation.

**Example:**
```python
from agents.algorithms.code_generation import AIAssistedCodeGenerator

generator = AIAssistedCodeGenerator()
result = generator.execute({
    "prompt": "Create a function that validates email addresses",
    "language": "python",
    "context": {
        "style": "functional",
        "include_tests": True,
        "include_docstrings": True,
        "include_type_hints": True
    }
})
print(result.result_data["generated_code"])
```

## 🧩 Problem Solving Algorithms

### 1. Divide and Conquer Solver
Breaks problems into smaller subproblems.

**Supported Problems:**
- Merge Sort
- Quick Sort
- Binary Search
- Maximum Subarray
- Closest Pair of Points
- Matrix Multiplication

**Example:**
```python
from agents.algorithms.problem_solving import DivideAndConquerSolver

solver = DivideAndConquerSolver()
result = solver.execute({
    "problem_type": "merge_sort",
    "data": [64, 34, 25, 12, 22, 11, 90]
})
print(f"Sorted: {result.result_data['result']}")
```

### 2. Backtracking Solver
Explores solution space with intelligent backtracking.

**Supported Problems:**
- N-Queens
- Sudoku
- Subset Sum
- Permutations
- Combinations
- Graph Coloring
- Maze Solving

**Example:**
```python
from agents.algorithms.problem_solving import BacktrackingSolver

solver = BacktrackingSolver()
result = solver.execute({
    "problem_type": "n_queens",
    "n": 8
})
print(f"Solutions found: {result.result_data['result']['solutions_count']}")
```

### 3. Dynamic Programming Solver
Solves optimization problems with memoization.

**Supported Problems:**
- Fibonacci Sequence
- 0/1 Knapsack
- Longest Common Subsequence
- Edit Distance
- Coin Change
- Longest Increasing Subsequence
- Matrix Chain Multiplication

**Example:**
```python
from agents.algorithms.problem_solving import DynamicProgrammingSolver

solver = DynamicProgrammingSolver()
result = solver.execute({
    "problem_type": "knapsack",
    "items": [
        {"weight": 2, "value": 3},
        {"weight": 3, "value": 4},
        {"weight": 4, "value": 5},
        {"weight": 5, "value": 6}
    ],
    "capacity": 8
})
print(f"Maximum value: {result.result_data['result']['max_value']}")
```

### 4. Greedy Algorithm Solver
Makes locally optimal choices.

**Supported Problems:**
- Activity Selection
- Fractional Knapsack
- Huffman Coding
- Interval Scheduling
- Job Sequencing
- Minimum Coins
- Task Assignment

**Example:**
```python
from agents.algorithms.problem_solving import GreedyAlgorithmSolver

solver = GreedyAlgorithmSolver()
result = solver.execute({
    "problem_type": "activity_selection",
    "activities": [
        {"start": 1, "end": 3},
        {"start": 2, "end": 5},
        {"start": 4, "end": 7},
        {"start": 6, "end": 9}
    ]
})
print(f"Selected activities: {result.result_data['result']['count']}")
```

### 5. Constraint Satisfaction Solver
Solves problems with variables, domains, and constraints.

**Supported Problems:**
- Map Coloring
- Scheduling
- Cryptarithmetic
- Logic Puzzles

**Example:**
```python
from agents.algorithms.problem_solving import ConstraintSatisfactionSolver

solver = ConstraintSatisfactionSolver()
result = solver.execute({
    "problem_type": "map_coloring",
    "variables": ["WA", "NT", "SA", "Q", "NSW", "V"],
    "domains": {var: ["red", "green", "blue"] for var in ["WA", "NT", "SA", "Q", "NSW", "V"]},
    "constraints": [("WA", "NT"), ("WA", "SA"), ("NT", "SA"), ("NT", "Q"), 
                   ("SA", "Q"), ("SA", "NSW"), ("SA", "V"), ("Q", "NSW"), ("NSW", "V")]
})
print(f"Solution: {result.result_data['result']['solution']}")
```

## 🎼 Algorithm Orchestrator

The orchestrator automatically selects the best algorithm for your problem.

**Example:**
```python
from agents.algorithms.optimization import AlgorithmOrchestrator

orchestrator = AlgorithmOrchestrator()

# Get recommendation
recommendation = orchestrator.recommend_algorithm({
    "task": "code_generation",
    "requirements": {"pattern": "singleton"}
})
print(f"Recommended: {recommendation['algorithm_name']}")

# Execute with best algorithm
result = orchestrator.execute_with_best_algorithm({
    "pattern": "singleton",
    "class_name": "ConfigManager",
    "language": "python"
})

# Compare algorithms
results = orchestrator.compare_algorithms(
    problem={"problem_type": "merge_sort", "data": [3, 1, 4, 1, 5]},
    algorithm_keys=["divide_conquer", "greedy"]
)

# Get metrics
metrics = orchestrator.get_algorithm_metrics()
print(metrics)
```

## 🤖 Specialized Agents

### Code Generation Agent
```python
from agents.automation import CodeGenerationAgent
import asyncio

agent = CodeGenerationAgent()

task = Task(
    title="Generate Singleton",
    description="Create a singleton pattern",
    input_data={
        "generation_type": "pattern",
        "pattern": "singleton",
        "class_name": "DatabasePool"
    }
)

result = asyncio.run(agent.execute_task(task))
print(result["generated_code"])
```

### Problem Solver Agent
```python
from agents.automation import ProblemSolverAgent
import asyncio

agent = ProblemSolverAgent()

task = Task(
    title="Solve Knapsack",
    description="Optimize knapsack problem",
    input_data={
        "solver_type": "dynamic_programming",
        "problem_type": "knapsack",
        "items": [{"weight": 2, "value": 3}, {"weight": 3, "value": 4}],
        "capacity": 5
    }
)

result = asyncio.run(agent.execute_task(task))
print(result["solution"])
```

### Algorithm Optimizer Agent
```python
from agents.automation import AlgorithmOptimizerAgent
import asyncio

agent = AlgorithmOptimizerAgent()

# Get recommendation
task = Task(
    title="Recommend Algorithm",
    description="Find best algorithm for sorting",
    input_data={
        "action": "recommend",
        "problem": {
            "task": "sorting large dataset",
            "requirements": {"data_size": "large"}
        }
    }
)

result = asyncio.run(agent.execute_task(task))
print(result["recommendation"])
```

## 📊 Performance Metrics

All algorithms track:
- Execution count
- Success/failure rates
- Average execution time
- Error tracking

Access metrics via:
```python
algorithm.get_metrics()
```

## 🚀 Quick Start

```python
# Install dependencies (if needed)
# pip install pydantic

# Import what you need
from agents.algorithms.code_generation import TemplateBasedCodeGenerator
from agents.algorithms.problem_solving import DynamicProgrammingSolver
from agents.algorithms.optimization import AlgorithmOrchestrator

# Use individual algorithms
generator = TemplateBasedCodeGenerator()
solver = DynamicProgrammingSolver()

# Or use orchestrator for automatic selection
orchestrator = AlgorithmOrchestrator()
result = orchestrator.execute_with_best_algorithm(your_problem)
```

## 🔧 Configuration

Configure algorithm behavior:
```python
from agents.algorithms.base import AlgorithmConfig

config = AlgorithmConfig(
    max_iterations=5000,
    timeout_seconds=600,
    optimize_for="speed",  # or "quality", "memory"
    debug_mode=True,
    parallel_execution=False
)

algorithm = YourAlgorithm(config=config)
```

## 📖 Integration with Multi-Agentic Systems

These algorithms are designed to work seamlessly with the multi-agentic system:

1. **Agents** can use algorithms to solve assigned tasks
2. **Orchestrator** distributes problems to appropriate algorithm-enabled agents
3. **Collaboration** between agents using different algorithms
4. **Metrics** feed back into agent performance monitoring

## 🤝 Contributing

To add new algorithms:

1. Inherit from `Algorithm` base class
2. Implement `_execute_core()` method
3. Add to appropriate category module
4. Update orchestrator with recommendation logic

## 📝 License

Part of the bash.d multi-agentic system - MIT License
