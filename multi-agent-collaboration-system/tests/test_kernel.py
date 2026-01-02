"""
Tests for the Agent Kernel.
"""

import unittest
from src.kernel import Agent

class TestAgent(unittest.TestCase):
    """
    Tests for the Agent class.
    """

    def test_agent_creation(self):
        """
        Tests that an Agent can be created with the correct properties.
        """
        agent = Agent(
            name="test_agent",
            role="Test Role",
            goal="Test Goal",
            backstory="Test Backstory"
        )
        self.assertEqual(agent.name, "test_agent")
        self.assertEqual(agent.role, "Test Role")
        self.assertEqual(agent.goal, "Test Goal")
        self.assertEqual(agent.backstory, "Test Backstory")
        self.assertEqual(agent.tools, [])
        self.assertIsNone(agent.llm)

    def test_agent_task_execution(self):
        """
        Tests the placeholder task execution method.
        """
        agent = Agent(name="test_agent", role="Test", goal="Test", backstory="Test")
        result = agent.execute_task("Test the execution.")
        self.assertEqual(result, "Task 'Test the execution.' completed by 'test_agent'.")

if __name__ == '__main__':
    unittest.main()
