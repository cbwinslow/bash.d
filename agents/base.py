"""
Base Agent Models and Classes

This module defines the core agent architecture using Pydantic for data validation
and type safety. All specialized agents inherit from these base classes.
"""

from enum import Enum
from typing import Optional, List, Dict, Any, Callable
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict
import uuid


class AgentStatus(str, Enum):
    """Agent operational status"""
    IDLE = "idle"
    BUSY = "busy"
    WORKING = "working"
    PAUSED = "paused"
    ERROR = "error"
    STOPPED = "stopped"
    STARTING = "starting"
    STOPPING = "stopping"


class AgentType(str, Enum):
    """Agent specialization types"""
    PROGRAMMING = "programming"
    DEVOPS = "devops"
    DOCUMENTATION = "documentation"
    TESTING = "testing"
    SECURITY = "security"
    DATA = "data"
    DESIGN = "design"
    COMMUNICATION = "communication"
    MONITORING = "monitoring"
    AUTOMATION = "automation"
    GENERAL = "general"


class CommunicationProtocol(str, Enum):
    """Agent communication protocols"""
    A2A = "a2a"  # Agent-to-Agent
    HTTP = "http"
    WEBSOCKET = "websocket"
    MCP = "mcp"  # Model Context Protocol
    RABBITMQ = "rabbitmq"
    REDIS_PUBSUB = "redis_pubsub"


class TaskPriority(str, Enum):
    """Task priority levels"""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    BACKGROUND = "background"


class TaskStatus(str, Enum):
    """Task execution status"""
    PENDING = "pending"
    QUEUED = "queued"
    ASSIGNED = "assigned"
    IN_PROGRESS = "in_progress"
    PAUSED = "paused"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    TIMEOUT = "timeout"


class AgentCapability(BaseModel):
    """Defines a specific capability of an agent"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    name: str = Field(..., description="Name of the capability")
    description: str = Field(..., description="Detailed description of what this capability does")
    parameters: Dict[str, Any] = Field(default_factory=dict, description="Required parameters")
    required: bool = Field(default=True, description="Whether this capability is required for the agent")


class AgentMessage(BaseModel):
    """Message structure for agent communication"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Unique message ID")
    sender_id: str = Field(..., description="ID of the sending agent")
    receiver_id: Optional[str] = Field(None, description="ID of the receiving agent (None for broadcast)")
    protocol: CommunicationProtocol = Field(default=CommunicationProtocol.A2A)
    content: Dict[str, Any] = Field(..., description="Message payload")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    priority: TaskPriority = Field(default=TaskPriority.MEDIUM)
    correlation_id: Optional[str] = Field(None, description="For request-response correlation")


class Task(BaseModel):
    """Represents a task to be executed by an agent"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Unique task ID")
    title: str = Field(..., description="Task title")
    description: str = Field(..., description="Detailed task description")
    agent_type: Optional[AgentType] = Field(None, description="Preferred agent type for this task")
    assigned_agent_id: Optional[str] = Field(None, description="ID of assigned agent")
    priority: TaskPriority = Field(default=TaskPriority.MEDIUM)
    status: TaskStatus = Field(default=TaskStatus.PENDING)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    deadline: Optional[datetime] = None
    input_data: Dict[str, Any] = Field(default_factory=dict)
    output_data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    retry_count: int = Field(default=0)
    max_retries: int = Field(default=3)
    dependencies: List[str] = Field(default_factory=list, description="Task IDs this task depends on")
    tags: List[str] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class AgentMetrics(BaseModel):
    """Performance and health metrics for an agent"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    tasks_completed: int = Field(default=0)
    tasks_failed: int = Field(default=0)
    tasks_in_progress: int = Field(default=0)
    average_response_time: float = Field(default=0.0, description="Average response time in seconds")
    success_rate: float = Field(default=1.0, description="Success rate (0.0 to 1.0)")
    uptime_seconds: float = Field(default=0.0)
    cpu_usage_percent: float = Field(default=0.0)
    memory_usage_mb: float = Field(default=0.0)
    last_health_check: Optional[datetime] = None
    errors_count: int = Field(default=0)
    warnings_count: int = Field(default=0)


