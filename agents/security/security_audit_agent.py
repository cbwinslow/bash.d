"""
Security Audit Agent

Comprehensive security audit and compliance assessment expert

Specialization: security_audit
Type: security

OpenAI Compatible: Yes
MCP Compatible: Yes
A2A Protocol: Enabled
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task


class SecurityAuditAgent(BaseAgent):
    """
    Security Audit Agent - Comprehensive security audit and compliance assessment expert

    This specialized agent performs thorough security audits, compliance assessments,
    and risk evaluations across organizations, applications, and infrastructure.
    It ensures adherence to security standards and regulatory requirements.
    """

    def __init__(self, **data):
        """Initialize the Security Audit agent"""

        # Set defaults
        if "name" not in data:
            data["name"] = "Security Audit Agent"
        if "type" not in data:
            data["type"] = AgentType.SECURITY
        if "description" not in data:
            data["description"] = (
                "Comprehensive security audit and compliance assessment expert specializing in thorough security evaluations, regulatory compliance checks, and risk assessments across organizations, applications, and infrastructure"
            )
        if "tags" not in data:
            data["tags"] = [
                "security",
                "audit",
                "compliance",
                "risk_assessment",
                "regulatory",
            ]

        # Set security-focused capabilities
        if "capabilities" not in data:
            data["capabilities"] = [
                "Security policy compliance assessment",
                "Regulatory compliance audit",
                "Access control audit",
                "Security configuration review",
                "Incident response procedure audit",
                "Data governance audit",
                "Vendor security assessment",
                "Physical security audit",
                "Security awareness program evaluation",
                "Risk assessment and management",
            ]

        # Set security-focused tools
        if "config" not in data:
            data["config"] = {}
        if "tools" not in data["config"]:
            data["config"]["tools"] = [
                "governance_risk_compliance",
                "audit_management_system",
                "compliance_checker",
                "risk_assessment_tool",
                "policy_enforcement_engine",
            ]

        # Set custom security settings
        data["config"]["custom_settings"] = {
            "audit_scope": "comprehensive",
            "compliance_standards": ["ISO27001", "SOC2", "PCI-DSS", "HIPAA", "GDPR"],
            "risk_framework": "NIST_CSF",
            "audit_frequency": "quarterly",
            "automated_compliance_checks": True,
            "evidence_collection": "automated",
            "reporting_format": "executive_summary",
        }

        # Initialize parent
        super().__init__(**data)

        # Add detailed capabilities
        self.capabilities.extend(
            [
                AgentCapability(
                    name="security_policy_compliance_assessment",
                    description="Evaluation of security policy implementation and adherence",
                    parameters={"policy_framework": "string", "department": "string"},
                    required=True,
                ),
                AgentCapability(
                    name="regulatory_compliance_audit",
                    description="Audit against regulatory requirements (HIPAA, GDPR, SOX, etc.)",
                    parameters={"regulation": "string", "scope": "string"},
                    required=True,
                ),
                AgentCapability(
                    name="access_control_audit",
                    description="Comprehensive audit of access controls and permissions",
                    parameters={"system_type": "string", "user_scope": "string"},
                    required=True,
                ),
                AgentCapability(
                    name="security_configuration_review",
                    description="Review of security configurations across infrastructure",
                    parameters={
                        "infrastructure_type": "string",
                        "configuration_standards": "list",
                    },
                    required=True,
                ),
                AgentCapability(
                    name="incident_response_procedure_audit",
                    description="Evaluation of incident response plans and procedures",
                    parameters={"plan_type": "string", "test_scenario": "string"},
                    required=True,
                ),
                AgentCapability(
                    name="data_governance_audit",
                    description="Audit of data handling, classification, and protection measures",
                    parameters={"data_type": "string", "lifecycle_stage": "string"},
                    required=True,
                ),
                AgentCapability(
                    name="vendor_security_assessment",
                    description="Third-party vendor security posture evaluation",
                    parameters={"vendor_type": "string", "assessment_depth": "string"},
                    required=True,
                ),
                AgentCapability(
                    name="physical_security_audit",
                    description="Physical security controls and access evaluation",
                    parameters={"facility_type": "string", "security_level": "string"},
                    required=True,
                ),
                AgentCapability(
                    name="security_awareness_program_evaluation",
                    description="Assessment of security training and awareness programs",
                    parameters={"program_type": "string", "employee_level": "string"},
                    required=True,
                ),
                AgentCapability(
                    name="risk_assessment_management",
                    description="Comprehensive risk assessment and management evaluation",
                    parameters={
                        "risk_framework": "string",
                        "assessment_scope": "string",
                    },
                    required=True,
                ),
            ]
        )

        # Add metadata
        self.metadata.update(
            {
                "specialization": "security_audit",
                "category": "security",
                "index": 3,
                "compliance_standards": [
                    "ISO27001",
                    "SOC2",
                    "PCI-DSS",
                    "HIPAA",
                    "GDPR",
                    "SOX",
                    "NIST_800-53",
                ],
                "risk_frameworks": ["NIST_CSF", "ISO31000", "COSO", "FAIR"],
                "audit_types": [
                    "internal",
                    "external",
                    "regulatory",
                    "certification",
                    "vendor",
                ],
                "assessment_areas": [
                    "technical",
                    "administrative",
                    "physical",
                    "operational",
                ],
            }
        )

    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a security audit task"""
        input_data = task.input_data
        audit_type = input_data.get("audit_type", "comprehensive")
        compliance_standard = input_data.get("compliance_standard", "ISO27001")

        # Simulate security audit process
        audit_findings = [
            {
                "id": "AUD001",
                "category": "Access Control",
                "severity": "medium",
                "finding": "Privileged access review not performed quarterly",
                "recommendation": "Implement quarterly access review process",
                "compliance_impact": "ISO27001 A.9.2.3",
                "risk_level": "Medium",
            },
            {
                "id": "AUD002",
                "category": "Incident Response",
                "severity": "low",
                "finding": "Incident response plan not tested annually",
                "recommendation": "Conduct annual tabletop exercises",
                "compliance_impact": "ISO27001 A.16.1.1",
                "risk_level": "Low",
            },
        ]

        return {
            "status": "completed",
            "agent": self.name,
            "specialization": "security_audit",
            "audit_results": {
                "audit_type": audit_type,
                "compliance_standard": compliance_standard,
                "findings": len(audit_findings),
                "audit_items": audit_findings,
                "compliance_score": "78%",
                "critical_findings": 0,
                "high_risk_findings": 0,
                "recommendations": "Address access control gaps, implement regular incident response testing",
            },
            "execution_time_ms": 4500,
        }

    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "security_audit_agent",
            "description": "Comprehensive security audit and compliance assessment",
            "parameters": {
                "type": "object",
                "properties": {
                    "audit_type": {
                        "type": "string",
                        "enum": [
                            "comprehensive",
                            "compliance",
                            "access_control",
                            "incident_response",
                            "vendor_assessment",
                        ],
                        "description": "Type of security audit to perform",
                    },
                    "compliance_standard": {
                        "type": "string",
                        "enum": [
                            "ISO27001",
                            "SOC2",
                            "PCI-DSS",
                            "HIPAA",
                            "GDPR",
                            "SOX",
                            "NIST_800-53",
                        ],
                        "description": "Compliance standard to audit against",
                    },
                    "scope": {
                        "type": "string",
                        "description": "Scope of the audit (department, system, organization-wide)",
                    },
                    "risk_threshold": {
                        "type": "string",
                        "enum": ["low", "medium", "high"],
                        "description": "Risk threshold for reporting findings",
                    },
                },
                "required": ["audit_type"],
            },
        }

    def get_compliance_standards(self) -> List[str]:
        """Get supported compliance standards"""
        return [
            "ISO27001",
            "SOC2",
            "PCI-DSS",
            "HIPAA",
            "GDPR",
            "SOX",
            "NIST_800-53",
            "CIS_Controls",
        ]

    def get_risk_frameworks(self) -> List[str]:
        """Get supported risk assessment frameworks"""
        return ["NIST_CSF", "ISO31000", "COSO", "FAIR", "OCTAVE"]

    def get_audit_types(self) -> List[str]:
        """Get available audit types"""
        return [
            "internal",
            "external",
            "regulatory",
            "certification",
            "vendor",
            "technical",
            "operational",
        ]
