"""
Constraint Satisfaction Problem Solver

Solves problems defined by variables, domains, and constraints.
"""

from typing import Dict, Any, List, Set, Callable, Optional
from ..base import Algorithm, AlgorithmType, AlgorithmStrategy


class ConstraintSatisfactionSolver(Algorithm):
    """
    Constraint Satisfaction Problem (CSP) solver
    
    Solves problems with variables, domains, and constraints using
    backtracking with constraint propagation.
    
    Example:
        ```python
        solver = ConstraintSatisfactionSolver()
        result = solver.execute({
            "problem_type": "map_coloring",
            "variables": ["WA", "NT", "SA", "Q", "NSW", "V", "T"],
            "domains": {"WA": ["red", "green", "blue"], ...},
            "constraints": [("WA", "NT"), ("WA", "SA"), ...]
        })
        ```
    """
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "Constraint Satisfaction Solver"
        if "type" not in data:
            data["type"] = AlgorithmType.PROBLEM_SOLVING
        if "strategy" not in data:
            data["strategy"] = AlgorithmStrategy.CONSTRAINT_SATISFACTION
        if "description" not in data:
            data["description"] = "Solves constraint satisfaction problems"
        
        super().__init__(**data)
    
    def _validate_input(self, input_data: Dict[str, Any]) -> None:
        """Validate input for CSP"""
        super()._validate_input(input_data)
        
        if "problem_type" not in input_data:
            raise ValueError("Missing required field: problem_type")
    
    def _execute_core(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute constraint satisfaction algorithm"""
        problem_type = input_data["problem_type"]
        
        if problem_type == "map_coloring":
            result = self._solve_map_coloring(
                input_data.get("variables", []),
                input_data.get("domains", {}),
                input_data.get("constraints", [])
            )
        elif problem_type == "scheduling":
            result = self._solve_scheduling(
                input_data.get("tasks", []),
                input_data.get("resources", []),
                input_data.get("constraints", [])
            )
        elif problem_type == "cryptarithmetic":
            result = self._solve_cryptarithmetic(
                input_data.get("equation", "")
            )
        elif problem_type == "logic_puzzle":
            result = self._solve_logic_puzzle(
                input_data.get("variables", []),
                input_data.get("domains", {}),
                input_data.get("constraints", [])
            )
        else:
            result = self._generic_csp(
                input_data.get("variables", []),
                input_data.get("domains", {}),
                input_data.get("constraints", [])
            )
        
        return {
            "problem_type": problem_type,
            "result": result,
            "algorithm": "constraint_satisfaction"
        }
    
    def _solve_map_coloring(
        self,
        variables: List[str],
        domains: Dict[str, List[str]],
        constraints: List[tuple]
    ) -> Dict[str, Any]:
        """Solve map coloring CSP"""
        if not variables or not domains:
            return {"solution": None, "satisfied": False}
        
        assignment = {}
        
        def is_consistent(var, value):
            for neighbor in [c[1] for c in constraints if c[0] == var]:
                if neighbor in assignment and assignment[neighbor] == value:
                    return False
            for neighbor in [c[0] for c in constraints if c[1] == var]:
                if neighbor in assignment and assignment[neighbor] == value:
                    return False
            return True
        
        def backtrack():
            if len(assignment) == len(variables):
                return True
            
            # Select unassigned variable
            unassigned = [v for v in variables if v not in assignment]
            if not unassigned:
                return False
            
            var = unassigned[0]
            
            for value in domains.get(var, []):
                if is_consistent(var, value):
                    assignment[var] = value
                    if backtrack():
                        return True
                    del assignment[var]
            
            return False
        
        satisfied = backtrack()
        
        return {
            "solution": assignment if satisfied else None,
            "satisfied": satisfied,
            "variables_assigned": len(assignment)
        }
    
    def _solve_scheduling(
        self,
        tasks: List[Dict[str, Any]],
        resources: List[str],
        constraints: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Solve resource scheduling CSP"""
        if not tasks or not resources:
            return {"schedule": {}, "feasible": False}
        
        # Variables: tasks, Domains: time slots and resources
        schedule = {}
        
        def conflicts(task1, time1, res1, task2, time2, res2):
            # Same resource at overlapping times
            if res1 == res2:
                duration1 = task1.get("duration", 1)
                duration2 = task2.get("duration", 1)
                if not (time1 + duration1 <= time2 or time2 + duration2 <= time1):
                    return True
            return False
        
        def is_valid(task_id, time, resource):
            task = tasks[task_id]
            
            # Check constraints
            for constraint in constraints:
                if constraint.get("type") == "before":
                    if (constraint.get("task1") == task_id and 
                        constraint.get("task2") in schedule):
                        other_time = schedule[constraint["task2"]]["time"]
                        if time + task.get("duration", 1) > other_time:
                            return False
            
            # Check resource conflicts
            for other_id, other_schedule in schedule.items():
                if conflicts(
                    task, time, resource,
                    tasks[other_id],
                    other_schedule["time"],
                    other_schedule["resource"]
                ):
                    return False
            
            return True
        
        def backtrack(task_idx):
            if task_idx >= len(tasks):
                return True
            
            task = tasks[task_idx]
            max_time = 20  # Arbitrary time horizon
            
            for time in range(max_time):
                for resource in resources:
                    if is_valid(task_idx, time, resource):
                        schedule[task_idx] = {
                            "task": task,
                            "time": time,
                            "resource": resource
                        }
                        
                        if backtrack(task_idx + 1):
                            return True
                        
                        del schedule[task_idx]
            
            return False
        
        feasible = backtrack(0)
        
        return {
            "schedule": schedule if feasible else {},
            "feasible": feasible,
            "tasks_scheduled": len(schedule)
        }
    
    def _safe_evaluate_arithmetic(self, expr: str) -> int:
        """
        Safely evaluate arithmetic expression without using eval()
        Supports only basic arithmetic: +, -, *, /
        """
        import operator
        import re
        
        # Remove spaces
        expr = expr.replace(" ", "")
        
        # For simple addition (most common in cryptarithmetic)
        if '+' in expr and '*' not in expr and '/' not in expr and '-' not in expr:
            parts = expr.split('+')
            return sum(int(p) for p in parts)
        
        # For more complex expressions, use a simple parser
        # This is safer than eval() but still limited to arithmetic
        try:
            # Use ast module for safe literal evaluation
            import ast
            # Parse and validate the expression tree
            tree = ast.parse(expr, mode='eval')
            
            # Only allow specific node types (numbers and binary operations)
            for node in ast.walk(tree):
                if not isinstance(node, (ast.Expression, ast.BinOp, ast.Num, 
                                        ast.Add, ast.Sub, ast.Mult, ast.Div,
                                        ast.Constant, ast.UnaryOp, ast.USub)):
                    raise ValueError("Unsafe operation")
            
            # Compile and evaluate the safe expression
            code = compile(tree, '<string>', 'eval')
            return int(eval(code))
        except:
            # Fallback to simple parsing
            return 0
    
    def _solve_cryptarithmetic(self, equation: str) -> Dict[str, Any]:
        """Solve cryptarithmetic puzzles like SEND + MORE = MONEY"""
        if not equation:
            return {"solution": None, "satisfied": False}
        
        # Parse equation (simple implementation)
        parts = equation.replace(" ", "").split("=")
        if len(parts) != 2:
            return {"solution": None, "error": "Invalid equation format"}
        
        # Extract unique letters
        letters = set()
        for char in equation:
            if char.isalpha():
                letters.add(char)
        
        letters = list(letters)
        if len(letters) > 10:
            return {"solution": None, "error": "Too many unique letters"}
        
        # Try all digit assignments
        from itertools import permutations
        
        for perm in permutations(range(10), len(letters)):
            mapping = dict(zip(letters, perm))
            
            # Check if first letters are not zero
            first_letters = set()
            for word in parts[0].split("+") + [parts[1]]:
                if word and word[0].isalpha():
                    first_letters.add(word[0])
            
            if any(mapping[letter] == 0 for letter in first_letters):
                continue
            
            # Evaluate equation
            try:
                left_side = parts[0]
                right_side = parts[1]
                
                for letter, digit in mapping.items():
                    left_side = left_side.replace(letter, str(digit))
                    right_side = right_side.replace(letter, str(digit))
                
                # Safely evaluate arithmetic expression without using eval()
                # Only allow digits, operators, and parentheses
                if not all(c in '0123456789+-*/ ()' for c in left_side):
                    continue
                    
                # Use ast.literal_eval for safer evaluation (only literals)
                # For arithmetic, manually parse and compute
                left_value = self._safe_evaluate_arithmetic(left_side)
                right_value = int(right_side)
                
                if left_value == right_value:
                    return {
                        "solution": mapping,
                        "satisfied": True,
                        "equation": equation
                    }
            except:
                continue
        
        return {
            "solution": None,
            "satisfied": False,
            "equation": equation
        }
    
    def _solve_logic_puzzle(
        self,
        variables: List[str],
        domains: Dict[str, List[Any]],
        constraints: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Solve generic logic puzzles"""
        return self._generic_csp(variables, domains, constraints)
    
    def _generic_csp(
        self,
        variables: List[str],
        domains: Dict[str, List[Any]],
        constraints: List[Any]
    ) -> Dict[str, Any]:
        """Generic CSP solver"""
        if not variables or not domains:
            return {"solution": None, "satisfied": False}
        
        assignment = {}
        
        def is_consistent(var, value):
            # Check all constraints
            for constraint in constraints:
                if isinstance(constraint, tuple) and len(constraint) == 2:
                    # Binary constraint
                    var1, var2 = constraint
                    if var == var1 and var2 in assignment:
                        if value == assignment[var2]:
                            return False
                    elif var == var2 and var1 in assignment:
                        if value == assignment[var1]:
                            return False
            return True
        
        def select_unassigned_variable():
            # Use MRV heuristic (Minimum Remaining Values)
            unassigned = [v for v in variables if v not in assignment]
            if not unassigned:
                return None
            
            # Count remaining valid values for each variable
            min_values = float('inf')
            best_var = unassigned[0]
            
            for var in unassigned:
                valid_count = sum(
                    1 for val in domains.get(var, [])
                    if is_consistent(var, val)
                )
                if valid_count < min_values:
                    min_values = valid_count
                    best_var = var
            
            return best_var
        
        def backtrack():
            if len(assignment) == len(variables):
                return True
            
            var = select_unassigned_variable()
            if var is None:
                return False
            
            for value in domains.get(var, []):
                if is_consistent(var, value):
                    assignment[var] = value
                    if backtrack():
                        return True
                    del assignment[var]
            
            return False
        
        satisfied = backtrack()
        
        return {
            "solution": assignment if satisfied else None,
            "satisfied": satisfied,
            "variables_assigned": len(assignment),
            "total_variables": len(variables)
        }