class AgentConfig(BaseModel):
    """Configuration for an agent"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    model_provider: str = Field(default="openai", description="AI model provider (openai, anthropic, etc.)")
    model_name: str = Field(default="gpt-4", description="Specific model name")
    temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(default=4096, gt=0)
    timeout_seconds: int = Field(default=300, gt=0)
    retry_policy: Dict[str, Any] = Field(default_factory=lambda: {"max_retries": 3, "backoff_factor": 2})
    concurrency_limit: int = Field(default=5, gt=0, description="Max concurrent tasks")
    mcp_enabled: bool = Field(default=True, description="Enable Model Context Protocol")
    a2a_enabled: bool = Field(default=True, description="Enable Agent-to-Agent communication")
    rabbitmq_enabled: bool = Field(default=True, description="Enable RabbitMQ messaging")
    tools: List[str] = Field(default_factory=list, description="List of enabled tool IDs")
    custom_settings: Dict[str, Any] = Field(default_factory=dict)


class BaseAgent(BaseModel):
    """
    Base Agent Class
    
    All specialized agents inherit from this base class. It provides:
    - Unique identification
    - Status management
    - Communication capabilities
    - Task execution framework
    - Health monitoring
    - OpenAI API compatibility
    """
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    # Core Identity
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Unique agent identifier")
    name: str = Field(..., description="Human-readable agent name")
    type: AgentType = Field(..., description="Agent specialization type")
    description: str = Field(..., description="Detailed description of agent capabilities")
    version: str = Field(default="1.0.0")
    
    # Status and State
    status: AgentStatus = Field(default=AgentStatus.IDLE)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    last_active: Optional[datetime] = None
    
    # Configuration
    config: AgentConfig = Field(default_factory=AgentConfig)
    
    # Capabilities
    capabilities: List[AgentCapability] = Field(default_factory=list)
    supported_protocols: List[CommunicationProtocol] = Field(
        default_factory=lambda: [
            CommunicationProtocol.A2A,
            CommunicationProtocol.MCP,
            CommunicationProtocol.RABBITMQ
        ]
    )
    
    # Task Management
    current_task: Optional[Task] = None
    task_queue: List[Task] = Field(default_factory=list)
    
    # Metrics and Health
    metrics: AgentMetrics = Field(default_factory=AgentMetrics)
    
    # Team and Crew
    team_id: Optional[str] = None
    crew_id: Optional[str] = None
    
    # Metadata
    tags: List[str] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)
    
    def __str__(self) -> str:
        return f"{self.type.value}Agent({self.name})[{self.status.value}]"
    
    def __repr__(self) -> str:
        return f"<{self.__class__.__name__} id={self.id} name={self.name} status={self.status.value}>"
    
    def is_available(self) -> bool:
        """Check if agent is available to accept new tasks"""
        return (
            self.status == AgentStatus.IDLE and
            len(self.task_queue) < self.config.concurrency_limit
        )
    
    def can_handle_task(self, task: Task) -> bool:
        """Check if agent can handle a specific task"""
        if task.agent_type and task.agent_type != self.type:
            return False
        return self.is_available()
    
    def add_task(self, task: Task) -> bool:
        """Add a task to the agent's queue"""
        if not self.is_available():
            return False
        task.assigned_agent_id = self.id
        task.status = TaskStatus.QUEUED
        self.task_queue.append(task)
        return True
    
    def get_next_task(self) -> Optional[Task]:
        """Get the next task from the queue based on priority"""
        if not self.task_queue:
            return None
        
        # Sort by priority and created_at
        priority_order = {
            TaskPriority.CRITICAL: 0,
            TaskPriority.HIGH: 1,
            TaskPriority.MEDIUM: 2,
            TaskPriority.LOW: 3,
            TaskPriority.BACKGROUND: 4
        }
        
        self.task_queue.sort(
            key=lambda t: (priority_order.get(t.priority, 999), t.created_at)
        )
        
        return self.task_queue.pop(0) if self.task_queue else None
    
    def update_status(self, new_status: AgentStatus) -> None:
        """Update agent status and last_active timestamp"""
        self.status = new_status
        self.last_active = datetime.utcnow()
        
        if new_status == AgentStatus.WORKING and not self.started_at:
            self.started_at = datetime.utcnow()
    
    def record_task_completion(self, success: bool, response_time: float) -> None:
        """Record metrics for completed task"""
        if success:
            self.metrics.tasks_completed += 1
        else:
            self.metrics.tasks_failed += 1
        
        # Update average response time
        total_tasks = self.metrics.tasks_completed + self.metrics.tasks_failed
        if total_tasks > 0:
            self.metrics.average_response_time = (
                (self.metrics.average_response_time * (total_tasks - 1) + response_time) / total_tasks
            )
        
        # Update success rate
        if total_tasks > 0:
            self.metrics.success_rate = self.metrics.tasks_completed / total_tasks
    
    def health_check(self) -> Dict[str, Any]:
        """Perform a health check and return status"""
        self.metrics.last_health_check = datetime.utcnow()
        
        return {
            "agent_id": self.id,
            "name": self.name,
            "status": self.status.value,
            "is_healthy": self.status not in [AgentStatus.ERROR, AgentStatus.STOPPED],
            "uptime_seconds": self.metrics.uptime_seconds,
            "tasks_in_queue": len(self.task_queue),
            "current_task": self.current_task.id if self.current_task else None,
            "metrics": self.metrics.model_dump(),
            "last_check": self.metrics.last_health_check.isoformat()
        }
    
    def to_openai_compatible(self) -> Dict[str, Any]:
        """
        Convert agent to OpenAI-compatible format for function calling
        """
        return {
            "name": self.name.replace(" ", "_").lower(),
            "description": self.description,
            "parameters": {
                "type": "object",
                "properties": {
                    "task": {
                        "type": "string",
                        "description": "The task to be executed"
                    },
                    "priority": {
                        "type": "string",
                        "enum": [p.value for p in TaskPriority],
                        "description": "Task priority level"
                    },
                    "input_data": {
                        "type": "object",
                        "description": "Additional input data for the task"
                    }
                },
                "required": ["task"]
            }
        }
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """
        Execute a task (to be implemented by subclasses)
        
        Args:
            task: Task to execute
            
        Returns:
            Task execution results
        """
        # Default implementation - subclasses should override
        return {
            "status": "not_implemented",
            "message": "Task execution not implemented for this agent type"
        }
