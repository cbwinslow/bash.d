# Algorithm Reference Guide

Quick reference for which algorithm to use for specific problems.

## Code Generation Algorithms

### Template-Based Generator
**Best for:** Repetitive code, boilerplate, standardized patterns

| Use Case | Template | Language Support |
|----------|----------|------------------|
| Class definitions | `class_definition` | Python, JavaScript, Go |
| Function definitions | `function_definition` | Python, JavaScript, Go |
| API endpoints | `api_endpoint` | Python |
| Test cases | `test_case` | Python |
| React components | `react_component` | JavaScript |
| Struct definitions | `struct_definition` | Go |
| Interface definitions | `interface_definition` | Go |

**Example:**
```python
# Generate a Python class
generator.execute({
    "template_name": "class_definition",
    "language": "python",
    "variables": {...}
})
```

### AST-Based Generator
**Best for:** Syntactically correct code, transformations, refactoring

| Use Case | AST Type | Description |
|----------|----------|-------------|
| Functions | `function` | Generate function with body |
| Classes | `class` | Generate class with methods |
| Modules | `module` | Generate module with imports |
| Expressions | `expression` | Generate expressions |

**Example:**
```python
# Generate a function with AST
generator.execute({
    "ast_type": "function",
    "name": "process_data",
    "parameters": ["data"],
    "body": [...]
})
```

### Pattern-Based Generator
**Best for:** Design patterns, architectural patterns

| Pattern | Use Case | Complexity |
|---------|----------|------------|
| Singleton | Single instance classes | Low |
| Factory | Object creation | Medium |
| Observer | Event systems | Medium |
| Strategy | Interchangeable algorithms | Medium |
| Builder | Complex object construction | Medium |
| Adapter | Interface compatibility | Low |

**Example:**
```python
# Generate Singleton pattern
generator.execute({
    "pattern": "singleton",
    "class_name": "ConfigManager"
})
```

### AI-Assisted Generator
**Best for:** Complex logic, natural language descriptions, custom requirements

| Use Case | Context Options |
|----------|----------------|
| Custom functions | `style`, `include_tests`, `include_docstrings` |
| Complex algorithms | `framework`, `design_pattern` |
| Full features | `include_type_hints`, `additional_requirements` |

**Example:**
```python
# Generate from natural language
generator.execute({
    "prompt": "Create a function to validate email addresses",
    "language": "python",
    "context": {"include_tests": True}
})
```

## Problem-Solving Algorithms

### Divide and Conquer
**Best for:** Problems that can be broken into independent subproblems

| Problem Type | Time Complexity | Space | Use Case |
|--------------|----------------|-------|----------|
| `merge_sort` | O(n log n) | O(n) | Sorting data |
| `quick_sort` | O(n log n) avg | O(log n) | Fast sorting |
| `binary_search` | O(log n) | O(1) | Searching sorted data |
| `max_subarray` | O(n log n) | O(log n) | Maximum sum subarray |
| `closest_pair` | O(n log n) | O(n) | Closest points |
| `strassen_matrix` | O(n^2.8) | O(n^2) | Matrix multiplication |

**When to use:**
- ✅ Data can be divided equally
- ✅ Subproblems are independent
- ✅ Need optimal solution
- ❌ Cannot divide problem easily

### Backtracking
**Best for:** Constraint satisfaction, exploration problems

| Problem Type | Typical Size | Use Case |
|--------------|-------------|----------|
| `n_queens` | n ≤ 20 | Placement problems |
| `sudoku` | 9x9 board | Puzzle solving |
| `subset_sum` | n ≤ 30 | Combination finding |
| `permutations` | n ≤ 10 | All arrangements |
| `combinations` | n ≤ 20 | Subset selection |
| `graph_coloring` | nodes ≤ 50 | Resource allocation |
| `maze` | size ≤ 1000 | Path finding |

**When to use:**
- ✅ Need all solutions or one valid solution
- ✅ Constraints can prune search space
- ✅ No better algorithm available
- ❌ Search space is too large

### Dynamic Programming
**Best for:** Optimization problems with overlapping subproblems

| Problem Type | Time Complexity | Space | Use Case |
|--------------|----------------|-------|----------|
| `fibonacci` | O(n) | O(n) | Sequence generation |
| `knapsack` | O(nW) | O(nW) | Resource optimization |
| `longest_common_subsequence` | O(mn) | O(mn) | String similarity |
| `edit_distance` | O(mn) | O(mn) | String comparison |
| `coin_change` | O(nA) | O(A) | Making change |
| `longest_increasing_subsequence` | O(n²) | O(n) | Finding patterns |
| `matrix_chain_multiplication` | O(n³) | O(n²) | Optimal ordering |

**When to use:**
- ✅ Optimal substructure exists
- ✅ Overlapping subproblems
- ✅ Need optimal solution
- ❌ No overlapping subproblems

### Greedy Algorithms
**Best for:** Problems where local optimum leads to global optimum

| Problem Type | Time Complexity | Optimal? | Use Case |
|--------------|----------------|----------|----------|
| `activity_selection` | O(n log n) | ✓ | Scheduling |
| `fractional_knapsack` | O(n log n) | ✓ | Resource allocation |
| `huffman_coding` | O(n log n) | ✓ | Compression |
| `interval_scheduling` | O(n log n) | ✓ | Meeting rooms |
| `job_sequencing` | O(n log n) | ✓ | Deadline scheduling |
| `minimum_coins` | O(n) | Sometimes | Making change |
| `task_assignment` | O(n log n) | Heuristic | Load balancing |

