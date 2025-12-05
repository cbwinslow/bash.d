"""
JavaScript Full Stack Developer Agent

Full-stack JavaScript developer

Specialization: javascript_fullstack
Type: programming

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class JavaScriptFullStackDeveloperAgent(BaseAgent):
    """
    JavaScript Full Stack Developer - Full-stack JavaScript developer
    
    This specialized agent is configured for javascript_fullstack tasks.
    """
    
    def __init__(self, **data):
        """Initialize the JavaScript Full Stack Developer agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "JavaScript Full Stack Developer"
        if "type" not in data:
            data["type"] = AgentType.PROGRAMMING
        if "description" not in data:
            data["description"] = "Full-stack JavaScript developer"
        if "tags" not in data:
            data["tags"] = ["programming_agent"]
        
        # Initialize parent
        super().__init__(**data)
        
        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="javascript_fullstack",
                description="Specialized capability for javascript_fullstack",
                parameters={},
                required=True
            )
        )
        
        # Add metadata
        self.metadata.update({
            "specialization": "javascript_fullstack",
            "category": "programming",
            "index": 2
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "javascript_fullstack"
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "javascript_full_stack_developer",
            "description": "Full-stack JavaScript developer",
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
