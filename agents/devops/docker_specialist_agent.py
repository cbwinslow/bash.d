"""
Docker Specialist Agent

Expert in Docker containerization, orchestration, and container management

Specialization: docker_specialist
Type: devops

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class DockerSpecialistAgent(BaseAgent):
    """
    Docker Specialist - Expert in Docker containerization and orchestration

    This specialized agent is configured for containerization tasks including Dockerfile optimization,
    multi-container setups, Docker Compose, and container orchestration best practices.
    """

    def __init__(self, **data):
        """Initialize the Docker Specialist agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Docker Specialist"
        if "type" not in data:
            data["type"] = AgentType.DEVOPS
        if "description" not in data:
            data["description"] = (
                "Expert in Docker containerization, orchestration, and container management"
            )
        if "tags" not in data:
            data["tags"] = [
                "docker",
                "containers",
                "devops",
                "orchestration",
                "microservices",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add DevOps-specific capabilities
        self.capabilities.extend(
            [
                "dockerfile_optimization",
                "multi_stage_builds",
                "container_security",
                "image_optimization",
                "docker_compose",
                "container_monitoring",
                "volume_management",
                "network_configuration",
                "container_scaling",
                "docker_registry_management",
            ]
        )

        # Set DevOps-specific tools
        self.config.tools.extend(
            [
                "docker_cli",
                "docker_compose",
                "container_monitoring",
                "image_scanner",
                "registry_manager",
            ]
        )

        # Set DevOps-specific configuration
        self.config.custom_settings.update(
            {
                "docker_version": "latest",
                "default_registry": "docker.io",
                "security_scan_enabled": True,
                "multi_architecture_builds": True,
                "container_monitoring": "prometheus",
                "orchestration_platform": "kubernetes",
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "docker_specialist",
                "category": "devops",
                "platforms": ["Docker", "Docker Compose", "Docker Swarm"],
                "certifications": ["Docker Certified Associate"],
                "expertise_level": "expert",
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a Docker specialization task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "docker_specialist",
            "capabilities_used": self.capabilities[:3],
            "tools_used": self.config.tools[:2],
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "docker_specialist",
            "description": "Expert in Docker containerization, orchestration, and container management",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Docker task to perform",
                    },
                    "container_type": {
                        "type": "string",
                        "enum": ["single", "multi", "microservices", "monolith"],
                        "description": "Type of container setup",
                    },
                    "optimization_focus": {
                        "type": "string",
                        "enum": ["size", "security", "performance", "build_time"],
                        "description": "Primary optimization goal",
                    },
                },
                "required": ["task_description"],
            },
        }
