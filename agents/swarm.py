"""
AI Agent Swarm System

This module implements swarm intelligence for coordinating multiple AI agents
to solve complex problems through collective behavior and democratic decision-making.

Based on research:
- Swarm intelligence inspired by natural systems (ants, bees)
- Distributed problem solving with emergent behavior
- Democratic voting for consensus
- Self-organization and adaptive coordination
"""

import asyncio
import logging
from enum import Enum
from typing import List, Dict, Any, Optional, Callable, Set
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict
import uuid

from .base import (
    BaseAgent,
    Task,
    TaskStatus,
    TaskPriority,
    AgentType,
    AgentStatus,
    AgentMessage,
    CommunicationProtocol
)
from .voting import (
    DemocraticVoter,
    VotingStrategy,
    Vote,
    VoteResult,
    ConsensusBuilder
)

logger = logging.getLogger(__name__)


class SwarmBehavior(str, Enum):
    """Swarm coordination behaviors"""
    COLLABORATIVE = "collaborative"  # All agents work together
    COMPETITIVE = "competitive"  # Agents compete for best solution
    HIERARCHICAL = "hierarchical"  # Leader-follower structure
    DEMOCRATIC = "democratic"  # Vote on decisions
    EMERGENT = "emergent"  # Self-organizing behavior
    PARALLEL = "parallel"  # Parallel independent work


class SwarmState(str, Enum):
    """Swarm operational states"""
    FORMING = "forming"  # Assembling swarm
    ACTIVE = "active"  # Working on tasks
    COORDINATING = "coordinating"  # Coordinating between agents
    VOTING = "voting"  # Democratic decision-making
    CONVERGING = "converging"  # Reaching consensus
    COMPLETED = "completed"  # Task completed
    PAUSED = "paused"  # Temporarily paused
    DISSOLVED = "dissolved"  # Swarm disbanded


