"""
Agent Orchestration System

This module provides the core orchestration logic for managing multiple agents,
distributing tasks, handling communication, and ensuring continuous operation.
"""

import asyncio
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, timezone
from collections import defaultdict
from enum import Enum

from .base import (
    BaseAgent,
    Task,
    TaskStatus,
    TaskPriority,
    AgentStatus,
    AgentMessage,
    CommunicationProtocol
)

logger = logging.getLogger(__name__)


class OrchestrationStrategy(str, Enum):
    """Task distribution strategies"""
    ROUND_ROBIN = "round_robin"
    LEAST_BUSY = "least_busy"
    SPECIALIZED = "specialized"
    PRIORITY_BASED = "priority_based"
    LOAD_BALANCED = "load_balanced"


class AgentOrchestrator:
    """
    Central orchestration system for managing multiple AI agents
    
    This orchestrator:
    - Maintains a registry of all agents
    - Distributes tasks to appropriate agents
    - Monitors agent health and performance
    - Handles agent-to-agent communication
    - Ensures continuous task execution
    - Manages agent lifecycle
    
    Example:
        ```python
        orchestrator = AgentOrchestrator()
        
        # Register agents
        orchestrator.register_agent(python_agent)
        orchestrator.register_agent(devops_agent)
        
        # Submit tasks
        task = Task(title="Build API", priority=TaskPriority.HIGH)
        orchestrator.submit_task(task)
        
        # Start orchestration
        await orchestrator.run()
        ```
    """
    
    def __init__(
        self,
        strategy: OrchestrationStrategy = OrchestrationStrategy.SPECIALIZED,
        max_concurrent_tasks: int = 100,
        health_check_interval: int = 30
    ):
        """
        Initialize the orchestrator
        
        Args:
            strategy: Task distribution strategy
            max_concurrent_tasks: Maximum concurrent tasks across all agents
            health_check_interval: Interval for health checks in seconds
        """
        self.strategy = strategy
        self.max_concurrent_tasks = max_concurrent_tasks
        self.health_check_interval = health_check_interval
        
        # Agent registry
        self.agents: Dict[str, BaseAgent] = {}
        self.agents_by_type: Dict[str, List[BaseAgent]] = defaultdict(list)
        
        # Task management
        self.pending_tasks: List[Task] = []
        self.active_tasks: Dict[str, Task] = {}
        self.completed_tasks: List[Task] = []
        self.failed_tasks: List[Task] = []
        
        # Communication
        self.message_queue: asyncio.Queue = asyncio.Queue()
        
        # State
        self.running = False
        self.started_at: Optional[datetime] = None
        
        # Metrics
        self.metrics = {
            "tasks_submitted": 0,
            "tasks_completed": 0,
            "tasks_failed": 0,
            "messages_sent": 0,
            "agents_registered": 0
        }
    
    def register_agent(self, agent: BaseAgent) -> None:
        """
        Register an agent with the orchestrator
        
        Args:
            agent: The agent to register
        """
        self.agents[agent.id] = agent
        self.agents_by_type[agent.type.value].append(agent)
        self.metrics["agents_registered"] += 1
        
        logger.info(f"Registered agent: {agent.name} ({agent.type.value})")
    
    def unregister_agent(self, agent_id: str) -> None:
        """
        Unregister an agent
        
        Args:
            agent_id: ID of the agent to unregister
        """
        if agent_id in self.agents:
            agent = self.agents[agent_id]
            self.agents_by_type[agent.type.value].remove(agent)
            del self.agents[agent_id]
            logger.info(f"Unregistered agent: {agent_id}")
    
    def submit_task(self, task: Task) -> str:
        """
        Submit a task for execution
        
        Args:
            task: The task to submit
            
        Returns:
            Task ID
        """
        task.status = TaskStatus.PENDING
        self.pending_tasks.append(task)
        self.metrics["tasks_submitted"] += 1
        
        logger.info(f"Task submitted: {task.title} (Priority: {task.priority.value})")
        
        return task.id
    
    def get_available_agents(
        self,
        agent_type: Optional[str] = None,
        min_capacity: int = 1
    ) -> List[BaseAgent]:
        """
        Get list of available agents
        
        Args:
            agent_type: Filter by agent type
            min_capacity: Minimum capacity (free task slots)
            
        Returns:
            List of available agents
        """
        agents = []
        
        search_pool = (
            self.agents_by_type.get(agent_type, []) if agent_type
            else self.agents.values()
        )
        
        for agent in search_pool:
            free_slots = agent.config.concurrency_limit - len(agent.task_queue)
            if agent.is_available() and free_slots >= min_capacity:
                agents.append(agent)
        
        return agents
    
    def assign_task(self, task: Task) -> Optional[BaseAgent]:
        """
        Assign a task to an appropriate agent
        
        Args:
            task: The task to assign
            
        Returns:
            The agent assigned to the task, or None if no agent available
        """
        # Get candidate agents
        candidates = self.get_available_agents(
            agent_type=task.agent_type.value if task.agent_type else None
        )
        
        if not candidates:
            return None
        
        # Select agent based on strategy
        selected_agent = None
        
        if self.strategy == OrchestrationStrategy.SPECIALIZED:
            # Prefer agents that match the task type exactly
            if task.agent_type:
                type_specific = [a for a in candidates if a.type == task.agent_type]
                if type_specific:
                    selected_agent = type_specific[0]
        
        elif self.strategy == OrchestrationStrategy.LEAST_BUSY:
            # Select agent with fewest tasks
            selected_agent = min(candidates, key=lambda a: len(a.task_queue))
        
        elif self.strategy == OrchestrationStrategy.ROUND_ROBIN:
            # Simple round-robin
            selected_agent = candidates[0]
        
        elif self.strategy == OrchestrationStrategy.LOAD_BALANCED:
            # Consider both queue length and current task
            def load_score(agent):
                queue_weight = len(agent.task_queue) * 2
                active_weight = 3 if agent.current_task else 0
                return queue_weight + active_weight
            
            selected_agent = min(candidates, key=load_score)
        
        # Fallback
        if not selected_agent:
            selected_agent = candidates[0]
        
        # Assign task
        if selected_agent.add_task(task):
            self.active_tasks[task.id] = task
            logger.info(f"Task {task.title} assigned to {selected_agent.name}")
            return selected_agent
        
        return None
    
    async def execute_agent_tasks(self, agent: BaseAgent) -> None:
        """
        Continuously execute tasks for an agent
        
        Args:
            agent: The agent to execute tasks for
        """
        while self.running:
            try:
                # Update agent status
                if agent.task_queue and agent.status == AgentStatus.IDLE:
                    agent.update_status(AgentStatus.WORKING)
                
                # Get next task
                task = agent.get_next_task()
                
                if task:
                    # Execute task
                    agent.current_task = task
                    task.status = TaskStatus.IN_PROGRESS
                    task.started_at = datetime.now(timezone.utc)
                    
                    start_time = asyncio.get_event_loop().time()
                    
                    try:
                        # Execute (placeholder - would call actual agent execution)
                        await asyncio.sleep(0.1)  # Simulate work
                        result = await agent.execute_task(task)
                        
                        # Record success
                        task.status = TaskStatus.COMPLETED
                        task.completed_at = datetime.now(timezone.utc)
                        task.output_data = result
                        
                        elapsed = asyncio.get_event_loop().time() - start_time
                        agent.record_task_completion(True, elapsed)
                        
                        # Move to completed
                        if task.id in self.active_tasks:
                            del self.active_tasks[task.id]
                        self.completed_tasks.append(task)
                        self.metrics["tasks_completed"] += 1
                        
                        logger.info(f"Task completed: {task.title} by {agent.name}")
                    
                    except Exception as e:
                        # Record failure
                        task.status = TaskStatus.FAILED
                        task.completed_at = datetime.now(timezone.utc)
                        task.error = str(e)
                        
                        elapsed = asyncio.get_event_loop().time() - start_time
                        agent.record_task_completion(False, elapsed)
                        
                        # Handle retry or failure
                        if task.retry_count < task.max_retries:
                            task.retry_count += 1
                            task.status = TaskStatus.PENDING
                            self.pending_tasks.append(task)
                            logger.warning(f"Task failed, retrying: {task.title}")
                        else:
                            if task.id in self.active_tasks:
                                del self.active_tasks[task.id]
                            self.failed_tasks.append(task)
                            self.metrics["tasks_failed"] += 1
                            logger.error(f"Task failed permanently: {task.title} - {e}")
                    
                    finally:
                        agent.current_task = None
                
                else:
                    # No tasks, update status and wait
                    if agent.status == AgentStatus.WORKING:
                        agent.update_status(AgentStatus.IDLE)
                    await asyncio.sleep(0.5)
            
            except Exception as e:
                logger.error(f"Error in agent task execution: {e}")
                await asyncio.sleep(1)
    
    async def distribute_tasks(self) -> None:
        """Continuously distribute pending tasks to available agents"""
        while self.running:
            try:
                if self.pending_tasks:
                    # Sort by priority
                    self.pending_tasks.sort(
                        key=lambda t: (
                            {
                                TaskPriority.CRITICAL: 0,
                                TaskPriority.HIGH: 1,
                                TaskPriority.MEDIUM: 2,
                                TaskPriority.LOW: 3,
                                TaskPriority.BACKGROUND: 4
                            }.get(t.priority, 999),
                            t.created_at
                        )
                    )
                    
                    # Try to assign tasks
                    assigned = []
                    for task in self.pending_tasks[:]:
                        if self.assign_task(task):
                            assigned.append(task)
                    
                    # Remove assigned tasks
                    for task in assigned:
                        self.pending_tasks.remove(task)
                
                await asyncio.sleep(1)
            
            except Exception as e:
                logger.error(f"Error in task distribution: {e}")
                await asyncio.sleep(1)
    
    async def health_monitor(self) -> None:
        """Monitor agent health"""
        while self.running:
            try:
                for agent in self.agents.values():
                    health = agent.health_check()
                    
                    if not health["is_healthy"]:
                        logger.warning(f"Agent unhealthy: {agent.name}")
                
                await asyncio.sleep(self.health_check_interval)
            
            except Exception as e:
                logger.error(f"Error in health monitoring: {e}")
                await asyncio.sleep(self.health_check_interval)
    
    async def run(self) -> None:
        """
        Start the orchestration system
        
        This starts all background tasks and keeps agents working continuously.
        """
        self.running = True
        self.started_at = datetime.now(timezone.utc)
        
        logger.info("Starting Agent Orchestrator...")
        logger.info(f"Registered agents: {len(self.agents)}")
        logger.info(f"Strategy: {self.strategy.value}")
        
        # Start background tasks
        tasks = [
            asyncio.create_task(self.distribute_tasks()),
            asyncio.create_task(self.health_monitor())
        ]
        
        # Start agent execution tasks
        for agent in self.agents.values():
            tasks.append(asyncio.create_task(self.execute_agent_tasks(agent)))
        
        try:
            # Run until stopped
            await asyncio.gather(*tasks)
        except KeyboardInterrupt:
            logger.info("Shutting down orchestrator...")
            self.running = False
            
            # Cancel all tasks
            for task in tasks:
                task.cancel()
            
            await asyncio.gather(*tasks, return_exceptions=True)
    
    def get_status(self) -> Dict[str, Any]:
        """Get orchestrator status"""
        return {
            "running": self.running,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "agents": {
                "total": len(self.agents),
                "by_type": {k: len(v) for k, v in self.agents_by_type.items()},
                "available": len(self.get_available_agents())
            },
            "tasks": {
                "pending": len(self.pending_tasks),
                "active": len(self.active_tasks),
                "completed": len(self.completed_tasks),
                "failed": len(self.failed_tasks)
            },
            "metrics": self.metrics
        }
