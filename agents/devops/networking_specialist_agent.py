"""
Networking Specialist Agent

Expert in network architecture, security, and optimization for cloud and on-premise environments

Specialization: networking_specialist
Type: devops

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class NetworkingSpecialistAgent(BaseAgent):
    """
    Networking Specialist - Expert in network architecture and security

    This specialized agent is configured for networking tasks including network design,
    security implementation, performance optimization, and troubleshooting.
    """

    def __init__(self, **data):
        """Initialize the Networking Specialist agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Networking Specialist"
        if "type" not in data:
            data["type"] = AgentType.DEVOPS
        if "description" not in data:
            data["description"] = (
                "Expert in network architecture, security, and optimization for cloud and on-premise environments"
            )
        if "tags" not in data:
            data["tags"] = [
                "networking",
                "security",
                "firewall",
                "cdn",
                "load_balancer",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add DevOps-specific capabilities
        self.capabilities.extend(
            [
                "network_design",
                "firewall_configuration",
                "load_balancing",
                "cdn_setup",
                "vpn_configuration",
                "network_monitoring",
                "dns_management",
                "traffic_analysis",
                "network_security",
                "bandwidth_optimization",
            ]
        )

        # Set DevOps-specific tools
        self.config.tools.extend(
            [
                "wireshark",
                "nmap",
                "ansible_networking",
                "terraform_networking",
                "prometheus_network",
            ]
        )

        # Set DevOps-specific configuration
        self.config.custom_settings.update(
            {
                "primary_vendor": "cisco",
                "monitoring_tool": "prometheus_grafana",
                "firewall_type": "next_gen",
                "load_balancer": "nginx",
                "cdn_provider": "cloudflare",
                "dns_provider": "route53",
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "networking_specialist",
                "category": "devops",
                "platforms": ["Cisco", "Juniper", "AWS VPC", "Azure VNet", "GCP VPC"],
                "certifications": [
                    "CCNP",
                    "AWS Advanced Networking",
                    "Azure Network Engineer",
                ],
                "expertise_level": "expert",
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a networking specialization task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "networking_specialist",
            "capabilities_used": self.capabilities[:3],
            "tools_used": self.config.tools[:2],
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "networking_specialist",
            "description": "Expert in network architecture, security, and optimization for cloud and on-premise environments",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Networking task to perform",
                    },
                    "network_type": {
                        "type": "string",
                        "enum": ["cloud", "on-premise", "hybrid", "edge", "sd-wan"],
                        "description": "Type of network environment",
                    },
                    "focus_area": {
                        "type": "string",
                        "enum": [
                            "security",
                            "performance",
                            "scalability",
                            "monitoring",
                            "troubleshooting",
                        ],
                        "description": "Primary focus area for the networking task",
                    },
                },
                "required": ["task_description"],
            },
        }
