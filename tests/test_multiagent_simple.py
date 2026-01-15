"""
Comprehensive tests for Multi-Agent System
"""

import sys
import os
from datetime import datetime, timedelta, timezone

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from agents.base import (
    BaseAgent,
    Task,
    TaskPriority,
    TaskStatus,
    AgentType,
    AgentStatus,
    AgentConfig,
    AgentCapability,
    AgentMessage,
    AgentMetrics,
    CommunicationProtocol,
)


class TestAgentCreation:
    """Tests for agent creation and initialization"""

    def test_agent_creation_basic(self):
        """Test creating a basic agent"""
        agent = BaseAgent(
            name="Test Agent",
            type=AgentType.PROGRAMMING,
            description="Test agent for unit tests"
        )
        
        assert agent.name == "Test Agent"
        assert agent.type == AgentType.PROGRAMMING
        assert agent.status == AgentStatus.IDLE
        assert agent.is_available()
        assert agent.id is not None
        assert len(agent.id) == 36  # UUID format

    def test_agent_creation_all_types(self):
        """Test creating agents of all types"""
        for agent_type in AgentType:
            agent = BaseAgent(
                name=f"Test {agent_type.value} Agent",
                type=agent_type,
                description=f"Agent for {agent_type.value} tasks"
            )
            assert agent.type == agent_type
            assert agent.is_available()

    def test_agent_with_custom_config(self):
        """Test agent with custom configuration"""
        config = AgentConfig(
            model_provider="anthropic",
            model_name="claude-3",
            temperature=0.5,
            max_tokens=8192,
            timeout_seconds=600,
            concurrency_limit=10
        )
        
        agent = BaseAgent(
            name="Custom Config Agent",
            type=AgentType.PROGRAMMING,
            description="Agent with custom config",
            config=config
        )
        
        assert agent.config.model_provider == "anthropic"
        assert agent.config.model_name == "claude-3"
        assert agent.config.temperature == 0.5
        assert agent.config.max_tokens == 8192
        assert agent.config.concurrency_limit == 10

    def test_agent_string_representation(self):
        """Test agent string representations"""
        agent = BaseAgent(
            name="Test Agent",
            type=AgentType.DEVOPS,
            description="Test agent"
        )
        
        # use_enum_values=True converts enum to string
        str_repr = str(agent)
        assert "devops" in str_repr.lower()
        assert "Test Agent" in str_repr
        assert agent.id in repr(agent)


class TestTaskManagement:
    """Tests for task creation and management"""

    def test_task_creation(self):
        """Test creating a task"""
        task = Task(
            title="Test Task",
            description="A test task",
            priority=TaskPriority.HIGH,
            agent_type=AgentType.PROGRAMMING
        )
        
        assert task.title == "Test Task"
        assert task.priority == TaskPriority.HIGH
        assert task.agent_type == AgentType.PROGRAMMING
        assert task.status == TaskStatus.PENDING
        assert task.id is not None

    def test_task_all_priorities(self):
        """Test tasks with all priority levels"""
        for priority in TaskPriority:
            task = Task(
                title=f"{priority.value} Task",
                description=f"Task with {priority.value} priority",
                priority=priority
            )
            assert task.priority == priority

    def test_task_with_metadata(self):
        """Test task with metadata and input data"""
        task = Task(
            title="Data Task",
            description="Task with data",
            priority=TaskPriority.MEDIUM,
            input_data={"key": "value", "count": 42},
            metadata={"source": "test", "version": "1.0"},
            tags=["test", "data"]
        )
        
        assert task.input_data["key"] == "value"
        assert task.input_data["count"] == 42
        assert task.metadata["source"] == "test"
        assert "test" in task.tags

    def test_task_with_deadline(self):
        """Test task with deadline"""
        deadline = datetime.now(timezone.utc) + timedelta(hours=2)
        task = Task(
            title="Urgent Task",
            description="Task with deadline",
            priority=TaskPriority.CRITICAL,
            deadline=deadline
        )
        
        assert task.deadline == deadline
        assert task.deadline > datetime.now(timezone.utc)


