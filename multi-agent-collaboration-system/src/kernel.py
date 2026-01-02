"""
This module defines the core components of the agent system, including the base Agent class.
"""

from dataclasses import dataclass, field
from typing import List, Any

@dataclass
class Agent:
    """
    Represents an AI agent in the system.
    """
    name: str
    role: str
    goal: str
    backstory: str
    tools: List[Any] = field(default_factory=list)
    llm: Any = None

    def __post_init__(self):
        print(f"Agent '{self.name}' ({self.role}) has been initialized.")

    def execute_task(self, task):
        """
        A placeholder for the agent's task execution logic.
        """
        print(f"Agent '{self.name}' is executing task: {task}")
        # In a real implementation, this would involve planning,
        # tool usage, and interaction with the LLM.
        return f"Task '{task}' completed by '{self.name}'."
