"""
Technical Writer Agent

Technical documentation specialist

Specialization: technical_writing
Type: documentation

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class TechnicalWriterAgent(BaseAgent):
    """
    Technical Writer - Technical documentation specialist

    This specialized agent is configured for technical_writing tasks.
    """

    def __init__(self, **data):
        """Initialize the Technical Writer agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Technical Writer"
        if "type" not in data:
            data["type"] = AgentType.DOCUMENTATION
        if "description" not in data:
            data["description"] = (
                "Expert in technical documentation, user guides, and comprehensive documentation strategies with specialization in creating clear, concise, and comprehensive technical documentation for software projects, APIs, and systems"
            )
        if "tags" not in data:
            data["tags"] = [
                "documentation",
                "technical_writing",
                "user_guides",
                "api_docs",
                "documentation_strategy",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.extend(
            [
                "Technical documentation creation and structuring",
                "User guide and manual development",
                "API documentation writing and organization",
                "README and contribution guide creation",
                "Installation and setup documentation",
                "Troubleshooting and FAQ documentation",
                "Release notes and changelog generation",
                "Documentation template design",
                "Content organization and information architecture",
                "Documentation review and editing",
            ]
        )

        # Configure tools
        self.config.tools.extend(
            [
                "markdown_processor",
                "documentation_generator",
                "template_engine",
                "content_validator",
                "style_checker",
            ]
        )

        # Configure custom settings for documentation
        self.config.custom_settings.update(
            {
                "documentation_format": "markdown",
                "style_guide": "microsoft_manual_of_style",
                "target_audience": "developers",
                "technical_level": "intermediate",
                "include_code_examples": True,
                "generate_toc": True,
                "validation_rules": ["readability", "completeness", "accuracy"],
                "output_formats": ["md", "html", "pdf"],
                "template_library": "technical_docs",
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "technical_writing",
                "category": "documentation",
                "index": 1,
                "expertise_areas": [
                    "technical_docs",
                    "user_guides",
                    "api_documentation",
                    "documentation_strategy",
                ],
                "writing_style": "clear_concise_technical",
                "supported_formats": ["markdown", "html", "pdf", "docx"],
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a technical writing task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "technical_writing",
            "task_type": "documentation_creation",
            "output_format": "structured_documentation",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "technical_writer",
            "description": "Expert in technical documentation, user guides, and comprehensive documentation strategies",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Technical writing task to perform",
                    },
                    "target_audience": {
                        "type": "string",
                        "enum": ["developers", "end_users", "administrators", "mixed"],
                        "description": "Target audience for the documentation",
                    },
                    "documentation_type": {
                        "type": "string",
                        "enum": [
                            "user_guide",
                            "api_reference",
                            "installation_guide",
                            "troubleshooting",
                            "release_notes",
                        ],
                        "description": "Type of documentation to create",
                    },
                },
                "required": ["task_description"],
            },
        }
