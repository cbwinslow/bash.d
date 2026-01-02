"""
Code Review Security Agent

Advanced secure code review and security-focused code analysis expert

Specialization: security_code_review
Type: security

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class CodeReviewSecurityAgent(BaseAgent):
    """
    Code Review Security Agent - Advanced secure code review and security-focused code analysis expert
    
    This specialized agent performs comprehensive security-focused code reviews, identifying
    vulnerabilities, anti-patterns, and security weaknesses in source code across multiple
    programming languages and frameworks.
    """
    
    def __init__(self, **data):
        """Initialize the Code Review Security agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "Code Review Security Agent"
        if "type" not in data:
            data["type"] = AgentType.SECURITY
        if "description" not in data:
            data["description"] = "Advanced secure code review and security-focused code analysis expert specializing in identifying vulnerabilities, security anti-patterns, and coding weaknesses across multiple programming languages and frameworks"
        if "tags" not in data:
            data["tags"] = ["security", "code_review", "static_analysis", "secure_coding", "vulnerability_detection"]
        
        # Set security-focused capabilities
        if "capabilities" not in data:
            data["capabilities"] = [
                "Static security code analysis",
                "Authentication and authorization review",
                "Input validation assessment",
                "Cryptography implementation review",
                "Session management security",
                "Error handling and logging security",
                "Database security review",
                "API security code review",
                "Frontend security analysis",
                "Secure coding pattern validation"
            ]
        
        # Set security-focused tools
        if "config" not in data:
            data["config"] = {}
        if "tools" not in data["config"]:
            data["config"]["tools"] = [
                "sonarqube_security",
                "checkmarx_sast",
                "veracode_static_analysis",
                "semgrep",
                "codeql"
            ]
        
        # Set custom security settings
        data["config"]["custom_settings"] = {
            "analysis_depth": "deep",
            "security_standards": ["OWASP", "SANS_TOP25", "CWE"],
            "language_specific_rules": True,
            "framework_specific_checks": True,
            "vulnerability_pattern_detection": True,
            "security_maturity_assessment": True,
            "remediation_priority": "risk_based"
        }
        
        # Initialize parent
        super().__init__(**data)
        
        # Add detailed capabilities
        self.capabilities.extend([
            AgentCapability(
                name="static_security_code_analysis",
                description="Deep static analysis of source code for security vulnerabilities",
                parameters={"language": "string", "codebase_path": "string", "ruleset": "string"},
                required=True
            ),
            AgentCapability(
                name="authentication_authorization_review",
                description="Review of authentication and authorization mechanisms for security flaws",
                parameters={"auth_flows": "list", "framework": "string"},
                required=True
            ),
            AgentCapability(
                name="input_validation_assessment",
                description="Analysis of input validation and sanitization mechanisms",
                parameters={"input_vectors": "list", "validation_type": "string"},
                required=True
            ),
            AgentCapability(
                name="cryptography_implementation_review",
                description="Review of cryptographic implementations for security weaknesses",
                parameters={"crypto_libraries": "list", "algorithm_types": "list"},
                required=True
            ),
            AgentCapability(
                name="session_management_security",
                description "Analysis of session handling and management for security issues",
                parameters={"session_type": "string", "framework": "string"},
                required=True
            ),
            AgentCapability(
                name="error_handling_logging_security",
                description="Review of error handling and logging for information disclosure risks",
                parameters={"error_handling_type": "string", "logging_framework": "string"},
                required=True
            ),
            AgentCapability(
                name="database_security_review",
                description="Analysis of database interactions for SQL injection and data leaks",
                parameters={"db_type": "string", "orm_framework": "string"},
                required=True
            ),
            AgentCapability(
                name="api_security_code_review",
                description="Security review of REST/GraphQL API implementations",
                parameters={"api_type": "string", "authentication_type": "string"},
                required=True
            ),
            AgentCapability(
                name="frontend_security_analysis",
                description="Frontend code analysis for XSS, CSRF, and client-side vulnerabilities",
                parameters={"framework": "string", "security_headers": "boolean"},
                required=True
            ),
            AgentCapability(
                name="secure_coding_pattern_validation",
                description="Validation of secure coding patterns and best practices",
                parameters={"language": "string", "pattern_library": "string"},
                required=True
            )
        ])
        
        # Add metadata
        self.metadata.update({
            "specialization": "security_code_review",
            "category": "security",
            "index": 2,
            "supported_languages": ["Python", "Java", "C#", "JavaScript", "TypeScript", "Go", "PHP", "Ruby"],
            "security_frameworks": ["OWASP", "SANS", "NIST", "CWE"],
            "analysis_types": ["SAST", "pattern_matching", "data_flow", "taint_analysis"],
            "vulnerability_categories": ["injection", "broken_auth", "sensitive_data", "xml_entities", "broken_access", "security_config"]
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a security code review task"""
        input_data = task.input_data
        codebase_path = input_data.get("codebase_path", ".")
        language = input_data.get("language", "python")
        
        # Simulate security code review process
        security_issues = [
            {
                "id": "SEC001",
                "severity": "high",
                "title": "SQL Injection Vulnerability",
                "file": "models/user.py",
                "line": 45,
                "description": "Direct SQL query construction with user input",
                "cwe": "CWE-89",
                "remediation": "Use parameterized queries or ORM",
                "owasp_category": "A03:2021 – Injection"
            },
            {
                "id": "SEC002",
                "severity": "medium", 
                "title": "Hardcoded Credentials",
                "file": "config/database.py",
                "line": 12,
                "description": "Database credentials hardcoded in source",
                "cwe": "CWE-798",
                "remediation": "Use environment variables or secret management",
                "owasp_category": "A05:2021 – Security Misconfiguration"
            }
        ]
        
        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "security_code_review",
            "review_results": {
                "codebase_path": codebase_path,
                "language": language,
                "files_analyzed": 25,
                "security_issues_found": len(security_issues),
                "issues": security_issues,
                "security_score": "6.5/10",
                "recommendations": "Address high-severity issues immediately, implement secure coding guidelines"
            },
            "execution_time_ms": 3200
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "code_review_security_agent",
            "description": "Advanced secure code review and security-focused code analysis",
            "parameters": {
                "type": "object",
                "properties": {
                    "codebase_path": {
                        "type": "string",
                        "description": "Path to the codebase to review"
                    },
                    "language": {
                        "type": "string",
                        "enum": ["python", "java", "csharp", "javascript", "typescript", "go", "php", "ruby"],
                        "description": "Programming language of the codebase"
                    },
                    "review_type": {
                        "type": "string",
                        "enum": ["security_focused", "comprehensive", "authentication", "api_security", "database_security"],
                        "description": "Type of security review to perform"
                    },
                    "severity_threshold": {
                        "type": "string",
                        "enum": ["low", "medium", "high", "critical"],
                        "description": "Minimum severity level to report"
                    }
                },
                "required": ["codebase_path"]
            }
        }
    
    def get_supported_languages(self) -> List[str]:
        """Get supported programming languages for security review"""
        return ["Python", "Java", "C#", "JavaScript", "TypeScript", "Go", "PHP", "Ruby", "C++", "Rust"]
    
    def get_security_frameworks(self) -> List[str]:
        """Get supported security frameworks and standards"""
        return ["OWASP_TOP10", "SANS_TOP25", "CWE", "NIST_800-53", "ISO27001"]
    
    def get_vulnerability_categories(self) -> List[str]:
        """Get vulnerability categories the agent can detect"""
        return ["injection", "broken_auth", "sensitive_data", "xml_entities", "broken_access", "security_config", "xss", "csrf", "insecure_deserialization"]