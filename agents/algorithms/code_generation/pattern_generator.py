"""
Pattern-Based Code Generator

Generates code based on recognized design patterns and best practices.
Implements common software design patterns automatically.
"""

from typing import Dict, Any, List, Optional
from ..base import Algorithm, AlgorithmType, AlgorithmStrategy


class PatternBasedCodeGenerator(Algorithm):
    """
    Pattern-based code generation algorithm
    
    Generates code implementing common design patterns like Singleton,
    Factory, Observer, Strategy, etc.
    
    Example:
        ```python
        generator = PatternBasedCodeGenerator()
        result = generator.execute({
            "pattern": "singleton",
            "class_name": "DatabaseConnection",
            "language": "python",
            "additional_methods": ["connect", "disconnect", "query"]
        })
        ```
    """
    
    # Design pattern implementations
    PATTERNS = {
        "singleton": {
            "python": """class ${class_name}:
    \"\"\"Singleton pattern implementation\"\"\"
    _instance = None
    _initialized = False
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        if not self._initialized:
            self._initialize()
            self.__class__._initialized = True
    
    def _initialize(self):
        \"\"\"Initialize the singleton instance\"\"\"
        pass
${additional_methods}
""",
        },
        "factory": {
            "python": """from abc import ABC, abstractmethod
from typing import Dict, Type

class ${product_interface}(ABC):
    \"\"\"Product interface\"\"\"
    
    @abstractmethod
    def operation(self) -> str:
        pass

${concrete_products}

class ${factory_name}:
    \"\"\"Factory for creating products\"\"\"
    
    def __init__(self):
        self._products: Dict[str, Type[${product_interface}]] = {}
    
    def register_product(self, product_type: str, product_class: Type[${product_interface}]):
        \"\"\"Register a product type\"\"\"
        self._products[product_type] = product_class
    
    def create(self, product_type: str) -> ${product_interface}:
        \"\"\"Create a product instance\"\"\"
        product_class = self._products.get(product_type)
        if not product_class:
            raise ValueError(f"Unknown product type: {product_type}")
        return product_class()
""",
        },
        "observer": {
            "python": """from abc import ABC, abstractmethod
from typing import List

class Observer(ABC):
    \"\"\"Observer interface\"\"\"
    
    @abstractmethod
    def update(self, subject: 'Subject') -> None:
        pass

class Subject:
    \"\"\"Subject that observers watch\"\"\"
    
    def __init__(self):
        self._observers: List[Observer] = []
        self._state = None
    
    def attach(self, observer: Observer) -> None:
        \"\"\"Attach an observer\"\"\"
        if observer not in self._observers:
            self._observers.append(observer)
    
    def detach(self, observer: Observer) -> None:
        \"\"\"Detach an observer\"\"\"
        self._observers.remove(observer)
    
    def notify(self) -> None:
        \"\"\"Notify all observers\"\"\"
        for observer in self._observers:
            observer.update(self)
    
    @property
    def state(self):
        return self._state
    
    @state.setter
    def state(self, value):
        self._state = value
        self.notify()

class ${observer_name}(Observer):
    \"\"\"Concrete observer implementation\"\"\"
    
    def update(self, subject: Subject) -> None:
        \"\"\"React to subject state change\"\"\"
        print(f"Observer notified. New state: {subject.state}")
""",
        },
        "strategy": {
            "python": """from abc import ABC, abstractmethod
from typing import Any

class Strategy(ABC):
    \"\"\"Strategy interface\"\"\"
    
    @abstractmethod
    def execute(self, data: Any) -> Any:
        pass

${concrete_strategies}

class Context:
    \"\"\"Context that uses a strategy\"\"\"
    
    def __init__(self, strategy: Strategy):
        self._strategy = strategy
    
    @property
    def strategy(self) -> Strategy:
        return self._strategy
    
    @strategy.setter
    def strategy(self, strategy: Strategy):
        self._strategy = strategy
    
    def execute_strategy(self, data: Any) -> Any:
        \"\"\"Execute the current strategy\"\"\"
        return self._strategy.execute(data)
""",
        },
        "builder": {
            "python": """class ${product_name}:
    \"\"\"Product being built\"\"\"
    
    def __init__(self):
${product_attributes}
    
    def __str__(self):
        return f"${product_name}({', '.join(f'{k}={v}' for k, v in self.__dict__.items())})"

class ${builder_name}:
    \"\"\"Builder for ${product_name}\"\"\"
    
    def __init__(self):
        self._product = ${product_name}()
    
    def reset(self):
        \"\"\"Reset the builder\"\"\"
        self._product = ${product_name}()
        return self

${builder_methods}
    
    def build(self) -> ${product_name}:
        \"\"\"Build and return the product\"\"\"
        product = self._product
        self.reset()
        return product
""",
        },
        "adapter": {
            "python": """from abc import ABC, abstractmethod

class Target(ABC):
    \"\"\"Target interface that client uses\"\"\"
    
    @abstractmethod
    def request(self) -> str:
        pass

class Adaptee:
    \"\"\"Existing class with incompatible interface\"\"\"
    
    def specific_request(self) -> str:
        return ".eetpadA eht fo roivaheb laicepS"

class ${adapter_name}(Target):
    \"\"\"Adapter that makes Adaptee compatible with Target\"\"\"
    
    def __init__(self, adaptee: Adaptee):
        self._adaptee = adaptee
    
    def request(self) -> str:
        \"\"\"Adapt the interface\"\"\"
        return f"Adapter: {self._adaptee.specific_request()[::-1]}"
""",
        },
    }
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "Pattern-Based Code Generator"
        if "type" not in data:
            data["type"] = AlgorithmType.CODE_GENERATION
        if "strategy" not in data:
            data["strategy"] = AlgorithmStrategy.PATTERN_BASED
        if "description" not in data:
            data["description"] = "Generates code implementing design patterns"
        
        super().__init__(**data)
    
    def _validate_input(self, input_data: Dict[str, Any]) -> None:
        """Validate input data for pattern-based generation"""
        super()._validate_input(input_data)
        
        if "pattern" not in input_data:
            raise ValueError("Missing required field: pattern")
        
        pattern = input_data["pattern"]
        if pattern not in self.PATTERNS:
            available = ", ".join(self.PATTERNS.keys())
            raise ValueError(f"Unknown pattern: {pattern}. Available: {available}")
    
    def _execute_core(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute pattern-based code generation"""
        pattern = input_data["pattern"]
        language = input_data.get("language", "python")
        
        if language not in self.PATTERNS[pattern]:
            raise ValueError(f"Pattern {pattern} not available for language {language}")
        
        template = self.PATTERNS[pattern][language]
        variables = self._prepare_pattern_variables(pattern, input_data)
        
        # Simple substitution
        generated_code = template
        for key, value in variables.items():
            generated_code = generated_code.replace(f"${{{key}}}", str(value))
        
        return {
            "generated_code": generated_code,
            "pattern": pattern,
            "language": language,
            "variables": variables,
            "code_length": len(generated_code)
        }
    
    def _prepare_pattern_variables(
        self, 
        pattern: str, 
        input_data: Dict[str, Any]
    ) -> Dict[str, str]:
        """Prepare variables for pattern template"""
        variables = {}
        
        if pattern == "singleton":
            variables["class_name"] = input_data.get("class_name", "Singleton")
            additional_methods = input_data.get("additional_methods", [])
            methods_code = "\n".join([
                f"    def {method}(self):\n        pass\n"
                for method in additional_methods
            ])
            variables["additional_methods"] = methods_code
        
        elif pattern == "factory":
            variables["product_interface"] = input_data.get("product_interface", "Product")
            variables["factory_name"] = input_data.get("factory_name", "ProductFactory")
            concrete_products = input_data.get("concrete_products", [])
            products_code = "\n\n".join([
                f"class {product}({variables['product_interface']}):\n    def operation(self) -> str:\n        return \"{product} operation\""
                for product in concrete_products
            ])
            variables["concrete_products"] = products_code
        
        elif pattern == "observer":
            variables["observer_name"] = input_data.get("observer_name", "ConcreteObserver")
        
        elif pattern == "strategy":
            concrete_strategies = input_data.get("concrete_strategies", [])
            strategies_code = "\n\n".join([
                f"class {strategy}(Strategy):\n    def execute(self, data: Any) -> Any:\n        return data  # Implement strategy logic"
                for strategy in concrete_strategies
            ])
            variables["concrete_strategies"] = strategies_code
        
        elif pattern == "builder":
            variables["product_name"] = input_data.get("product_name", "Product")
            variables["builder_name"] = input_data.get("builder_name", "ProductBuilder")
            attributes = input_data.get("attributes", [])
            attr_code = "\n".join([f"        self.{attr} = None" for attr in attributes])
            variables["product_attributes"] = attr_code
            methods_code = "\n\n".join([
                f"    def set_{attr}(self, value):\n        self._product.{attr} = value\n        return self"
                for attr in attributes
            ])
            variables["builder_methods"] = methods_code
        
        elif pattern == "adapter":
            variables["adapter_name"] = input_data.get("adapter_name", "Adapter")
        
        return variables
    
    def list_patterns(self) -> List[str]:
        """List all available patterns"""
        return list(self.PATTERNS.keys())
    
    def get_pattern_info(self, pattern: str) -> Dict[str, Any]:
        """Get information about a specific pattern"""
        if pattern not in self.PATTERNS:
            raise ValueError(f"Unknown pattern: {pattern}")
        
        return {
            "pattern": pattern,
            "supported_languages": list(self.PATTERNS[pattern].keys()),
            "description": self._get_pattern_description(pattern)
        }
    
    def _get_pattern_description(self, pattern: str) -> str:
        """Get description for a pattern"""
        descriptions = {
            "singleton": "Ensures a class has only one instance and provides global access to it",
            "factory": "Provides an interface for creating objects without specifying exact classes",
            "observer": "Defines a one-to-many dependency between objects",
            "strategy": "Defines a family of algorithms and makes them interchangeable",
            "builder": "Separates complex object construction from its representation",
            "adapter": "Converts the interface of a class into another interface clients expect",
        }
        return descriptions.get(pattern, "No description available")
