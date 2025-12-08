"""
AI Agent Crew System

This module implements organized crews of AI agents with defined roles,
hierarchies, and workflows for structured problem solving.

Crews differ from swarms:
- Swarms: Self-organizing, emergent behavior, democratic
- Crews: Structured roles, hierarchical, coordinated workflows

Based on CrewAI and similar frameworks for organized multi-agent teams.
"""

import asyncio
import logging
from enum import Enum
from typing import List, Dict, Any, Optional, Callable
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict
import uuid

from .base import (
    BaseAgent,
    Task,
    TaskStatus,
    TaskPriority,
    AgentType,
    AgentStatus
)
from .voting import (
    DemocraticVoter,
    VotingStrategy,
    Vote,
    VoteResult
)

logger = logging.getLogger(__name__)


class CrewRole(str, Enum):
    """Roles within a crew"""
    LEADER = "leader"  # Leads the crew, makes final decisions
    SPECIALIST = "specialist"  # Domain expert
    COORDINATOR = "coordinator"  # Coordinates between members
    EXECUTOR = "executor"  # Executes tasks
    REVIEWER = "reviewer"  # Reviews and validates work
    ADVISOR = "advisor"  # Provides guidance and recommendations


class CrewProcess(str, Enum):
    """Crew workflow processes"""
    SEQUENTIAL = "sequential"  # Tasks executed in order
    PARALLEL = "parallel"  # Tasks executed simultaneously
    HIERARCHICAL = "hierarchical"  # Leader delegates to subordinates
    CONSENSUS = "consensus"  # Democratic decision-making
    PIPELINE = "pipeline"  # Output of one feeds into next


class CrewState(str, Enum):
    """Crew operational states"""
    ASSEMBLING = "assembling"  # Building the crew
    READY = "ready"  # Ready to work
    WORKING = "working"  # Executing tasks
    REVIEWING = "reviewing"  # Reviewing results
    COMPLETED = "completed"  # Work completed
    PAUSED = "paused"  # Temporarily paused
    DISBANDED = "disbanded"  # Crew disbanded


