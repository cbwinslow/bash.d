"""
Algorithm Optimizer Agent

Agent that analyzes and optimizes algorithm selection and performance.
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task
from ..algorithms.optimization import AlgorithmOrchestrator


class AlgorithmOptimizerAgent(BaseAgent):
    """
    Algorithm Optimizer Agent
    
    This agent analyzes problems, recommends optimal algorithms,
    compares algorithm performance, and provides optimization insights.
    """
    
    def __init__(self, **data):
        """Initialize the Algorithm Optimizer agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "Algorithm Optimizer Agent"
        if "type" not in data:
            data["type"] = AgentType.AUTOMATION
        if "description" not in data:
            data["description"] = "Analyzes and optimizes algorithm selection and performance"
        if "tags" not in data:
            data["tags"] = ["automation_agent", "optimization"]
        
        # Initialize parent
        super().__init__(**data)
        
        # Initialize algorithm orchestrator
        self.orchestrator = AlgorithmOrchestrator()
        
        # Add capabilities
        self.capabilities.extend([
            AgentCapability(
                name="algorithm_recommendation",
                description="Recommend best algorithm for a problem",
                parameters={"task": "str", "requirements": "dict"},
                required=True
            ),
            AgentCapability(
                name="algorithm_comparison",
                description="Compare multiple algorithms on same problem",
                parameters={"problem": "dict", "algorithms": "list"},
                required=True
            ),
            AgentCapability(
                name="performance_analysis",
                description="Analyze algorithm performance metrics",
                parameters={},
                required=True
            ),
            AgentCapability(
                name="optimization_insights",
                description="Provide insights for optimization",
                parameters={"execution_history": "list"},
                required=True
            ),
        ])
        
        # Add metadata
        self.metadata.update({
            "specialization": "algorithm_optimization",
            "category": "automation",
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute an optimization task"""
        input_data = task.input_data
        action = input_data.get("action", "recommend")
        
        if action == "recommend":
            # Recommend best algorithm
            problem = input_data.get("problem", {})
            recommendation = self.orchestrator.recommend_algorithm(problem)
            
            return {
                "status": "completed",
                "agent": self.name,
                "action": "recommendation",
                "recommendation": recommendation
            }
        
        elif action == "compare":
            # Compare algorithms
            problem = input_data.get("problem", {})
            algorithms = input_data.get("algorithms", [])
            
            results = self.orchestrator.compare_algorithms(problem, algorithms)
            
            # Analyze results
            comparison = self._analyze_comparison(results)
            
            return {
                "status": "completed",
                "agent": self.name,
                "action": "comparison",
                "results": results,
                "analysis": comparison
            }
        
        elif action == "analyze":
            # Analyze performance
            metrics = self.orchestrator.get_algorithm_metrics()
            insights = self._generate_insights(metrics)
            
            return {
                "status": "completed",
                "agent": self.name,
                "action": "analysis",
                "metrics": metrics,
                "insights": insights
            }
        
        elif action == "list":
            # List algorithms
            algorithm_type = input_data.get("algorithm_type")
            algorithms = self.orchestrator.list_algorithms(algorithm_type)
            
            return {
                "status": "completed",
                "agent": self.name,
                "action": "list",
                "algorithms": algorithms
            }
        
        else:
            return {
                "status": "failed",
                "error": f"Unknown action: {action}"
            }
    
    def _analyze_comparison(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze comparison results"""
        analysis = {
            "fastest": None,
            "most_successful": None,
            "summary": []
        }
        
        fastest_time = float('inf')
        best_success_rate = 0.0
        
        for algo_key, result in results.items():
            if result.success:
                if result.execution_time_ms < fastest_time:
                    fastest_time = result.execution_time_ms
                    analysis["fastest"] = algo_key
            
            analysis["summary"].append({
                "algorithm": algo_key,
                "success": result.success,
                "execution_time_ms": result.execution_time_ms,
                "strategy": result.strategy.value
            })
        
        return analysis
    
    def _generate_insights(self, metrics: Dict[str, Any]) -> List[str]:
        """Generate optimization insights from metrics"""
        insights = []
        
        for algo_key, algo_metrics in metrics.items():
            success_rate = algo_metrics.get("success_rate", 0.0)
            executions = algo_metrics.get("executions", 0)
            avg_time = algo_metrics.get("avg_execution_time_ms", 0.0)
            
            if executions > 0:
                if success_rate < 0.8:
                    insights.append(
                        f"{algo_key}: Low success rate ({success_rate:.2%}), "
                        "consider reviewing input validation"
                    )
                
                if avg_time > 1000:
                    insights.append(
                        f"{algo_key}: High average execution time ({avg_time:.0f}ms), "
                        "consider optimization"
                    )
                
                if success_rate > 0.95 and avg_time < 100:
                    insights.append(
                        f"{algo_key}: Excellent performance "
                        f"({success_rate:.2%} success, {avg_time:.0f}ms avg)"
                    )
        
        if not insights:
            insights.append("No significant issues detected. All algorithms performing well.")
        
        return insights
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "algorithm_optimizer_agent",
            "description": "Analyze and optimize algorithm selection and performance",
            "parameters": {
                "type": "object",
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": ["recommend", "compare", "analyze", "list"],
                        "description": "Action to perform"
                    },
                    "problem": {
                        "type": "object",
                        "description": "Problem description for recommendation/comparison"
                    },
                    "algorithms": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "List of algorithms to compare"
                    },
                    "algorithm_type": {
                        "type": "string",
                        "enum": ["code_generation", "problem_solving"],
                        "description": "Filter algorithms by type"
                    }
                },
                "required": ["action"]
            }
        }
    
    def get_execution_history(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent execution history"""
        return self.orchestrator.get_execution_history(limit)
