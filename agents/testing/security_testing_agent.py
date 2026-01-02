"""
Security Testing Agent

Expert in security testing and vulnerability assessment

Specialization: security_testing
Type: testing

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class SecurityTestingAgent(BaseAgent):
    """
    Security Testing Agent - Expert in security testing and vulnerability assessment

    Specialized in comprehensive security testing including penetration testing,
    vulnerability scanning, security code analysis, and compliance validation.
    Focuses on identifying security weaknesses and ensuring robust security posture.
    """

    def __init__(self, **data):
        """Initialize the Security Testing agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Security Testing Specialist"
        if "type" not in data:
            data["type"] = AgentType.TESTING
        if "description" not in data:
            data["description"] = (
                "Expert in security testing with focus on penetration testing, vulnerability assessment, security code analysis, and compliance validation for web applications, APIs, and enterprise systems"
            )
        if "tags" not in data:
            data["tags"] = [
                "security_testing",
                "penetration_testing",
                "vulnerability_assessment",
                "compliance",
                "secure_coding",
            ]

        # Initialize parent
        super().__init__(**data)

        # Add capabilities
        self.capabilities.extend(
            [
                "penetration_testing",
                "vulnerability_scanning",
                "security_code_analysis",
                "authentication_testing",
                "authorization_testing",
                "injection_testing",
                "xss_detection",
                "csrf_testing",
                "security_headers_analysis",
                "compliance_validation",
            ]
        )

        # Configure tools
        self.config.tools.extend(
            [
                "owasp_zap",
                "burp_suite",
                "nessus",
                "nmap",
                "metasploit",
                "sqlmap",
                "sonarqube",
                "bandit",
                "semgrep",
                "checkmarx",
            ]
        )

        # Configure custom settings
        self.config.custom_settings.update(
            {
                "security_scanners": ["owasp_zap", "burp_suite", "nessus"],
                "code_analysis_tools": ["sonarqube", "bandit", "semgrep", "checkmarx"],
                "penetration_tools": ["metasploit", "nmap", "sqlmap"],
                "compliance_standards": [
                    "owasp_top_10",
                    "sans_top_25",
                    "nist",
                    "iso_27001",
                ],
                "security_frameworks": ["nist_csf", "iso_27001", "soc_2", "pci_dss"],
                "vulnerability_types": [
                    "injection",
                    "xss",
                    "csrf",
                    "authentication",
                    "authorization",
                ],
                "risk_levels": ["critical", "high", "medium", "low", "info"],
                "reporting_formats": ["sarif", "pdf", "html", "json"],
            }
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "security_testing",
                "category": "testing",
                "test_types": [
                    "penetration",
                    "vulnerability",
                    "code_analysis",
                    "compliance",
                ],
                "standards": ["owasp_top_10", "sans_top_25", "nist", "iso_27001"],
                "vulnerabilities": [
                    "sql_injection",
                    "xss",
                    "csrf",
                    "authentication_bypass",
                ],
                "compliance": ["pci_dss", "hipaa", "gdpr", "soc_2"],
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a security testing task"""
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "security_testing",
            "task_type": "security_testing",
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "security_testing_agent",
            "description": "Expert in security testing and vulnerability assessment",
            "parameters": {
                "type": "object",
                "properties": {
                    "task_description": {
                        "type": "string",
                        "description": "Security testing task to perform",
                    },
                    "test_type": {
                        "type": "string",
                        "enum": [
                            "penetration",
                            "vulnerability_scan",
                            "code_analysis",
                            "compliance_check",
                        ],
                        "description": "Type of security test",
                    },
                    "target_scope": {
                        "type": "string",
                        "enum": [
                            "web_application",
                            "api",
                            "mobile_app",
                            "infrastructure",
                            "all",
                        ],
                        "description": "Scope of security testing",
                    },
                },
                "required": ["task_description"],
            },
        }
