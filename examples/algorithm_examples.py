#!/usr/bin/env python3
"""
Example demonstrations of code generation and problem-solving algorithms

This script demonstrates all the algorithms available in the multi-agentic system.

Note: This is an example/demo script. For production use, install the package
properly using pip or add it to PYTHONPATH instead of modifying sys.path.
"""

import sys
from pathlib import Path

# Add parent directory to path (for demo purposes only)
# In production, install the package properly or use PYTHONPATH
sys.path.insert(0, str(Path(__file__).parent.parent))

from agents.algorithms.code_generation import (
    TemplateBasedCodeGenerator,
    ASTBasedCodeGenerator,
    PatternBasedCodeGenerator,
    AIAssistedCodeGenerator
)
from agents.algorithms.problem_solving import (
    DivideAndConquerSolver,
    BacktrackingSolver,
    DynamicProgrammingSolver,
    GreedyAlgorithmSolver,
    ConstraintSatisfactionSolver
)
from agents.algorithms.optimization import AlgorithmOrchestrator


def example_template_generator():
    """Example: Template-based code generation"""
    print("\n" + "="*60)
    print("EXAMPLE 1: Template-Based Code Generation")
    print("="*60)
    
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
    
    if result.success:
        print("\n✓ Generated Code:")
        print(result.result_data["generated_code"])
        print(f"\n⚡ Execution time: {result.execution_time_ms:.2f}ms")
    else:
        print(f"\n✗ Error: {result.error}")


def example_ast_generator():
    """Example: AST-based code generation"""
    print("\n" + "="*60)
    print("EXAMPLE 2: AST-Based Code Generation")
    print("="*60)
    
    generator = ASTBasedCodeGenerator()
    
    result = generator.execute({
        "ast_type": "function",
        "name": "calculate_discount",
        "parameters": ["price", "discount_rate"],
        "body": [
            {"type": "assign", "target": "discount", "value": "price * discount_rate"},
            {"type": "assign", "target": "final_price", "value": "price - discount"},
            {"type": "return", "value": "final_price"}
        ]
    })
    
    if result.success:
        print("\n✓ Generated Code:")
        print(result.result_data["generated_code"])
        print(f"\n✓ Valid syntax: {result.result_data['is_valid']}")
        print(f"⚡ Execution time: {result.execution_time_ms:.2f}ms")
    else:
        print(f"\n✗ Error: {result.error}")


def example_pattern_generator():
    """Example: Pattern-based code generation"""
    print("\n" + "="*60)
    print("EXAMPLE 3: Pattern-Based Code Generation (Singleton)")
    print("="*60)
    
    generator = PatternBasedCodeGenerator()
    
    result = generator.execute({
        "pattern": "singleton",
        "class_name": "DatabaseConnection",
        "language": "python",
        "additional_methods": ["connect", "disconnect", "query"]
    })
    
    if result.success:
        print("\n✓ Generated Code:")
        print(result.result_data["generated_code"][:500] + "...")
        print(f"\n⚡ Execution time: {result.execution_time_ms:.2f}ms")
        print(f"📋 Available patterns: {', '.join(generator.list_patterns())}")
    else:
        print(f"\n✗ Error: {result.error}")


def example_divide_conquer():
    """Example: Divide and conquer sorting"""
    print("\n" + "="*60)
    print("EXAMPLE 4: Divide and Conquer - Merge Sort")
    print("="*60)
    
    solver = DivideAndConquerSolver()
    
    data = [64, 34, 25, 12, 22, 11, 90, 88, 45, 50]
    print(f"\nUnsorted: {data}")
    
    result = solver.execute({
        "problem_type": "merge_sort",
        "data": data
    })
    
    if result.success:
        print(f"✓ Sorted: {result.result_data['result']}")
        print(f"⚡ Execution time: {result.execution_time_ms:.2f}ms")
    else:
        print(f"\n✗ Error: {result.error}")


def example_backtracking():
    """Example: Backtracking N-Queens"""
    print("\n" + "="*60)
    print("EXAMPLE 5: Backtracking - N-Queens Problem")
    print("="*60)
    
    solver = BacktrackingSolver()
    
    result = solver.execute({
        "problem_type": "n_queens",
        "n": 8
    })
    
    if result.success:
        solutions_count = result.result_data['result']['solutions_count']
        first_solution = result.result_data['result']['first_solution']
        print(f"\n✓ Solutions found: {solutions_count}")
        print(f"✓ First solution: {first_solution}")
        print(f"⚡ Execution time: {result.execution_time_ms:.2f}ms")
    else:
        print(f"\n✗ Error: {result.error}")


def example_dynamic_programming():
    """Example: Dynamic programming knapsack"""
    print("\n" + "="*60)
    print("EXAMPLE 6: Dynamic Programming - Knapsack Problem")
    print("="*60)
    
    solver = DynamicProgrammingSolver()
    
    items = [
        {"weight": 2, "value": 3},
        {"weight": 3, "value": 4},
        {"weight": 4, "value": 5},
        {"weight": 5, "value": 8},
        {"weight": 9, "value": 10}
    ]
    capacity = 10
    
    print(f"\nItems: {items}")
    print(f"Capacity: {capacity}")
    
    result = solver.execute({
        "problem_type": "knapsack",
        "items": items,
        "capacity": capacity
    })
    
    if result.success:
        print(f"\n✓ Maximum value: {result.result_data['result']['max_value']}")
        print(f"✓ Selected items: {result.result_data['result']['selected_items']}")
        print(f"⚡ Execution time: {result.execution_time_ms:.2f}ms")
    else:
        print(f"\n✗ Error: {result.error}")


