"""
Technical Writer Agent

Technical documentation specialist

Specialization: technical_writing
Type: documentation

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class TechnicalWriterAgent(BaseAgent):
    """
    Technical Writer - Technical documentation specialist
    
    This specialized agent is configured for technical_writing tasks.
    """
    
    def __init__(self, **data):
        """Initialize the Technical Writer agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "Technical Writer"
        if "type" not in data:
            data["type"] = AgentType.DOCUMENTATION
        if "description" not in data:
            data["description"] = "Technical documentation specialist"
        if "tags" not in data:
            data["tags"] = ["documentation_agent"]
        
        # Initialize parent
        super().__init__(**data)
        
        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="technical_writing",
                description="Specialized capability for technical_writing",
                parameters={},
                required=True
            )
        )
        
        # Add metadata
        self.metadata.update({
            "specialization": "technical_writing",
            "category": "documentation",
            "index": 5
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "technical_writing"
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "technical_writer",
            "description": "Technical documentation specialist",
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