class CrewConfiguration(BaseModel):
    """Configuration for an agent crew"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    crew_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str = Field(..., description="Name of the crew")
    description: str = Field(default="", description="Crew purpose and objectives")
    process: CrewProcess = Field(default=CrewProcess.SEQUENTIAL)
    
    # Role requirements
    required_roles: Dict[CrewRole, int] = Field(
        default_factory=lambda: {CrewRole.LEADER: 1, CrewRole.EXECUTOR: 1}
    )
    
    # Workflow settings
    allow_delegation: bool = Field(default=True, description="Allow task delegation")
    require_review: bool = Field(default=True, description="Require work review")
    voting_enabled: bool = Field(default=False, description="Use voting for decisions")
    voting_strategy: VotingStrategy = Field(default=VotingStrategy.MAJORITY)
    
    # Quality settings
    quality_threshold: float = Field(default=0.8, ge=0.0, le=1.0)
    max_retries: int = Field(default=3, ge=0)
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class CrewMember(BaseModel):
    """Member of a crew with assigned role"""
    agent_id: str
    agent_name: str
    agent_type: AgentType
    role: CrewRole
    capabilities: List[str] = Field(default_factory=list)
    tasks_assigned: int = Field(default=0)
    tasks_completed: int = Field(default=0)
    quality_score: float = Field(default=1.0, ge=0.0, le=1.0)
    joined_at: datetime = Field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class CrewTask(BaseModel):
    """Task within a crew workflow"""
    task_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    title: str
    description: str
    priority: TaskPriority = Field(default=TaskPriority.MEDIUM)
    
    # Assignment
    assigned_to: Optional[str] = None  # Agent ID
    assigned_role: Optional[CrewRole] = None
    delegated_from: Optional[str] = None  # Task ID if delegated
    
    # Dependencies
    depends_on: List[str] = Field(default_factory=list, description="Task IDs this depends on")
    blocks: List[str] = Field(default_factory=list, description="Task IDs blocked by this")
    
    # Execution
    status: TaskStatus = Field(default=TaskStatus.PENDING)
    result: Optional[Any] = None
    quality_score: Optional[float] = None
    retry_count: int = Field(default=0)
    
    # Review
    requires_review: bool = Field(default=True)
    reviewed_by: Optional[str] = None
    review_approved: Optional[bool] = None
    review_feedback: Optional[str] = None
    
    # Timing
    created_at: datetime = Field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    
    metadata: Dict[str, Any] = Field(default_factory=dict)


class AgentCrew:
    """
    Organized crew of AI agents with defined roles and workflows
    
    A crew provides structured coordination with:
    - Defined roles (leader, specialist, executor, reviewer, etc.)
    - Workflow processes (sequential, parallel, hierarchical, etc.)
    - Task delegation and dependencies
    - Quality review and validation
    - Optional democratic decision-making
    
    Example:
        ```python
        # Create crew configuration
        config = CrewConfiguration(
            name="Full-Stack Development Crew",
            process=CrewProcess.SEQUENTIAL,
            required_roles={
                CrewRole.LEADER: 1,
                CrewRole.SPECIALIST: 2,
                CrewRole.REVIEWER: 1
            }
        )
        
        # Create crew
        crew = AgentCrew(config)
        
        # Add crew members
        crew.add_member(lead_developer, CrewRole.LEADER)
        crew.add_member(backend_dev, CrewRole.SPECIALIST)
        crew.add_member(frontend_dev, CrewRole.SPECIALIST)
        crew.add_member(qa_engineer, CrewRole.REVIEWER)
        
        # Create workflow
        tasks = [
            CrewTask(title="Design API", description="Design REST API"),
            CrewTask(title="Implement Backend", description="Build API"),
            CrewTask(title="Create Frontend", description="Build UI"),
            CrewTask(title="Test Integration", description="E2E tests")
        ]
        
        # Execute workflow
        result = await crew.execute_workflow(tasks)
        ```
    """
    
    def __init__(self, config: CrewConfiguration):
        """
        Initialize agent crew
        
        Args:
            config: Crew configuration
        """
        self.config = config
        self.crew_id = config.crew_id
        self.name = config.name
        
        # Member management
        self.members: Dict[str, CrewMember] = {}
        self.members_by_role: Dict[CrewRole, List[str]] = {role: [] for role in CrewRole}
        self.agent_instances: Dict[str, BaseAgent] = {}
        
        # Task management
        self.tasks: Dict[str, CrewTask] = {}
        self.task_queue: List[str] = []
        self.active_tasks: Dict[str, str] = {}  # task_id -> agent_id
        self.completed_tasks: List[str] = []
        
        # State
        self.state = CrewState.ASSEMBLING
        self.created_at = datetime.utcnow()
        self.started_at: Optional[datetime] = None
        self.completed_at: Optional[datetime] = None
        
        # Voting system (if enabled)
        if config.voting_enabled:
            self.voter = DemocraticVoter(strategy=config.voting_strategy)
        else:
            self.voter = None
        
        # Event log
        self.event_log: List[Dict[str, Any]] = []
        
        logger.info(f"Created crew '{self.name}' ({self.crew_id})")
    
    def add_member(
        self,
        agent: BaseAgent,
        role: CrewRole,
        capabilities: Optional[List[str]] = None
    ) -> bool:
        """
        Add a member to the crew
        
        Args:
            agent: Agent instance
            role: Role in the crew
            capabilities: Optional list of specific capabilities
        
        Returns:
            True if added successfully
        """
        if agent.id in self.members:
            logger.warning(f"Agent {agent.id} already in crew")
            return False
        
        member = CrewMember(
            agent_id=agent.id,
            agent_name=agent.name,
            agent_type=agent.type,
            role=role,
            capabilities=capabilities or agent.capabilities or []
        )
        
        self.members[agent.id] = member
        self.members_by_role[role].append(agent.id)
        self.agent_instances[agent.id] = agent
        
        self._log_event("member_joined", {
            "agent_id": agent.id,
            "agent_name": agent.name,
            "role": role
        })
        
        logger.info(f"Added {agent.name} to crew '{self.name}' as {role}")
        
        # Check if crew is ready
        if self._check_crew_ready():
            self.state = CrewState.READY
            self._log_event("crew_ready", {"member_count": len(self.members)})
        
        return True
    
    def remove_member(self, agent_id: str) -> bool:
        """
        Remove a member from the crew
        
        Args:
            agent_id: ID of agent to remove
        
        Returns:
            True if removed successfully
        """
        if agent_id not in self.members:
            return False
        
        member = self.members[agent_id]
        role = member.role
        
        del self.members[agent_id]
        if agent_id in self.members_by_role[role]:
            self.members_by_role[role].remove(agent_id)
        if agent_id in self.agent_instances:
            del self.agent_instances[agent_id]
        
        self._log_event("member_left", {"agent_id": agent_id, "role": role})
        
        # Check if crew still ready
        if not self._check_crew_ready() and self.state == CrewState.READY:
            self.state = CrewState.ASSEMBLING
            self._log_event("crew_not_ready", {"member_count": len(self.members)})
        
        return True
    
    def _check_crew_ready(self) -> bool:
        """Check if crew has all required roles filled"""
        for role, required_count in self.config.required_roles.items():
            if len(self.members_by_role[role]) < required_count:
                return False
        return True
    
    def get_leader(self) -> Optional[CrewMember]:
        """Get the crew leader"""
        leaders = self.members_by_role[CrewRole.LEADER]
        if leaders:
            return self.members[leaders[0]]
        return None
    
    def get_members_by_role(self, role: CrewRole) -> List[CrewMember]:
        """Get all members with a specific role"""
        return [self.members[aid] for aid in self.members_by_role[role]]
    
    def assign_task(
        self,
        task: CrewTask,
        agent_id: Optional[str] = None,
        role: Optional[CrewRole] = None
    ) -> bool:
        """
        Assign a task to an agent or role
        
        Args:
            task: Task to assign
            agent_id: Specific agent ID (optional)
            role: Role to assign to (optional)
        
        Returns:
            True if assigned successfully
        """
        if agent_id and agent_id not in self.members:
            logger.warning(f"Agent {agent_id} not in crew")
            return False
        
        if not agent_id and role:
            # Find available agent with role
            candidates = self.members_by_role.get(role, [])
            available = [aid for aid in candidates if aid not in self.active_tasks.values()]
            if not available:
                logger.warning(f"No available agents with role {role}")
                return False
            agent_id = available[0]
        
        if not agent_id:
            logger.warning("No agent specified for task assignment")
            return False
        
        task.assigned_to = agent_id
        task.assigned_role = self.members[agent_id].role
        self.tasks[task.task_id] = task
        self.task_queue.append(task.task_id)
        
        self.members[agent_id].tasks_assigned += 1
        
        self._log_event("task_assigned", {
            "task_id": task.task_id,
            "agent_id": agent_id,
            "role": self.members[agent_id].role
        })
        
        return True
    
    async def execute_workflow(self, tasks: List[CrewTask]) -> Dict[str, Any]:
        """
        Execute a workflow of tasks
        
        Args:
            tasks: List of tasks in workflow
        
        Returns:
            Results of workflow execution
        """
        if self.state != CrewState.READY:
            return {
                "success": False,
                "error": f"Crew not ready (state: {self.state})",
                "crew_id": self.crew_id
            }
        
        self.state = CrewState.WORKING
        self.started_at = datetime.utcnow()
        
        # Add all tasks
        for task in tasks:
            self.tasks[task.task_id] = task
        
        try:
            # Execute based on process type
            if self.config.process == CrewProcess.SEQUENTIAL:
                result = await self._execute_sequential(tasks)
            elif self.config.process == CrewProcess.PARALLEL:
                result = await self._execute_parallel(tasks)
            elif self.config.process == CrewProcess.HIERARCHICAL:
                result = await self._execute_hierarchical(tasks)
            elif self.config.process == CrewProcess.CONSENSUS:
                result = await self._execute_consensus(tasks)
            else:
                result = await self._execute_sequential(tasks)
            
            self.state = CrewState.COMPLETED
            self.completed_at = datetime.utcnow()
            
            return result
            
        except Exception as e:
            logger.error(f"Error executing workflow: {e}")
            self.state = CrewState.READY
            return {
                "success": False,
                "error": str(e),
                "crew_id": self.crew_id
            }
    
    async def _execute_sequential(self, tasks: List[CrewTask]) -> Dict[str, Any]:
        """Execute tasks sequentially"""
        results = []
        
        for task in tasks:
            # Auto-assign if not assigned
            if not task.assigned_to:
                self.assign_task(task, role=CrewRole.EXECUTOR)
            
            result = await self._execute_single_task(task)
            results.append(result)
            
            if not result.get("success", False):
                return {
                    "success": False,
                    "error": f"Task {task.task_id} failed",
                    "results": results,
                    "crew_id": self.crew_id
                }
        
        return {
            "success": True,
            "process": "sequential",
            "tasks_completed": len(results),
            "results": results,
            "crew_id": self.crew_id
        }
    
    async def _execute_parallel(self, tasks: List[CrewTask]) -> Dict[str, Any]:
        """Execute tasks in parallel"""
        # Auto-assign tasks
        for task in tasks:
            if not task.assigned_to:
                self.assign_task(task, role=CrewRole.EXECUTOR)
        
        # Execute all concurrently
        results = await asyncio.gather(
            *[self._execute_single_task(task) for task in tasks],
            return_exceptions=True
        )
        
        success_count = sum(1 for r in results if isinstance(r, dict) and r.get("success", False))
        
        return {
            "success": success_count == len(tasks),
            "process": "parallel",
            "tasks_completed": success_count,
            "results": results,
            "crew_id": self.crew_id
        }
    
    async def _execute_hierarchical(self, tasks: List[CrewTask]) -> Dict[str, Any]:
        """Execute with leader delegating to subordinates"""
        leader = self.get_leader()
        if not leader:
            return {
                "success": False,
                "error": "No leader assigned",
                "crew_id": self.crew_id
            }
        
        # Leader reviews and delegates tasks
        for task in tasks:
            # Delegate to specialists or executors
            if not task.assigned_to:
                # Try specialist first, then executor
                specialists = self.members_by_role[CrewRole.SPECIALIST]
                executors = self.members_by_role[CrewRole.EXECUTOR]
                candidates = specialists + executors
                
                if candidates:
                    self.assign_task(task, agent_id=candidates[0])
                    task.delegated_from = leader.agent_id
        
        # Execute delegated tasks
        return await self._execute_parallel(tasks)
    
    async def _execute_consensus(self, tasks: List[CrewTask]) -> Dict[str, Any]:
        """Execute with consensus decision-making"""
        if not self.voter:
            return {
                "success": False,
                "error": "Voting not enabled for this crew",
                "crew_id": self.crew_id
            }
        
        results = []
        
        for task in tasks:
            # Multiple agents work on task
            agents = list(self.members.keys())[:min(3, len(self.members))]
            
            # Simulate voting on solution
            votes = [
                Vote(
                    voter_id=aid,
                    choice=f"Solution from {aid}",
                    confidence=0.8
                )
                for aid in agents
            ]
            
            vote_result = self.voter.conduct_vote(votes)
            
            results.append({
                "task_id": task.task_id,
                "success": vote_result.winner is not None,
                "solution": vote_result.winner,
                "vote_result": vote_result.model_dump()
            })
        
        return {
            "success": all(r["success"] for r in results),
            "process": "consensus",
            "tasks_completed": len(results),
            "results": results,
            "crew_id": self.crew_id
        }
    
    async def _execute_single_task(self, task: CrewTask) -> Dict[str, Any]:
        """
        Execute a single task
        
        Args:
            task: Task to execute
        
        Returns:
            Task execution result
        """
        if not task.assigned_to:
            return {
                "success": False,
                "error": "Task not assigned",
                "task_id": task.task_id
            }
        
        task.status = TaskStatus.IN_PROGRESS
        task.started_at = datetime.utcnow()
        self.active_tasks[task.task_id] = task.assigned_to
        
        self._log_event("task_started", {
            "task_id": task.task_id,
            "agent_id": task.assigned_to
        })
        
        try:
            # Simulate task execution
            # In real implementation, would call agent.execute_task()
            await asyncio.sleep(0.1)  # Simulate work
            
            result = {
                "success": True,
                "solution": f"Solution for {task.title}",
                "task_id": task.task_id
            }
            
            task.result = result
            task.quality_score = 0.9
            task.status = TaskStatus.COMPLETED
            task.completed_at = datetime.utcnow()
            
            # Review if required
            if task.requires_review and self.config.require_review:
                review_result = await self._review_task(task)
                if not review_result.get("approved", True):
                    task.status = TaskStatus.FAILED
                    result["success"] = False
                    result["error"] = "Review failed"
            
            # Update member stats
            if task.assigned_to in self.members:
                self.members[task.assigned_to].tasks_completed += 1
            
            del self.active_tasks[task.task_id]
            self.completed_tasks.append(task.task_id)
            
            self._log_event("task_completed", {
                "task_id": task.task_id,
                "success": result["success"]
            })
            
            return result
            
        except Exception as e:
            logger.error(f"Error executing task {task.task_id}: {e}")
            task.status = TaskStatus.FAILED
            if task.task_id in self.active_tasks:
                del self.active_tasks[task.task_id]
            
            return {
                "success": False,
                "error": str(e),
                "task_id": task.task_id
            }
    
    async def _review_task(self, task: CrewTask) -> Dict[str, Any]:
        """
        Review a completed task
        
        Args:
            task: Task to review
        
        Returns:
            Review result
        """
        # Find a reviewer
        reviewers = self.members_by_role[CrewRole.REVIEWER]
        if not reviewers:
            # No reviewer available, auto-approve
            return {"approved": True, "feedback": "No reviewer available"}
        
        reviewer_id = reviewers[0]
        task.reviewed_by = reviewer_id
        
        # Simulate review
        # In real implementation, would have reviewer agent evaluate the work
        approved = task.quality_score and task.quality_score >= self.config.quality_threshold
        
        task.review_approved = approved
        task.review_feedback = "Quality threshold met" if approved else "Quality below threshold"
        
        self._log_event("task_reviewed", {
            "task_id": task.task_id,
            "reviewer_id": reviewer_id,
            "approved": approved
        })
        
        return {
            "approved": approved,
            "feedback": task.review_feedback,
            "reviewer_id": reviewer_id
        }
    
    def _log_event(self, event_type: str, data: Dict[str, Any]):
        """Log a crew event"""
        event = {
            "timestamp": datetime.utcnow().isoformat(),
            "crew_id": self.crew_id,
            "event_type": event_type,
            "data": data
        }
        self.event_log.append(event)
    
    def get_status(self) -> Dict[str, Any]:
        """Get current crew status"""
        return {
            "crew_id": self.crew_id,
            "name": self.name,
            "state": self.state,
            "process": self.config.process,
            "members": len(self.members),
            "tasks_total": len(self.tasks),
            "tasks_active": len(self.active_tasks),
            "tasks_completed": len(self.completed_tasks),
            "created_at": self.created_at.isoformat(),
            "is_ready": self._check_crew_ready()
        }
    
    def disband(self):
        """Disband the crew"""
        self.state = CrewState.DISBANDED
        self._log_event("crew_disbanded", {
            "final_member_count": len(self.members),
            "tasks_completed": len(self.completed_tasks)
        })
        logger.info(f"Disbanded crew '{self.name}'")
