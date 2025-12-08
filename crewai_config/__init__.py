"""
CrewAI Configuration System

Multi-agent crew configuration and orchestration for parallel execution,
democratic decision-making, and collaborative problem-solving.

Features:
- Parallel crew execution
- Democratic voting and consensus
- Hierarchical and peer-to-peer governance
- Inter-agent communication (RabbitMQ, Redis)
- Multi-crew swarms
- Task orchestration and dependencies
"""

from .schemas.crew_models import (
    CrewConfig,
    CrewTask,
    CrewMember,
    ProcessType,
    GovernanceModel,
    VotingStrategy,
    ConflictResolution,
    CrewRole,
    DemocraticProposal,
    VotingSession,
    VoteRecord,
    SwarmConfig,
    CrewCommunication,
    CrewMetrics
)

from .governance.democratic_voting import (
    DemocraticVotingSystem,
    ConsensusBuilder
)

from .communication.messaging import (
    Message,
    MessageType,
    RabbitMQMessenger,
    RedisMessenger,
    CrewMessagingHub
)

from .crews.crew_orchestrator import (
    CrewOrchestrator
)

__version__ = "1.0.0"

__all__ = [
    # Models
    "CrewConfig",
    "CrewTask",
    "CrewMember",
    "ProcessType",
    "GovernanceModel",
    "VotingStrategy",
    "ConflictResolution",
    "CrewRole",
    "DemocraticProposal",
    "VotingSession",
    "VoteRecord",
    "SwarmConfig",
    "CrewCommunication",
    "CrewMetrics",
    
    # Governance
    "DemocraticVotingSystem",
    "ConsensusBuilder",
    
    # Communication
    "Message",
    "MessageType",
    "RabbitMQMessenger",
    "RedisMessenger",
    "CrewMessagingHub",
    
    # Orchestration
    "CrewOrchestrator",
]
