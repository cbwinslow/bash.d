"""
CI/CD Pipeline Agent

Expert in building and optimizing continuous integration and deployment pipelines

Specialization: cicd_pipeline
Type: devops

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class CicdPipelineAgent(BaseAgent):
    """
    CI/CD Pipeline Engineer - Expert in building and optimizing CI/CD pipelines

    This specialized agent is configured for CI/CD tasks including pipeline design,
    automation, testing integration, and deployment optimization.
    """

    def __init__(self, **data):
        """Initialize the CI/CD Pipeline agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "CI/CD Pipeline Engineer"
        if "type" not in data:
            data["type"] = AgentType.DEVOPS
        if "description" not in data:
            data["description"] = (
                "Expert in building and optimizing continuous integration and deployment pipelines"
            )
        if "tags" not in data:
            data["tags"] = [
                "cicd",
                "pipeline",
                "automation",
                "deployment",
                "integration",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add DevOps-specific capabilities
        self.capabilities.extend(
            [
                "pipeline_design",
                "build_optimization",
                "test_automation",
                "deployment_strategies",
                "artifact_management",
                "pipeline_security",
                "monitoring_alerting",
                "rollback_procedures",
                "multi_branch",
                "performance_testing",
            ]
        )

        # Set DevOps-specific tools
        self.config.tools.extend(
            ["jenkins", "github_actions", "gitlab_ci", "azure_pipelines", "artifactory"]
        )

        # Set DevOps-specific configuration
        self.config.custom_settings.update(
            {
                "primary_platform": "github_actions",
                "artifact_repository": "artifactory",
                "test_framework": "pytest_junit",
                "deployment_strategy": "blue_green",
                "security_scanning": True,
                "parallel_execution": True,
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "cicd_pipeline",
                "category": "devops",
                "platforms": [
                    "Jenkins",
                    "GitHub Actions",
                    "GitLab CI",
                    "Azure Pipelines",
                ],
                "certifications": ["AWS DevOps Engineer", "Azure DevOps Engineer"],
                "expertise_level": "expert",
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a CI/CD pipeline specialization task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "cicd_pipeline",
            "capabilities_used": self.capabilities[:3],
            "tools_used": self.config.tools[:2],
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "cicd_pipeline_engineer",
            "description": "Expert in building and optimizing continuous integration and deployment pipelines",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "CI/CD task to perform",
                    },
                    "pipeline_type": {
                        "type": "string",
                        "enum": ["build", "deploy", "test", "security", "monitoring"],
                        "description": "Type of pipeline to create or optimize",
                    },
                    "platform": {
                        "type": "string",
                        "enum": [
                            "github_actions",
                            "gitlab_ci",
                            "jenkins",
                            "azure_pipelines",
                        ],
                        "description": "CI/CD platform to use",
                    },
                },
                "required": ["task_description"],
            },
        }
