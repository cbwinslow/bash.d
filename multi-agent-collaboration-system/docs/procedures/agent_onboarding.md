# Agent Onboarding Procedure

This document describes the procedure for creating and registering a new agent with the system.

## 1. Prerequisites

- A clear definition of the agent's `role`, `goal`, and `backstory`.
- A list of the specific `tools` the agent will need to accomplish its goal.

## 2. Procedure

1.  **Define the Agent Class**:
    - Create a new Python file in the `src/agents/` directory (e.g., `src/agents/research_agent.py`).
    - In this file, define a new agent configuration dictionary or class.

    ```python
    # src/agents/research_agent.py

    from ..kernel import Agent

    def create_research_agent():
        return Agent(
            name="research_agent",
            role="Web Researcher",
            goal="To find and synthesize information from the web on a given topic.",
            backstory="An expert researcher skilled in using web search tools to find the most relevant and accurate information.",
            tools=["web_search"]
        )
    ```

2.  **Register the Agent**:
    - Open the agent registry file (e.g., `src/agent_registry.py`).
    - Import your new agent creation function and add it to the registry.

    ```python
    # src/agent_registry.py

    from .agents.research_agent import create_research_agent
    # ... other agent imports

    AGENT_REGISTRY = {
        "researcher": create_research_agent,
        # ... other agents
    }
    ```

3.  **Implement Required Tools**:
    - Ensure that all tools listed in the agent's `tools` array are implemented and registered in the `src/tools/` directory.

4.  **Create a Test Case**:
    - Add a new test file in the `tests/agents/` directory.
    - Write a unit test to verify that the new agent can be created and that its properties are correctly defined.
