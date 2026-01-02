"""
Cloud Engineer Agent

Expert in cloud services implementation, migration, and optimization across major cloud platforms

Specialization: cloud_engineer
Type: devops

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class CloudEngineerAgent(BaseAgent):
    """
    Cloud Engineer - Expert in cloud services implementation and optimization

    This specialized agent is configured for cloud engineering tasks including migration,
    service deployment, cost optimization, and cloud-native application development.
    """

    def __init__(self, **data):
        """Initialize the Cloud Engineer agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Cloud Engineer"
        if "type" not in data:
            data["type"] = AgentType.DEVOPS
        if "description" not in data:
            data["description"] = (
                "Expert in cloud services implementation, migration, and optimization across major cloud platforms"
            )
        if "tags" not in data:
            data["tags"] = ["cloud", "aws", "azure", "gcp", "migration"]

        # Initialize parent
        super().__init__(**data)

        # Add DevOps-specific capabilities
        self.capabilities.extend(
            [
                "cloud_migration",
                "service_deployment",
                "cost_optimization",
                "serverless_architecture",
                "cloud_monitoring",
                "auto_scaling",
                "cloud_security",
                "backup_disaster",
                "multi_cloud",
                "api_gateway",
            ]
        )

        # Set DevOps-specific tools
        self.config.tools.extend(
            ["aws_cli", "azure_cli", "gcloud_cli", "cloudformation", "terraform_cloud"]
        )

        # Set DevOps-specific configuration
        self.config.custom_settings.update(
            {
                "primary_cloud": "aws",
                "regions": ["us-east-1", "eu-west-1", "ap-southeast-1"],
                "cost_monitoring": True,
                "auto_scaling": True,
                "serverless_platform": "aws_lambda",
                "monitoring_tool": "cloudwatch",
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "cloud_engineer",
                "category": "devops",
                "platforms": ["AWS", "Azure", "GCP", "Oracle Cloud", "IBM Cloud"],
                "certifications": [
                    "AWS Certified DevOps Engineer",
                    "Azure DevOps Engineer",
                    "Google Professional Cloud Engineer",
                ],
                "expertise_level": "expert",
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a cloud engineering specialization task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "cloud_engineer",
            "capabilities_used": self.capabilities[:3],
            "tools_used": self.config.tools[:2],
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "cloud_engineer",
            "description": "Expert in cloud services implementation, migration, and optimization across major cloud platforms",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Cloud engineering task to perform",
                    },
                    "cloud_platform": {
                        "type": "string",
                        "enum": ["aws", "azure", "gcp", "multi_cloud"],
                        "description": "Cloud platform to work with",
                    },
                    "service_type": {
                        "type": "string",
                        "enum": [
                            "compute",
                            "storage",
                            "networking",
                            "database",
                            "serverless",
                        ],
                        "description": "Type of cloud service to work with",
                    },
                },
                "required": ["task_description"],
            },
        }
