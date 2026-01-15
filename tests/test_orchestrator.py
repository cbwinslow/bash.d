"""
Tests for Agent Orchestrator
"""

import sys
import os
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from agents.base import (
    BaseAgent,
    AgentType,
    AgentStatus,
    Task,
    TaskPriority,
    TaskStatus,
)


class TestOrchestrator:
    """Tests for orchestrator functionality"""

    def test_agent_pool_management(self):
        """Test managing a pool of agents"""
        agents = []
        for agent_type in [AgentType.PROGRAMMING, AgentType.DEVOPS, AgentType.TESTING]:
            agent = BaseAgent(
                name=f"{agent_type.value.title()} Agent",
                type=agent_type,
                description=f"Agent for {agent_type.value} tasks"
            )
            agents.append(agent)
        
        assert len(agents) == 3
        assert all(agent.is_available() for agent in agents)

    def test_task_routing(self):
        """Test routing tasks to appropriate agents"""
        programming_agent = BaseAgent(
            name="Programmer",
            type=AgentType.PROGRAMMING,
            description="Programming agent"
        )
        
        devops_agent = BaseAgent(
            name="DevOps",
            type=AgentType.DEVOPS,
            description="DevOps agent"
        )
        
        agents = [programming_agent, devops_agent]
        
        code_task = Task(
            title="Write Code",
            description="Write Python code",
            agent_type=AgentType.PROGRAMMING,
            priority=TaskPriority.HIGH
        )
        
        deploy_task = Task(
            title="Deploy",
            description="Deploy to production",
            agent_type=AgentType.DEVOPS,
            priority=TaskPriority.HIGH
        )
        
        # Find suitable agent for each task
        code_agent = next(
            (a for a in agents if a.can_handle_task(code_task)), None
        )
        deploy_agent = next(
            (a for a in agents if a.can_handle_task(deploy_task)), None
        )
        
        assert code_agent == programming_agent
        assert deploy_agent == devops_agent

    def test_load_balancing(self):
        """Test distributing tasks among agents"""
        agents = [
            BaseAgent(
                name=f"Worker {i}",
                type=AgentType.GENERAL,
                description=f"General worker {i}"
            )
            for i in range(3)
        ]
        
        tasks = [
            Task(
                title=f"Task {i}",
                description=f"General task {i}",
                priority=TaskPriority.MEDIUM
            )
            for i in range(6)
        ]
        
        # Distribute tasks round-robin
        for i, task in enumerate(tasks):
            agent = agents[i % len(agents)]
            agent.add_task(task)
        
        # Each agent should have 2 tasks
        for agent in agents:
            assert len(agent.task_queue) == 2

    def test_agent_failover(self):
        """Test handling agent failures"""
        primary = BaseAgent(
            name="Primary",
            type=AgentType.PROGRAMMING,
            description="Primary agent"
        )
        
        backup = BaseAgent(
            name="Backup",
            type=AgentType.PROGRAMMING,
            description="Backup agent"
        )
        
        task = Task(
            title="Important Task",
            description="Must be completed",
            priority=TaskPriority.CRITICAL
        )
        
        # Assign to primary
        primary.add_task(task)
        
        # Simulate primary failure
        primary.update_status(AgentStatus.ERROR)
        
        # Failover to backup
        if not primary.is_available():
            # Re-queue task to backup
            failed_task = primary.task_queue.pop(0)
            failed_task.status = TaskStatus.PENDING
            failed_task.assigned_agent_id = None
            backup.add_task(failed_task)
        
        assert len(backup.task_queue) == 1
        assert backup.task_queue[0].title == "Important Task"


class TestTaskDependencies:
    """Tests for task dependency handling"""

    def test_task_dependencies(self):
        """Test tasks with dependencies"""
        task1 = Task(
            title="Build",
            description="Build the project",
            priority=TaskPriority.HIGH
        )
        
        task2 = Task(
            title="Test",
            description="Run tests",
            priority=TaskPriority.HIGH,
            dependencies=[task1.id]
        )
        
        task3 = Task(
            title="Deploy",
            description="Deploy to production",
            priority=TaskPriority.HIGH,
            dependencies=[task1.id, task2.id]
        )
        
        assert len(task1.dependencies) == 0
        assert len(task2.dependencies) == 1
        assert len(task3.dependencies) == 2
        assert task1.id in task2.dependencies
        assert task1.id in task3.dependencies
        assert task2.id in task3.dependencies

    def test_dependency_resolution(self):
        """Test checking if dependencies are satisfied"""
        completed_tasks = {}
        
        task1 = Task(
            title="Task 1",
            description="First task",
            priority=TaskPriority.HIGH
        )
        
        task2 = Task(
            title="Task 2",
            description="Second task",
            priority=TaskPriority.HIGH,
            dependencies=[task1.id]
        )
        
        # Check if task2 can start (dependencies not met)
        can_start = all(
            dep_id in completed_tasks 
            for dep_id in task2.dependencies
        )
        assert not can_start
        
        # Complete task1
        task1.status = TaskStatus.COMPLETED
        completed_tasks[task1.id] = task1
        
        # Now task2 can start
        can_start = all(
            dep_id in completed_tasks 
            for dep_id in task2.dependencies
        )
        assert can_start


class TestAgentTeams:
    """Tests for agent team functionality"""

    def test_team_assignment(self):
        """Test assigning agents to teams"""
        team_id = "team-1"
        
        agents = [
            BaseAgent(
                name=f"Team Member {i}",
                type=AgentType.PROGRAMMING,
                description=f"Team member {i}",
                team_id=team_id
            )
            for i in range(3)
        ]
        
        assert all(a.team_id == team_id for a in agents)

    def test_crew_assignment(self):
        """Test assigning agents to crews"""
        crew_id = "crew-alpha"
        
        agent = BaseAgent(
            name="Crew Member",
            type=AgentType.PROGRAMMING,
            description="Crew member agent",
            crew_id=crew_id
        )
        
        assert agent.crew_id == crew_id


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
