"""
Integration tests for the multi-agent system
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
    AgentMessage,
    CommunicationProtocol,
)


class TestAgentCommunication:
    """Tests for inter-agent communication"""

    def test_message_exchange(self, programming_agent, devops_agent):
        """Test message exchange between agents"""
        message = AgentMessage(
            sender_id=programming_agent.id,
            receiver_id=devops_agent.id,
            content={
                "type": "request",
                "action": "deploy",
                "artifact": "app-v1.0.0"
            },
            priority=TaskPriority.HIGH
        )
        
        assert message.sender_id == programming_agent.id
        assert message.receiver_id == devops_agent.id
        assert message.content["action"] == "deploy"

    def test_broadcast_message(self, agent_pool):
        """Test broadcasting messages to all agents"""
        sender = agent_pool[0]
        
        message = AgentMessage(
            sender_id=sender.id,
            receiver_id=None,  # Broadcast
            content={
                "type": "announcement",
                "message": "System maintenance in 5 minutes"
            },
            priority=TaskPriority.HIGH
        )
        
        # All agents except sender should receive
        recipients = [a for a in agent_pool if a.id != sender.id]
        assert len(recipients) == len(agent_pool) - 1
        assert message.receiver_id is None


class TestWorkflow:
    """Tests for complete workflows"""

    def test_ci_cd_pipeline(self):
        """Test a complete CI/CD pipeline workflow"""
        # Create specialized agents
        developer = BaseAgent(
            name="Developer",
            type=AgentType.PROGRAMMING,
            description="Code developer"
        )
        
        tester = BaseAgent(
            name="Tester",
            type=AgentType.TESTING,
            description="Test engineer"
        )
        
        deployer = BaseAgent(
            name="Deployer",
            type=AgentType.DEVOPS,
            description="Deployment specialist"
        )
        
        # Create pipeline tasks
        build_task = Task(
            title="Build Application",
            description="Compile and build the application",
            priority=TaskPriority.HIGH,
            agent_type=AgentType.PROGRAMMING
        )
        
        test_task = Task(
            title="Run Tests",
            description="Execute test suite",
            priority=TaskPriority.HIGH,
            agent_type=AgentType.TESTING,
            dependencies=[build_task.id]
        )
        
        deploy_task = Task(
            title="Deploy to Production",
            description="Deploy application to production",
            priority=TaskPriority.HIGH,
            agent_type=AgentType.DEVOPS,
            dependencies=[build_task.id, test_task.id]
        )
        
        # Assign tasks
        assert developer.add_task(build_task)
        assert tester.add_task(test_task)
        assert deployer.add_task(deploy_task)
        
        # Verify task queues
        assert len(developer.task_queue) == 1
        assert len(tester.task_queue) == 1
        assert len(deployer.task_queue) == 1

    def test_code_review_workflow(self):
        """Test code review workflow"""
        author = BaseAgent(
            name="Code Author",
            type=AgentType.PROGRAMMING,
            description="Code author"
        )
        
        reviewer = BaseAgent(
            name="Code Reviewer",
            type=AgentType.SECURITY,
            description="Security code reviewer"
        )
        
        # Author submits code
        write_task = Task(
            title="Write Feature",
            description="Implement new feature",
            priority=TaskPriority.HIGH,
            agent_type=AgentType.PROGRAMMING
        )
        author.add_task(write_task)
        
        # Complete writing
        write_task.status = TaskStatus.COMPLETED
        author.record_task_completion(success=True, response_time=120.0)
        
        # Submit for review
        review_task = Task(
            title="Review Feature",
            description="Security review of new feature",
            priority=TaskPriority.HIGH,
            agent_type=AgentType.SECURITY,
            dependencies=[write_task.id],
            input_data={"code_ref": write_task.id}
        )
        
        reviewer.add_task(review_task)
        
        assert len(reviewer.task_queue) == 1
        assert review_task.input_data["code_ref"] == write_task.id


class TestScalability:
    """Tests for system scalability"""

    def test_many_agents(self):
        """Test creating many agents"""
        agents = []
        for i in range(100):
            agent = BaseAgent(
                name=f"Agent {i}",
                type=AgentType.GENERAL,
                description=f"Test agent {i}"
            )
            agents.append(agent)
        
        assert len(agents) == 100
        assert all(a.is_available() for a in agents)

    def test_many_tasks(self, programming_agent):
        """Test handling many tasks"""
        # Override concurrency limit for test
        programming_agent.config.concurrency_limit = 1000
        
        for i in range(100):
            task = Task(
                title=f"Task {i}",
                description=f"Test task {i}",
                priority=TaskPriority.MEDIUM
            )
            programming_agent.add_task(task)
        
        assert len(programming_agent.task_queue) == 100

    def test_concurrent_task_processing(self, agent_pool):
        """Test concurrent task processing simulation"""
        tasks_completed = 0
        
        # Assign one task to each agent
        for agent in agent_pool:
            task = Task(
                title=f"Task for {agent.name}",
                description="Concurrent task",
                priority=TaskPriority.MEDIUM
            )
            agent.add_task(task)
        
        # Simulate processing
        for agent in agent_pool:
            if agent.task_queue:
                task = agent.get_next_task()
                task.status = TaskStatus.COMPLETED
                agent.record_task_completion(success=True, response_time=1.0)
                tasks_completed += 1
        
        assert tasks_completed == len(agent_pool)


class TestErrorHandling:
    """Tests for error handling scenarios"""

    def test_task_failure_handling(self, programming_agent):
        """Test handling task failures"""
        task = Task(
            title="Failing Task",
            description="Task that will fail",
            priority=TaskPriority.HIGH,
            max_retries=3
        )
        
        programming_agent.add_task(task)
        
        # Simulate failure
        task.status = TaskStatus.FAILED
        task.error = "Simulated failure"
        task.retry_count += 1
        
        programming_agent.record_task_completion(success=False, response_time=5.0)
        
        assert task.retry_count == 1
        assert task.retry_count < task.max_retries
        assert programming_agent.metrics.tasks_failed == 1

    def test_agent_recovery(self, programming_agent):
        """Test agent recovery from error state"""
        programming_agent.update_status(AgentStatus.ERROR)
        assert not programming_agent.is_available()
        
        # Recover
        programming_agent.update_status(AgentStatus.IDLE)
        assert programming_agent.is_available()

    def test_task_timeout(self, programming_agent):
        """Test task timeout handling"""
        task = Task(
            title="Long Running Task",
            description="Task that times out",
            priority=TaskPriority.MEDIUM
        )
        
        programming_agent.add_task(task)
        
        # Simulate timeout
        task.status = TaskStatus.TIMEOUT
        task.error = "Task execution timed out"
        
        assert task.status == TaskStatus.TIMEOUT


class TestMetricsAggregation:
    """Tests for metrics collection and aggregation"""

    def test_agent_metrics_accumulation(self, programming_agent):
        """Test metrics accumulation over multiple tasks"""
        for i in range(10):
            success = i % 2 == 0  # 50% success rate
            programming_agent.record_task_completion(
                success=success,
                response_time=float(i + 1)
            )
        
        assert programming_agent.metrics.tasks_completed == 5
        assert programming_agent.metrics.tasks_failed == 5
        assert programming_agent.metrics.success_rate == 0.5

    def test_pool_metrics(self, agent_pool):
        """Test aggregating metrics from agent pool"""
        total_completed = 0
        total_failed = 0
        
        for i, agent in enumerate(agent_pool):
            agent.record_task_completion(success=True, response_time=1.0)
            if i % 3 == 0:
                agent.record_task_completion(success=False, response_time=2.0)
        
        for agent in agent_pool:
            total_completed += agent.metrics.tasks_completed
            total_failed += agent.metrics.tasks_failed
        
        assert total_completed == len(agent_pool)
        assert total_failed > 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
