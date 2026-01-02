"""
Performance Test Agent

Expert in performance testing and load testing methodologies

Specialization: performance_testing
Type: testing

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class PerformanceTestAgent(BaseAgent):
    """
    Performance Test Agent - Expert in performance testing and load testing methodologies

    Specialized in comprehensive performance testing including load testing,
    stress testing, scalability testing, and performance monitoring. Focuses on
    identifying bottlenecks, optimizing system performance, and ensuring reliability.
    """

    def __init__(self, **data):
        """Initialize the Performance Test agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Performance Test Specialist"
        if "type" not in data:
            data["type"] = AgentType.TESTING
        if "description" not in data:
            data["description"] = (
                "Expert in performance testing with focus on load testing, stress testing, scalability analysis, and performance optimization for web applications, APIs, and enterprise systems"
            )
        if "tags" not in data:
            data["tags"] = [
                "performance_testing",
                "load_testing",
                "stress_testing",
                "scalability",
                "optimization",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.extend(
            [
                "load_testing",
                "stress_testing",
                "endurance_testing",
                "spike_testing",
                "volume_testing",
                "scalability_analysis",
                "bottleneck_identification",
                "performance_monitoring",
                "capacity_planning",
                "benchmark_testing",
            ]
        )

        # Configure tools
        self.config.tools.extend(
            [
                "jmeter",
                "gatling",
                "k6",
                "locust",
                "artillery",
                "wrk",
                "hey",
                "boom",
                "apache_bench",
                "siege",
            ]
        )

        # Configure custom settings
        self.config.custom_settings.update(
            {
                "load_testing_tools": ["jmeter", "gatling", "k6", "locust"],
                "monitoring_tools": ["prometheus", "grafana", "new_relic", "datadog"],
                "performance_metrics": [
                    "response_time",
                    "throughput",
                    "cpu_usage",
                    "memory_usage",
                    "error_rate",
                ],
                "test_types": ["load", "stress", "endurance", "spike", "volume"],
                "concurrent_users": {"min": 10, "max": 10000},
                "duration_targets": {"short": 60, "medium": 300, "long": 3600},
                "response_time_sla": {"p50": 200, "p95": 500, "p99": 1000},
                "throughput_units": "requests_per_second",
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "performance_testing",
                "category": "testing",
                "test_types": ["load", "stress", "endurance", "spike", "volume"],
                "protocols": ["http", "https", "grpc", "websocket"],
                "metrics": [
                    "response_time",
                    "throughput",
                    "error_rate",
                    "resource_usage",
                ],
                "environments": ["staging", "production", "performance"],
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a performance testing task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "performance_testing",
            "task_type": "performance_testing",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "performance_test_agent",
            "description": "Expert in performance testing and load testing methodologies",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Performance testing task to perform",
                    },
                    "test_type": {
                        "type": "string",
                        "enum": ["load", "stress", "endurance", "spike", "volume"],
                        "description": "Type of performance test",
                    },
                    "concurrent_users": {
                        "type": "integer",
                        "minimum": 1,
                        "description": "Number of concurrent users to simulate",
                    },
                },
                "required": ["task_description"],
            },
        }
