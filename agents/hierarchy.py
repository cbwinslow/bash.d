"""
Hierarchical Multi-Agent System

This module implements a hierarchical agent architecture with:
- Manager agents for high-level planning and task decomposition
- Worker agents for task execution
- Coordinator agents for synchronization and communication
- Support for complex problem solving through hierarchical organization
"""

import asyncio
import logging
import random
from typing import List, Dict, Any, Optional, Set, Tuple
from datetime import datetime
from enum import Enum
from dataclasses import dataclass, field

from .base import (
    BaseAgent,
    Task,
    TaskStatus,
    TaskPriority,
    AgentStatus,
    AgentType,
    AgentMessage,
    CommunicationProtocol
)

logger = logging.getLogger(__name__)


class AgentRole(str, Enum):
    """Hierarchical agent roles"""
    MANAGER = "manager"
    COORDINATOR = "coordinator"
    WORKER = "worker"
    SPECIALIST = "specialist"
    SUPERVISOR = "supervisor"


@dataclass
class TaskDecomposition:
    """Result of task decomposition"""
    original_task: Task
    subtasks: List[Task] = field(default_factory=list)
    dependencies: Dict[str, List[str]] = field(default_factory=dict)
    execution_plan: List[List[str]] = field(default_factory=list)  # Parallel execution stages
    estimated_time: float = 0.0


class HierarchicalAgent(BaseAgent):
    """
    Extended agent with hierarchical capabilities
    """
    role: AgentRole = AgentRole.WORKER
    parent_id: Optional[str] = None
    subordinates: List[str] = field(default_factory=list)
    delegation_enabled: bool = True
    max_subordinates: int = 10
    
    def can_delegate(self) -> bool:
        """Check if agent can delegate tasks"""
        return (
            self.delegation_enabled and
            self.role in [AgentRole.MANAGER, AgentRole.COORDINATOR, AgentRole.SUPERVISOR] and
            len(self.subordinates) > 0
        )
    
    def add_subordinate(self, agent_id: str) -> bool:
        """Add a subordinate agent"""
        if len(self.subordinates) < self.max_subordinates:
            self.subordinates.append(agent_id)
            return True
        return False


