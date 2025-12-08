"""
Template-Based Code Generator

Generates code using predefined templates with variable substitution.
Ideal for standardized code patterns and boilerplate generation.
"""

from typing import Dict, Any, Optional
from string import Template
from ..base import Algorithm, AlgorithmType, AlgorithmStrategy


class TemplateBasedCodeGenerator(Algorithm):
    """
    Template-based code generation algorithm
    
    Uses string templates with variable substitution to generate code.
    Supports multiple programming languages and code patterns.
    
    Example:
        ```python
        generator = TemplateBasedCodeGenerator()
        result = generator.execute({
            "template_name": "class_definition",
            "language": "python",
            "variables": {
                "class_name": "MyClass",
                "base_class": "BaseClass",
                "methods": ["__init__", "process", "validate"]
            }
        })
        ```
    """
    
    # Predefined templates for common code patterns
    TEMPLATES = {
        "python": {
            "class_definition": """class ${class_name}(${base_class}):
    \"\"\"${description}\"\"\"
    
    def __init__(self, ${init_params}):
        super().__init__()
        ${init_body}
    
${methods}
""",
            "function_definition": """def ${function_name}(${parameters}) -> ${return_type}:
    \"\"\"${description}\"\"\"
    ${body}
    return ${return_value}
""",
            "api_endpoint": """@app.${method}("${path}")
async def ${endpoint_name}(${parameters}):
    \"\"\"${description}\"\"\"
    try:
        ${body}
        return {"status": "success", "data": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}
""",
            "test_case": """def test_${test_name}(${fixtures}):
    \"\"\"${description}\"\"\"
    # Arrange
    ${arrange}
    
    # Act
    ${act}
    
    # Assert
    ${assert_statements}
""",
        },
        "javascript": {
            "class_definition": """class ${class_name} extends ${base_class} {
    /**
     * ${description}
     */
    constructor(${constructor_params}) {
        super();
        ${constructor_body}
    }
    
${methods}
}
""",
            "function_definition": """function ${function_name}(${parameters}) {
    /**
     * ${description}
     */
    ${body}
    return ${return_value};
}
""",
            "react_component": """import React from 'react';

const ${component_name} = ({ ${props} }) => {
    ${hooks}
    
    return (
        ${jsx_template}
    );
};

export default ${component_name};
""",
        },
        "go": {
            "struct_definition": """type ${struct_name} struct {
${fields}
}

func New${struct_name}(${constructor_params}) *${struct_name} {
    return &${struct_name}{
        ${field_initialization}
    }
}
""",
            "interface_definition": """type ${interface_name} interface {
${methods}
}
""",
        },
    }
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "Template-Based Code Generator"
        if "type" not in data:
            data["type"] = AlgorithmType.CODE_GENERATION
        if "strategy" not in data:
            data["strategy"] = AlgorithmStrategy.TEMPLATE_BASED
        if "description" not in data:
            data["description"] = "Generates code using predefined templates with variable substitution"
        
        super().__init__(**data)
    
    def _validate_input(self, input_data: Dict[str, Any]) -> None:
        """Validate input data for template-based generation"""
        super()._validate_input(input_data)
        
        required_fields = ["template_name", "language", "variables"]
        for field in required_fields:
            if field not in input_data:
                raise ValueError(f"Missing required field: {field}")
        
        language = input_data["language"]
        template_name = input_data["template_name"]
        
        if language not in self.TEMPLATES:
            raise ValueError(f"Unsupported language: {language}")
        
        if template_name not in self.TEMPLATES[language]:
            raise ValueError(f"Unknown template: {template_name} for language {language}")
    
    def _execute_core(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute template-based code generation"""
        language = input_data["language"]
        template_name = input_data["template_name"]
        variables = input_data["variables"]
        
        # Get template
        template_str = self.TEMPLATES[language][template_name]
        template = Template(template_str)
        
        # Apply variables
        try:
            generated_code = template.safe_substitute(variables)
        except KeyError as e:
            raise ValueError(f"Missing template variable: {e}")
        
        return {
            "generated_code": generated_code,
            "language": language,
            "template_name": template_name,
            "variables_used": list(variables.keys()),
            "code_length": len(generated_code),
            "lines_of_code": len(generated_code.split('\n'))
        }
    
    def add_custom_template(
        self, 
        language: str, 
        template_name: str, 
        template_str: str
    ) -> None:
        """
        Add a custom template
        
        Args:
            language: Programming language
            template_name: Name for the template
            template_str: Template string with ${variable} placeholders
        """
        if language not in self.TEMPLATES:
            self.TEMPLATES[language] = {}
        
        self.TEMPLATES[language][template_name] = template_str
    
    def list_templates(self, language: Optional[str] = None) -> Dict[str, Any]:
        """
        List available templates
        
        Args:
            language: Optional language filter
            
        Returns:
            Dictionary of available templates
        """
        if language:
            return {
                language: list(self.TEMPLATES.get(language, {}).keys())
            }
        
        return {
            lang: list(templates.keys())
            for lang, templates in self.TEMPLATES.items()
        }
