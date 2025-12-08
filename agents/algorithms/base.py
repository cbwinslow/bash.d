"""
Base Algorithm Classes and Interfaces

Provides the foundation for all algorithm implementations in the system.
"""

from enum import Enum
from typing import Dict, Any, Optional, List, Callable
from datetime import datetime
from pydantic import BaseModel, Field
import uuid


class AlgorithmType(str, Enum):
    """Types of algorithms available in the system"""
    CODE_GENERATION = "code_generation"
    PROBLEM_SOLVING = "problem_solving"
    OPTIMIZATION = "optimization"
    ANALYSIS = "analysis"
    TRANSFORMATION = "transformation"


class AlgorithmStrategy(str, Enum):
    """Algorithm execution strategies"""
    TEMPLATE_BASED = "template_based"
    AST_BASED = "ast_based"
    PATTERN_BASED = "pattern_based"
    AI_ASSISTED = "ai_assisted"
    DIVIDE_CONQUER = "divide_conquer"
    BACKTRACKING = "backtracking"
    DYNAMIC_PROGRAMMING = "dynamic_programming"
    GREEDY = "greedy"
    CONSTRAINT_SATISFACTION = "constraint_satisfaction"
    GENETIC = "genetic"
    SIMULATED_ANNEALING = "simulated_annealing"
    PARTICLE_SWARM = "particle_swarm"


class AlgorithmResult(BaseModel):
    """Result of an algorithm execution"""
    algorithm_id: str
    algorithm_name: str
    strategy: AlgorithmStrategy
    success: bool
    result_data: Dict[str, Any] = Field(default_factory=dict)
    error: Optional[str] = None
    execution_time_ms: float = 0.0
    metadata: Dict[str, Any] = Field(default_factory=dict)
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class AlgorithmConfig(BaseModel):
    """Configuration for algorithm execution"""
    max_iterations: int = Field(default=1000, gt=0)
    timeout_seconds: int = Field(default=300, gt=0)
    optimize_for: str = Field(default="quality")  # quality, speed, memory
    debug_mode: bool = Field(default=False)
    parallel_execution: bool = Field(default=False)
    custom_params: Dict[str, Any] = Field(default_factory=dict)


class Algorithm(BaseModel):
    """
    Base Algorithm Class
    
    All algorithm implementations inherit from this base class.
    """
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str = Field(..., description="Algorithm name")
    type: AlgorithmType = Field(..., description="Algorithm type")
    strategy: AlgorithmStrategy = Field(..., description="Execution strategy")
    description: str = Field(..., description="Algorithm description")
    version: str = Field(default="1.0.0")
    config: AlgorithmConfig = Field(default_factory=AlgorithmConfig)
    
    # Metrics
    executions_count: int = Field(default=0)
    success_count: int = Field(default=0)
    failure_count: int = Field(default=0)
    average_execution_time_ms: float = Field(default=0.0)
    
    def execute(self, input_data: Dict[str, Any]) -> AlgorithmResult:
        """
        Execute the algorithm
        
        Args:
            input_data: Input data for the algorithm
            
        Returns:
            AlgorithmResult with execution details
        """
        start_time = datetime.utcnow()
        
        try:
            # Validate input
            self._validate_input(input_data)
            
            # Execute core logic
            result_data = self._execute_core(input_data)
            
            # Calculate execution time
            end_time = datetime.utcnow()
            execution_time_ms = (end_time - start_time).total_seconds() * 1000
            
            # Update metrics
            self.executions_count += 1
            self.success_count += 1
            self._update_average_execution_time(execution_time_ms)
            
            return AlgorithmResult(
                algorithm_id=self.id,
                algorithm_name=self.name,
                strategy=self.strategy,
                success=True,
                result_data=result_data,
                execution_time_ms=execution_time_ms,
                metadata={
                    "version": self.version,
                    "input_keys": list(input_data.keys())
                }
            )
            
        except Exception as e:
            end_time = datetime.utcnow()
            execution_time_ms = (end_time - start_time).total_seconds() * 1000
            
            self.executions_count += 1
            self.failure_count += 1
            
            return AlgorithmResult(
                algorithm_id=self.id,
                algorithm_name=self.name,
                strategy=self.strategy,
                success=False,
                error=str(e),
                execution_time_ms=execution_time_ms
            )
    
    def _validate_input(self, input_data: Dict[str, Any]) -> None:
        """
        Validate input data
        
        Override in subclasses for specific validation
        """
        if not isinstance(input_data, dict):
            raise ValueError("Input data must be a dictionary")
    
    def _execute_core(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Core algorithm logic
        
        Must be implemented by subclasses
        """
        raise NotImplementedError("Subclasses must implement _execute_core")
    
    def _update_average_execution_time(self, execution_time_ms: float) -> None:
        """Update running average of execution time"""
        if self.executions_count == 1:
            self.average_execution_time_ms = execution_time_ms
        else:
            self.average_execution_time_ms = (
                (self.average_execution_time_ms * (self.executions_count - 1) + execution_time_ms)
                / self.executions_count
            )
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get algorithm performance metrics"""
        success_rate = (
            self.success_count / self.executions_count 
            if self.executions_count > 0 else 0.0
        )
        
        return {
            "algorithm_id": self.id,
            "algorithm_name": self.name,
            "executions": self.executions_count,
            "successes": self.success_count,
            "failures": self.failure_count,
            "success_rate": success_rate,
            "avg_execution_time_ms": self.average_execution_time_ms
        }
