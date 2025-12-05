"""
Python Backend Developer Agent

Expert in Python backend development

Specialization: python_backend
Type: programming

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class PythonBackendDeveloperAgent(BaseAgent):
    """
    Python Backend Developer - Expert in Python backend development
    
    This specialized agent is configured for python_backend tasks.
    """
    
    def __init__(self, **data):
        """Initialize the Python Backend Developer agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "Python Backend Developer"
        if "type" not in data:
            data["type"] = AgentType.PROGRAMMING
        if "description" not in data:
            data["description"] = "Expert in Python backend development"
        if "tags" not in data:
            data["tags"] = ["programming_agent"]
        
        # Initialize parent
        super().__init__(**data)
        
        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="python_backend",
                description="Specialized capability for python_backend",
                parameters={},
                required=True
            )
        )
        
        # Add metadata
        self.metadata.update({
            "specialization": "python_backend",
            "category": "programming",
            "index": 1
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "python_backend"
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "python_backend_developer",
            "description": "Expert in Python backend development",
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
