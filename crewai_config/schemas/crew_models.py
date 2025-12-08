"""
CrewAI Configuration Models

Pydantic models for defining crews, democratic voting, and multi-agent collaboration.
Based on research from CrewAI, CodeSim, MapCoder, and swarm intelligence principles.
"""

from enum import Enum
from typing import Optional, List, Dict, Any, Union
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict
import uuid


class ProcessType(str, Enum):
    """Crew execution process types"""
    SEQUENTIAL = "sequential"
    PARALLEL = "parallel"
    HIERARCHICAL = "hierarchical"
    DEMOCRATIC = "democratic"
    HYBRID = "hybrid"


class GovernanceModel(str, Enum):
    """Crew governance models"""
    HIERARCHICAL = "hierarchical"  # Manager-led
    DEMOCRATIC = "democratic"  # Peer voting
    CONSENSUS = "consensus"  # Unanimous agreement
    MAJORITY = "majority"  # Majority voting
    WEIGHTED = "weighted"  # Weighted by expertise
    DELEGATED = "delegated"  # Delegated authority


class VotingStrategy(str, Enum):
    """Voting strategies for democratic decision-making"""
    SIMPLE_MAJORITY = "simple_majority"  # > 50%
    SUPERMAJORITY = "supermajority"  # >= 66%
    UNANIMOUS = "unanimous"  # 100%
    WEIGHTED_VOTE = "weighted_vote"  # Based on expertise
    RANKED_CHOICE = "ranked_choice"  # Ranked voting
    APPROVAL = "approval"  # Approval voting


class ConflictResolution(str, Enum):
    """Conflict resolution strategies"""
    MANAGER_DECIDES = "manager_decides"
    REVOTE = "revote"
    ESCALATE = "escalate"
    COMPROMISE = "compromise"
    RANDOM = "random"
    EXPERT_DECIDES = "expert_decides"


class CrewRole(str, Enum):
    """Roles within a crew"""
    MANAGER = "manager"
    SPECIALIST = "specialist"
    REVIEWER = "reviewer"
    COORDINATOR = "coordinator"
    EXECUTOR = "executor"
    OBSERVER = "observer"


class TaskDependencyType(str, Enum):
    """Types of task dependencies"""
    SEQUENTIAL = "sequential"  # Must complete before next
    PARALLEL = "parallel"  # Can run concurrently
    CONDITIONAL = "conditional"  # Based on outcome
    OPTIONAL = "optional"  # Not required


class CrewStatus(str, Enum):
    """Crew operational status"""
    IDLE = "idle"
    ACTIVE = "active"
    PAUSED = "paused"
    COMPLETED = "completed"
    FAILED = "failed"
    VOTING = "voting"


class VoteRecord(BaseModel):
    """Record of a single vote"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    voter_id: str = Field(..., description="Agent ID who voted")
    voter_name: str = Field(..., description="Agent name")
    vote: Union[bool, int, str] = Field(..., description="The vote value")
    weight: float = Field(default=1.0, description="Vote weight based on expertise")
    reasoning: Optional[str] = Field(None, description="Reasoning behind the vote")
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class VotingSession(BaseModel):
    """A democratic voting session"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    proposal_id: str = Field(..., description="What is being voted on")
    proposal_description: str = Field(..., description="Description of proposal")
    strategy: VotingStrategy = Field(default=VotingStrategy.SIMPLE_MAJORITY)
    votes: List[VoteRecord] = Field(default_factory=list)
    required_votes: Optional[int] = Field(None, description="Required number of votes")
    threshold: float = Field(default=0.5, description="Threshold for passing (0.0-1.0)")
    started_at: datetime = Field(default_factory=datetime.utcnow)
    completed_at: Optional[datetime] = None
    passed: Optional[bool] = None
    result: Optional[Dict[str, Any]] = None


class CrewTask(BaseModel):
    """Task within a crew workflow"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str = Field(..., description="Task name")
    description: str = Field(..., description="Task description")
    assigned_agent_ids: List[str] = Field(default_factory=list)
    assigned_agent_roles: List[str] = Field(default_factory=list)
    dependencies: List[str] = Field(default_factory=list, description="Task IDs this depends on")
    dependency_type: TaskDependencyType = Field(default=TaskDependencyType.SEQUENTIAL)
    requires_vote: bool = Field(default=False, description="Requires democratic vote")
    voting_strategy: Optional[VotingStrategy] = None
    expected_output: Optional[str] = Field(None, description="Expected output format")
    tools: List[str] = Field(default_factory=list, description="Required tools")
    timeout_seconds: int = Field(default=300)
    retry_on_failure: bool = Field(default=True)
    max_retries: int = Field(default=3)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class CrewMember(BaseModel):
    """Member of a crew"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    agent_id: str = Field(..., description="Reference to agent configuration")
    agent_name: str = Field(..., description="Agent name")
    role: CrewRole = Field(default=CrewRole.SPECIALIST)
    expertise_weight: float = Field(default=1.0, ge=0.0, le=10.0)
    can_vote: bool = Field(default=True)
    can_delegate: bool = Field(default=False)
    assigned_tasks: List[str] = Field(default_factory=list)
    capabilities: List[str] = Field(default_factory=list)


