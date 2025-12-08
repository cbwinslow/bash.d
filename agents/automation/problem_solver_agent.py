"""
Problem Solver Agent

Specialized agent for solving complex problems using multiple algorithms.
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task
from ..algorithms.optimization import AlgorithmOrchestrator


class ProblemSolverAgent(BaseAgent):
    """
    Problem Solver Agent - Multi-algorithm problem solver
    
    This agent uses multiple problem-solving algorithms to tackle
    complex problems. It supports divide & conquer, backtracking,
    dynamic programming, greedy algorithms, and constraint satisfaction.
    """
    
    def __init__(self, **data):
        """Initialize the Problem Solver agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "Problem Solver Agent"
        if "type" not in data:
            data["type"] = AgentType.AUTOMATION
        if "description" not in data:
            data["description"] = "Automated problem solving using multiple algorithms"
        if "tags" not in data:
            data["tags"] = ["automation_agent", "problem_solving"]
        
        # Initialize parent
        super().__init__(**data)
        
        # Initialize algorithm orchestrator
        self.orchestrator = AlgorithmOrchestrator()
        
        # Add capabilities
        self.capabilities.extend([
            AgentCapability(
                name="divide_and_conquer",
                description="Solve problems by dividing into subproblems",
                parameters={"problem_type": "str", "data": "any"},
                required=True
            ),
            AgentCapability(
                name="backtracking",
                description="Solve problems using backtracking search",
                parameters={"problem_type": "str", "constraints": "list"},
                required=True
            ),
            AgentCapability(
                name="dynamic_programming",
                description="Solve optimization problems with memoization",
                parameters={"problem_type": "str", "parameters": "dict"},
                required=True
            ),
            AgentCapability(
                name="greedy_algorithm",
                description="Solve problems using greedy local optimization",
                parameters={"problem_type": "str", "items": "list"},
                required=True
            ),
            AgentCapability(
                name="constraint_satisfaction",
                description="Solve CSP problems with variables and constraints",
                parameters={"variables": "list", "domains": "dict", "constraints": "list"},
                required=True
            ),
        ])
        
        # Add metadata
        self.metadata.update({
            "specialization": "problem_solving",
            "category": "automation",
            "algorithms_available": [
                "divide_conquer", "backtracking", "dynamic_programming",
                "greedy", "constraint_satisfaction"
            ]
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a problem-solving task"""
        input_data = task.input_data
        solver_type = input_data.get("solver_type", "auto")
        
        if solver_type == "auto":
            # Let orchestrator choose best algorithm
            result = self.orchestrator.execute_with_best_algorithm(input_data)
        else:
            # Use specific algorithm
            algorithm_map = {
                "divide_conquer": "divide_conquer",
                "backtracking": "backtracking",
                "dynamic_programming": "dynamic_programming",
                "greedy": "greedy",
                "constraint_satisfaction": "constraint_satisfaction"
            }
            algorithm_key = algorithm_map.get(solver_type)
            
            if not algorithm_key:
                return {
                    "status": "failed",
                    "error": f"Unknown solver type: {solver_type}"
                }
            
            result = self.orchestrator.execute_with_algorithm(algorithm_key, input_data)
        
        return {
            "status": "completed" if result.success else "failed",
            "agent": self.name,
            "algorithm_used": result.strategy.value,
            "solution": result.result_data.get("result"),
            "execution_time_ms": result.execution_time_ms,
            "metadata": result.metadata
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "problem_solver_agent",
            "description": "Solve complex problems using multiple algorithms",
            "parameters": {
                "type": "object",
                "properties": {
                    "solver_type": {
                        "type": "string",
                        "enum": [
                            "auto", "divide_conquer", "backtracking",
                            "dynamic_programming", "greedy", "constraint_satisfaction"
                        ],
                        "description": "Type of problem-solving algorithm to use"
                    },
                    "problem_type": {
                        "type": "string",
                        "description": "Specific problem type (e.g., knapsack, n_queens)"
                    },
                    "data": {
                        "type": "object",
                        "description": "Problem data and parameters"
                    }
                },
                "required": ["problem_type"]
            }
        }
    
    def get_supported_problem_types(self) -> Dict[str, List[str]]:
        """Get list of supported problem types by algorithm"""
        return {
            "divide_conquer": [
                "merge_sort", "quick_sort", "binary_search",
                "max_subarray", "closest_pair", "strassen_matrix"
            ],
            "backtracking": [
                "n_queens", "sudoku", "subset_sum",
                "permutations", "combinations", "graph_coloring", "maze"
            ],
            "dynamic_programming": [
                "fibonacci", "knapsack", "longest_common_subsequence",
                "edit_distance", "coin_change", "longest_increasing_subsequence",
                "matrix_chain_multiplication"
            ],
            "greedy": [
                "activity_selection", "fractional_knapsack", "huffman_coding",
                "interval_scheduling", "job_sequencing", "minimum_coins",
                "task_assignment"
            ],
            "constraint_satisfaction": [
                "map_coloring", "scheduling", "cryptarithmetic",
                "logic_puzzle"
            ]
        }
    
    def get_algorithm_metrics(self) -> Dict[str, Any]:
        """Get performance metrics for all algorithms"""
        return self.orchestrator.get_algorithm_metrics()
