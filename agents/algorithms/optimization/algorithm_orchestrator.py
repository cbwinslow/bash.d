"""
Algorithm Orchestrator

Coordinates multiple algorithms to solve complex problems by selecting
the most appropriate algorithm based on problem characteristics.
"""

from typing import Dict, Any, List, Optional
from ..base import Algorithm, AlgorithmType, AlgorithmStrategy, AlgorithmResult
from ..code_generation import (
    TemplateBasedCodeGenerator,
    ASTBasedCodeGenerator,
    PatternBasedCodeGenerator,
    AIAssistedCodeGenerator
)
from ..problem_solving import (
    DivideAndConquerSolver,
    BacktrackingSolver,
    DynamicProgrammingSolver,
    GreedyAlgorithmSolver,
    ConstraintSatisfactionSolver
)


class AlgorithmOrchestrator:
    """
    Orchestrates multiple algorithms for complex problem solving
    
    Analyzes problems and selects the most appropriate algorithm(s) to use.
    Can combine multiple algorithms for complex tasks.
    
    Example:
        ```python
        orchestrator = AlgorithmOrchestrator()
        
        # Analyze problem and get recommendation
        recommendation = orchestrator.recommend_algorithm({
            "task": "code_generation",
            "requirements": {"pattern": "singleton"}
        })
        
        # Execute with recommended algorithm
        result = orchestrator.execute_with_best_algorithm({
            "task": "code_generation",
            "template_name": "class_definition",
            "language": "python"
        })
        ```
    """
    
    def __init__(self):
        """Initialize the orchestrator with all available algorithms"""
        # Initialize code generation algorithms
        self.code_generators = {
            "template": TemplateBasedCodeGenerator(),
            "ast": ASTBasedCodeGenerator(),
            "pattern": PatternBasedCodeGenerator(),
            "ai": AIAssistedCodeGenerator()
        }
        
        # Initialize problem solving algorithms
        self.problem_solvers = {
            "divide_conquer": DivideAndConquerSolver(),
            "backtracking": BacktrackingSolver(),
            "dynamic_programming": DynamicProgrammingSolver(),
            "greedy": GreedyAlgorithmSolver(),
            "constraint_satisfaction": ConstraintSatisfactionSolver()
        }
        
        # All algorithms
        self.all_algorithms = {
            **self.code_generators,
            **self.problem_solvers
        }
        
        # Execution history
        self.execution_history: List[Dict[str, Any]] = []
    
    def recommend_algorithm(self, problem: Dict[str, Any]) -> Dict[str, Any]:
        """
        Recommend the best algorithm for a problem
        
        Args:
            problem: Problem description with task type and requirements
            
        Returns:
            Recommendation with algorithm name and confidence
        """
        task_type = problem.get("task", "").lower()
        requirements = problem.get("requirements", {})
        
        # Code generation recommendations
        if "code" in task_type or "generate" in task_type:
            if "pattern" in requirements or "design_pattern" in requirements:
                return {
                    "algorithm": "pattern",
                    "algorithm_name": "Pattern-Based Code Generator",
                    "confidence": 0.95,
                    "reason": "Design pattern specified"
                }
            elif "ast" in requirements or "syntax_tree" in requirements:
                return {
                    "algorithm": "ast",
                    "algorithm_name": "AST-Based Code Generator",
                    "confidence": 0.90,
                    "reason": "AST manipulation required"
                }
            elif "template" in requirements or "boilerplate" in requirements:
                return {
                    "algorithm": "template",
                    "algorithm_name": "Template-Based Code Generator",
                    "confidence": 0.85,
                    "reason": "Template-based generation"
                }
            else:
                return {
                    "algorithm": "ai",
                    "algorithm_name": "AI-Assisted Code Generator",
                    "confidence": 0.80,
                    "reason": "AI for flexible generation"
                }
        
        # Problem solving recommendations
        elif "sort" in task_type or "search" in task_type:
            return {
                "algorithm": "divide_conquer",
                "algorithm_name": "Divide and Conquer Solver",
                "confidence": 0.90,
                "reason": "Efficient for sorting/searching"
            }
        
        elif "constraint" in task_type or "csp" in task_type:
            return {
                "algorithm": "constraint_satisfaction",
                "algorithm_name": "Constraint Satisfaction Solver",
                "confidence": 0.95,
                "reason": "CSP problem detected"
            }
        
        elif "optimize" in task_type or "knapsack" in task_type:
            if "fraction" in task_type:
                return {
                    "algorithm": "greedy",
                    "algorithm_name": "Greedy Algorithm Solver",
                    "confidence": 0.85,
                    "reason": "Fractional optimization"
                }
            else:
                return {
                    "algorithm": "dynamic_programming",
                    "algorithm_name": "Dynamic Programming Solver",
                    "confidence": 0.90,
                    "reason": "Optimization problem"
                }
        
        elif "permutation" in task_type or "combination" in task_type:
            return {
                "algorithm": "backtracking",
                "algorithm_name": "Backtracking Solver",
                "confidence": 0.90,
                "reason": "Combinatorial problem"
            }
        
        # Default recommendation
        return {
            "algorithm": "ai",
            "algorithm_name": "AI-Assisted Code Generator",
            "confidence": 0.60,
            "reason": "General purpose algorithm"
        }
    
    def execute_with_best_algorithm(
        self, 
        problem: Dict[str, Any]
    ) -> AlgorithmResult:
        """
        Execute problem with the best recommended algorithm
        
        Args:
            problem: Problem description
            
        Returns:
            Algorithm execution result
        """
        recommendation = self.recommend_algorithm(problem)
        algorithm_key = recommendation["algorithm"]
        
        if algorithm_key not in self.all_algorithms:
            raise ValueError(f"Algorithm not found: {algorithm_key}")
        
        algorithm = self.all_algorithms[algorithm_key]
        result = algorithm.execute(problem)
        
        # Record execution
        self.execution_history.append({
            "problem": problem,
            "recommendation": recommendation,
            "result": result,
            "algorithm_used": algorithm_key
        })
        
        return result
    
    def execute_with_algorithm(
        self,
        algorithm_key: str,
        problem: Dict[str, Any]
    ) -> AlgorithmResult:
        """
        Execute problem with a specific algorithm
        
        Args:
            algorithm_key: Key of the algorithm to use
            problem: Problem description
            
        Returns:
            Algorithm execution result
        """
        if algorithm_key not in self.all_algorithms:
            raise ValueError(f"Algorithm not found: {algorithm_key}")
        
        algorithm = self.all_algorithms[algorithm_key]
        result = algorithm.execute(problem)
        
        # Record execution
        self.execution_history.append({
            "problem": problem,
            "result": result,
            "algorithm_used": algorithm_key
        })
        
        return result
    
    def compare_algorithms(
        self,
        problem: Dict[str, Any],
        algorithm_keys: List[str]
    ) -> Dict[str, AlgorithmResult]:
        """
        Compare multiple algorithms on the same problem
        
        Args:
            problem: Problem to solve
            algorithm_keys: List of algorithm keys to compare
            
        Returns:
            Dictionary mapping algorithm keys to results
        """
        results = {}
        
        for key in algorithm_keys:
            if key in self.all_algorithms:
                algorithm = self.all_algorithms[key]
                results[key] = algorithm.execute(problem)
        
        return results
    
    def get_algorithm_metrics(self) -> Dict[str, Any]:
        """Get performance metrics for all algorithms"""
        metrics = {}
        
        for key, algorithm in self.all_algorithms.items():
            metrics[key] = algorithm.get_metrics()
        
        return metrics
    
    def get_execution_history(
        self, 
        limit: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Get execution history
        
        Args:
            limit: Maximum number of records to return
            
        Returns:
            List of execution records
        """
        if limit:
            return self.execution_history[-limit:]
        return self.execution_history
    
    def list_algorithms(self, algorithm_type: Optional[str] = None) -> Dict[str, Any]:
        """
        List available algorithms
        
        Args:
            algorithm_type: Optional filter by type (code_generation, problem_solving)
            
        Returns:
            Dictionary of algorithms with their info
        """
        algorithms_info = {}
        
        if algorithm_type == "code_generation":
            source = self.code_generators
        elif algorithm_type == "problem_solving":
            source = self.problem_solvers
        else:
            source = self.all_algorithms
        
        for key, algorithm in source.items():
            algorithms_info[key] = {
                "name": algorithm.name,
                "type": algorithm.type.value,
                "strategy": algorithm.strategy.value,
                "description": algorithm.description,
                "version": algorithm.version,
                "executions": algorithm.executions_count,
                "success_rate": (
                    algorithm.success_count / algorithm.executions_count
                    if algorithm.executions_count > 0 else 0.0
                )
            }
        
        return algorithms_info
    
    def clear_history(self) -> None:
        """Clear execution history"""
        self.execution_history.clear()
