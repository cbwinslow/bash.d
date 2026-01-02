"""
API Documentation Agent

Expert in API reference documentation, endpoint specifications, and interactive API guides

Specialization: api_documentation
Type: documentation

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class ApiDocumentationAgent(BaseAgent):
    """
    API Documentation Agent - Expert in API reference documentation, endpoint specifications, and interactive API guides

    This specialized agent is configured for api_documentation tasks with expertise in creating
    comprehensive API documentation including OpenAPI/Swagger specifications, endpoint references,
    authentication guides, and interactive API explorers.
    """

    def __init__(self, **data):
        """Initialize the API Documentation agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "API Documentation Specialist"
        if "type" not in data:
            data["type"] = AgentType.DOCUMENTATION
        if "description" not in data:
            data["description"] = (
                "Expert in API reference documentation, endpoint specifications, and interactive API guides with specialization in creating comprehensive API documentation including OpenAPI/Swagger specifications, endpoint references, authentication guides, and interactive API explorers"
            )
        if "tags" not in data:
            data["tags"] = [
                "documentation",
                "api_docs",
                "openapi",
                "swagger",
                "endpoint_documentation",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.extend(
            [
                "OpenAPI/Swagger specification generation",
                "API endpoint documentation and reference",
                "Interactive API guide creation",
                "Authentication and authorization documentation",
                "Request/response example generation",
                "Error code and status code documentation",
                "API versioning documentation",
                "Rate limiting and usage policies documentation",
                "SDK and client library documentation",
                "API testing and validation documentation",
            ]
        )

        # Configure tools
        self.config.tools.extend(
            [
                "openapi_generator",
                "swagger_ui_builder",
                "endpoint_analyzer",
                "authentication_mapper",
                "example_generator",
            ]
        )

        # Configure custom settings for API documentation
        self.config.custom_settings.update(
            {
                "specification_format": "openapi_3_0",
                "documentation_style": "developer_focused",
                "include_interactive_examples": True,
                "generate_code_samples": True,
                "supported_languages": [
                    "javascript",
                    "python",
                    "curl",
                    "java",
                    "csharp",
                ],
                "authentication_types": [
                    "oauth2",
                    "api_key",
                    "bearer_token",
                    "basic_auth",
                ],
                "error_formatting": "http_status_codes",
                "response_formatting": "json_schema",
                "testing_framework": "postman_collection",
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "api_documentation",
                "category": "documentation",
                "index": 2,
                "expertise_areas": [
                    "api_reference",
                    "openapi",
                    "swagger",
                    "endpoint_docs",
                    "authentication_guides",
                ],
                "specification_standards": ["openapi_3_0", "swagger_2_0", "raml"],
                "interactive_tools": ["swagger_ui", "redoc", "stoplight"],
                "code_sample_languages": [
                    "javascript",
                    "python",
                    "curl",
                    "java",
                    "csharp",
                    "php",
                    "ruby",
                    "go",
                ],
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute an API documentation task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "api_documentation",
            "task_type": "api_reference_creation",
            "output_format": "openapi_specification",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "api_documentation_specialist",
            "description": "Expert in API reference documentation, endpoint specifications, and interactive API guides",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "API documentation task to perform",
                    },
                    "specification_format": {
                        "type": "string",
                        "enum": ["openapi_3_0", "swagger_2_0", "raml"],
                        "description": "API specification format to use",
                    },
                    "documentation_type": {
                        "type": "string",
                        "enum": ["reference", "guide", "tutorial", "interactive"],
                        "description": "Type of API documentation to create",
                    },
                },
                "required": ["task_description"],
            },
        }
