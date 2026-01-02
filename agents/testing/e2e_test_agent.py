"""
E2E Test Agent

Expert in end-to-end testing and user journey validation

Specialization: e2e_testing
Type: testing

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class E2ETestAgent(BaseAgent):
    """
    E2E Test Agent - Expert in end-to-end testing and user journey validation

    Specialized in comprehensive end-to-end testing that validates entire
    user workflows from start to finish. Focuses on user experience testing,
    cross-platform validation, and real-world scenario testing.
    """

    def __init__(self, **data):
        """Initialize the E2E Test agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "E2E Test Specialist"
        if "type" not in data:
            data["type"] = AgentType.TESTING
        if "description" not in data:
            data["description"] = (
                "Expert in end-to-end testing with focus on user journey validation, cross-platform testing, and comprehensive workflow testing across web, mobile, and desktop applications"
            )
        if "tags" not in data:
            data["tags"] = [
                "e2e_testing",
                "user_journey",
                "cross_platform",
                "ui_testing",
                "automation",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.extend(
            [
                "user_journey_testing",
                "cross_browser_testing",
                "mobile_app_testing",
                "desktop_application_testing",
                "visual_regression_testing",
                "accessibility_testing",
                "workflow_automation",
                "real_user_simulation",
                "performance_validation",
                "user_experience_testing",
            ]
        )

        # Configure tools
        self.config.tools.extend(
            [
                "selenium",
                "playwright",
                "cypress",
                "testcafe",
                "puppeteer",
                "appium",
                "detox",
                "webdriverio",
                "percy",
                "applitools",
            ]
        )

        # Configure custom settings
        self.config.custom_settings.update(
            {
                "web_automation": ["selenium", "playwright", "cypress", "puppeteer"],
                "mobile_testing": ["appium", "detox", "xcuitest", "espresso"],
                "browsers": ["chrome", "firefox", "safari", "edge"],
                "mobile_platforms": ["ios", "android"],
                "visual_testing": ["percy", "applitools", "backstopjs"],
                "accessibility_standards": ["wcag_2.1", "section_508"],
                "headless_execution": True,
                "parallel_execution": True,
                "real_device_testing": True,
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "e2e_testing",
                "category": "testing",
                "platforms": ["web", "mobile", "desktop"],
                "browsers": ["chrome", "firefox", "safari", "edge"],
                "mobile_os": ["ios", "android"],
                "testing_types": [
                    "functional",
                    "visual",
                    "accessibility",
                    "performance",
                ],
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute an E2E testing task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "e2e_testing",
            "task_type": "e2e_testing",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "e2e_test_agent",
            "description": "Expert in end-to-end testing and user journey validation",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "E2E testing task to perform",
                    },
                    "platform": {
                        "type": "string",
                        "enum": ["web", "mobile", "desktop", "all"],
                        "description": "Target platform for testing",
                    },
                    "user_journey": {
                        "type": "string",
                        "description": "Specific user journey or workflow to test",
                    },
                },
                "required": ["task_description"],
            },
        }
