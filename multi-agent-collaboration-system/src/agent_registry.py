"""
This module provides a registry for managing and accessing agent instances.
"""

from .kernel import Agent

# A dictionary to hold agent creation functions.
# The key is the agent's name, and the value is a function that returns an Agent instance.
_agent_registry = {}

def register_agent(name: str, creation_func: callable):
    """
    Registers an agent creation function.
    """
    if name in _agent_registry:
        print(f"Warning: Agent '{name}' is already registered. Overwriting.")
    _agent_registry[name] = creation_func
    print(f"Agent '{name}' registered.")

def get_agent(name: str) -> Agent:
    """
    Gets an agent instance from the registry.
    """
    if name not in _agent_registry:
        raise ValueError(f"Agent '{name}' is not registered.")
    
    creation_func = _agent_registry[name]
    return creation_func()

def list_agents() -> list[str]:
    """
    Returns a list of all registered agent names.
    """
    return list(_agent_registry.keys())
