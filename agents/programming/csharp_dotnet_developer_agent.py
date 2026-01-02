"""
C# .NET Developer Agent

Expert in C# and .NET application development

Specialization: csharp_dotnet
Type: programming

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class CSharpDotNetDeveloperAgent(BaseAgent):
    """
    C# .NET Developer - Expert in C# and .NET application development

    This specialized agent is configured for csharp_dotnet tasks.
    """

    def __init__(self, **data):
        """Initialize the C# .NET Developer agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "C# .NET Developer"
        if "type" not in data:
            data["type"] = AgentType.PROGRAMMING
        if "description" not in data:
            data["description"] = "Expert in C# and .NET application development"
        if "tags" not in data:
            data["tags"] = ["programming_agent"]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="csharp_dotnet",
                description="Specialized capability for csharp_dotnet",
                parameters={},
                required=True,
            )
        )

        # Add metadata
        self.metadata.update(
            {"specialization": "csharp_dotnet", "category": "programming", "index": 7}
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "csharp_dotnet",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "csharp_dotnet_developer",
            "description": "Expert in C# and .NET application development",
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
