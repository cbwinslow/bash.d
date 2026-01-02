"""
Ruby Rails Developer Agent

Expert in Ruby on Rails web application development

Specialization: ruby_rails
Type: programming

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class RubyRailsDeveloperAgent(BaseAgent):
    """
    Ruby Rails Developer - Expert in Ruby on Rails web application development

    This specialized agent is configured for ruby_rails tasks.
    """

    def __init__(self, **data):
        """Initialize the Ruby Rails Developer agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Ruby Rails Developer"
        if "type" not in data:
            data["type"] = AgentType.PROGRAMMING
        if "description" not in data:
            data["description"] = "Expert in Ruby on Rails web application development"
        if "tags" not in data:
            data["tags"] = ["programming_agent"]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="ruby_rails",
                description="Specialized capability for ruby_rails",
                parameters={},
                required=True,
            )
        )

        # Add metadata
        self.metadata.update(
            {"specialization": "ruby_rails", "category": "programming", "index": 10}
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "ruby_rails",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "ruby_rails_developer",
            "description": "Expert in Ruby on Rails web application development",
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
