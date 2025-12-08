"""
Crew Orchestration System

Manages crew execution, task distribution, and agent coordination.
Supports parallel execution, hierarchical workflows, and democratic decision-making.
"""

import asyncio
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
from enum import Enum

from ..schemas.crew_models import (
    CrewConfig,
    CrewTask,
    CrewMember,
    ProcessType,
    GovernanceModel,
    CrewStatus,
    CrewMetrics,
    TaskDependencyType
)
from ..governance.democratic_voting import DemocraticVotingSystem, ConsensusBuilder
from ..communication.messaging import CrewMessagingHub, Message, MessageType

logger = logging.getLogger(__name__)


class TaskStatus(str, Enum):
    """Task execution status"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"


class CrewOrchestrator:
    """
    Orchestrates crew execution and coordination
    
    Features:
    - Sequential, parallel, and hierarchical execution
    - Democratic decision-making
    - Task dependency management
    - Agent coordination
    - Performance monitoring
    """
    
    def __init__(
        self,
        crew_config: CrewConfig,
        messaging_hub: Optional[CrewMessagingHub] = None
    ):
        self.config = crew_config
        self.messaging_hub = messaging_hub
        
        # Task tracking
        self.task_status: Dict[str, TaskStatus] = {}
        self.task_results: Dict[str, Any] = {}
        self.task_errors: Dict[str, str] = {}
        
        # Agent tracking
        self.agent_assignments: Dict[str, List[str]] = {}  # agent_id -> task_ids
        self.agent_availability: Dict[str, bool] = {}
        
        # Democratic governance
        self.consensus_builder: Optional[ConsensusBuilder] = None
        if crew_config.governance_model in [
            GovernanceModel.DEMOCRATIC,
            GovernanceModel.CONSENSUS,
            GovernanceModel.MAJORITY
        ]:
            self.consensus_builder = ConsensusBuilder(
                crew_id=crew_config.id,
                members=crew_config.members
            )
        
        # Metrics
        self.metrics = CrewMetrics(crew_id=crew_config.id)
        self.start_time: Optional[datetime] = None
        self.end_time: Optional[datetime] = None
        
        # Initialize task status
        for task in crew_config.tasks:
            self.task_status[task.id] = TaskStatus.PENDING
        
        # Initialize agent availability
        for member in crew_config.members:
            self.agent_availability[member.agent_id] = True
    
    async def execute(self) -> Dict[str, Any]:
        """
        Execute the crew workflow
        
        Returns:
            Execution results including task outcomes and metrics
        """
        self.config.status = CrewStatus.ACTIVE
        self.config.started_at = datetime.utcnow()
        self.start_time = datetime.utcnow()
        
        logger.info(f"Starting crew execution: {self.config.name}")
        logger.info(f"Process type: {self.config.process_type.value}")
        logger.info(f"Governance: {self.config.governance_model.value}")
        
        try:
            if self.config.process_type == ProcessType.SEQUENTIAL:
                await self._execute_sequential()
            
            elif self.config.process_type == ProcessType.PARALLEL:
                await self._execute_parallel()
            
            elif self.config.process_type == ProcessType.HIERARCHICAL:
                await self._execute_hierarchical()
            
            elif self.config.process_type == ProcessType.DEMOCRATIC:
                await self._execute_democratic()
            
            elif self.config.process_type == ProcessType.HYBRID:
                await self._execute_hybrid()
            
            self.config.status = CrewStatus.COMPLETED
            logger.info(f"Crew execution completed: {self.config.name}")
        
        except Exception as e:
            self.config.status = CrewStatus.FAILED
            logger.error(f"Crew execution failed: {e}")
            raise
        
        finally:
            self.config.completed_at = datetime.utcnow()
            self.end_time = datetime.utcnow()
            self._update_metrics()
        
        return self._get_results()
    
    async def _execute_sequential(self) -> None:
        """Execute tasks sequentially"""
        logger.info("Executing tasks sequentially")
        
        for task in self.config.tasks:
            if await self._can_execute_task(task):
                await self._execute_task(task)
    
    async def _execute_parallel(self) -> None:
        """Execute tasks in parallel"""
        logger.info("Executing tasks in parallel")
        
        # Group tasks by dependency level
        task_groups = self._group_tasks_by_dependencies()
        
        # Execute each group in parallel
        for group in task_groups:
            tasks = [self._execute_task(task) for task in group]
            await asyncio.gather(*tasks, return_exceptions=True)
    
    async def _execute_hierarchical(self) -> None:
        """Execute with hierarchical management"""
        logger.info("Executing with hierarchical management")
        
        # Manager coordinates task distribution
        manager_id = self.config.manager_id
        
        if not manager_id:
            logger.warning("No manager specified, falling back to sequential")
            await self._execute_sequential()
            return
        
        # Manager assigns tasks to agents
        for task in self.config.tasks:
            if await self._can_execute_task(task):
                # Manager decides assignment
                await self._manager_assign_task(task, manager_id)
                await self._execute_task(task)
    
    async def _execute_democratic(self) -> None:
        """Execute with democratic decision-making"""
        logger.info("Executing with democratic decision-making")
        
        for task in self.config.tasks:
            if await self._can_execute_task(task):
                # Requires vote for major decisions
                if task.requires_vote:
                    vote_passed = await self._conduct_vote(task)
                    if not vote_passed:
                        self.task_status[task.id] = TaskStatus.SKIPPED
                        logger.info(f"Task skipped by vote: {task.name}")
                        continue
                
                await self._execute_task(task)
    
    async def _execute_hybrid(self) -> None:
        """Execute with hybrid governance"""
        logger.info("Executing with hybrid governance")
        
        # Combine hierarchical coordination with democratic input
        manager_id = self.config.manager_id
        
        for task in self.config.tasks:
            if await self._can_execute_task(task):
                # Democratic vote on approach
                if task.requires_vote:
                    vote_passed = await self._conduct_vote(task)
                    if not vote_passed:
                        self.task_status[task.id] = TaskStatus.SKIPPED
                        continue
                
                # Manager coordinates execution
                if manager_id:
                    await self._manager_assign_task(task, manager_id)
                
                await self._execute_task(task)
    
    async def _execute_task(self, task: CrewTask) -> None:
        """
        Execute a single task
        
        Args:
            task: Task to execute
        """
        logger.info(f"Executing task: {task.name}")
        
        self.task_status[task.id] = TaskStatus.RUNNING
        task_start = datetime.utcnow()
        
        try:
            # Assign agents
            agents = self._assign_agents_to_task(task)
            
            if not agents:
                raise Exception("No available agents for task")
            
            # Simulate task execution (would call actual agent execution)
            await asyncio.sleep(0.1)
            
            # Placeholder result
            result = {
                "task_id": task.id,
                "task_name": task.name,
                "assigned_agents": [a.agent_name for a in agents],
                "status": "completed",
                "timestamp": datetime.utcnow().isoformat()
            }
            
            self.task_status[task.id] = TaskStatus.COMPLETED
            self.task_results[task.id] = result
            
            task_duration = (datetime.utcnow() - task_start).total_seconds()
            self.metrics.tasks_completed += 1
            
            # Update average duration
            total_tasks = self.metrics.tasks_completed + self.metrics.tasks_failed
            if total_tasks > 0:
                self.metrics.average_task_duration = (
                    (self.metrics.average_task_duration * (total_tasks - 1) + task_duration)
                    / total_tasks
                )
            
            logger.info(f"Task completed: {task.name}")
            
            # Notify via messaging
            if self.messaging_hub:
                for agent in agents:
                    message = Message(
                        message_type=MessageType.TASK_RESPONSE,
                        sender_id=self.config.id,
                        sender_name=self.config.name,
                        crew_id=self.config.id,
                        receiver_id=agent.agent_id,
                        content=result
                    )
                    self.messaging_hub.send_to_agent(message, agent.agent_id)
        
        except Exception as e:
            self.task_status[task.id] = TaskStatus.FAILED
            self.task_errors[task.id] = str(e)
            self.metrics.tasks_failed += 1
            
            logger.error(f"Task failed: {task.name} - {e}")
            
            # Retry logic
            if task.retry_on_failure and task.max_retries > 0:
                logger.info(f"Retrying task: {task.name}")
                # Would implement retry logic here
    
    async def _can_execute_task(self, task: CrewTask) -> bool:
        """Check if task dependencies are met"""
        if not task.dependencies:
            return True
        
        for dep_id in task.dependencies:
            if self.task_status.get(dep_id) != TaskStatus.COMPLETED:
                return False
        
        return True
    
    def _assign_agents_to_task(self, task: CrewTask) -> List[CrewMember]:
        """Assign agents to a task"""
        assigned = []
        
        # Use pre-assigned agents
        if task.assigned_agent_ids:
            for agent_id in task.assigned_agent_ids:
                member = next(
                    (m for m in self.config.members if m.agent_id == agent_id),
                    None
                )
                if member and self.agent_availability.get(agent_id, False):
                    assigned.append(member)
        
        # Assign by role
        elif task.assigned_agent_roles:
            for role in task.assigned_agent_roles:
                member = next(
                    (m for m in self.config.members 
                     if m.role.value == role and self.agent_availability.get(m.agent_id, False)),
                    None
                )
                if member:
                    assigned.append(member)
        
        # Auto-assign available agents
        else:
            for member in self.config.members:
                if self.agent_availability.get(member.agent_id, False):
                    assigned.append(member)
                    break
        
        return assigned
    
    async def _manager_assign_task(self, task: CrewTask, manager_id: str) -> None:
        """Manager assigns task to agents"""
        logger.info(f"Manager {manager_id} assigning task: {task.name}")
        # Implementation would involve manager decision logic
        pass
    
    async def _conduct_vote(self, task: CrewTask) -> bool:
        """
        Conduct democratic vote on task
        
        Returns:
            True if vote passed
        """
        if not self.consensus_builder or not task.voting_strategy:
            return True
        
        # Create proposal
        proposal = self.consensus_builder.create_proposal(
            proposer_id=self.config.id,
            title=f"Execute task: {task.name}",
            description=task.description,
            proposal_type="task_execution"
        )
        
        # Start voting
        voting_session = self.consensus_builder.start_voting(
            proposal_id=proposal.id,
            strategy=task.voting_strategy
        )
        
        # Simulate votes from agents (would be actual agent votes)
        voting_system = DemocraticVotingSystem(voting_session, self.config.members)
        
        for member in self.config.members:
            if member.can_vote:
                # Simulate vote (would request actual vote from agent)
                vote = True  # Placeholder
                voting_system.cast_vote(member.agent_id, vote)
        
        self.metrics.votes_conducted += 1
        
        if voting_session.passed:
            self.metrics.consensus_reached += 1
        
        logger.info(
            f"Vote on '{task.name}': {'PASSED' if voting_session.passed else 'FAILED'}"
        )
        
        return voting_session.passed or False
    
    def _group_tasks_by_dependencies(self) -> List[List[CrewTask]]:
        """Group tasks by dependency levels for parallel execution"""
        groups: List[List[CrewTask]] = []
        remaining_tasks = self.config.tasks.copy()
        
        while remaining_tasks:
            # Find tasks with no dependencies on remaining tasks
            current_group = []
            
            for task in remaining_tasks[:]:
                deps_met = all(
                    dep_id not in [t.id for t in remaining_tasks]
                    for dep_id in task.dependencies
                )
                
                if deps_met:
                    current_group.append(task)
                    remaining_tasks.remove(task)
            
            if current_group:
                groups.append(current_group)
            else:
                # Circular dependency, break
                logger.warning("Circular dependency detected")
                break
        
        return groups
    
    def _update_metrics(self) -> None:
        """Update crew metrics"""
        if self.start_time and self.end_time:
            self.metrics.total_runtime_seconds = (
                self.end_time - self.start_time
            ).total_seconds()
        
        total_tasks = self.metrics.tasks_completed + self.metrics.tasks_failed
        if total_tasks > 0:
            self.metrics.success_rate = self.metrics.tasks_completed / total_tasks
        
        # Calculate participation rates
        for member in self.config.members:
            task_count = len(
                [t for t in self.config.tasks if member.agent_id in t.assigned_agent_ids]
            )
            self.metrics.member_participation_rate[member.agent_id] = (
                task_count / len(self.config.tasks) if self.config.tasks else 0
            )
        
        self.metrics.last_updated = datetime.utcnow()
    
    def _get_results(self) -> Dict[str, Any]:
        """Get execution results"""
        return {
            "crew_id": self.config.id,
            "crew_name": self.config.name,
            "status": self.config.status.value,
            "started_at": self.config.started_at.isoformat() if self.config.started_at else None,
            "completed_at": self.config.completed_at.isoformat() if self.config.completed_at else None,
            "tasks": {
                "total": len(self.config.tasks),
                "completed": self.metrics.tasks_completed,
                "failed": self.metrics.tasks_failed,
                "status": {task_id: status.value for task_id, status in self.task_status.items()}
            },
            "task_results": self.task_results,
            "task_errors": self.task_errors,
            "metrics": self.metrics.model_dump(),
            "governance": {
                "model": self.config.governance_model.value,
                "votes_conducted": self.metrics.votes_conducted,
                "consensus_reached": self.metrics.consensus_reached
            }
        }
    
    def get_status(self) -> Dict[str, Any]:
        """Get current crew status"""
        return {
            "crew_id": self.config.id,
            "name": self.config.name,
            "status": self.config.status.value,
            "process_type": self.config.process_type.value,
            "governance": self.config.governance_model.value,
            "members": len(self.config.members),
            "tasks": {
                "total": len(self.config.tasks),
                "completed": sum(1 for s in self.task_status.values() if s == TaskStatus.COMPLETED),
                "running": sum(1 for s in self.task_status.values() if s == TaskStatus.RUNNING),
                "failed": sum(1 for s in self.task_status.values() if s == TaskStatus.FAILED),
                "pending": sum(1 for s in self.task_status.values() if s == TaskStatus.PENDING)
            }
        }
