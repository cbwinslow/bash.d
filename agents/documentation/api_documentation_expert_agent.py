"""
API Documentation Expert Agent

API documentation expert

Specialization: api_docs
Type: documentation

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class APIDocumentationExpertAgent(BaseAgent):
    """
    API Documentation Expert - API documentation expert
    
    This specialized agent is configured for api_docs tasks.
    """
    
    def __init__(self, **data):
        """Initialize the API Documentation Expert agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "API Documentation Expert"
        if "type" not in data:
            data["type"] = AgentType.DOCUMENTATION
        if "description" not in data:
            data["description"] = "API documentation expert"
        if "tags" not in data:
            data["tags"] = ["documentation_agent"]
        
        # Initialize parent
        super().__init__(**data)
        
        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="api_docs",
                description="Specialized capability for api_docs",
                parameters={},
                required=True
            )
        )
        
        # Add metadata
        self.metadata.update({
            "specialization": "api_docs",
            "category": "documentation",
            "index": 6
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "api_docs"
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "api_documentation_expert",
            "description": "API documentation expert",
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
