"""
Pytest configuration and fixtures for bash.d tests
"""

import sys
import os
import pytest

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from agents.base import (
    BaseAgent,
    AgentType,
    AgentStatus,
    AgentConfig,
    Task,
    TaskPriority,
)


@pytest.fixture
def programming_agent():
    """Create a programming agent for testing"""
    return BaseAgent(
        name="Test Programming Agent",
        type=AgentType.PROGRAMMING,
        description="Agent for programming tasks in tests"
    )


@pytest.fixture
def devops_agent():
    """Create a DevOps agent for testing"""
    return BaseAgent(
        name="Test DevOps Agent",
        type=AgentType.DEVOPS,
        description="Agent for DevOps tasks in tests"
    )


@pytest.fixture
def testing_agent():
    """Create a testing agent for testing"""
    return BaseAgent(
        name="Test Testing Agent",
        type=AgentType.TESTING,
        description="Agent for testing tasks in tests"
    )


@pytest.fixture
def agent_pool():
    """Create a pool of different agent types"""
    return [
        BaseAgent(
            name=f"Pool Agent - {agent_type.value}",
            type=agent_type,
            description=f"Pool agent for {agent_type.value}"
        )
        for agent_type in AgentType
    ]


@pytest.fixture
def high_priority_task():
    """Create a high priority task"""
    return Task(
        title="High Priority Task",
        description="A high priority test task",
        priority=TaskPriority.HIGH,
        agent_type=AgentType.PROGRAMMING
    )


@pytest.fixture
def critical_task():
    """Create a critical priority task"""
    return Task(
        title="Critical Task",
        description="A critical test task",
        priority=TaskPriority.CRITICAL,
        agent_type=AgentType.PROGRAMMING
    )


@pytest.fixture
def task_list():
    """Create a list of tasks with varying priorities"""
    priorities = [
        TaskPriority.LOW,
        TaskPriority.MEDIUM,
        TaskPriority.HIGH,
        TaskPriority.CRITICAL,
        TaskPriority.BACKGROUND,
    ]
    
    return [
        Task(
            title=f"Task {p.value}",
            description=f"Task with {p.value} priority",
            priority=p
        )
        for p in priorities
    ]


@pytest.fixture
def custom_config():
    """Create a custom agent configuration"""
    return AgentConfig(
        model_provider="anthropic",
        model_name="claude-3-opus",
        temperature=0.3,
        max_tokens=16384,
        timeout_seconds=900,
        concurrency_limit=3,
        mcp_enabled=True,
        a2a_enabled=True,
        tools=["code_gen", "code_review", "testing"]
    )


@pytest.fixture
def configured_agent(custom_config):
    """Create an agent with custom configuration"""
    return BaseAgent(
        name="Configured Agent",
        type=AgentType.PROGRAMMING,
        description="Agent with custom config",
        config=custom_config
    )
