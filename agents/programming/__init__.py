"""
Programming Agents

This module contains specialized programming language agents for the multi-agent system.
Includes agents for Python, JavaScript, TypeScript, Rust, Go, Java, C#, C++, PHP, and Ruby.
"""

from .python_backend_developer_agent import PythonBackendDeveloperAgent
from .javascript_full_stack_developer_agent import JavaScriptFullStackDeveloperAgent
from .typescript_full_stack_developer_agent import TypeScriptFullStackDeveloperAgent
from .rust_systems_developer_agent import RustSystemsDeveloperAgent
from .go_cloud_developer_agent import GoCloudDeveloperAgent
from .java_enterprise_developer_agent import JavaEnterpriseDeveloperAgent
from .csharp_dotnet_developer_agent import CSharpDotnetDeveloperAgent
from .cpp_performance_developer_agent import CppPerformanceDeveloperAgent
from .php_web_developer_agent import PHPWebDeveloperAgent
from .ruby_rails_developer_agent import RubyRailsDeveloperAgent

__all__ = [
    "PythonBackendDeveloperAgent",
    "JavaScriptFullStackDeveloperAgent",
    "TypeScriptFullStackDeveloperAgent",
    "RustSystemsDeveloperAgent",
    "GoCloudDeveloperAgent",
    "JavaEnterpriseDeveloperAgent",
    "CSharpDotnetDeveloperAgent",
    "CppPerformanceDeveloperAgent",
    "PHPWebDeveloperAgent",
    "RubyRailsDeveloperAgent",
]

# Registry for easy access
PROGRAMMING_AGENTS = {
    "python": PythonBackendDeveloperAgent,
    "javascript": JavaScriptFullStackDeveloperAgent,
    "typescript": TypeScriptFullStackDeveloperAgent,
    "rust": RustSystemsDeveloperAgent,
    "go": GoCloudDeveloperAgent,
    "java": JavaEnterpriseDeveloperAgent,
    "csharp": CSharpDotnetDeveloperAgent,
    "cpp": CppPerformanceDeveloperAgent,
    "php": PHPWebDeveloperAgent,
    "ruby": RubyRailsDeveloperAgent,
}


def create_programming_agent(language: str, **kwargs):
    """Create a programming agent by language name."""
    agent_class = PROGRAMMING_AGENTS.get(language.lower())
    if not agent_class:
        raise ValueError(f"Unsupported programming language: {language}")
    return agent_class(**kwargs)


def list_programming_agents():
    """List all available programming agent languages."""
    return list(PROGRAMMING_AGENTS.keys())
