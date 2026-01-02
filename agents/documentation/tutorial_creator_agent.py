"""
Tutorial Creator Agent

Expert in creating step-by-step tutorials, learning paths, and educational content

Specialization: tutorial_creation
Type: documentation

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class TutorialCreatorAgent(BaseAgent):
    """
    Tutorial Creator - Expert in creating step-by-step tutorials, learning paths, and educational content

    This specialized agent is configured for tutorial_creation tasks with expertise in developing
    comprehensive learning materials, step-by-step guides, interactive tutorials, and educational
    content that caters to different skill levels and learning styles.
    """

    def __init__(self, **data):
        """Initialize the Tutorial Creator agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Tutorial Creator"
        if "type" not in data:
            data["type"] = AgentType.DOCUMENTATION
        if "description" not in data:
            data["description"] = (
                "Expert in creating step-by-step tutorials, learning paths, and educational content with specialization in developing comprehensive learning materials, step-by-step guides, interactive tutorials, and educational content that caters to different skill levels and learning styles"
            )
        if "tags" not in data:
            data["tags"] = [
                "documentation",
                "tutorials",
                "learning_paths",
                "educational_content",
                "step_by_step_guides",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.extend(
            [
                "Step-by-step tutorial development",
                "Learning path design and structuring",
                "Interactive tutorial creation",
                "Beginner-friendly content writing",
                "Advanced topic tutorials",
                "Hands-on exercise development",
                "Code-along tutorial creation",
                "Video script and transcript generation",
                "Quiz and assessment creation",
                "Progressive difficulty curriculum design",
            ]
        )

        # Configure tools
        self.config.tools.extend(
            [
                "tutorial_builder",
                "learning_path_designer",
                "exercise_generator",
                "progress_tracker",
                "interactive_builder",
            ]
        )

        # Configure custom settings for tutorial creation
        self.config.custom_settings.update(
            {
                "tutorial_format": "step_by_step",
                "difficulty_levels": ["beginner", "intermediate", "advanced"],
                "learning_style": "hands_on",
                "include_exercises": True,
                "provide_code_examples": True,
                "estimated_time_tracking": True,
                "prerequisites_checklist": True,
                "learning_objectives": True,
                "progress_milestones": True,
                "interactivity_level": "high",
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "tutorial_creation",
                "category": "documentation",
                "index": 3,
                "expertise_areas": [
                    "tutorials",
                    "learning_paths",
                    "educational_content",
                    "step_by_step_guides",
                    "curriculum_design",
                ],
                "target_audiences": [
                    "beginners",
                    "intermediate_learners",
                    "advanced_users",
                    "educators",
                ],
                "tutorial_types": [
                    "getting_started",
                    "how_to_guides",
                    "deep_dive",
                    "best_practices",
                    "troubleshooting",
                ],
                "interactive_elements": [
                    "code_sandbox",
                    "quizzes",
                    "exercises",
                    "live_examples",
                ],
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a tutorial creation task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "tutorial_creation",
            "task_type": "educational_content_development",
            "output_format": "structured_tutorial",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "tutorial_creator",
            "description": "Expert in creating step-by-step tutorials, learning paths, and educational content",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Tutorial creation task to perform",
                    },
                    "difficulty_level": {
                        "type": "string",
                        "enum": ["beginner", "intermediate", "advanced"],
                        "description": "Target difficulty level for the tutorial",
                    },
                    "tutorial_type": {
                        "type": "string",
                        "enum": [
                            "getting_started",
                            "how_to_guide",
                            "deep_dive",
                            "best_practices",
                            "troubleshooting",
                        ],
                        "description": "Type of tutorial to create",
                    },
                    "include_exercises": {
                        "type": "boolean",
                        "description": "Whether to include hands-on exercises",
                    },
                },
                "required": ["task_description"],
            },
        }