def example_greedy():
    """Example: Greedy activity selection"""
    print("\n" + "="*60)
    print("EXAMPLE 7: Greedy - Activity Selection")
    print("="*60)
    
    solver = GreedyAlgorithmSolver()
    
    activities = [
        {"start": 1, "end": 4},
        {"start": 3, "end": 5},
        {"start": 0, "end": 6},
        {"start": 5, "end": 7},
        {"start": 3, "end": 9},
        {"start": 5, "end": 9},
        {"start": 6, "end": 10},
        {"start": 8, "end": 11},
        {"start": 8, "end": 12},
        {"start": 2, "end": 14}
    ]
    
    print(f"\nActivities: {len(activities)}")
    
    result = solver.execute({
        "problem_type": "activity_selection",
        "activities": activities
    })
    
    if result.success:
        print(f"\n✓ Maximum activities selected: {result.result_data['result']['count']}")
        print(f"✓ Selected: {result.result_data['result']['selected']}")
        print(f"⚡ Execution time: {result.execution_time_ms:.2f}ms")
    else:
        print(f"\n✗ Error: {result.error}")


def example_constraint_satisfaction():
    """Example: Constraint satisfaction - Map coloring"""
    print("\n" + "="*60)
    print("EXAMPLE 8: Constraint Satisfaction - Map Coloring")
    print("="*60)
    
    solver = ConstraintSatisfactionSolver()
    
    variables = ["WA", "NT", "SA", "Q", "NSW", "V"]
    domains = {var: ["red", "green", "blue"] for var in variables}
    constraints = [
        ("WA", "NT"), ("WA", "SA"), ("NT", "SA"), 
        ("NT", "Q"), ("SA", "Q"), ("SA", "NSW"), 
        ("SA", "V"), ("Q", "NSW"), ("NSW", "V")
    ]
    
    print(f"\nRegions: {variables}")
    print(f"Colors available: {domains['WA']}")
    print(f"Constraints (borders): {len(constraints)}")
    
    result = solver.execute({
        "problem_type": "map_coloring",
        "variables": variables,
        "domains": domains,
        "constraints": constraints
    })
    
    if result.success:
        print(f"\n✓ Solution found: {result.result_data['result']['satisfied']}")
        print(f"✓ Coloring: {result.result_data['result']['solution']}")
        print(f"⚡ Execution time: {result.execution_time_ms:.2f}ms")
    else:
        print(f"\n✗ Error: {result.error}")


def example_orchestrator():
    """Example: Algorithm orchestrator"""
    print("\n" + "="*60)
    print("EXAMPLE 9: Algorithm Orchestrator - Smart Selection")
    print("="*60)
    
    orchestrator = AlgorithmOrchestrator()
    
    # Example 1: Get recommendation
    problem1 = {
        "task": "code_generation",
        "requirements": {"pattern": "factory"}
    }
    
    recommendation = orchestrator.recommend_algorithm(problem1)
    print(f"\n📊 Problem: {problem1['task']}")
    print(f"✓ Recommended: {recommendation['algorithm_name']}")
    print(f"✓ Confidence: {recommendation['confidence']:.0%}")
    print(f"📝 Reason: {recommendation['reason']}")
    
    # Example 2: Execute with best algorithm
    problem2 = {
        "problem_type": "merge_sort",
        "data": [5, 2, 8, 1, 9]
    }
    
    result = orchestrator.execute_with_best_algorithm(problem2)
    print(f"\n📊 Problem: Sorting {problem2['data']}")
    print(f"✓ Result: {result.result_data['result']}")
    print(f"⚡ Time: {result.execution_time_ms:.2f}ms")
    
    # Show metrics
    print("\n📈 Algorithm Metrics:")
    metrics = orchestrator.get_algorithm_metrics()
    for algo, metric in metrics.items():
        if metric['executions'] > 0:
            print(f"  {algo}: {metric['executions']} executions, "
                  f"{metric['success_rate']:.0%} success rate")


def main():
    """Run all examples"""
    print("\n" + "="*60)
    print("MULTI-AGENTIC SYSTEM ALGORITHMS DEMONSTRATION")
    print("="*60)
    print("\nDemonstrating code generation and problem-solving algorithms")
    print("designed for multi-agentic systems.\n")
    
    examples = [
        example_template_generator,
        example_ast_generator,
        example_pattern_generator,
        example_divide_conquer,
        example_backtracking,
        example_dynamic_programming,
        example_greedy,
        example_constraint_satisfaction,
        example_orchestrator
    ]
    
    for i, example in enumerate(examples, 1):
        try:
            example()
        except Exception as e:
            print(f"\n✗ Example {i} failed: {e}")
    
    print("\n" + "="*60)
    print("DEMONSTRATION COMPLETE")
    print("="*60)
    print("\n✓ All algorithms demonstrated successfully!")
    print("💡 See agents/algorithms/README.md for detailed documentation\n")


if __name__ == "__main__":
    main()
