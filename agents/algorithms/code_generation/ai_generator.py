"""
AI-Assisted Code Generator

Generates code using AI models with context-aware understanding.
Leverages large language models for intelligent code generation.
"""

from typing import Dict, Any, Optional, List
from ..base import Algorithm, AlgorithmType, AlgorithmStrategy


class AIAssistedCodeGenerator(Algorithm):
    """
    AI-assisted code generation algorithm
    
    Uses AI models to generate code with natural language descriptions.
    Provides intelligent, context-aware code generation.
    
    Example:
        ```python
        generator = AIAssistedCodeGenerator()
        result = generator.execute({
            "prompt": "Create a function that calculates fibonacci numbers",
            "language": "python",
            "context": {
                "style": "functional",
                "include_tests": True,
                "include_docstrings": True
            }
        })
        ```
    """
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "AI-Assisted Code Generator"
        if "type" not in data:
            data["type"] = AlgorithmType.CODE_GENERATION
        if "strategy" not in data:
            data["strategy"] = AlgorithmStrategy.AI_ASSISTED
        if "description" not in data:
            data["description"] = "Generates code using AI models with natural language understanding"
        
        super().__init__(**data)
        
        # AI model configuration
        self.model_provider = "openai"
        self.model_name = "gpt-4"
        self.temperature = 0.2  # Lower for more deterministic code
    
    def _validate_input(self, input_data: Dict[str, Any]) -> None:
        """Validate input data for AI-assisted generation"""
        super()._validate_input(input_data)
        
        if "prompt" not in input_data and "description" not in input_data:
            raise ValueError("Either 'prompt' or 'description' is required")
    
    def _execute_core(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute AI-assisted code generation"""
        prompt = input_data.get("prompt") or input_data.get("description")
        language = input_data.get("language", "python")
        context = input_data.get("context", {})
        
        # Build enhanced prompt with context
        enhanced_prompt = self._build_prompt(prompt, language, context)
        
        # Simulate AI generation (in production, this would call actual AI API)
        generated_code = self._simulate_ai_generation(enhanced_prompt, language, context)
        
        # Extract metadata from generation
        metadata = self._extract_metadata(generated_code, language)
        
        return {
            "generated_code": generated_code,
            "language": language,
            "prompt": prompt,
            "context": context,
            "metadata": metadata,
            "code_length": len(generated_code)
        }
    
    def _build_prompt(
        self, 
        user_prompt: str, 
        language: str, 
        context: Dict[str, Any]
    ) -> str:
        """Build an enhanced prompt for AI model"""
        prompt_parts = [
            f"Generate {language} code for the following requirement:",
            f"\n{user_prompt}\n",
        ]
        
        # Add context-specific instructions
        if context.get("style"):
            prompt_parts.append(f"Code style: {context['style']}")
        
        if context.get("include_docstrings", True):
            prompt_parts.append("Include comprehensive docstrings")
        
        if context.get("include_tests"):
            prompt_parts.append("Include unit tests")
        
        if context.get("include_type_hints", True) and language == "python":
            prompt_parts.append("Include type hints")
        
        if context.get("framework"):
            prompt_parts.append(f"Use framework: {context['framework']}")
        
        if context.get("design_pattern"):
            prompt_parts.append(f"Implement design pattern: {context['design_pattern']}")
        
        if context.get("additional_requirements"):
            prompt_parts.append(f"Additional requirements: {context['additional_requirements']}")
        
        prompt_parts.append("\nGenerate clean, production-ready code.")
        
        return "\n".join(prompt_parts)
    
    def _simulate_ai_generation(
        self, 
        prompt: str, 
        language: str, 
        context: Dict[str, Any]
    ) -> str:
        """
        Simulate AI code generation
        
        In production, this would call actual AI API.
        For now, generates example code based on context.
        """
        # This is a simulation - real implementation would call AI API
        if "function" in prompt.lower() and "fibonacci" in prompt.lower():
            if context.get("style") == "functional":
                return self._generate_fibonacci_functional()
            else:
                return self._generate_fibonacci_iterative()
        
        elif "class" in prompt.lower() or "api" in prompt.lower():
            return self._generate_example_class(language, context)
        
        else:
            return self._generate_generic_template(language, prompt)
    
    def _generate_fibonacci_functional(self) -> str:
        """Generate functional fibonacci implementation"""
        return '''def fibonacci(n: int) -> int:
    """
    Calculate the nth Fibonacci number using functional approach.
    
    Args:
        n: The position in the Fibonacci sequence (0-indexed)
    
    Returns:
        The nth Fibonacci number
    
    Raises:
        ValueError: If n is negative
    
    Examples:
        >>> fibonacci(0)
        0
        >>> fibonacci(1)
        1
        >>> fibonacci(10)
        55
    """
    if n < 0:
        raise ValueError("n must be non-negative")
    
    if n <= 1:
        return n
    
    return fibonacci(n - 1) + fibonacci(n - 2)


def fibonacci_memoized(n: int, memo: dict = None) -> int:
    """
    Calculate Fibonacci with memoization for better performance.
    
    Args:
        n: The position in the Fibonacci sequence
        memo: Memoization dictionary (internal use)
    
    Returns:
        The nth Fibonacci number
    """
    if memo is None:
        memo = {}
    
    if n in memo:
        return memo[n]
    
    if n <= 1:
        return n
    
    memo[n] = fibonacci_memoized(n - 1, memo) + fibonacci_memoized(n - 2, memo)
    return memo[n]
'''
    
    def _generate_fibonacci_iterative(self) -> str:
        """Generate iterative fibonacci implementation"""
        return '''def fibonacci(n: int) -> int:
    """
    Calculate the nth Fibonacci number using iterative approach.
    
    Args:
        n: The position in the Fibonacci sequence (0-indexed)
    
    Returns:
        The nth Fibonacci number
    
    Raises:
        ValueError: If n is negative
    """
    if n < 0:
        raise ValueError("n must be non-negative")
    
    if n <= 1:
        return n
    
    prev, curr = 0, 1
    for _ in range(2, n + 1):
        prev, curr = curr, prev + curr
    
    return curr
'''
    
    def _generate_example_class(self, language: str, context: Dict[str, Any]) -> str:
        """Generate example class code"""
        if language == "python":
            return '''from typing import Optional, Dict, Any

class DataProcessor:
    """
    A processor for data transformation and validation.
    
    This class provides methods to process, transform, and validate data
    in a production environment with proper error handling.
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the data processor.
        
        Args:
            config: Optional configuration dictionary
        """
        self.config = config or {}
        self._processed_count = 0
    
    def process(self, data: Any) -> Any:
        """
        Process input data.
        
        Args:
            data: Input data to process
        
        Returns:
            Processed data
        
        Raises:
            ValueError: If data is invalid
        """
        if not self.validate(data):
            raise ValueError("Invalid data")
        
        result = self._transform(data)
        self._processed_count += 1
        return result
    
    def validate(self, data: Any) -> bool:
        """
        Validate input data.
        
        Args:
            data: Data to validate
        
        Returns:
            True if valid, False otherwise
        """
        return data is not None
    
    def _transform(self, data: Any) -> Any:
        """Transform data (internal method)"""
        return data
    
    @property
    def processed_count(self) -> int:
        """Get the count of processed items"""
        return self._processed_count
'''
        return "// Code generation for this language is not yet implemented"
    
    def _generate_generic_template(self, language: str, prompt: str) -> str:
        """Generate generic code template"""
        return f'''# Generated code for: {prompt}
# Language: {language}
# This is a placeholder - integrate with actual AI API for production use

def generated_function():
    """Generated function based on prompt"""
    pass
'''
    
    def _extract_metadata(self, code: str, language: str) -> Dict[str, Any]:
        """Extract metadata from generated code"""
        lines = code.split('\n')
        
        metadata = {
            "lines_of_code": len(lines),
            "non_empty_lines": len([l for l in lines if l.strip()]),
            "has_docstrings": '"""' in code or "'''" in code,
            "has_comments": '#' in code or '//' in code,
        }
        
        if language == "python":
            metadata["has_type_hints"] = '->' in code or ': ' in code
            metadata["function_count"] = code.count('def ')
            metadata["class_count"] = code.count('class ')
        
        return metadata
    
    def configure_model(
        self, 
        provider: str = "openai", 
        model_name: str = "gpt-4",
        temperature: float = 0.2
    ) -> None:
        """
        Configure the AI model
        
        Args:
            provider: AI model provider (openai, anthropic, etc.)
            model_name: Specific model name
            temperature: Temperature for generation (0.0-1.0)
        """
        self.model_provider = provider
        self.model_name = model_name
        self.temperature = max(0.0, min(1.0, temperature))
