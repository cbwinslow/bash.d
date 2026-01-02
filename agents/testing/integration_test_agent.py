"""
Integration Test Agent

Expert in integration testing and system component testing

Specialization: integration_testing
Type: testing

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class IntegrationTestAgent(BaseAgent):
    """
    Integration Test Agent - Expert in integration testing and system component testing

    Specialized in designing and executing integration tests that verify
    interactions between different system components, APIs, databases,
    and external services. Focuses on end-to-end workflows and system reliability.
    """

    def __init__(self, **data):
        """Initialize the Integration Test agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Integration Test Specialist"
        if "type" not in data:
            data["type"] = AgentType.TESTING
        if "description" not in data:
            data["description"] = (
                "Expert in integration testing methodologies with focus on API testing, database integration, service communication, and end-to-end system validation"
            )
        if "tags" not in data:
            data["tags"] = [
                "integration_testing",
                "api_testing",
                "system_testing",
                "service_integration",
                "end_to_end",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.extend(
            [
                "api_integration_testing",
                "database_integration_testing",
                "service_communication_testing",
                "message_queue_testing",
                "contract_testing",
                "workflow_validation",
                "dependency_injection_testing",
                "microservices_testing",
                "system_boundary_testing",
                "integration_scenario_design",
            ]
        )

        # Configure tools
        self.config.tools.extend(
            [
                "postman",
                "newman",
                "rest_assured",
                "insomnia",
                "soap_ui",
                "docker_compose",
                "testcontainers",
                "wiremock",
                "mountebank",
                "pact",
            ]
        )

        # Configure custom settings
        self.config.custom_settings.update(
            {
                "api_testing_tools": ["postman", "rest_assured", "newman"],
                "database_testing": ["postgresql", "mysql", "mongodb", "redis"],
                "message_systems": ["rabbitmq", "kafka", "activemq"],
                "container_orchestration": "docker_compose",
                "contract_testing": "pact",
                "mock_servers": ["wiremock", "mountebank"],
                "service_discovery": "consul",
                "monitoring": ["prometheus", "grafana"],
                "log_analysis": ["elk_stack", "fluentd"],
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "integration_testing",
                "category": "testing",
                "test_types": ["api", "database", "message_queue", "microservices"],
                "protocols": ["http", "https", "grpc", "websocket", "amqp"],
                "environments": ["development", "staging", "integration"],
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute an integration testing task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "integration_testing",
            "task_type": "integration_testing",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "integration_test_agent",
            "description": "Expert in integration testing and system component testing",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Integration testing task to perform",
                    },
                    "test_scope": {
                        "type": "string",
                        "enum": [
                            "api",
                            "database",
                            "message_queue",
                            "microservices",
                            "full_system",
                        ],
                        "description": "Scope of integration testing",
                    },
                    "environment": {
                        "type": "string",
                        "enum": ["development", "staging", "integration"],
                        "description": "Target testing environment",
                    },
                },
                "required": ["task_description"],
            },
        }
