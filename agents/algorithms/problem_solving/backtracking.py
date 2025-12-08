"""
Backtracking Problem Solver

Explores solution space by trying possibilities and backtracking when
a path doesn't lead to a solution.
"""

from typing import Dict, Any, List, Set, Callable, Optional
from ..base import Algorithm, AlgorithmType, AlgorithmStrategy


class BacktrackingSolver(Algorithm):
    """
    Backtracking algorithm solver
    
    Explores all possibilities by building solutions incrementally
    and abandoning them when they fail to satisfy constraints.
    
    Example:
        ```python
        solver = BacktrackingSolver()
        result = solver.execute({
            "problem_type": "n_queens",
            "n": 8
        })
        ```
    """
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "Backtracking Solver"
        if "type" not in data:
            data["type"] = AlgorithmType.PROBLEM_SOLVING
        if "strategy" not in data:
            data["strategy"] = AlgorithmStrategy.BACKTRACKING
        if "description" not in data:
            data["description"] = "Solves problems by exploring and backtracking"
        
        super().__init__(**data)
    
    def _validate_input(self, input_data: Dict[str, Any]) -> None:
        """Validate input for backtracking"""
        super()._validate_input(input_data)
        
        if "problem_type" not in input_data:
            raise ValueError("Missing required field: problem_type")
    
    def _execute_core(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute backtracking algorithm"""
        problem_type = input_data["problem_type"]
        
        if problem_type == "n_queens":
            result = self._solve_n_queens(input_data.get("n", 8))
        elif problem_type == "sudoku":
            result = self._solve_sudoku(input_data.get("board", []))
        elif problem_type == "subset_sum":
            result = self._solve_subset_sum(
                input_data.get("numbers", []),
                input_data.get("target", 0)
            )
        elif problem_type == "permutations":
            result = self._generate_permutations(input_data.get("items", []))
        elif problem_type == "combinations":
            result = self._generate_combinations(
                input_data.get("items", []),
                input_data.get("k", 2)
            )
        elif problem_type == "graph_coloring":
            result = self._solve_graph_coloring(
                input_data.get("graph", {}),
                input_data.get("colors", 3)
            )
        elif problem_type == "maze":
            result = self._solve_maze(input_data.get("maze", []))
        else:
            result = {"error": f"Unknown problem type: {problem_type}"}
        
        return {
            "problem_type": problem_type,
            "result": result,
            "algorithm": "backtracking"
        }
    
    def _solve_n_queens(self, n: int) -> Dict[str, Any]:
        """Solve N-Queens problem"""
        def is_safe(board, row, col):
            # Check column
            for i in range(row):
                if board[i] == col:
                    return False
            
            # Check diagonal
            for i in range(row):
                if abs(board[i] - col) == abs(i - row):
                    return False
            
            return True
        
        def solve(board, row):
            if row == n:
                solutions.append(board[:])
                return
            
            for col in range(n):
                if is_safe(board, row, col):
                    board[row] = col
                    solve(board, row + 1)
                    board[row] = -1
        
        solutions = []
        board = [-1] * n
        solve(board, 0)
        
        return {
            "solutions_count": len(solutions),
            "first_solution": solutions[0] if solutions else None,
            "n": n
        }
    
    def _solve_sudoku(self, board: List[List[int]]) -> Dict[str, Any]:
        """Solve Sudoku puzzle"""
        if not board:
            # Create empty 9x9 board for demo
            board = [[0] * 9 for _ in range(9)]
        
        def is_valid(board, row, col, num):
            # Check row
            if num in board[row]:
                return False
            
            # Check column
            if num in [board[i][col] for i in range(9)]:
                return False
            
            # Check 3x3 box
            box_row, box_col = 3 * (row // 3), 3 * (col // 3)
            for i in range(box_row, box_row + 3):
                for j in range(box_col, box_col + 3):
                    if board[i][j] == num:
                        return False
            
            return True
        
        def solve():
            for i in range(9):
                for j in range(9):
                    if board[i][j] == 0:
                        for num in range(1, 10):
                            if is_valid(board, i, j, num):
                                board[i][j] = num
                                if solve():
                                    return True
                                board[i][j] = 0
                        return False
            return True
        
        solved = solve()
        
        return {
            "solved": solved,
            "board": board if solved else None
        }
    
    def _solve_subset_sum(self, numbers: List[int], target: int) -> Dict[str, Any]:
        """Find subsets that sum to target"""
        def backtrack(start, current_sum, path):
            if current_sum == target:
                solutions.append(path[:])
                return
            
            if current_sum > target or start >= len(numbers):
                return
            
            for i in range(start, len(numbers)):
                path.append(numbers[i])
                backtrack(i + 1, current_sum + numbers[i], path)
                path.pop()
        
        solutions = []
        backtrack(0, 0, [])
        
        return {
            "solutions_count": len(solutions),
            "solutions": solutions[:10],  # Limit output
            "target": target
        }
    
    def _generate_permutations(self, items: List[Any]) -> Dict[str, Any]:
        """Generate all permutations"""
        def backtrack(path, remaining):
            if not remaining:
                results.append(path[:])
                return
            
            for i in range(len(remaining)):
                path.append(remaining[i])
                backtrack(path, remaining[:i] + remaining[i+1:])
                path.pop()
        
        results = []
        backtrack([], items)
        
        return {
            "count": len(results),
            "permutations": results[:20]  # Limit output
        }
    
    def _generate_combinations(self, items: List[Any], k: int) -> Dict[str, Any]:
        """Generate all k-combinations"""
        def backtrack(start, path):
            if len(path) == k:
                results.append(path[:])
                return
            
            for i in range(start, len(items)):
                path.append(items[i])
                backtrack(i + 1, path)
                path.pop()
        
        results = []
        backtrack(0, [])
        
        return {
            "count": len(results),
            "combinations": results
        }
    
    def _solve_graph_coloring(
        self, 
        graph: Dict[int, List[int]], 
        num_colors: int
    ) -> Dict[str, Any]:
        """Solve graph coloring problem"""
        if not graph:
            return {"colored": False, "colors": {}}
        
        colors = {}
        vertices = list(graph.keys())
        
        def is_safe(vertex, color):
            for neighbor in graph.get(vertex, []):
                if colors.get(neighbor) == color:
                    return False
            return True
        
        def backtrack(vertex_idx):
            if vertex_idx == len(vertices):
                return True
            
            vertex = vertices[vertex_idx]
            for color in range(num_colors):
                if is_safe(vertex, color):
                    colors[vertex] = color
                    if backtrack(vertex_idx + 1):
                        return True
                    del colors[vertex]
            
            return False
        
        colored = backtrack(0)
        
        return {
            "colored": colored,
            "colors": colors if colored else {},
            "num_colors_used": len(set(colors.values())) if colored else 0
        }
    
    def _solve_maze(self, maze: List[List[int]]) -> Dict[str, Any]:
        """Solve maze (1 = wall, 0 = path)"""
        if not maze:
            return {"solvable": False, "path": []}
        
        rows, cols = len(maze), len(maze[0])
        
        def solve_maze_recursive(r, c, path, visited):
            """Recursive helper with explicit state parameters"""
            if r == rows - 1 and c == cols - 1:
                path.append((r, c))
                return True
            
            if not (0 <= r < rows and 0 <= c < cols):
                return False
            if maze[r][c] == 1 or (r, c) in visited:
                return False
            
            visited.add((r, c))
            path.append((r, c))
            
            # Try all directions: right, down, left, up
            for dr, dc in [(0, 1), (1, 0), (0, -1), (-1, 0)]:
                if solve_maze_recursive(r + dr, c + dc, path, visited):
                    return True
            
            path.pop()
            return False
        
        path = []
        visited = set()
        solvable = solve_maze_recursive(0, 0, path, visited)
        
        return {
            "solvable": solvable,
            "path": path if solvable else [],
            "path_length": len(path) if solvable else 0
        }
