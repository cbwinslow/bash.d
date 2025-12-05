"""
Docker Container Expert Agent

Docker containerization specialist

Specialization: docker
Type: devops

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class DockerContainerExpertAgent(BaseAgent):
    """
    Docker Container Expert - Docker containerization specialist
    
    This specialized agent is configured for docker tasks.
    """
    
    def __init__(self, **data):
        """Initialize the Docker Container Expert agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "Docker Container Expert"
        if "type" not in data:
            data["type"] = AgentType.DEVOPS
        if "description" not in data:
            data["description"] = "Docker containerization specialist"
        if "tags" not in data:
            data["tags"] = ["devops_agent"]
        
        # Initialize parent
        super().__init__(**data)
        
        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="docker",
                description="Specialized capability for docker",
                parameters={},
                required=True
            )
        )
        
        # Add metadata
        self.metadata.update({
            "specialization": "docker",
            "category": "devops",
            "index": 4
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "docker"
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "docker_container_expert",
            "description": "Docker containerization specialist",
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