class ManagerAgent(HierarchicalAgent):
    """
    Manager Agent for high-level planning and task decomposition
    
    Responsibilities:
    - Break down complex problems into manageable subtasks
    - Assign work to subordinate agents
    - Monitor progress and handle escalations
    - Make strategic decisions
    """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.role = AgentRole.MANAGER
        self.delegation_enabled = True
    
    async def decompose_task(self, task: Task) -> TaskDecomposition:
        """
        Decompose a complex task into subtasks
        
        Args:
            task: Complex task to decompose
            
        Returns:
            TaskDecomposition with subtasks and execution plan
        """
        logger.info(f"Manager {self.name} decomposing task: {task.title}")
        
        decomposition = TaskDecomposition(original_task=task)
        
        # Analyze task complexity
        complexity = self._analyze_complexity(task)
        
        if complexity > 10:  # High complexity, needs decomposition
            # Strategy 1: Break by components
            if "api" in task.description.lower():
                decomposition.subtasks.extend([
                    Task(
                        title=f"Design API schema for {task.title}",
                        description="Define API endpoints, request/response models",
                        priority=task.priority,
                        agent_type=AgentType.DESIGN
                    ),
                    Task(
                        title=f"Implement API handlers for {task.title}",
                        description="Create route handlers and business logic",
                        priority=task.priority,
                        agent_type=AgentType.PROGRAMMING
                    ),
                    Task(
                        title=f"Add tests for {task.title}",
                        description="Write unit and integration tests",
                        priority=task.priority,
                        agent_type=AgentType.TESTING
                    ),
                    Task(
                        title=f"Document API for {task.title}",
                        description="Create API documentation",
                        priority=task.priority,
                        agent_type=AgentType.DOCUMENTATION
                    )
                ])
            
            # Strategy 2: Break by phases
            elif "system" in task.description.lower() or "application" in task.description.lower():
                decomposition.subtasks.extend([
                    Task(
                        title=f"Design architecture for {task.title}",
                        description="Define system architecture and components",
                        priority=TaskPriority.HIGH,
                        agent_type=AgentType.DESIGN
                    ),
                    Task(
                        title=f"Implement core functionality for {task.title}",
                        description="Build main application components",
                        priority=task.priority,
                        agent_type=AgentType.PROGRAMMING
                    ),
                    Task(
                        title=f"Set up infrastructure for {task.title}",
                        description="Configure deployment and infrastructure",
                        priority=task.priority,
                        agent_type=AgentType.DEVOPS
                    ),
                    Task(
                        title=f"Security review for {task.title}",
                        description="Perform security audit and fixes",
                        priority=TaskPriority.HIGH,
                        agent_type=AgentType.SECURITY
                    )
                ])
            
            # Strategy 3: Generic decomposition
            else:
                num_subtasks = min(complexity // 3, 10)
                for i in range(num_subtasks):
                    decomposition.subtasks.append(Task(
                        title=f"Subtask {i+1} of {task.title}",
                        description=f"Component {i+1} of the main task",
                        priority=task.priority,
                        agent_type=task.agent_type
                    ))
            
            # Build dependencies
            for i in range(1, len(decomposition.subtasks)):
                prev_task = decomposition.subtasks[i-1]
                curr_task = decomposition.subtasks[i]
                curr_task.dependencies.append(prev_task.id)
                decomposition.dependencies[curr_task.id] = [prev_task.id]
            
            # Create execution plan (stages that can run in parallel)
            decomposition.execution_plan = self._create_execution_plan(
                decomposition.subtasks,
                decomposition.dependencies
            )
            
            # Estimate time
            decomposition.estimated_time = len(decomposition.execution_plan) * 10.0  # seconds
        
        else:
            # Task is simple enough, no decomposition needed
            decomposition.subtasks = [task]
            decomposition.execution_plan = [[task.id]]
            decomposition.estimated_time = 5.0
        
        logger.info(f"Decomposed into {len(decomposition.subtasks)} subtasks")
        return decomposition
    
    def _analyze_complexity(self, task: Task) -> int:
        """Analyze task complexity (0-100)"""
        complexity = 0
        
        # Description length
        complexity += len(task.description) // 20
        
        # Keywords indicating complexity
        complex_keywords = [
            "system", "application", "api", "database", "multiple",
            "complex", "integrate", "architecture", "microservice"
        ]
        for keyword in complex_keywords:
            if keyword in task.description.lower():
                complexity += 5
        
        # Priority indicates complexity
        if task.priority == TaskPriority.CRITICAL:
            complexity += 10
        elif task.priority == TaskPriority.HIGH:
            complexity += 5
        
        # Dependencies indicate complexity
        complexity += len(task.dependencies) * 3
        
        return min(complexity, 100)
    
    def _create_execution_plan(
        self,
        subtasks: List[Task],
        dependencies: Dict[str, List[str]]
    ) -> List[List[str]]:
        """
        Create execution plan with parallel stages
        
        Returns:
            List of stages, where each stage contains task IDs that can run in parallel
        """
        plan: List[List[str]] = []
        completed: Set[str] = set()
        remaining = {task.id for task in subtasks}
        
        while remaining:
            # Find tasks with all dependencies met
            stage = []
            for task_id in remaining:
                deps = dependencies.get(task_id, [])
                if all(dep in completed for dep in deps):
                    stage.append(task_id)
            
            if not stage:
                # Circular dependency or error
                stage = list(remaining)  # Add all remaining to break deadlock
            
            plan.append(stage)
            for task_id in stage:
                completed.add(task_id)
                remaining.remove(task_id)
        
        return plan
    
    async def delegate_task(
        self,
        task: Task,
        agent_id: str
    ) -> bool:
        """
        Delegate a task to a subordinate agent
        
        Args:
            task: Task to delegate
            agent_id: ID of subordinate agent
            
        Returns:
            True if delegation successful
        """
        if agent_id not in self.subordinates:
            logger.warning(f"Agent {agent_id} is not a subordinate of {self.name}")
            return False
        
        logger.info(f"Manager {self.name} delegating task {task.title} to agent {agent_id}")
        
        # In a real implementation, this would send a message to the agent
        # For now, we'll just log it
        task.assigned_agent_id = agent_id
        task.status = TaskStatus.ASSIGNED
        
        return True


class CoordinatorAgent(HierarchicalAgent):
    """
    Coordinator Agent for synchronization and communication
    
    Responsibilities:
    - Coordinate work between multiple agents
    - Manage dependencies and synchronization
    - Handle agent-to-agent communication
    - Resolve conflicts and bottlenecks
    """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.role = AgentRole.COORDINATOR
        self.sync_points: Dict[str, Set[str]] = {}  # sync_id -> set of waiting agents
    
    async def coordinate_parallel_execution(
        self,
        tasks: List[Task],
        agents: Dict[str, BaseAgent]
    ) -> Dict[str, Any]:
        """
        Coordinate parallel execution of multiple tasks
        
        Args:
            tasks: Tasks to coordinate
            agents: Available agents
            
        Returns:
            Coordination results
        """
        logger.info(f"Coordinator {self.name} managing {len(tasks)} tasks across {len(agents)} agents")
        
        results = {
            "started_at": datetime.utcnow(),
            "tasks_completed": 0,
            "tasks_failed": 0,
            "sync_points": 0
        }
        
        # Create task batches that can run in parallel
        batches = self._create_parallel_batches(tasks)
        
        for batch_idx, batch in enumerate(batches):
            logger.info(f"Executing batch {batch_idx + 1}/{len(batches)} with {len(batch)} tasks")
            
            # Assign tasks to agents
            assignments = self._assign_tasks_to_agents(batch, agents)
            
            # Execute tasks in parallel
            batch_tasks = []
            for task, agent in assignments:
                batch_tasks.append(self._execute_coordinated_task(task, agent))
            
            # Wait for batch completion (synchronization point)
            batch_results = await asyncio.gather(*batch_tasks, return_exceptions=True)
            
            results["sync_points"] += 1
            
            # Process results
            for result in batch_results:
                if isinstance(result, Exception):
                    results["tasks_failed"] += 1
                    logger.error(f"Task failed: {result}")
                else:
                    results["tasks_completed"] += 1
        
        results["completed_at"] = datetime.utcnow()
        results["duration"] = (results["completed_at"] - results["started_at"]).total_seconds()
        
        return results
    
    def _create_parallel_batches(self, tasks: List[Task]) -> List[List[Task]]:
        """Create batches of tasks that can run in parallel"""
        batches: List[List[Task]] = []
        completed_ids: Set[str] = set()
        remaining = tasks.copy()
        
        while remaining:
            batch = []
            for task in remaining[:]:
                # Check if all dependencies are completed
                if all(dep in completed_ids for dep in task.dependencies):
                    batch.append(task)
                    remaining.remove(task)
            
            if not batch and remaining:
                # No tasks ready - might be circular dependency
                # Add one task to break the cycle
                batch.append(remaining.pop(0))
            
            if batch:
                batches.append(batch)
                for task in batch:
                    completed_ids.add(task.id)
        
        return batches
    
    def _assign_tasks_to_agents(
        self,
        tasks: List[Task],
        agents: Dict[str, BaseAgent]
    ) -> List[Tuple[Task, BaseAgent]]:
        """Assign tasks to agents optimally"""
        assignments = []
        available_agents = list(agents.values())
        
        for task in tasks:
            # Find best agent for task
            best_agent = None
            best_score = -1
            
            for agent in available_agents:
                if not agent.is_available():
                    continue
                
                score = 0
                # Match agent type
                if task.agent_type and task.agent_type == agent.type:
                    score += 10
                
                # Consider agent performance
                score += agent.metrics.success_rate * 5
                
                # Consider agent load
                score -= len(agent.task_queue)
                
                if score > best_score:
                    best_score = score
                    best_agent = agent
            
            if best_agent:
                assignments.append((task, best_agent))
        
        return assignments
    
    async def _execute_coordinated_task(
        self,
        task: Task,
        agent: BaseAgent
    ) -> Dict[str, Any]:
        """Execute a task with coordination"""
        task.status = TaskStatus.IN_PROGRESS
        task.started_at = datetime.utcnow()
        
        try:
            # Simulate task execution
            await asyncio.sleep(random.uniform(0.1, 0.5))
            
            task.status = TaskStatus.COMPLETED
            task.completed_at = datetime.utcnow()
            
            return {
                "task_id": task.id,
                "agent_id": agent.id,
                "status": "completed"
            }
        
        except Exception as e:
            task.status = TaskStatus.FAILED
            task.error = str(e)
            raise
    
    async def create_sync_point(self, sync_id: str, required_agents: Set[str]) -> None:
        """Create a synchronization point for agents"""
        self.sync_points[sync_id] = required_agents.copy()
        logger.info(f"Created sync point {sync_id} for {len(required_agents)} agents")
    
    async def wait_at_sync_point(self, sync_id: str, agent_id: str) -> None:
        """Wait at a synchronization point"""
        if sync_id not in self.sync_points:
            return
        
        if agent_id in self.sync_points[sync_id]:
            self.sync_points[sync_id].remove(agent_id)
            logger.info(f"Agent {agent_id} reached sync point {sync_id}")
        
        # Wait for all agents to reach sync point
        while self.sync_points.get(sync_id):
            await asyncio.sleep(0.1)
        
        logger.info(f"All agents passed sync point {sync_id}")


class WorkerAgent(HierarchicalAgent):
    """
    Worker Agent for task execution
    
    Responsibilities:
    - Execute assigned tasks
    - Report progress to manager/coordinator
    - Request help when needed
    - Focus on specialized work
    """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.role = AgentRole.WORKER
        self.delegation_enabled = False
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """
        Execute a task
        
        Args:
            task: Task to execute
            
        Returns:
            Task results
        """
        logger.info(f"Worker {self.name} executing task: {task.title}")
        
        task.status = TaskStatus.IN_PROGRESS
        task.started_at = datetime.utcnow()
        
        try:
            # Simulate work based on task complexity
            work_time = len(task.description) / 100.0
            await asyncio.sleep(min(work_time, 2.0))
            
            # Generate result
            result = {
                "task_id": task.id,
                "worker": self.name,
                "completed": True,
                "output": f"Completed: {task.title}"
            }
            
            task.status = TaskStatus.COMPLETED
            task.completed_at = datetime.utcnow()
            task.output_data = result
            
            return result
        
        except Exception as e:
            task.status = TaskStatus.FAILED
            task.error = str(e)
            logger.error(f"Worker {self.name} failed task {task.title}: {e}")
            raise
    
    async def request_help(self, issue: str) -> None:
        """Request help from manager or coordinator"""
        if self.parent_id:
            logger.info(f"Worker {self.name} requesting help: {issue}")
            # In real implementation, would send message to parent
        else:
            logger.warning(f"Worker {self.name} has no manager to request help from")