class SwarmConfiguration(BaseModel):
    """Configuration for a swarm of agents"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    swarm_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str = Field(..., description="Name of the swarm")
    description: str = Field(default="", description="Swarm purpose and goals")
    behavior: SwarmBehavior = Field(default=SwarmBehavior.DEMOCRATIC)
    voting_strategy: VotingStrategy = Field(default=VotingStrategy.MAJORITY)
    
    # Agent configuration
    min_agents: int = Field(default=3, ge=1, description="Minimum agents required")
    max_agents: int = Field(default=10, ge=1, description="Maximum agents allowed")
    required_agent_types: List[AgentType] = Field(default_factory=list)
    
    # Coordination settings
    communication_protocol: CommunicationProtocol = Field(default=CommunicationProtocol.A2A)
    consensus_threshold: float = Field(default=0.75, ge=0.0, le=1.0)
    max_iterations: int = Field(default=10, ge=1)
    convergence_timeout: int = Field(default=300, description="Timeout in seconds")
    
    # Task settings
    parallel_tasks: bool = Field(default=True, description="Allow parallel task execution")
    task_decomposition: bool = Field(default=True, description="Break complex tasks into subtasks")
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class SwarmAgent(BaseModel):
    """Agent membership in a swarm"""
    agent_id: str
    agent_type: AgentType
    role: str = Field(default="member", description="Role in swarm")
    vote_weight: float = Field(default=1.0, ge=0.0)
    specialization: List[str] = Field(default_factory=list)
    performance_score: float = Field(default=1.0, ge=0.0, le=1.0)
    tasks_completed: int = Field(default=0)
    joined_at: datetime = Field(default_factory=datetime.utcnow)


class SwarmTask(BaseModel):
    """Task assigned to a swarm"""
    task_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    parent_task_id: Optional[str] = None
    title: str
    description: str
    priority: TaskPriority = Field(default=TaskPriority.MEDIUM)
    assigned_agents: List[str] = Field(default_factory=list)
    required_votes: int = Field(default=1)
    status: TaskStatus = Field(default=TaskStatus.PENDING)
    result: Optional[Any] = None
    vote_result: Optional[VoteResult] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class AgentSwarm:
    """
    AI Agent Swarm for collaborative problem solving
    
    A swarm coordinates multiple agents to work together on complex problems
    using democratic voting and collective intelligence.
    
    Key features:
    - Dynamic agent assignment based on capabilities
    - Democratic decision-making through voting
    - Task decomposition and parallel execution
    - Self-organization and emergent behavior
    - Consensus building through iteration
    
    Example:
        ```python
        # Create swarm configuration
        config = SwarmConfiguration(
            name="Development Swarm",
            behavior=SwarmBehavior.DEMOCRATIC,
            voting_strategy=VotingStrategy.MAJORITY,
            min_agents=3,
            required_agent_types=[
                AgentType.PROGRAMMING,
                AgentType.TESTING,
                AgentType.DOCUMENTATION
            ]
        )
        
        # Create swarm
        swarm = AgentSwarm(config)
        
        # Add agents
        swarm.add_agent(python_agent)
        swarm.add_agent(test_agent)
        swarm.add_agent(doc_agent)
        
        # Assign task
        task = SwarmTask(
            title="Build REST API",
            description="Create a FastAPI REST API with tests and docs"
        )
        
        # Execute with democratic decision-making
        result = await swarm.execute_task(task)
        ```
    """
    
    def __init__(self, config: SwarmConfiguration):
        """
        Initialize agent swarm
        
        Args:
            config: Swarm configuration
        """
        self.config = config
        self.swarm_id = config.swarm_id
        self.name = config.name
        
        # Agent management
        self.agents: Dict[str, SwarmAgent] = {}
        self.agent_instances: Dict[str, BaseAgent] = {}
        
        # Task management
        self.tasks: Dict[str, SwarmTask] = {}
        self.active_tasks: Set[str] = set()
        self.completed_tasks: Set[str] = set()
        
        # State
        self.state = SwarmState.FORMING
        self.created_at = datetime.utcnow()
        self.started_at: Optional[datetime] = None
        self.completed_at: Optional[datetime] = None
        
        # Voting system
        self.voter = DemocraticVoter(
            strategy=config.voting_strategy,
            threshold=config.consensus_threshold
        )
        
        # Consensus builder for iterative improvement
        self.consensus_builder = ConsensusBuilder(
            max_rounds=config.max_iterations,
            consensus_threshold=config.consensus_threshold
        )
        
        # Communication
        self.message_queue: asyncio.Queue = asyncio.Queue()
        self.event_log: List[Dict[str, Any]] = []
        
        logger.info(f"Created swarm '{self.name}' ({self.swarm_id})")
    
    def add_agent(
        self,
        agent: BaseAgent,
        role: str = "member",
        vote_weight: float = 1.0
    ) -> bool:
        """
        Add an agent to the swarm
        
        Args:
            agent: Agent instance to add
            role: Role in the swarm
            vote_weight: Voting weight for weighted voting
        
        Returns:
            True if added successfully
        """
        if len(self.agents) >= self.config.max_agents:
            logger.warning(f"Swarm '{self.name}' is full ({self.config.max_agents} agents)")
            return False
        
        if agent.id in self.agents:
            logger.warning(f"Agent {agent.id} already in swarm")
            return False
        
        swarm_agent = SwarmAgent(
            agent_id=agent.id,
            agent_type=agent.type,
            role=role,
            vote_weight=vote_weight,
            specialization=agent.capabilities or []
        )
        
        self.agents[agent.id] = swarm_agent
        self.agent_instances[agent.id] = agent
        
        self._log_event("agent_joined", {
            "agent_id": agent.id,
            "agent_type": agent.type,
            "role": role
        })
        
        logger.info(f"Added agent {agent.name} to swarm '{self.name}'")
        
        # Check if we can activate
        if len(self.agents) >= self.config.min_agents and self.state == SwarmState.FORMING:
            self.state = SwarmState.ACTIVE
            self._log_event("swarm_activated", {"agent_count": len(self.agents)})
        
        return True
    
    def remove_agent(self, agent_id: str) -> bool:
        """
        Remove an agent from the swarm
        
        Args:
            agent_id: ID of agent to remove
        
        Returns:
            True if removed successfully
        """
        if agent_id not in self.agents:
            return False
        
        del self.agents[agent_id]
        if agent_id in self.agent_instances:
            del self.agent_instances[agent_id]
        
        self._log_event("agent_left", {"agent_id": agent_id})
        
        # Check if we need to deactivate
        if len(self.agents) < self.config.min_agents and self.state == SwarmState.ACTIVE:
            self.state = SwarmState.FORMING
            self._log_event("swarm_deactivated", {"agent_count": len(self.agents)})
        
        return True
    
    def get_agent_by_type(self, agent_type: AgentType) -> List[SwarmAgent]:
        """Get all agents of a specific type"""
        return [a for a in self.agents.values() if a.agent_type == agent_type]
    
    def get_available_agents(self) -> List[SwarmAgent]:
        """Get agents that are not busy"""
        available = []
        for agent_id, swarm_agent in self.agents.items():
            if agent_id in self.agent_instances:
                agent = self.agent_instances[agent_id]
                if agent.status in [AgentStatus.IDLE, AgentStatus.WORKING]:
                    available.append(swarm_agent)
        return available
    
    async def execute_task(self, task: SwarmTask) -> Dict[str, Any]:
        """
        Execute a task using the swarm
        
        Args:
            task: Task to execute
        
        Returns:
            Result including solution and voting information
        """
        if self.state not in [SwarmState.ACTIVE, SwarmState.COORDINATING]:
            return {
                "success": False,
                "error": f"Swarm not active (state: {self.state})",
                "task_id": task.task_id
            }
        
        self.tasks[task.task_id] = task
        self.active_tasks.add(task.task_id)
        task.status = TaskStatus.IN_PROGRESS
        task.started_at = datetime.utcnow()
        
        self._log_event("task_started", {
            "task_id": task.task_id,
            "title": task.title
        })
        
        try:
            # Select agents for task
            assigned_agents = await self._assign_agents_to_task(task)
            if not assigned_agents:
                return {
                    "success": False,
                    "error": "No suitable agents available",
                    "task_id": task.task_id
                }
            
            task.assigned_agents = [a.agent_id for a in assigned_agents]
            
            # Execute based on swarm behavior
            if self.config.behavior == SwarmBehavior.DEMOCRATIC:
                result = await self._execute_democratic(task, assigned_agents)
            elif self.config.behavior == SwarmBehavior.COLLABORATIVE:
                result = await self._execute_collaborative(task, assigned_agents)
            elif self.config.behavior == SwarmBehavior.PARALLEL:
                result = await self._execute_parallel(task, assigned_agents)
            else:
                result = await self._execute_democratic(task, assigned_agents)
            
            task.status = TaskStatus.COMPLETED
            task.completed_at = datetime.utcnow()
            task.result = result
            
            self.active_tasks.discard(task.task_id)
            self.completed_tasks.add(task.task_id)
            
            self._log_event("task_completed", {
                "task_id": task.task_id,
                "success": result.get("success", False)
            })
            
            return result
            
        except Exception as e:
            logger.error(f"Error executing task {task.task_id}: {e}")
            task.status = TaskStatus.FAILED
            self.active_tasks.discard(task.task_id)
            
            return {
                "success": False,
                "error": str(e),
                "task_id": task.task_id
            }
    
    async def _assign_agents_to_task(self, task: SwarmTask) -> List[SwarmAgent]:
        """
        Assign appropriate agents to a task
        
        Args:
            task: Task to assign
        
        Returns:
            List of assigned agents
        """
        available = self.get_available_agents()
        
        if not available:
            return []
        
        # For now, use all available agents
        # In a real implementation, this would use capability matching
        return available[:self.config.max_agents]
    
    async def _execute_democratic(
        self,
        task: SwarmTask,
        agents: List[SwarmAgent]
    ) -> Dict[str, Any]:
        """
        Execute task with democratic voting
        
        Each agent proposes a solution, then agents vote on the best one.
        
        Args:
            task: Task to execute
            agents: Assigned agents
        
        Returns:
            Result with winning solution
        """
        self.state = SwarmState.COORDINATING
        
        # Simulate each agent proposing a solution
        # In real implementation, would call agent.execute_task()
        proposals = []
        for agent in agents:
            proposal = {
                "agent_id": agent.agent_id,
                "solution": f"Solution from {agent.agent_id}",
                "confidence": 0.8
            }
            proposals.append(proposal)
        
        # Conduct voting
        self.state = SwarmState.VOTING
        votes = [
            Vote(
                voter_id=p["agent_id"],
                choice=p["solution"],
                confidence=p["confidence"]
            )
            for p in proposals
        ]
        
        vote_result = self.voter.conduct_vote(votes, total_agents=len(agents))
        task.vote_result = vote_result
        
        self.state = SwarmState.CONVERGING
        
        return {
            "success": vote_result.winner is not None,
            "solution": vote_result.winner,
            "vote_result": vote_result.model_dump(),
            "proposals": len(proposals),
            "consensus": vote_result.is_consensus,
            "task_id": task.task_id
        }
    
    async def _execute_collaborative(
        self,
        task: SwarmTask,
        agents: List[SwarmAgent]
    ) -> Dict[str, Any]:
        """
        Execute task with collaborative approach
        
        Agents work together to build a solution iteratively.
        
        Args:
            task: Task to execute
            agents: Assigned agents
        
        Returns:
            Collaborative result
        """
        self.state = SwarmState.COORDINATING
        
        # Simulate collaborative work
        # In real implementation, agents would iterate and improve together
        solution = f"Collaborative solution from {len(agents)} agents"
        
        return {
            "success": True,
            "solution": solution,
            "agents_participated": len(agents),
            "approach": "collaborative",
            "task_id": task.task_id
        }
    
    async def _execute_parallel(
        self,
        task: SwarmTask,
        agents: List[SwarmAgent]
    ) -> Dict[str, Any]:
        """
        Execute task with parallel approach
        
        Each agent works independently, results are combined.
        
        Args:
            task: Task to execute
            agents: Assigned agents
        
        Returns:
            Combined parallel results
        """
        self.state = SwarmState.COORDINATING
        
        # Simulate parallel execution
        results = []
        for agent in agents:
            result = f"Result from {agent.agent_id}"
            results.append(result)
        
        return {
            "success": True,
            "solution": results,
            "agents_participated": len(agents),
            "approach": "parallel",
            "task_id": task.task_id
        }
    
    def _log_event(self, event_type: str, data: Dict[str, Any]):
        """Log a swarm event"""
        event = {
            "timestamp": datetime.utcnow().isoformat(),
            "swarm_id": self.swarm_id,
            "event_type": event_type,
            "data": data
        }
        self.event_log.append(event)
    
    def get_status(self) -> Dict[str, Any]:
        """Get current swarm status"""
        return {
            "swarm_id": self.swarm_id,
            "name": self.name,
            "state": self.state,
            "behavior": self.config.behavior,
            "agents": len(self.agents),
            "active_tasks": len(self.active_tasks),
            "completed_tasks": len(self.completed_tasks),
            "created_at": self.created_at.isoformat(),
            "uptime": (datetime.utcnow() - self.created_at).total_seconds()
        }
    
    def dissolve(self):
        """Dissolve the swarm"""
        self.state = SwarmState.DISSOLVED
        self._log_event("swarm_dissolved", {
            "final_agent_count": len(self.agents),
            "tasks_completed": len(self.completed_tasks)
        })
        logger.info(f"Dissolved swarm '{self.name}'")


class SwarmCoordinator:
    """
    Coordinates multiple swarms for complex problem solving
    
    Manages multiple swarms working on different aspects of a problem,
    coordinating between them and aggregating results.
    """
    
    def __init__(self):
        """Initialize swarm coordinator"""
        self.swarms: Dict[str, AgentSwarm] = {}
        self.created_at = datetime.utcnow()
        
        logger.info("Initialized SwarmCoordinator")
    
    def create_swarm(self, config: SwarmConfiguration) -> AgentSwarm:
        """
        Create a new swarm
        
        Args:
            config: Swarm configuration
        
        Returns:
            Created swarm
        """
        swarm = AgentSwarm(config)
        self.swarms[swarm.swarm_id] = swarm
        return swarm
    
    def get_swarm(self, swarm_id: str) -> Optional[AgentSwarm]:
        """Get a swarm by ID"""
        return self.swarms.get(swarm_id)
    
    def dissolve_swarm(self, swarm_id: str) -> bool:
        """Dissolve a swarm"""
        if swarm_id in self.swarms:
            self.swarms[swarm_id].dissolve()
            del self.swarms[swarm_id]
            return True
        return False
    
    def get_all_swarms(self) -> List[Dict[str, Any]]:
        """Get status of all swarms"""
        return [swarm.get_status() for swarm in self.swarms.values()]
    
    async def execute_across_swarms(
        self,
        task: Task,
        swarm_ids: List[str]
    ) -> Dict[str, Any]:
        """
        Execute a task across multiple swarms and aggregate results
        
        Args:
            task: Task to execute
            swarm_ids: List of swarm IDs to use
        
        Returns:
            Aggregated results from all swarms
        """
        results = []
        
        for swarm_id in swarm_ids:
            swarm = self.get_swarm(swarm_id)
            if swarm:
                swarm_task = SwarmTask(
                    title=task.title,
                    description=task.description,
                    priority=task.priority
                )
                result = await swarm.execute_task(swarm_task)
                results.append({
                    "swarm_id": swarm_id,
                    "result": result
                })
        
        return {
            "task_id": task.task_id,
            "swarms_used": len(results),
            "results": results,
            "success": all(r["result"].get("success", False) for r in results)
        }
