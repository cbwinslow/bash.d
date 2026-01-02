"""
TypeScript Full Stack Developer Agent

Expert in TypeScript full-stack development

Specialization: typescript_fullstack
Type: programming

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class TypeScriptFullStackDeveloperAgent(BaseAgent):
    """
    TypeScript Full Stack Developer - Expert in TypeScript full-stack development

    This specialized agent is configured for typescript_fullstack tasks.
    """

    def __init__(self, **data):
        """Initialize the TypeScript Full Stack Developer agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "TypeScript Full Stack Developer"
        if "type" not in data:
            data["type"] = AgentType.PROGRAMMING
        if "description" not in data:
            data["description"] = "Expert in TypeScript full-stack development"
        if "tags" not in data:
            data["tags"] = ["programming_agent"]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="typescript_fullstack",
                description="Specialized capability for typescript_fullstack",
                parameters={},
                required=True,
            )
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "typescript_fullstack",
                "category": "programming",
                "index": 3,
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "typescript_fullstack",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "typescript_full_stack_developer",
            "description": "Expert in TypeScript full-stack development",
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
