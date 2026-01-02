"""
Markdown Specialist Agent

Expert in Markdown formatting, documentation structuring, and content conversion

Specialization: markdown_specialist
Type: documentation

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class MarkdownSpecialistAgent(BaseAgent):
    """
    Markdown Specialist - Expert in Markdown formatting, documentation structuring, and content conversion

    This specialized agent is configured for markdown_specialist tasks with expertise in creating
    well-structured Markdown documents, converting between different documentation formats,
    optimizing content for various Markdown renderers, and implementing advanced Markdown features.
    """

    def __init__(self, **data):
        """Initialize the Markdown Specialist agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Markdown Specialist"
        if "type" not in data:
            data["type"] = AgentType.DOCUMENTATION
        if "description" not in data:
            data["description"] = (
                "Expert in Markdown formatting, documentation structuring, and content conversion with specialization in creating well-structured Markdown documents, converting between different documentation formats, optimizing content for various Markdown renderers, and implementing advanced Markdown features"
            )
        if "tags" not in data:
            data["tags"] = [
                "documentation",
                "markdown",
                "formatting",
                "content_conversion",
                "documentation_structuring",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.extend(
            [
                "Advanced Markdown formatting and syntax",
                "Documentation structure and organization",
                "Content conversion between formats",
                "Markdown table and list optimization",
                "Code block and syntax highlighting",
                "Link management and reference formatting",
                "Image and media embedding optimization",
                "Cross-platform Markdown compatibility",
                "Markdown extensions and plugins utilization",
                "Template and reusable component creation",
            ]
        )

        # Configure tools
        self.config.tools.extend(
            [
                "markdown_processor",
                "format_converter",
                "structure_validator",
                "link_checker",
                "template_manager",
            ]
        )

        # Configure custom settings for Markdown specialization
        self.config.custom_settings.update(
            {
                "markdown_flavor": "github_flavored",
                "output_format": "gfm",
                "syntax_highlighting": "prism",
                "table_formatting": "aligned",
                "link_style": "reference",
                "image_optimization": True,
                "code_block_formatting": "language_specific",
                "toc_generation": True,
                "cross_reference_links": True,
                "compatibility_mode": "github",
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "markdown_specialist",
                "category": "documentation",
                "index": 4,
                "expertise_areas": [
                    "markdown_formatting",
                    "content_conversion",
                    "documentation_structuring",
                    "advanced_syntax",
                ],
                "supported_flavors": [
                    "gfm",
                    "commonmark",
                    "markdown_extra",
                    "multimarkdown",
                ],
                "output_formats": ["md", "html", "pdf", "docx", "latex"],
                "extensions_used": [
                    "tables",
                    "fenced_code",
                    "autolink",
                    "strikethrough",
                    "task_lists",
                ],
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a Markdown specialist task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "markdown_specialist",
            "task_type": "markdown_formatting_conversion",
            "output_format": "optimized_markdown",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "markdown_specialist",
            "description": "Expert in Markdown formatting, documentation structuring, and content conversion",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Markdown specialist task to perform",
                    },
                    "markdown_flavor": {
                        "type": "string",
                        "enum": [
                            "gfm",
                            "commonmark",
                            "markdown_extra",
                            "multimarkdown",
                        ],
                        "description": "Markdown flavor to use",
                    },
                    "conversion_target": {
                        "type": "string",
                        "enum": ["html", "pdf", "docx", "latex", " restructuring"],
                        "description": "Target format for conversion or restructuring",
                    },
                    "optimization_focus": {
                        "type": "string",
                        "enum": [
                            "readability",
                            "compatibility",
                            "features",
                            "performance",
                        ],
                        "description": "Focus area for Markdown optimization",
                    },
                },
                "required": ["task_description"],
            },
        }