class TestAgentTaskQueue:
    """Tests for agent task queue operations"""

    def test_agent_add_task(self):
        """Test adding tasks to agent queue"""
        agent = BaseAgent(
            name="Test Agent",
            type=AgentType.PROGRAMMING,
            description="Test agent"
        )
        
        task = Task(
            title="Test Task",
            description="Test task description",
            priority=TaskPriority.HIGH
        )
        
        assert agent.add_task(task)
        assert len(agent.task_queue) == 1
        assert task.assigned_agent_id == agent.id
        assert task.status == TaskStatus.QUEUED

    def test_agent_multiple_tasks(self):
        """Test adding multiple tasks to queue"""
        agent = BaseAgent(
            name="Test Agent",
            type=AgentType.PROGRAMMING,
            description="Test agent"
        )
        
        for i in range(3):
            task = Task(
                title=f"Task {i}",
                description=f"Description {i}",
                priority=TaskPriority.MEDIUM
            )
            assert agent.add_task(task)
        
        assert len(agent.task_queue) == 3

    def test_agent_get_next_task_priority_order(self):
        """Test that tasks are retrieved in priority order"""
        agent = BaseAgent(
            name="Test Agent",
            type=AgentType.PROGRAMMING,
            description="Test agent"
        )
        
        # Add tasks in non-priority order
        low_task = Task(title="Low", description="Low priority", priority=TaskPriority.LOW)
        high_task = Task(title="High", description="High priority", priority=TaskPriority.HIGH)
        critical_task = Task(title="Critical", description="Critical priority", priority=TaskPriority.CRITICAL)
        
        agent.add_task(low_task)
        agent.add_task(high_task)
        agent.add_task(critical_task)
        
        # Should get critical first
        next_task = agent.get_next_task()
        assert next_task.priority == TaskPriority.CRITICAL
        
        # Then high
        next_task = agent.get_next_task()
        assert next_task.priority == TaskPriority.HIGH
        
        # Then low
        next_task = agent.get_next_task()
        assert next_task.priority == TaskPriority.LOW

    def test_agent_task_compatibility(self):
        """Test task compatibility checking"""
        agent = BaseAgent(
            name="Programming Agent",
            type=AgentType.PROGRAMMING,
            description="Programming tasks only"
        )
        
        compatible_task = Task(
            title="Code Task",
            description="Programming task",
            agent_type=AgentType.PROGRAMMING,
            priority=TaskPriority.MEDIUM
        )
        
        incompatible_task = Task(
            title="DevOps Task",
            description="DevOps task",
            agent_type=AgentType.DEVOPS,
            priority=TaskPriority.MEDIUM
        )
        
        assert agent.can_handle_task(compatible_task)
        assert not agent.can_handle_task(incompatible_task)


class TestAgentStatus:
    """Tests for agent status management"""

    def test_agent_status_update(self):
        """Test updating agent status"""
        agent = BaseAgent(
            name="Test Agent",
            type=AgentType.PROGRAMMING,
            description="Test agent"
        )
        
        assert agent.status == AgentStatus.IDLE
        
        agent.update_status(AgentStatus.WORKING)
        assert agent.status == AgentStatus.WORKING
        assert agent.last_active is not None
        assert agent.started_at is not None

    def test_agent_availability(self):
        """Test agent availability checking"""
        agent = BaseAgent(
            name="Test Agent",
            type=AgentType.PROGRAMMING,
            description="Test agent"
        )
        
        assert agent.is_available()
        
        agent.update_status(AgentStatus.BUSY)
        assert not agent.is_available()
        
        agent.update_status(AgentStatus.IDLE)
        assert agent.is_available()


