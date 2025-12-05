"""
Unit Test Developer Agent

Unit testing specialist

Specialization: unit_testing
Type: testing

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class UnitTestDeveloperAgent(BaseAgent):
    """
    Unit Test Developer - Unit testing specialist
    
    This specialized agent is configured for unit_testing tasks.
    """
    
    def __init__(self, **data):
        """Initialize the Unit Test Developer agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "Unit Test Developer"
        if "type" not in data:
            data["type"] = AgentType.TESTING
        if "description" not in data:
            data["description"] = "Unit testing specialist"
        if "tags" not in data:
            data["tags"] = ["testing_agent"]
        
        # Initialize parent
        super().__init__(**data)
        
        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="unit_testing",
                description="Specialized capability for unit_testing",
                parameters={},
                required=True
            )
        )
        
        # Add metadata
        self.metadata.update({
            "specialization": "unit_testing",
            "category": "testing",
            "index": 7
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "unit_testing"
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "unit_test_developer",
            "description": "Unit testing specialist",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Task to perform"
                    }
                },
                "required": ["task_description"]
            }
        }
