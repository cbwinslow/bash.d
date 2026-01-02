"""
Java Enterprise Developer Agent

Expert in Java enterprise application development

Specialization: java_enterprise
Type: programming

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class JavaEnterpriseDeveloperAgent(BaseAgent):
    """
    Java Enterprise Developer - Expert in Java enterprise application development

    This specialized agent is configured for java_enterprise tasks.
    """

    def __init__(self, **data):
        """Initialize the Java Enterprise Developer agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Java Enterprise Developer"
        if "type" not in data:
            data["type"] = AgentType.PROGRAMMING
        if "description" not in data:
            data["description"] = "Expert in Java enterprise application development"
        if "tags" not in data:
            data["tags"] = ["programming_agent"]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="java_enterprise",
                description="Specialized capability for java_enterprise",
                parameters={},
                required=True,
            )
        )

        # Add metadata
        self.metadata.update(
            {"specialization": "java_enterprise", "category": "programming", "index": 6}
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "java_enterprise",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "java_enterprise_developer",
            "description": "Expert in Java enterprise application development",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Task to perform",
                    }
                },
                "required": ["task_description"],
            },
        }
