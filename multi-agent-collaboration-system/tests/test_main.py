"""
Tests for the main application.
"""

import unittest
from src.main import Orchestrator

class TestMain(unittest.TestCase):
    """
    Tests for the main orchestrator.
    """

    def test_orchestrator_initialization(self):
        """
        Tests that the orchestrator can be initialized.
        """
        config = {
            "project_name": "test_project",
            "version": "0.1.0"
        }
        orchestrator = Orchestrator(config)
        self.assertIsNotNone(orchestrator)
        self.assertEqual(orchestrator.config, config)

if __name__ == '__main__':
    unittest.main()
