"""
C++ Performance Developer Agent

Expert in C++ performance-critical development

Specialization: cpp_performance
Type: programming

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class CppPerformanceDeveloperAgent(BaseAgent):
    """
    C++ Performance Developer - Expert in C++ performance-critical development

    This specialized agent is configured for cpp_performance tasks.
    """

    def __init__(self, **data):
        """Initialize the C++ Performance Developer agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "C++ Performance Developer"
        if "type" not in data:
            data["type"] = AgentType.PROGRAMMING
        if "description" not in data:
            data["description"] = "Expert in C++ performance-critical development"
        if "tags" not in data:
            data["tags"] = ["programming_agent"]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="cpp_performance",
                description="Specialized capability for cpp_performance",
                parameters={},
                required=True,
            )
        )

        # Add metadata
        self.metadata.update(
            {"specialization": "cpp_performance", "category": "programming", "index": 8}
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "cpp_performance",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "cpp_performance_developer",
            "description": "Expert in C++ performance-critical development",
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
