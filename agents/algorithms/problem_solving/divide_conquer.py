"""
Divide and Conquer Problem Solver

Breaks down complex problems into smaller subproblems, solves them independently,
and combines the results.
"""

from typing import Dict, Any, List, Callable, Optional
from ..base import Algorithm, AlgorithmType, AlgorithmStrategy


class DivideAndConquerSolver(Algorithm):
    """
    Divide and Conquer algorithm solver
    
    Breaks problems into smaller subproblems, solves recursively,
    and combines solutions.
    
    Example:
        ```python
        solver = DivideAndConquerSolver()
        result = solver.execute({
            "problem_type": "merge_sort",
            "data": [64, 34, 25, 12, 22, 11, 90],
        })
        ```
    """
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "Divide and Conquer Solver"
        if "type" not in data:
            data["type"] = AlgorithmType.PROBLEM_SOLVING
        if "strategy" not in data:
            data["strategy"] = AlgorithmStrategy.DIVIDE_CONQUER
        if "description" not in data:
            data["description"] = "Solves problems by dividing into subproblems"
        
        super().__init__(**data)
    
    def _validate_input(self, input_data: Dict[str, Any]) -> None:
        """Validate input for divide and conquer"""
        super()._validate_input(input_data)
        
        if "problem_type" not in input_data:
            raise ValueError("Missing required field: problem_type")
    
    def _execute_core(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute divide and conquer algorithm"""
        problem_type = input_data["problem_type"]
        
        if problem_type == "merge_sort":
            result = self._merge_sort(input_data.get("data", []))
        elif problem_type == "quick_sort":
            result = self._quick_sort(input_data.get("data", []))
        elif problem_type == "binary_search":
            result = self._binary_search(
                input_data.get("data", []),
                input_data.get("target")
            )
        elif problem_type == "max_subarray":
            result = self._max_subarray(input_data.get("data", []))
        elif problem_type == "closest_pair":
            result = self._closest_pair(input_data.get("points", []))
        elif problem_type == "strassen_matrix":
            result = self._strassen_matrix_multiply(
                input_data.get("matrix_a", []),
                input_data.get("matrix_b", [])
            )
        else:
            result = self._generic_divide_conquer(input_data)
        
        return {
            "problem_type": problem_type,
            "result": result,
            "algorithm": "divide_and_conquer",
            "approach": self._get_approach_description(problem_type)
        }
    
    def _merge_sort(self, arr: List[Any]) -> List[Any]:
        """Merge sort implementation"""
        if len(arr) <= 1:
            return arr
        
        # Divide
        mid = len(arr) // 2
        left = self._merge_sort(arr[:mid])
        right = self._merge_sort(arr[mid:])
        
        # Conquer (merge)
        return self._merge(left, right)
    
    def _merge(self, left: List[Any], right: List[Any]) -> List[Any]:
        """Merge two sorted arrays"""
        result = []
        i = j = 0
        
        while i < len(left) and j < len(right):
            if left[i] <= right[j]:
                result.append(left[i])
                i += 1
            else:
                result.append(right[j])
                j += 1
        
        result.extend(left[i:])
        result.extend(right[j:])
        return result
    
    def _quick_sort(self, arr: List[Any]) -> List[Any]:
        """Quick sort implementation"""
        if len(arr) <= 1:
            return arr
        
        pivot = arr[len(arr) // 2]
        left = [x for x in arr if x < pivot]
        middle = [x for x in arr if x == pivot]
        right = [x for x in arr if x > pivot]
        
        return self._quick_sort(left) + middle + self._quick_sort(right)
    
    def _binary_search(self, arr: List[Any], target: Any) -> Dict[str, Any]:
        """Binary search implementation"""
        def search(arr, target, low, high):
            if low > high:
                return -1
            
            mid = (low + high) // 2
            if arr[mid] == target:
                return mid
            elif arr[mid] > target:
                return search(arr, target, low, mid - 1)
            else:
                return search(arr, target, mid + 1, high)
        
        sorted_arr = sorted(arr)
        index = search(sorted_arr, target, 0, len(sorted_arr) - 1)
        
        return {
            "found": index != -1,
            "index": index,
            "target": target
        }
    
    def _max_subarray(self, arr: List[int]) -> Dict[str, Any]:
        """Maximum subarray sum using divide and conquer"""
        def max_crossing_sum(arr, low, mid, high):
            left_sum = float('-inf')
            sum_val = 0
            for i in range(mid, low - 1, -1):
                sum_val += arr[i]
                left_sum = max(left_sum, sum_val)
            
            right_sum = float('-inf')
            sum_val = 0
            for i in range(mid + 1, high + 1):
                sum_val += arr[i]
                right_sum = max(right_sum, sum_val)
            
            return left_sum + right_sum
        
        def max_subarray_sum(arr, low, high):
            if low == high:
                return arr[low]
            
            mid = (low + high) // 2
            
            left_sum = max_subarray_sum(arr, low, mid)
            right_sum = max_subarray_sum(arr, mid + 1, high)
            cross_sum = max_crossing_sum(arr, low, mid, high)
            
            return max(left_sum, right_sum, cross_sum)
        
        if not arr:
            return {"max_sum": 0, "subarray": []}
        
        max_sum = max_subarray_sum(arr, 0, len(arr) - 1)
        
        return {
            "max_sum": max_sum,
            "array_length": len(arr)
        }
    
    def _closest_pair(self, points: List[tuple]) -> Dict[str, Any]:
        """Find closest pair of points"""
        if len(points) < 2:
            return {"distance": float('inf'), "points": []}
        
        # Simple implementation for demonstration
        min_dist = float('inf')
        closest = None
        
        for i in range(len(points)):
            for j in range(i + 1, len(points)):
                dist = self._distance(points[i], points[j])
                if dist < min_dist:
                    min_dist = dist
                    closest = (points[i], points[j])
        
        return {
            "distance": min_dist,
            "points": closest
        }
    
    def _distance(self, p1: tuple, p2: tuple) -> float:
        """Calculate Euclidean distance"""
        return ((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2) ** 0.5
    
    def _strassen_matrix_multiply(
        self, 
        A: List[List[int]], 
        B: List[List[int]]
    ) -> List[List[int]]:
        """
        Matrix multiplication (standard algorithm)
        
        Note: This is a standard O(n³) matrix multiplication, not the actual
        Strassen algorithm which is O(n^2.8). A full Strassen implementation
        would be significantly more complex and is typically only beneficial
        for very large matrices (n > 1000).
        """
        if not A or not B:
            return []
        
        n = len(A)
        m = len(B[0])
        
        result = [[0] * m for _ in range(n)]
        
        for i in range(n):
            for j in range(m):
                for k in range(len(B)):
                    result[i][j] += A[i][k] * B[k][j]
        
        return result
    
    def _generic_divide_conquer(self, input_data: Dict[str, Any]) -> Any:
        """Generic divide and conquer for custom problems"""
        data = input_data.get("data")
        
        if not data:
            return None
        
        # Base case
        if len(data) <= 1:
            return data
        
        # Divide
        mid = len(data) // 2
        left = data[:mid]
        right = data[mid:]
        
        return {
            "divided": True,
            "left_size": len(left),
            "right_size": len(right),
            "note": "Implement custom divide/conquer logic"
        }
    
    def _get_approach_description(self, problem_type: str) -> str:
        """Get description of the approach"""
        descriptions = {
            "merge_sort": "Divide array, sort halves, merge sorted halves",
            "quick_sort": "Partition around pivot, recursively sort partitions",
            "binary_search": "Divide search space in half each iteration",
            "max_subarray": "Find max in left, right, and crossing subarrays",
            "closest_pair": "Divide points, find closest in each half and across",
            "strassen_matrix": "Divide matrices into submatrices, multiply efficiently"
        }
        return descriptions.get(problem_type, "Custom divide and conquer approach")