**When to use:**
- ✅ Greedy choice property holds
- ✅ Need fast approximation
- ✅ Proven optimal for problem
- ❌ Need guaranteed optimal (use DP)

### Constraint Satisfaction
**Best for:** Problems with variables, domains, and constraints

| Problem Type | Variables | Constraints | Use Case |
|--------------|-----------|-------------|----------|
| `map_coloring` | Regions | Adjacent regions | Resource conflicts |
| `scheduling` | Tasks | Time/resources | Project planning |
| `cryptarithmetic` | Letters | Arithmetic rules | Puzzle solving |
| `logic_puzzle` | Any | Any | General CSP |

**When to use:**
- ✅ Clear variables and domains
- ✅ Explicit constraints
- ✅ Need valid solution
- ❌ Too many variables (>100)

## Algorithm Selection Decision Tree

```
Is it code generation?
├─ Yes → Is it a design pattern?
│  ├─ Yes → Pattern-Based Generator
│  └─ No → Is it standard boilerplate?
│     ├─ Yes → Template-Based Generator
│     └─ No → Is syntax critical?
│        ├─ Yes → AST-Based Generator
│        └─ No → AI-Assisted Generator
│
└─ No → Is it an optimization problem?
   ├─ Yes → Has overlapping subproblems?
   │  ├─ Yes → Dynamic Programming
   │  └─ No → Can local optimum work?
   │     ├─ Yes → Greedy Algorithm
   │     └─ No → Try all combinations?
   │        ├─ Yes → Backtracking
   │        └─ No → Divide and Conquer
   │
   └─ No → Is it sorting/searching?
      ├─ Yes → Divide and Conquer
      └─ No → Has explicit constraints?
         ├─ Yes → Constraint Satisfaction
         └─ No → Use Algorithm Orchestrator

```

## Performance Characteristics

### Speed Comparison (Typical)

| Algorithm Category | Small Input | Medium Input | Large Input |
|-------------------|-------------|--------------|-------------|
| Template Generation | 1-5 ms | 5-20 ms | 20-100 ms |
| AST Generation | 5-10 ms | 10-50 ms | 50-200 ms |
| Pattern Generation | 1-5 ms | 5-20 ms | 20-100 ms |
| AI Generation | 100-500 ms | 500-2000 ms | 2000-5000 ms |
| Divide & Conquer | 1-10 ms | 10-100 ms | 100-1000 ms |
| Backtracking | 10-100 ms | 100-1000 ms | 1000+ ms |
| Dynamic Programming | 5-50 ms | 50-500 ms | 500-5000 ms |
| Greedy | 1-5 ms | 5-50 ms | 50-500 ms |
| CSP | 10-100 ms | 100-1000 ms | 1000+ ms |

### Space Complexity

| Algorithm | Space Usage | Notes |
|-----------|-------------|-------|
| Template Generation | O(1) | Minimal memory |
| AST Generation | O(n) | AST tree size |
| Pattern Generation | O(1) | Template-based |
| AI Generation | O(n) | Context size |
| Divide & Conquer | O(log n) - O(n) | Recursion depth |
| Backtracking | O(n) | Stack depth |
| Dynamic Programming | O(n) - O(n²) | DP table |
| Greedy | O(1) - O(n) | Sorting space |
| CSP | O(nd) | Variables × domain |

## Common Use Cases

### Web Development
- **API Generation**: Template-Based Generator
- **Component Creation**: Template/Pattern-Based Generator
- **Database Models**: Pattern-Based Generator (Builder)
- **Route Optimization**: Greedy/Dynamic Programming

### Data Processing
- **Sorting Large Datasets**: Divide and Conquer (Merge Sort)
- **Finding Patterns**: Dynamic Programming (LCS, LIS)
- **Resource Allocation**: Dynamic Programming (Knapsack)
- **Task Scheduling**: Greedy (Activity Selection)

### DevOps/Automation
- **Config Generation**: Template-Based Generator
- **Build Job Scheduling**: Greedy (Job Sequencing)
- **Container Orchestration**: Constraint Satisfaction
- **Load Balancing**: Greedy (Task Assignment)

### Machine Learning
- **Feature Selection**: Greedy/Dynamic Programming
- **Hyperparameter Tuning**: Backtracking/CSP
- **Data Preprocessing**: Divide and Conquer
- **Pipeline Generation**: Template/Pattern-Based

## Error Handling

### Common Issues and Solutions

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| Timeout | Problem too large | Use greedy approximation |
| No solution found | Constraints too strict | Relax constraints |
| High memory usage | Large DP table | Use space optimization |
| Slow performance | Wrong algorithm | Use Algorithm Orchestrator |

## Quick Start Snippets

### Generate a Class
```python
from agents.algorithms.code_generation import PatternBasedCodeGenerator

gen = PatternBasedCodeGenerator()
result = gen.execute({
    "pattern": "singleton",
    "class_name": "MyClass"
})
```

### Solve Optimization Problem
```python
from agents.algorithms.problem_solving import DynamicProgrammingSolver

solver = DynamicProgrammingSolver()
result = solver.execute({
    "problem_type": "knapsack",
    "items": [...],
    "capacity": 100
})
```

### Smart Algorithm Selection
```python
from agents.algorithms.optimization import AlgorithmOrchestrator

orchestrator = AlgorithmOrchestrator()
result = orchestrator.execute_with_best_algorithm(problem)
```

## Further Reading

- **Detailed Documentation**: `agents/algorithms/README.md`
- **Integration Guide**: `docs/ALGORITHMS_INTEGRATION.md`
- **Examples**: `examples/algorithm_examples.py`
- **Agent Documentation**: `README_AGENTIC_SYSTEM.md`
