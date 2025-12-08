"""
Greedy Algorithm Solver

Makes locally optimal choices at each step to find a global solution.
"""

from typing import Dict, Any, List, Tuple
import heapq
from ..base import Algorithm, AlgorithmType, AlgorithmStrategy


class GreedyAlgorithmSolver(Algorithm):
    """
    Greedy algorithm solver
    
    Makes locally optimal choices at each step hoping to find global optimum.
    
    Example:
        ```python
        solver = GreedyAlgorithmSolver()
        result = solver.execute({
            "problem_type": "activity_selection",
            "activities": [
                {"start": 1, "end": 3},
                {"start": 2, "end": 5},
                {"start": 4, "end": 7}
            ]
        })
        ```
    """
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "Greedy Algorithm Solver"
        if "type" not in data:
            data["type"] = AlgorithmType.PROBLEM_SOLVING
        if "strategy" not in data:
            data["strategy"] = AlgorithmStrategy.GREEDY
        if "description" not in data:
            data["description"] = "Solves problems using greedy local optimization"
        
        super().__init__(**data)
    
    def _validate_input(self, input_data: Dict[str, Any]) -> None:
        """Validate input for greedy algorithm"""
        super()._validate_input(input_data)
        
        if "problem_type" not in input_data:
            raise ValueError("Missing required field: problem_type")
    
    def _execute_core(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute greedy algorithm"""
        problem_type = input_data["problem_type"]
        
        if problem_type == "activity_selection":
            result = self._activity_selection(input_data.get("activities", []))
        elif problem_type == "fractional_knapsack":
            result = self._fractional_knapsack(
                input_data.get("items", []),
                input_data.get("capacity", 0)
            )
        elif problem_type == "huffman_coding":
            result = self._huffman_coding(input_data.get("frequencies", {}))
        elif problem_type == "interval_scheduling":
            result = self._interval_scheduling(input_data.get("intervals", []))
        elif problem_type == "job_sequencing":
            result = self._job_sequencing(input_data.get("jobs", []))
        elif problem_type == "minimum_coins":
            result = self._minimum_coins(
                input_data.get("coins", []),
                input_data.get("amount", 0)
            )
        elif problem_type == "task_assignment":
            result = self._task_assignment(
                input_data.get("tasks", []),
                input_data.get("workers", [])
            )
        else:
            result = {"error": f"Unknown problem type: {problem_type}"}
        
        return {
            "problem_type": problem_type,
            "result": result,
            "algorithm": "greedy"
        }
    
    def _activity_selection(self, activities: List[Dict[str, int]]) -> Dict[str, Any]:
        """Select maximum number of non-overlapping activities"""
        if not activities:
            return {"selected": [], "count": 0}
        
        # Sort by end time
        sorted_activities = sorted(activities, key=lambda x: x["end"])
        
        selected = [sorted_activities[0]]
        last_end = sorted_activities[0]["end"]
        
        for activity in sorted_activities[1:]:
            if activity["start"] >= last_end:
                selected.append(activity)
                last_end = activity["end"]
        
        return {
            "selected": selected,
            "count": len(selected),
            "total_activities": len(activities)
        }
    
    def _fractional_knapsack(
        self, 
        items: List[Dict[str, float]], 
        capacity: float
    ) -> Dict[str, Any]:
        """Fractional knapsack - can take fractions of items"""
        if not items or capacity <= 0:
            return {"max_value": 0, "items": []}
        
        # Calculate value per weight and sort
        for item in items:
            item["ratio"] = item["value"] / item["weight"]
        
        sorted_items = sorted(items, key=lambda x: x["ratio"], reverse=True)
        
        total_value = 0.0
        selected_items = []
        remaining_capacity = capacity
        
        for item in sorted_items:
            if remaining_capacity >= item["weight"]:
                # Take whole item
                selected_items.append({
                    "item": item,
                    "fraction": 1.0,
                    "value": item["value"]
                })
                total_value += item["value"]
                remaining_capacity -= item["weight"]
            elif remaining_capacity > 0:
                # Take fraction
                fraction = remaining_capacity / item["weight"]
                selected_items.append({
                    "item": item,
                    "fraction": fraction,
                    "value": item["value"] * fraction
                })
                total_value += item["value"] * fraction
                remaining_capacity = 0
                break
        
        return {
            "max_value": total_value,
            "items": selected_items,
            "capacity_used": capacity - remaining_capacity
        }
    
    def _huffman_coding(self, frequencies: Dict[str, int]) -> Dict[str, Any]:
        """Generate Huffman codes for compression"""
        if not frequencies:
            return {"codes": {}, "tree": None}
        
        # Create heap of (frequency, unique_id, character, left, right)
        heap = [[freq, i, char, None, None] 
                for i, (char, freq) in enumerate(frequencies.items())]
        heapq.heapify(heap)
        
        unique_id = len(frequencies)
        
        # Build Huffman tree
        while len(heap) > 1:
            left = heapq.heappop(heap)
            right = heapq.heappop(heap)
            
            merged = [
                left[0] + right[0],  # Combined frequency
                unique_id,
                None,  # Internal node has no character
                left,
                right
            ]
            heapq.heappush(heap, merged)
            unique_id += 1
        
        # Generate codes
        codes = {}
        
        def generate_codes(node, code=""):
            if node[2] is not None:  # Leaf node
                codes[node[2]] = code if code else "0"
            else:  # Internal node
                if node[3]:  # Left child
                    generate_codes(node[3], code + "0")
                if node[4]:  # Right child
                    generate_codes(node[4], code + "1")
        
        if heap:
            generate_codes(heap[0])
        
        # Calculate compression ratio
        original_bits = sum(frequencies.values()) * 8  # Assuming 8 bits per char
        compressed_bits = sum(len(codes[char]) * freq 
                            for char, freq in frequencies.items())
        
        return {
            "codes": codes,
            "compression_ratio": original_bits / compressed_bits if compressed_bits > 0 else 0
        }
    
    def _interval_scheduling(self, intervals: List[Dict[str, int]]) -> Dict[str, Any]:
        """Schedule maximum non-overlapping intervals"""
        return self._activity_selection(intervals)
    
    def _job_sequencing(self, jobs: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Schedule jobs with deadlines to maximize profit"""
        if not jobs:
            return {"scheduled_jobs": [], "total_profit": 0}
        
        # Sort by profit (descending)
        sorted_jobs = sorted(jobs, key=lambda x: x.get("profit", 0), reverse=True)
        
        # Find maximum deadline
        max_deadline = max(job.get("deadline", 1) for job in sorted_jobs)
        
        # Schedule jobs
        schedule = [None] * max_deadline
        total_profit = 0
        scheduled = []
        
        for job in sorted_jobs:
            deadline = job.get("deadline", 1)
            
            # Find free slot before deadline
            for slot in range(min(deadline, max_deadline) - 1, -1, -1):
                if schedule[slot] is None:
                    schedule[slot] = job
                    scheduled.append(job)
                    total_profit += job.get("profit", 0)
                    break
        
        return {
            "scheduled_jobs": scheduled,
            "total_profit": total_profit,
            "jobs_scheduled": len(scheduled),
            "total_jobs": len(jobs)
        }
    
    def _minimum_coins(self, coins: List[int], amount: int) -> Dict[str, Any]:
        """Make change using minimum coins (greedy approach)"""
        if amount == 0:
            return {"coins_used": [], "count": 0}
        
        if not coins:
            return {"coins_used": [], "count": -1, "error": "No coins available"}
        
        # Sort coins in descending order
        coins_sorted = sorted(coins, reverse=True)
        
        coins_used = []
        remaining = amount
        
        for coin in coins_sorted:
            while remaining >= coin:
                coins_used.append(coin)
                remaining -= coin
        
        if remaining > 0:
            return {
                "coins_used": [],
                "count": -1,
                "error": "Cannot make exact change"
            }
        
        return {
            "coins_used": coins_used,
            "count": len(coins_used),
            "amount": amount
        }
    
    def _task_assignment(
        self, 
        tasks: List[Dict[str, Any]], 
        workers: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Assign tasks to workers to maximize efficiency"""
        if not tasks or not workers:
            return {"assignments": [], "total_efficiency": 0}
        
        # Sort tasks by priority/value
        sorted_tasks = sorted(
            tasks, 
            key=lambda x: x.get("priority", 0), 
            reverse=True
        )
        
        # Sort workers by skill/capacity
        sorted_workers = sorted(
            workers,
            key=lambda x: x.get("skill", 0),
            reverse=True
        )
        
        assignments = []
        worker_load = {worker.get("id", i): 0 for i, worker in enumerate(workers)}
        
        for task in sorted_tasks:
            # Find best available worker
            best_worker = None
            min_load = float('inf')
            
            for worker in sorted_workers:
                worker_id = worker.get("id", workers.index(worker))
                if worker_load[worker_id] < min_load:
                    min_load = worker_load[worker_id]
                    best_worker = worker
            
            if best_worker:
                worker_id = best_worker.get("id", workers.index(best_worker))
                assignments.append({
                    "task": task,
                    "worker": best_worker,
                    "worker_id": worker_id
                })
                worker_load[worker_id] += task.get("duration", 1)
        
        return {
            "assignments": assignments,
            "tasks_assigned": len(assignments),
            "total_tasks": len(tasks),
            "worker_load": worker_load
        }
