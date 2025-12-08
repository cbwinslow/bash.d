"""
Dynamic Programming Problem Solver

Solves problems by breaking them into overlapping subproblems and
storing solutions to avoid recomputation.
"""

from typing import Dict, Any, List
from ..base import Algorithm, AlgorithmType, AlgorithmStrategy


class DynamicProgrammingSolver(Algorithm):
    """
    Dynamic Programming algorithm solver
    
    Solves optimization problems by storing and reusing subproblem solutions.
    
    Example:
        ```python
        solver = DynamicProgrammingSolver()
        result = solver.execute({
            "problem_type": "knapsack",
            "items": [{"weight": 2, "value": 3}, {"weight": 3, "value": 4}],
            "capacity": 5
        })
        ```
    """
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "Dynamic Programming Solver"
        if "type" not in data:
            data["type"] = AlgorithmType.PROBLEM_SOLVING
        if "strategy" not in data:
            data["strategy"] = AlgorithmStrategy.DYNAMIC_PROGRAMMING
        if "description" not in data:
            data["description"] = "Solves problems using dynamic programming with memoization"
        
        super().__init__(**data)
    
    def _validate_input(self, input_data: Dict[str, Any]) -> None:
        """Validate input for dynamic programming"""
        super()._validate_input(input_data)
        
        if "problem_type" not in input_data:
            raise ValueError("Missing required field: problem_type")
    
    def _execute_core(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute dynamic programming algorithm"""
        problem_type = input_data["problem_type"]
        
        if problem_type == "fibonacci":
            result = self._fibonacci(input_data.get("n", 10))
        elif problem_type == "knapsack":
            result = self._knapsack(
                input_data.get("items", []),
                input_data.get("capacity", 0)
            )
        elif problem_type == "longest_common_subsequence":
            result = self._lcs(
                input_data.get("str1", ""),
                input_data.get("str2", "")
            )
        elif problem_type == "edit_distance":
            result = self._edit_distance(
                input_data.get("str1", ""),
                input_data.get("str2", "")
            )
        elif problem_type == "coin_change":
            result = self._coin_change(
                input_data.get("coins", []),
                input_data.get("amount", 0)
            )
        elif problem_type == "longest_increasing_subsequence":
            result = self._lis(input_data.get("sequence", []))
        elif problem_type == "matrix_chain_multiplication":
            result = self._matrix_chain(input_data.get("dimensions", []))
        else:
            result = {"error": f"Unknown problem type: {problem_type}"}
        
        return {
            "problem_type": problem_type,
            "result": result,
            "algorithm": "dynamic_programming"
        }
    
    def _fibonacci(self, n: int) -> Dict[str, Any]:
        """Calculate Fibonacci number using DP"""
        if n < 0:
            return {"error": "n must be non-negative"}
        
        if n <= 1:
            return {"value": n, "n": n}
        
        dp = [0] * (n + 1)
        dp[1] = 1
        
        for i in range(2, n + 1):
            dp[i] = dp[i-1] + dp[i-2]
        
        return {
            "value": dp[n],
            "n": n,
            "computed_values": len(dp)
        }
    
    def _knapsack(self, items: List[Dict[str, int]], capacity: int) -> Dict[str, Any]:
        """0/1 Knapsack problem"""
        if not items or capacity <= 0:
            return {"max_value": 0, "items": []}
        
        n = len(items)
        dp = [[0] * (capacity + 1) for _ in range(n + 1)]
        
        # Build DP table
        for i in range(1, n + 1):
            weight = items[i-1]["weight"]
            value = items[i-1]["value"]
            
            for w in range(capacity + 1):
                if weight <= w:
                    dp[i][w] = max(
                        dp[i-1][w],
                        dp[i-1][w-weight] + value
                    )
                else:
                    dp[i][w] = dp[i-1][w]
        
        # Backtrack to find items
        selected_items = []
        w = capacity
        for i in range(n, 0, -1):
            if dp[i][w] != dp[i-1][w]:
                selected_items.append(i-1)
                w -= items[i-1]["weight"]
        
        return {
            "max_value": dp[n][capacity],
            "selected_items": selected_items,
            "total_weight": sum(items[i]["weight"] for i in selected_items)
        }
    
    def _lcs(self, str1: str, str2: str) -> Dict[str, Any]:
        """Longest Common Subsequence"""
        m, n = len(str1), len(str2)
        dp = [[0] * (n + 1) for _ in range(m + 1)]
        
        for i in range(1, m + 1):
            for j in range(1, n + 1):
                if str1[i-1] == str2[j-1]:
                    dp[i][j] = dp[i-1][j-1] + 1
                else:
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1])
        
        # Reconstruct LCS
        lcs = []
        i, j = m, n
        while i > 0 and j > 0:
            if str1[i-1] == str2[j-1]:
                lcs.append(str1[i-1])
                i -= 1
                j -= 1
            elif dp[i-1][j] > dp[i][j-1]:
                i -= 1
            else:
                j -= 1
        
        lcs.reverse()
        
        return {
            "length": dp[m][n],
            "subsequence": "".join(lcs),
            "str1_length": m,
            "str2_length": n
        }
    
    def _edit_distance(self, str1: str, str2: str) -> Dict[str, Any]:
        """Edit Distance (Levenshtein distance)"""
        m, n = len(str1), len(str2)
        dp = [[0] * (n + 1) for _ in range(m + 1)]
        
        # Initialize base cases
        for i in range(m + 1):
            dp[i][0] = i
        for j in range(n + 1):
            dp[0][j] = j
        
        # Fill DP table
        for i in range(1, m + 1):
            for j in range(1, n + 1):
                if str1[i-1] == str2[j-1]:
                    dp[i][j] = dp[i-1][j-1]
                else:
                    dp[i][j] = 1 + min(
                        dp[i-1][j],      # Delete
                        dp[i][j-1],      # Insert
                        dp[i-1][j-1]     # Replace
                    )
        
        return {
            "distance": dp[m][n],
            "str1": str1,
            "str2": str2
        }
    
    def _coin_change(self, coins: List[int], amount: int) -> Dict[str, Any]:
        """Coin change problem - minimum coins needed"""
        if amount == 0:
            return {"min_coins": 0, "coins_used": []}
        
        if not coins:
            return {"min_coins": -1, "coins_used": []}
        
        dp = [float('inf')] * (amount + 1)
        dp[0] = 0
        parent = [-1] * (amount + 1)
        
        for i in range(1, amount + 1):
            for coin in coins:
                if coin <= i and dp[i - coin] + 1 < dp[i]:
                    dp[i] = dp[i - coin] + 1
                    parent[i] = coin
        
        if dp[amount] == float('inf'):
            return {"min_coins": -1, "coins_used": []}
        
        # Reconstruct solution
        coins_used = []
        curr = amount
        while curr > 0:
            coin = parent[curr]
            coins_used.append(coin)
            curr -= coin
        
        return {
            "min_coins": dp[amount],
            "coins_used": coins_used,
            "amount": amount
        }
    
    def _lis(self, sequence: List[int]) -> Dict[str, Any]:
        """Longest Increasing Subsequence"""
        if not sequence:
            return {"length": 0, "subsequence": []}
        
        n = len(sequence)
        dp = [1] * n
        parent = [-1] * n
        
        for i in range(1, n):
            for j in range(i):
                if sequence[j] < sequence[i] and dp[j] + 1 > dp[i]:
                    dp[i] = dp[j] + 1
                    parent[i] = j
        
        # Find max length and its index
        max_length = max(dp)
        max_idx = dp.index(max_length)
        
        # Reconstruct subsequence
        lis = []
        idx = max_idx
        while idx != -1:
            lis.append(sequence[idx])
            idx = parent[idx]
        lis.reverse()
        
        return {
            "length": max_length,
            "subsequence": lis,
            "original_length": n
        }
    
    def _matrix_chain(self, dimensions: List[int]) -> Dict[str, Any]:
        """Matrix Chain Multiplication - minimum operations"""
        if len(dimensions) < 2:
            return {"min_operations": 0}
        
        n = len(dimensions) - 1
        dp = [[0] * n for _ in range(n)]
        
        # l is chain length
        for l in range(2, n + 1):
            for i in range(n - l + 1):
                j = i + l - 1
                dp[i][j] = float('inf')
                
                for k in range(i, j):
                    cost = (dp[i][k] + dp[k+1][j] + 
                           dimensions[i] * dimensions[k+1] * dimensions[j+1])
                    dp[i][j] = min(dp[i][j], cost)
        
        return {
            "min_operations": dp[0][n-1] if n > 0 else 0,
            "num_matrices": n
        }
