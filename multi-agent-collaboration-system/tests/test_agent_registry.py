"""
Tests for the Agent Registry.
"""

import unittest
from src import agent_registry
from src.kernel import Agent

def create_test_agent():
    """A factory function to create a test agent."""
    return Agent(
        name="test_agent",
        role="Test Role",
        goal="Test Goal",
        backstory="Test Backstory"
    )

class TestAgentRegistry(unittest.TestCase):
    """
    Tests for the agent registry functions.
    """

    def setUp(self):
        """
        Clear the registry before each test.
        """
        agent_registry._agent_registry.clear()

    def test_register_and_get_agent(self):
        """
        Tests that an agent can be registered and then retrieved.
        """
        agent_registry.register_agent("test_agent", create_test_agent)
        
        retrieved_agent = agent_registry.get_agent("test_agent")
        self.assertIsInstance(retrieved_agent, Agent)
        self.assertEqual(retrieved_agent.name, "test_agent")

    def test_list_agents(self):
        """
        Tests that the list of registered agents can be retrieved.
        """
        self.assertEqual(agent_registry.list_agents(), [])
        agent_registry.register_agent("test_agent_1", create_test_agent)
        agent_registry.register_agent("test_agent_2", create_test_agent)
        self.assertEqual(sorted(agent_registry.list_agents()), ["test_agent_1", "test_agent_2"])

    def test_get_unregistered_agent(self):
        """
        Tests that getting an unregistered agent raises a ValueError.
        """
        with self.assertRaises(ValueError):
            agent_registry.get_agent("non_existent_agent")

if __name__ == '__main__':
    unittest.main()
