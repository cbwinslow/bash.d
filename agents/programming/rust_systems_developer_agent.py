"""
Rust Systems Developer Agent

Expert in Rust systems programming

Specialization: rust_systems
Type: programming

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class RustSystemsDeveloperAgent(BaseAgent):
    """
    Rust Systems Developer - Expert in Rust systems programming

    This specialized agent is configured for rust_systems tasks.
    """

    def __init__(self, **data):
        """Initialize the Rust Systems Developer agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Rust Systems Developer"
        if "type" not in data:
            data["type"] = AgentType.PROGRAMMING
        if "description" not in data:
            data["description"] = "Expert in Rust systems programming"
        if "tags" not in data:
            data["tags"] = ["programming_agent"]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="rust_systems",
                description="Specialized capability for rust_systems",
                parameters={},
                required=True,
            )
        )

        # Add metadata
        self.metadata.update(
            {"specialization": "rust_systems", "category": "programming", "index": 4}
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "rust_systems",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "rust_systems_developer",
            "description": "Expert in Rust systems programming",
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
