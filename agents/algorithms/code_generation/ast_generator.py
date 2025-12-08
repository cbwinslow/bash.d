"""
AST-Based Code Generator

Generates code by building and manipulating Abstract Syntax Trees.
Provides more structured and validated code generation.
"""

import ast
from typing import Dict, Any, List
from ..base import Algorithm, AlgorithmType, AlgorithmStrategy


class ASTBasedCodeGenerator(Algorithm):
    """
    AST-based code generation algorithm
    
    Builds Abstract Syntax Trees programmatically and converts them to code.
    Ensures syntactically valid code generation with full control over structure.
    
    Example:
        ```python
        generator = ASTBasedCodeGenerator()
        result = generator.execute({
            "ast_type": "function",
            "name": "calculate_sum",
            "parameters": ["a", "b"],
            "return_type": "int",
            "body": [
                {"type": "assign", "target": "result", "value": "a + b"},
                {"type": "return", "value": "result"}
            ]
        })
        ```
    """
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "AST-Based Code Generator"
        if "type" not in data:
            data["type"] = AlgorithmType.CODE_GENERATION
        if "strategy" not in data:
            data["strategy"] = AlgorithmStrategy.AST_BASED
        if "description" not in data:
            data["description"] = "Generates code using Abstract Syntax Tree manipulation"
        
        super().__init__(**data)
    
    def _validate_input(self, input_data: Dict[str, Any]) -> None:
        """Validate input data for AST-based generation"""
        super()._validate_input(input_data)
        
        if "ast_type" not in input_data:
            raise ValueError("Missing required field: ast_type")
        
        valid_types = ["function", "class", "module", "expression"]
        if input_data["ast_type"] not in valid_types:
            raise ValueError(f"ast_type must be one of: {valid_types}")
    
    def _execute_core(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute AST-based code generation"""
        ast_type = input_data["ast_type"]
        
        if ast_type == "function":
            generated_ast = self._generate_function_ast(input_data)
        elif ast_type == "class":
            generated_ast = self._generate_class_ast(input_data)
        elif ast_type == "module":
            generated_ast = self._generate_module_ast(input_data)
        elif ast_type == "expression":
            generated_ast = self._generate_expression_ast(input_data)
        else:
            raise ValueError(f"Unsupported AST type: {ast_type}")
        
        # Convert AST to code
        generated_code = ast.unparse(generated_ast)
        
        return {
            "generated_code": generated_code,
            "ast_type": ast_type,
            "ast_structure": ast.dump(generated_ast),
            "code_length": len(generated_code),
            "is_valid": self._validate_syntax(generated_code)
        }
    
    def _generate_function_ast(self, data: Dict[str, Any]) -> ast.FunctionDef:
        """Generate a function AST node"""
        name = data.get("name", "generated_function")
        parameters = data.get("parameters", [])
        body_data = data.get("body", [{"type": "pass"}])
        
        # Create parameters
        args = ast.arguments(
            posonlyargs=[],
            args=[ast.arg(arg=param, annotation=None) for param in parameters],
            kwonlyargs=[],
            kw_defaults=[],
            defaults=[]
        )
        
        # Create body
        body = self._generate_body(body_data)
        
        # Create function
        func = ast.FunctionDef(
            name=name,
            args=args,
            body=body,
            decorator_list=[],
            returns=None
        )
        
        return func
    
    def _generate_class_ast(self, data: Dict[str, Any]) -> ast.ClassDef:
        """Generate a class AST node"""
        name = data.get("name", "GeneratedClass")
        bases = data.get("bases", [])
        methods_data = data.get("methods", [])
        
        # Create base classes
        base_nodes = [ast.Name(id=base, ctx=ast.Load()) for base in bases]
        
        # Create methods
        body = []
        for method_data in methods_data:
            method_ast = self._generate_function_ast(method_data)
            body.append(method_ast)
        
        if not body:
            body = [ast.Pass()]
        
        # Create class
        cls = ast.ClassDef(
            name=name,
            bases=base_nodes,
            keywords=[],
            body=body,
            decorator_list=[]
        )
        
        return cls
    
    def _generate_module_ast(self, data: Dict[str, Any]) -> ast.Module:
        """Generate a module AST node"""
        statements_data = data.get("statements", [])
        
        body = []
        for stmt_data in statements_data:
            if stmt_data.get("type") == "function":
                body.append(self._generate_function_ast(stmt_data))
            elif stmt_data.get("type") == "class":
                body.append(self._generate_class_ast(stmt_data))
            elif stmt_data.get("type") == "import":
                module_name = stmt_data.get("module", "")
                body.append(ast.Import(names=[ast.alias(name=module_name, asname=None)]))
        
        if not body:
            body = [ast.Pass()]
        
        return ast.Module(body=body, type_ignores=[])
    
    def _generate_expression_ast(self, data: Dict[str, Any]) -> ast.Expr:
        """Generate an expression AST node"""
        expression = data.get("expression", "None")
        
        # Parse the expression
        expr_ast = ast.parse(expression, mode='eval')
        
        return ast.Expr(value=expr_ast.body)
    
    def _generate_body(self, body_data: List[Dict[str, Any]]) -> List[ast.stmt]:
        """Generate body statements from data"""
        body = []
        
        for stmt_data in body_data:
            stmt_type = stmt_data.get("type", "pass")
            
            if stmt_type == "pass":
                body.append(ast.Pass())
            elif stmt_type == "return":
                value = stmt_data.get("value", "None")
                value_ast = ast.parse(value, mode='eval').body
                body.append(ast.Return(value=value_ast))
            elif stmt_type == "assign":
                target = stmt_data.get("target", "result")
                value = stmt_data.get("value", "None")
                value_ast = ast.parse(value, mode='eval').body
                body.append(
                    ast.Assign(
                        targets=[ast.Name(id=target, ctx=ast.Store())],
                        value=value_ast
                    )
                )
            elif stmt_type == "expression":
                expression = stmt_data.get("expression", "None")
                expr_ast = ast.parse(expression, mode='eval').body
                body.append(ast.Expr(value=expr_ast))
        
        if not body:
            body = [ast.Pass()]
        
        return body
    
    def _validate_syntax(self, code: str) -> bool:
        """Validate that generated code has valid syntax"""
        try:
            ast.parse(code)
            return True
        except SyntaxError:
            return False
    
    def generate_from_spec(self, spec: Dict[str, Any]) -> str:
        """
        Generate code from a high-level specification
        
        Args:
            spec: Code specification with structure details
            
        Returns:
            Generated code string
        """
        result = self.execute(spec)
        if result.success:
            return result.result_data.get("generated_code", "")
        else:
            raise Exception(f"Code generation failed: {result.error}")
