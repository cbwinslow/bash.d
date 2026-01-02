"""
Tests for the Orchestrator.
"""

import unittest
from unittest.mock import MagicMock, patch
from src.main import Orchestrator
from src import agent_registry
from src.kernel import Agent

class TestOrchestrator(unittest.TestCase):
    """
    Tests for the Orchestrator class.
    """

    def setUp(self):
        """
        Clear the agent registry and any mocks before each test.
        """
        agent_registry._agent_registry.clear()
        self.config = {
            "project_name": "test_project",
            "version": "0.1.0"
        }
        self.orchestrator = Orchestrator(self.config)

    def test_add_task(self):
        """
        Tests that tasks are added to the queue correctly.
        """
        self.assertEqual(len(self.orchestrator.task_queue), 0)
        self.orchestrator.add_task("task1", "developer")
        self.assertEqual(len(self.orchestrator.task_queue), 1)
        self.assertEqual(self.orchestrator.task_queue[0]["description"], "task1")
        self.assertEqual(self.orchestrator.task_queue[0]["status"], "PENDING")

    @patch('src.agent_registry.get_agent')
    def test_delegate_task_success(self, mock_get_agent):
        """
        Tests successful task delegation to a registered agent.
        """
        mock_agent = MagicMock(spec=Agent)
        mock_agent.name = "TestAgent"
        mock_agent.execute_task.return_value = "Task completed successfully."
        mock_get_agent.return_value = mock_agent

        # Register a dummy agent for the orchestrator to find
        agent_registry.register_agent("developer", lambda: mock_agent)

        task = {"description": "write code", "assigned_agent_role": "developer", "status": "PENDING"}
        self.orchestrator.delegate_task(task)

        mock_get_agent.assert_called_with("developer")
        mock_agent.execute_task.assert_called_with("write code")
        self.assertEqual(task["status"], "COMPLETED")

    @patch('src.agent_registry.get_agent')
    def test_delegate_task_agent_not_found(self, mock_get_agent):
        """
        Tests task delegation when the assigned agent is not found.
        """
        mock_get_agent.side_effect = ValueError("Agent not found.")
        task = {"description": "unknown task", "assigned_agent_role": "non_existent_agent", "status": "PENDING"}
        self.orchestrator.delegate_task(task)
        self.assertEqual(task["status"], "FAILED")
        # No assert_called_with on execute_task as it should not be called

    @patch('src.agent_registry.get_agent')
    @patch('time.sleep', return_value=None) # Mock time.sleep to speed up tests
    def test_run_processes_tasks(self, mock_sleep, mock_get_agent):
        """
        Tests that the run method processes tasks from the queue.
        """
        mock_agent = MagicMock(spec=Agent)
        mock_agent.name = "TestAgent"
        mock_agent.execute_task.return_value = "Task completed successfully."
        mock_get_agent.return_value = mock_agent
        agent_registry.register_agent("developer", lambda: mock_agent)

        self.orchestrator.add_task("task A", "developer")
        self.orchestrator.add_task("task B", "developer")

        self.orchestrator.run()

        self.assertEqual(len(self.orchestrator.task_queue), 0)
        self.assertEqual(mock_agent.execute_task.call_count, 2)
        mock_sleep.assert_called_with(1) # Ensure sleep was called

if __name__ == '__main__':
    unittest.main()