class TestAgentMetrics:
    """Tests for agent metrics and health"""

    def test_record_task_completion(self):
        """Test recording task completion metrics"""
        agent = BaseAgent(
            name="Test Agent",
            type=AgentType.PROGRAMMING,
            description="Test agent"
        )
        
        agent.record_task_completion(success=True, response_time=1.5)
        assert agent.metrics.tasks_completed == 1
        assert agent.metrics.tasks_failed == 0
        assert agent.metrics.success_rate == 1.0
        
        agent.record_task_completion(success=False, response_time=2.0)
        assert agent.metrics.tasks_completed == 1
        assert agent.metrics.tasks_failed == 1
        assert agent.metrics.success_rate == 0.5

    def test_health_check(self):
        """Test agent health check"""
        agent = BaseAgent(
            name="Test Agent",
            type=AgentType.PROGRAMMING,
            description="Test agent"
        )
        
        health = agent.health_check()
        
        assert health["agent_id"] == agent.id
        assert health["name"] == agent.name
        assert health["status"] == "idle"
        assert health["is_healthy"] is True
        assert "metrics" in health

    def test_health_check_unhealthy(self):
        """Test health check for unhealthy agent"""
        agent = BaseAgent(
            name="Test Agent",
            type=AgentType.PROGRAMMING,
            description="Test agent"
        )
        
        agent.update_status(AgentStatus.ERROR)
        health = agent.health_check()
        
        assert health["is_healthy"] is False


class TestAgentMessage:
    """Tests for agent messaging"""

    def test_message_creation(self):
        """Test creating agent messages"""
        message = AgentMessage(
            sender_id="agent-1",
            receiver_id="agent-2",
            content={"action": "request", "data": "test"},
            priority=TaskPriority.HIGH
        )
        
        assert message.sender_id == "agent-1"
        assert message.receiver_id == "agent-2"
        assert message.content["action"] == "request"
        assert message.priority == TaskPriority.HIGH
        assert message.id is not None

    def test_broadcast_message(self):
        """Test creating broadcast message (no receiver)"""
        message = AgentMessage(
            sender_id="agent-1",
            content={"type": "broadcast", "data": "hello"}
        )
        
        assert message.receiver_id is None
        assert message.protocol == CommunicationProtocol.A2A


class TestAgentCapability:
    """Tests for agent capabilities"""

    def test_capability_creation(self):
        """Test creating agent capabilities"""
        capability = AgentCapability(
            name="code_generation",
            description="Generate code in multiple languages",
            parameters={"languages": ["python", "javascript"]},
            required=True
        )
        
        assert capability.name == "code_generation"
        assert "python" in capability.parameters["languages"]
        assert capability.required is True


class TestOpenAICompatibility:
    """Tests for OpenAI API compatibility"""

    def test_to_openai_compatible(self):
        """Test conversion to OpenAI-compatible format"""
        agent = BaseAgent(
            name="Python Developer",
            type=AgentType.PROGRAMMING,
            description="Expert Python developer for backend systems"
        )
        
        openai_format = agent.to_openai_compatible()
        
        assert "name" in openai_format
        assert "description" in openai_format
        assert "parameters" in openai_format
        assert openai_format["parameters"]["type"] == "object"
        assert "task" in openai_format["parameters"]["properties"]
        assert "required" in openai_format["parameters"]


class TestEnums:
    """Tests for enum values"""

    def test_agent_type_values(self):
        """Test all AgentType values exist"""
        expected = {"programming", "devops", "documentation", "testing", 
                   "security", "data", "design", "communication", "monitoring", 
                   "automation", "general"}
        actual = {t.value for t in AgentType}
        assert expected == actual

    def test_agent_status_values(self):
        """Test all AgentStatus values exist"""
        expected = {"idle", "busy", "working", "paused", "error", 
                   "stopped", "starting", "stopping"}
        actual = {s.value for s in AgentStatus}
        assert expected == actual

    def test_task_priority_values(self):
        """Test all TaskPriority values exist"""
        expected = {"critical", "high", "medium", "low", "background"}
        actual = {p.value for p in TaskPriority}
        assert expected == actual

    def test_task_status_values(self):
        """Test all TaskStatus values exist"""
        expected = {"pending", "queued", "assigned", "in_progress", "paused",
                   "completed", "failed", "cancelled", "timeout"}
        actual = {s.value for s in TaskStatus}
        assert expected == actual


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
