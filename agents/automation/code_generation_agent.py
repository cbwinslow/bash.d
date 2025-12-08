"""
Code Generation Agent

Specialized agent for automated code generation using multiple algorithms.
"""

from typing import Dict, Any, List
from ..base import BaseAgent, AgentType, AgentCapability, Task
from ..algorithms.optimization import AlgorithmOrchestrator


class CodeGenerationAgent(BaseAgent):
    """
    Code Generation Agent - Multi-algorithm code generator
    
    This agent uses multiple code generation algorithms to create code
    based on requirements. It can generate code from templates, AST,
    design patterns, or using AI assistance.
    """
    
    def __init__(self, **data):
        """Initialize the Code Generation agent"""
        
        # Set defaults
        if "name" not in data:
            data["name"] = "Code Generation Agent"
        if "type" not in data:
            data["type"] = AgentType.AUTOMATION
        if "description" not in data:
            data["description"] = "Automated code generation using multiple algorithms"
        if "tags" not in data:
            data["tags"] = ["automation_agent", "code_generation"]
        
        # Initialize parent
        super().__init__(**data)
        
        # Initialize algorithm orchestrator
        self.orchestrator = AlgorithmOrchestrator()
        
        # Add capabilities
        self.capabilities.extend([
            AgentCapability(
                name="template_code_generation",
                description="Generate code using templates",
                parameters={"template_name": "str", "language": "str", "variables": "dict"},
                required=True
            ),
            AgentCapability(
                name="ast_code_generation",
                description="Generate code using AST manipulation",
                parameters={"ast_type": "str", "name": "str", "body": "list"},
                required=True
            ),
            AgentCapability(
                name="pattern_code_generation",
                description="Generate code implementing design patterns",
                parameters={"pattern": "str", "class_name": "str"},
                required=True
            ),
            AgentCapability(
                name="ai_code_generation",
                description="Generate code using AI assistance",
                parameters={"prompt": "str", "language": "str"},
                required=True
            ),
        ])
        
        # Add metadata
        self.metadata.update({
            "specialization": "code_generation",
            "category": "automation",
            "algorithms_available": ["template", "ast", "pattern", "ai"]
        })
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Execute a code generation task"""
        input_data = task.input_data
        generation_type = input_data.get("generation_type", "auto")
        
        if generation_type == "auto":
            # Let orchestrator choose best algorithm
            result = self.orchestrator.execute_with_best_algorithm(input_data)
        else:
            # Use specific algorithm
            algorithm_map = {
                "template": "template",
                "ast": "ast",
                "pattern": "pattern",
                "ai": "ai"
            }
            algorithm_key = algorithm_map.get(generation_type)
            
            if not algorithm_key:
                return {
                    "status": "failed",
                    "error": f"Unknown generation type: {generation_type}"
                }
            
            result = self.orchestrator.execute_with_algorithm(algorithm_key, input_data)
        
        return {
            "status": "completed" if result.success else "failed",
            "agent": self.name,
            "algorithm_used": result.strategy.value,
            "generated_code": result.result_data.get("generated_code"),
            "execution_time_ms": result.execution_time_ms,
            "metadata": result.metadata
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """Get OpenAI function schema"""
        return {
            "name": "code_generation_agent",
            "description": "Generate code using multiple algorithms and strategies",
            "parameters": {
                "type": "object",
                "properties": {
                    "generation_type": {
                        "type": "string",
                        "enum": ["auto", "template", "ast", "pattern", "ai"],
                        "description": "Type of code generation algorithm to use"
                    },
                    "template_name": {
                        "type": "string",
                        "description": "Template name for template-based generation"
                    },
                    "language": {
                        "type": "string",
                        "description": "Programming language"
                    },
                    "variables": {
                        "type": "object",
                        "description": "Variables for template substitution"
                    },
                    "pattern": {
                        "type": "string",
                        "description": "Design pattern name"
                    },
                    "prompt": {
                        "type": "string",
                        "description": "Natural language description for AI generation"
                    }
                },
                "required": []
            }
        }
    
    def list_available_templates(self, language: str = None) -> Dict[str, Any]:
        """List available code templates"""
        template_gen = self.orchestrator.code_generators["template"]
        return template_gen.list_templates(language)
    
    def list_available_patterns(self) -> List[str]:
        """List available design patterns"""
        pattern_gen = self.orchestrator.code_generators["pattern"]
        return pattern_gen.list_patterns()
    
    def get_algorithm_metrics(self) -> Dict[str, Any]:
        """Get performance metrics for all algorithms"""
        return self.orchestrator.get_algorithm_metrics()
