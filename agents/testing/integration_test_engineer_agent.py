"""
Integration Test Engineer Agent

Integration testing expert

Specialization: integration_testing
Type: testing

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class IntegrationTestEngineerAgent(BaseAgent):
    """
    Integration Test Engineer - Integration testing expert
    
    This specialized agent is configured for integration_testing tasks.
    """
    
    def __init__(self, **data):
        """Initialize the Integration Test Engineer agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "Integration Test Engineer"
        if "type" not in data:
            data["type"] = AgentType.TESTING
        if "description" not in data:
            data["description"] = "Integration testing expert"
        if "tags" not in data:
            data["tags"] = ["testing_agent"]
        
        # Initialize parent
        super().__init__(**data)
        
        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="integration_testing",
                description="Specialized capability for integration_testing",
                parameters={},
                required=True
            )
        )
        
        # Add metadata
        self.metadata.update({
            "specialization": "integration_testing",
            "category": "testing",
            "index": 8
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "integration_testing"
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "integration_test_engineer",
            "description": "Integration testing expert",
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
