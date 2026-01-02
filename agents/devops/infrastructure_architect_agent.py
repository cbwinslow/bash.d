"""
Infrastructure Architect Agent

Expert in designing scalable, secure, and cost-effective infrastructure solutions

Specialization: infrastructure_architect
Type: devops

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class InfrastructureArchitectAgent(BaseAgent):
    """
    Infrastructure Architect - Expert in designing scalable and secure infrastructure

    This specialized agent is configured for infrastructure design tasks including
    cloud architecture, security planning, cost optimization, and scalability strategies.
    """

    def __init__(self, **data):
        """Initialize the Infrastructure Architect agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Infrastructure Architect"
        if "type" not in data:
            data["type"] = AgentType.DEVOPS
        if "description" not in data:
            data["description"] = (
                "Expert in designing scalable, secure, and cost-effective infrastructure solutions"
            )
        if "tags" not in data:
            data["tags"] = [
                "infrastructure",
                "architecture",
                "cloud",
                "scalability",
                "security",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add DevOps-specific capabilities
        self.capabilities.extend(
            [
                "cloud_architecture",
                "scalability_planning",
                "security_design",
                "cost_optimization",
                "disaster_recovery",
                "compliance_governance",
                "network_design",
                "storage_architecture",
                "monitoring_strategy",
                "hybrid_cloud",
            ]
        )

        # Set DevOps-specific tools
        self.config.tools.extend(
            ["terraform", "cloudformation", "arm_templates", "ansible", "cost_analyzer"]
        )

        # Set DevOps-specific configuration
        self.config.custom_settings.update(
            {
                "primary_cloud": "aws",
                "iac_tool": "terraform",
                "compliance_framework": "SOC2",
                "backup_retention": "30_days",
                "cost_monitoring": True,
                "multi_region": True,
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "infrastructure_architect",
                "category": "devops",
                "platforms": ["AWS", "Azure", "GCP", "On-premises", "Hybrid"],
                "certifications": [
                    "AWS Solutions Architect",
                    "Azure Architect",
                    "TOGAF",
                ],
                "expertise_level": "expert",
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute an infrastructure architecture specialization task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "infrastructure_architect",
            "capabilities_used": self.capabilities[:3],
            "tools_used": self.config.tools[:2],
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "infrastructure_architect",
            "description": "Expert in designing scalable, secure, and cost-effective infrastructure solutions",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Infrastructure task to perform",
                    },
                    "infrastructure_type": {
                        "type": "string",
                        "enum": [
                            "cloud",
                            "hybrid",
                            "on-premise",
                            "edge",
                            "multi-cloud",
                        ],
                        "description": "Type of infrastructure to design",
                    },
                    "focus_area": {
                        "type": "string",
                        "enum": [
                            "scalability",
                            "security",
                            "cost",
                            "performance",
                            "compliance",
                        ],
                        "description": "Primary focus area for the architecture",
                    },
                },
                "required": ["task_description"],
            },
        }
