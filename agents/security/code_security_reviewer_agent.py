"""
Code Security Reviewer Agent

Security-focused code review

Specialization: code_review
Type: security

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class CodeSecurityReviewerAgent(BaseAgent):
    """
    Code Security Reviewer - Security-focused code review
    
    This specialized agent is configured for code_review tasks.
    """
    
    def __init__(self, **data):
        """Initialize the Code Security Reviewer agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "Code Security Reviewer"
        if "type" not in data:
            data["type"] = AgentType.SECURITY
        if "description" not in data:
            data["description"] = "Security-focused code review"
        if "tags" not in data:
            data["tags"] = ["security_agent"]
        
        # Initialize parent
        super().__init__(**data)
        
        # Add capabilities
        self.capabilities.append(
            AgentCapability(
                name="code_review",
                description="Specialized capability for code_review",
                parameters={},
                required=True
            )
        )
        
        # Add metadata
        self.metadata.update({
            "specialization": "code_review",
            "category": "security",
            "index": 10
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "code_review"
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "code_security_reviewer",
            "description": "Security-focused code review",
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
