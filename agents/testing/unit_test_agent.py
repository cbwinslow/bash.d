"""
Unit Test Agent

Expert in unit testing methodologies and frameworks

Specialization: unit_testing
Type: testing

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class UnitTestAgent(BaseAgent):
    """
    Unit Test Agent - Expert in unit testing methodologies and frameworks

    Specialized in creating, maintaining, and optimizing unit tests across
    multiple programming languages and testing frameworks. Focuses on
    test-driven development, code coverage, and test automation.
    """

    def __init__(self, **data):
        """Initialize the Unit Test agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Unit Test Specialist"
        if "type" not in data:
            data["type"] = AgentType.TESTING
        if "description" not in data:
            data["description"] = (
                "Expert in unit testing methodologies and frameworks with focus on TDD, code coverage, and test automation across multiple programming languages"
            )
        if "tags" not in data:
            data["tags"] = [
                "unit_testing",
                "tdd",
                "code_coverage",
                "test_automation",
                "quality_assurance",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.extend(
            [
                "test_driven_development",
                "unit_test_design",
                "mock_object_creation",
                "test_doubt_implementation",
                "code_coverage_analysis",
                "assertion_optimization",
                "test_refactoring",
                "parameterized_testing",
                "test_case_generation",
                "continuous_integration_testing",
            ]
        )

        # Configure tools
        self.config.tools.extend(
            [
                "pytest",
                "junit",
                "unittest",
                "mocha",
                "jest",
                "coverage.py",
                "mock",
                "testdouble",
                "sinon",
                "chai",
            ]
        )

        # Configure custom settings
        self.config.custom_settings.update(
            {
                "testing_frameworks": ["pytest", "junit", "unittest", "jest", "mocha"],
                "coverage_target": 85,
                "test_patterns": ["test_*.py", "*_test.py", "*.test.js"],
                "mocking_strategies": ["mock", "stub", "spy", "fake"],
                "tdd_workflow": "red_green_refactor",
                "assertion_libraries": ["chai", "should.js", "hamcrest"],
                "reporting_formats": ["xml", "html", "json", "junit"],
                "parallel_execution": True,
                "test_discovery": "automatic",
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "unit_testing",
                "category": "testing",
                "frameworks": ["pytest", "junit", "unittest", "jest", "mocha"],
                "languages": ["python", "java", "javascript", "typescript", "c#", "go"],
                "testing_methodology": "tdd",
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a unit testing task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "unit_testing",
            "task_type": "unit_testing",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "unit_test_agent",
            "description": "Expert in unit testing methodologies and frameworks",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Unit testing task to perform",
                    },
                    "framework": {
                        "type": "string",
                        "enum": ["pytest", "junit", "unittest", "jest", "mocha"],
                        "description": "Testing framework to use",
                    },
                    "coverage_target": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 100,
                        "description": "Target code coverage percentage",
                    },
                },
                "required": ["task_description"],
            },
        }