class CrewConfig(BaseModel):
    """Configuration for a crew of agents"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    # Identity
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str = Field(..., description="Crew name")
    description: str = Field(..., description="Crew purpose and capabilities")
    version: str = Field(default="1.0.0")
    
    # Governance
    process_type: ProcessType = Field(default=ProcessType.SEQUENTIAL)
    governance_model: GovernanceModel = Field(default=GovernanceModel.HIERARCHICAL)
    voting_strategy: Optional[VotingStrategy] = None
    conflict_resolution: ConflictResolution = Field(default=ConflictResolution.MANAGER_DECIDES)
    
    # Members
    members: List[CrewMember] = Field(default_factory=list)
    manager_id: Optional[str] = Field(None, description="Manager agent ID")
    
    # Tasks and Workflow
    tasks: List[CrewTask] = Field(default_factory=list)
    parallel_execution: bool = Field(default=False)
    max_concurrent_tasks: int = Field(default=5, gt=0)
    
    # Communication
    communication_protocol: str = Field(default="rabbitmq")
    message_queue: Optional[str] = Field(None, description="Queue name for crew")
    broadcast_channel: Optional[str] = Field(None, description="Channel for broadcasts")
    
    # Memory and State
    shared_memory: bool = Field(default=True, description="Shared memory across agents")
    memory_isolation: bool = Field(default=False, description="Isolate agent memories")
    state_persistence: bool = Field(default=True)
    
    # Execution Settings
    timeout_seconds: int = Field(default=3600, gt=0)
    retry_failed_tasks: bool = Field(default=True)
    auto_retry_count: int = Field(default=3, ge=0)
    
    # Monitoring
    verbose: bool = Field(default=True)
    log_level: str = Field(default="INFO")
    metrics_enabled: bool = Field(default=True)
    
    # Status
    status: CrewStatus = Field(default=CrewStatus.IDLE)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    
    # Metadata
    tags: List[str] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class CrewMetrics(BaseModel):
    """Performance metrics for a crew"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    crew_id: str
    tasks_completed: int = Field(default=0)
    tasks_failed: int = Field(default=0)
    votes_conducted: int = Field(default=0)
    consensus_reached: int = Field(default=0)
    conflicts_resolved: int = Field(default=0)
    average_task_duration: float = Field(default=0.0)
    success_rate: float = Field(default=1.0)
    member_participation_rate: Dict[str, float] = Field(default_factory=dict)
    total_runtime_seconds: float = Field(default=0.0)
    last_updated: datetime = Field(default_factory=datetime.utcnow)


class DemocraticProposal(BaseModel):
    """A proposal for democratic decision-making"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    crew_id: str
    proposer_id: str
    proposer_name: str
    title: str = Field(..., description="Proposal title")
    description: str = Field(..., description="Detailed proposal")
    proposal_type: str = Field(..., description="Type: approach, tool, solution, etc.")
    options: List[str] = Field(default_factory=list, description="Options to vote on")
    voting_session: Optional[VotingSession] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    status: str = Field(default="pending")  # pending, voting, accepted, rejected
    result: Optional[Dict[str, Any]] = None


class CrewCommunication(BaseModel):
    """Communication settings for inter-crew and intra-crew messaging"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    crew_id: str
    
    # RabbitMQ Configuration
    rabbitmq_enabled: bool = Field(default=True)
    rabbitmq_exchange: str = Field(default="crew_exchange")
    rabbitmq_queue: Optional[str] = None
    rabbitmq_routing_key: Optional[str] = None
    
    # Redis Pub/Sub Configuration
    redis_enabled: bool = Field(default=True)
    redis_channel: Optional[str] = None
    
    # WebSocket Configuration
    websocket_enabled: bool = Field(default=False)
    websocket_url: Optional[str] = None
    
    # Inter-Crew Communication
    connected_crews: List[str] = Field(default_factory=list, description="Other crew IDs")
    message_routing: Dict[str, str] = Field(default_factory=dict, description="Routing rules")
    
    # Message Settings
    message_ttl_seconds: int = Field(default=3600)
    max_message_size: int = Field(default=1048576)  # 1MB
    compression_enabled: bool = Field(default=True)


class SwarmConfig(BaseModel):
    """Configuration for a swarm of multiple crews"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str = Field(..., description="Swarm name")
    description: str = Field(..., description="Swarm purpose")
    
    # Crews in the swarm
    crews: List[str] = Field(default_factory=list, description="Crew IDs")
    crew_configs: Dict[str, CrewConfig] = Field(default_factory=dict)
    
    # Swarm Governance
    governance_model: GovernanceModel = Field(default=GovernanceModel.DEMOCRATIC)
    inter_crew_voting: bool = Field(default=True)
    
    # Coordination
    coordinator_crew_id: Optional[str] = None
    task_distribution_strategy: str = Field(default="load_balanced")
    
    # Status
    status: str = Field(default="idle")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Metadata
    metadata: Dict[str, Any] = Field(default_factory=dict)
