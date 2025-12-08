"""
Simple tests for Multi-Agent System
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from agents.base import (
    BaseAgent,
    Task,
    TaskPriority,
    AgentType,
    AgentStatus
)


def test_agent_creation():
    """Test creating an agent"""
    agent = BaseAgent(
        name="Test Agent",
        type=AgentType.PROGRAMMING,
        description="Test agent for unit tests"
    )
    
    assert agent.name == "Test Agent"
    assert agent.type == AgentType.PROGRAMMING
    assert agent.status == AgentStatus.IDLE
    assert agent.is_available()
    print("✓ Agent creation test passed")


def test_agent_task_queue():
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
    print("✓ Agent task queue test passed")


def test_task_creation():
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
    print("✓ Task creation test passed")


if __name__ == "__main__":
    print("Running simple multiagent tests...")
    test_agent_creation()
    test_agent_task_queue()
    test_task_creation()
    print("\nAll tests passed! ✓")
