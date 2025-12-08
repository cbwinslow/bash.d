"""
Base Tool Classes and Models

Defines the core tool architecture using MCP protocol standards
and Pydantic for validation.
"""

from enum import Enum
from typing import Optional, Dict, Any, List, Callable
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict
import uuid


class ToolCategory(str, Enum):
    """Tool categories"""
    ANALYSIS = "analysis"
    BUILD = "build"
    TESTING = "testing"
    DOCUMENTATION = "documentation"
    DATA = "data"
    API = "api"
    FILESYSTEM = "filesystem"
    NETWORK = "network"
    DATABASE = "database"
    MONITORING = "monitoring"


class ToolStatus(str, Enum):
    """Tool execution status"""
    IDLE = "idle"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    TIMEOUT = "timeout"


class ToolParameter(BaseModel):
    """Tool parameter definition"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    name: str = Field(..., description="Parameter name")
    type: str = Field(..., description="Parameter type (string, integer, boolean, object, array)")
    description: str = Field(..., description="Parameter description")
    required: bool = Field(default=False)
    default: Optional[Any] = None
    enum: Optional[List[Any]] = None
    pattern: Optional[str] = None
    min_value: Optional[float] = None
    max_value: Optional[float] = None


class ToolResult(BaseModel):
    """Tool execution result"""
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    success: bool
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    execution_time: float = 0.0
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class BaseTool(BaseModel):
    """
    Base Tool Class - MCP Compatible
    
    All tools inherit from this base class and follow the Model Context Protocol
    for standardized agent-tool interaction.
    
    MCP Compatibility includes:
    - Standardized tool schema
    - Parameter validation
    - Result formatting
    - Error handling
    - OpenAI function calling compatible
    """
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    # Core Identity
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str = Field(..., description="Tool name")
    category: ToolCategory = Field(..., description="Tool category")
    description: str = Field(..., description="Detailed tool description")
    version: str = Field(default="1.0.0")
    
    # Parameters
    parameters: List[ToolParameter] = Field(default_factory=list)
    
    # Status
    status: ToolStatus = Field(default=ToolStatus.IDLE)
    
    # Metadata
    tags: List[str] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)
    
    # MCP Protocol
    mcp_compatible: bool = Field(default=True)
    openai_compatible: bool = Field(default=True)
    
    def get_mcp_schema(self) -> Dict[str, Any]:
        """
        Get MCP-compatible tool schema
        
        Returns:
            Dict following MCP protocol standards
        """
        return {
            "name": self.name,
            "description": self.description,
            "category": self.category.value,
            "version": self.version,
            "parameters": {
                "type": "object",
                "properties": {
                    param.name: {
                        "type": param.type,
                        "description": param.description,
                        **({"default": param.default} if param.default is not None else {}),
                        **({"enum": param.enum} if param.enum else {}),
                        **({"pattern": param.pattern} if param.pattern else {}),
                        **({"minimum": param.min_value} if param.min_value is not None else {}),
                        **({"maximum": param.max_value} if param.max_value is not None else {})
                    }
                    for param in self.parameters
                },
                "required": [p.name for p in self.parameters if p.required]
            },
            "returns": {
                "type": "object",
                "properties": {
                    "success": {"type": "boolean"},
                    "data": {"type": "object"},
                    "error": {"type": "string"}
                }
            }
        }
    
    def get_openai_function_schema(self) -> Dict[str, Any]:
        """
        Get OpenAI function calling schema
        
        Returns:
            Dict compatible with OpenAI function calling
        """
        return {
            "name": self.name.lower().replace(" ", "_"),
            "description": self.description,
            "parameters": {
                "type": "object",
                "properties": {
                    param.name: {
                        "type": param.type,
                        "description": param.description,
                        **({"enum": param.enum} if param.enum else {})
                    }
                    for param in self.parameters
                },
                "required": [p.name for p in self.parameters if p.required]
            }
        }
    
    async def execute(self, **kwargs) -> ToolResult:
        """
        Execute the tool with given parameters
        
        Args:
            **kwargs: Tool parameters
            
        Returns:
            ToolResult with execution results
        """
        start_time = datetime.utcnow()
        self.status = ToolStatus.RUNNING
        
        try:
            # Validate parameters
            self._validate_parameters(kwargs)
            
            # Execute tool logic (to be implemented by subclasses)
            result_data = await self._execute_impl(**kwargs)
            
            execution_time = (datetime.utcnow() - start_time).total_seconds()
            self.status = ToolStatus.COMPLETED
            
            return ToolResult(
                success=True,
                data=result_data,
                execution_time=execution_time
            )
        
        except Exception as e:
            execution_time = (datetime.utcnow() - start_time).total_seconds()
            self.status = ToolStatus.FAILED
            
            return ToolResult(
                success=False,
                error=str(e),
                execution_time=execution_time
            )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        """
        Implementation-specific execution logic
        
        Override this method in subclasses to provide tool functionality
        
        Args:
            **kwargs: Validated tool parameters
            
        Returns:
            Dict with execution results
        """
        raise NotImplementedError("Subclasses must implement _execute_impl")
    
    def _validate_parameters(self, params: Dict[str, Any]) -> None:
        """
        Validate tool parameters
        
        Args:
            params: Parameters to validate
            
        Raises:
            ValueError: If validation fails
        """
        # Check required parameters
        required_params = {p.name for p in self.parameters if p.required}
        provided_params = set(params.keys())
        
        missing = required_params - provided_params
        if missing:
            raise ValueError(f"Missing required parameters: {missing}")
        
        # Validate parameter types and constraints
        for param in self.parameters:
            if param.name in params:
                value = params[param.name]
                
                # Type validation (basic)
                if param.type == "integer" and not isinstance(value, int):
                    raise ValueError(f"Parameter {param.name} must be an integer")
                elif param.type == "string" and not isinstance(value, str):
                    raise ValueError(f"Parameter {param.name} must be a string")
                elif param.type == "boolean" and not isinstance(value, bool):
                    raise ValueError(f"Parameter {param.name} must be a boolean")
                
                # Enum validation
                if param.enum and value not in param.enum:
                    raise ValueError(f"Parameter {param.name} must be one of {param.enum}")
                
                # Range validation
                if param.type in ["integer", "number"]:
                    if param.min_value is not None and value < param.min_value:
                        raise ValueError(f"Parameter {param.name} must be >= {param.min_value}")
                    if param.max_value is not None and value > param.max_value:
                        raise ValueError(f"Parameter {param.name} must be <= {param.max_value}")
    
    def __str__(self) -> str:
        return f"{self.category.value}Tool({self.name})"
    
    def __repr__(self) -> str:
        return f"<{self.__class__.__name__} id={self.id} name={self.name}>"
