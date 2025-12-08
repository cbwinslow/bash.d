"""
Tool Registry System

This module provides a comprehensive tool registry for discovering,
loading, and managing all available tools in the system.
"""

from typing import Dict, Any, List, Optional, Type
from .base import BaseTool, ToolCategory
import importlib
import inspect
import json
from pathlib import Path


class ToolRegistry:
    """
    Central registry for all tools in the system.
    
    Provides:
    - Tool discovery and loading
    - Tool lookup by name or category
    - Schema generation in multiple formats
    - Tool versioning and metadata management
    """
    
    def __init__(self):
        self.tools: Dict[str, BaseTool] = {}
        self.tools_by_category: Dict[ToolCategory, List[BaseTool]] = {}
        self._initialized = False
    
    def initialize(self):
        """Discover and load all tools from the tools package."""
        if self._initialized:
            return
        
        # Import all tool modules
        tool_modules = [
            'filesystem_tools',
            'text_tools',
            'api_http_tools',
            'bitwarden_tools',
            'git_tools',
            'data_tools',
            'docker_tools',
            'system_tools'
        ]
        
        for module_name in tool_modules:
            try:
                module = importlib.import_module(f'tools.{module_name}')
                self._load_tools_from_module(module)
            except Exception as e:
                print(f"Warning: Failed to load {module_name}: {e}")
        
        self._initialized = True
    
    def _load_tools_from_module(self, module):
        """Load all tool classes from a module."""
        for name, obj in inspect.getmembers(module):
            if (inspect.isclass(obj) and 
                issubclass(obj, BaseTool) and 
                obj != BaseTool):
                try:
                    tool_instance = obj()
                    self.register_tool(tool_instance)
                except Exception as e:
                    print(f"Warning: Failed to instantiate {name}: {e}")
    
    def register_tool(self, tool: BaseTool):
        """Register a tool in the registry."""
        self.tools[tool.name] = tool
        
        if tool.category not in self.tools_by_category:
            self.tools_by_category[tool.category] = []
        
        self.tools_by_category[tool.category].append(tool)
    
    def get_tool(self, name: str) -> Optional[BaseTool]:
        """Get a tool by name."""
        return self.tools.get(name)
    
    def get_tools_by_category(self, category: ToolCategory) -> List[BaseTool]:
        """Get all tools in a category."""
        return self.tools_by_category.get(category, [])
    
    def get_all_tools(self) -> List[BaseTool]:
        """Get all registered tools."""
        return list(self.tools.values())
    
    def search_tools(self, query: str) -> List[BaseTool]:
        """Search tools by name, description, or tags."""
        query_lower = query.lower()
        results = []
        
        for tool in self.tools.values():
            if (query_lower in tool.name.lower() or
                query_lower in tool.description.lower() or
                any(query_lower in tag.lower() for tag in tool.tags)):
                results.append(tool)
        
        return results
    
    def get_tool_count(self) -> int:
        """Get total number of registered tools."""
        return len(self.tools)
    
    def get_category_counts(self) -> Dict[str, int]:
        """Get count of tools per category."""
        return {
            category.value: len(tools)
            for category, tools in self.tools_by_category.items()
        }
    
    def export_schemas(self, format: str = "openai") -> List[Dict[str, Any]]:
        """
        Export all tool schemas in specified format.
        
        Args:
            format: Output format ('openai', 'mcp', 'json')
        
        Returns:
            List of tool schemas in specified format
        """
        schemas = []
        
        for tool in self.tools.values():
            if format == "openai":
                schemas.append(tool.get_openai_function_schema())
            elif format == "mcp":
                schemas.append(tool.get_mcp_schema())
            elif format == "json":
                schemas.append({
                    "name": tool.name,
                    "category": tool.category.value,
                    "description": tool.description,
                    "version": tool.version,
                    "parameters": [
                        {
                            "name": p.name,
                            "type": p.type,
                            "description": p.description,
                            "required": p.required,
                            "default": p.default
                        }
                        for p in tool.parameters
                    ],
                    "tags": tool.tags
                })
            else:
                raise ValueError(f"Unsupported format: {format}")
        
        return schemas
    
    def save_schemas_to_file(self, filepath: str, format: str = "openai"):
        """
        Save all tool schemas to a file.
        
        Args:
            filepath: Path to output file
            format: Output format ('openai', 'mcp', 'json')
        """
        schemas = self.export_schemas(format)
        
        with open(filepath, 'w') as f:
            json.dump(schemas, f, indent=2)
    
    def generate_documentation(self) -> str:
        """
        Generate comprehensive documentation for all tools.
        
        Returns:
            Markdown formatted documentation
        """
        doc = "# Tool Documentation\n\n"
        doc += f"Total Tools: {self.get_tool_count()}\n\n"
        
        # Table of contents
        doc += "## Table of Contents\n\n"
        for category in sorted(self.tools_by_category.keys(), key=lambda x: x.value):
            tools = self.tools_by_category[category]
            doc += f"- [{category.value.title()}](#{category.value}) ({len(tools)} tools)\n"
        doc += "\n"
        
        # Tools by category
        for category in sorted(self.tools_by_category.keys(), key=lambda x: x.value):
            tools = self.tools_by_category[category]
            doc += f"## {category.value.title()}\n\n"
            
            for tool in sorted(tools, key=lambda x: x.name):
                doc += f"### `{tool.name}`\n\n"
                doc += f"{tool.description}\n\n"
                
                if tool.parameters:
                    doc += "**Parameters:**\n\n"
                    for param in tool.parameters:
                        required = " (required)" if param.required else " (optional)"
                        default = f" - default: `{param.default}`" if param.default is not None else ""
                        doc += f"- `{param.name}` ({param.type}){required}: {param.description}{default}\n"
                    doc += "\n"
                
                if tool.tags:
                    doc += f"**Tags:** {', '.join(tool.tags)}\n\n"
                
                doc += "---\n\n"
        
        return doc
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get statistics about registered tools."""
        return {
            "total_tools": self.get_tool_count(),
            "by_category": self.get_category_counts(),
            "categories": len(self.tools_by_category),
            "tools_with_tags": sum(1 for tool in self.tools.values() if tool.tags),
            "average_parameters": sum(len(tool.parameters) for tool in self.tools.values()) / len(self.tools) if self.tools else 0
        }


# Global registry instance
_registry = None


def get_registry() -> ToolRegistry:
    """Get the global tool registry instance."""
    global _registry
    if _registry is None:
        _registry = ToolRegistry()
        _registry.initialize()
    return _registry


def list_tools(category: Optional[ToolCategory] = None) -> List[BaseTool]:
    """
    List all tools, optionally filtered by category.
    
    Args:
        category: Optional category to filter by
    
    Returns:
        List of tools
    """
    registry = get_registry()
    
    if category:
        return registry.get_tools_by_category(category)
    else:
        return registry.get_all_tools()


def get_tool(name: str) -> Optional[BaseTool]:
    """
    Get a tool by name.
    
    Args:
        name: Tool name
    
    Returns:
        Tool instance or None if not found
    """
    registry = get_registry()
    return registry.get_tool(name)


def search_tools(query: str) -> List[BaseTool]:
    """
    Search for tools by name, description, or tags.
    
    Args:
        query: Search query
    
    Returns:
        List of matching tools
    """
    registry = get_registry()
    return registry.search_tools(query)


def export_tool_schemas(format: str = "openai", output_file: Optional[str] = None) -> List[Dict[str, Any]]:
    """
    Export tool schemas in specified format.
    
    Args:
        format: Output format ('openai', 'mcp', 'json')
        output_file: Optional file to save schemas to
    
    Returns:
        List of tool schemas
    """
    registry = get_registry()
    schemas = registry.export_schemas(format)
    
    if output_file:
        registry.save_schemas_to_file(output_file, format)
    
    return schemas


def generate_tool_documentation(output_file: Optional[str] = None) -> str:
    """
    Generate documentation for all tools.
    
    Args:
        output_file: Optional file to save documentation to
    
    Returns:
        Markdown formatted documentation
    """
    registry = get_registry()
    doc = registry.generate_documentation()
    
    if output_file:
        with open(output_file, 'w') as f:
            f.write(doc)
    
    return doc


def get_tool_statistics() -> Dict[str, Any]:
    """
    Get statistics about registered tools.
    
    Returns:
        Dictionary with tool statistics
    """
    registry = get_registry()
    return registry.get_statistics()


# CLI for tool registry management
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python -m tools.registry <command> [args]")
        print("\nCommands:")
        print("  list [category]          - List all tools or tools in a category")
        print("  search <query>           - Search for tools")
        print("  export <format> <file>   - Export schemas (openai/mcp/json)")
        print("  docs <file>              - Generate documentation")
        print("  stats                    - Show statistics")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "list":
        category = sys.argv[2] if len(sys.argv) > 2 else None
        if category:
            try:
                cat = ToolCategory(category)
                tools = list_tools(cat)
            except ValueError:
                print(f"Invalid category: {category}")
                sys.exit(1)
        else:
            tools = list_tools()
        
        for tool in tools:
            print(f"- {tool.name} ({tool.category.value}): {tool.description}")
    
    elif command == "search":
        if len(sys.argv) < 3:
            print("Usage: python -m tools.registry search <query>")
            sys.exit(1)
        
        query = sys.argv[2]
        tools = search_tools(query)
        
        print(f"Found {len(tools)} tools matching '{query}':")
        for tool in tools:
            print(f"- {tool.name}: {tool.description}")
    
    elif command == "export":
        if len(sys.argv) < 4:
            print("Usage: python -m tools.registry export <format> <file>")
            sys.exit(1)
        
        format = sys.argv[2]
        output_file = sys.argv[3]
        
        schemas = export_tool_schemas(format, output_file)
        print(f"Exported {len(schemas)} tool schemas to {output_file} in {format} format")
    
    elif command == "docs":
        if len(sys.argv) < 3:
            print("Usage: python -m tools.registry docs <file>")
            sys.exit(1)
        
        output_file = sys.argv[2]
        generate_tool_documentation(output_file)
        print(f"Generated documentation in {output_file}")
    
    elif command == "stats":
        stats = get_tool_statistics()
        print("Tool Statistics:")
        print(f"  Total Tools: {stats['total_tools']}")
        print(f"  Categories: {stats['categories']}")
        print(f"  Tools with Tags: {stats['tools_with_tags']}")
        print(f"  Average Parameters: {stats['average_parameters']:.1f}")
        print("\nBy Category:")
        for category, count in sorted(stats['by_category'].items()):
            print(f"  {category}: {count}")
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
