# Multi-Agent Collaboration System

This project is a framework for building and orchestrating a multi-agent AI system. It provides a foundation for creating collaborative AI agents that can work together to solve complex tasks, share information through a persistent memory store, and leverage external tools.

## Core Concepts

- **Agent**: An autonomous AI entity with a specific role, set of tools, and capabilities.
- **Orchestrator**: A component that manages the assignment of tasks to agents and coordinates their collaboration.
- **Shared Memory**: A centralized, persistent memory store (e.g., using Mem0) that allows agents to share knowledge and maintain context across sessions.
- **Tools**: External modules or APIs that agents can use to interact with the outside world (e.g., a GitHub client, a web search tool).

## Getting Started

1.  **Initialize the Git Repository**:
    ```bash
    git init
    git add .
    git commit -m "Initial project structure and documentation"
    ```

2.  **Set up Python Environment**:
    It is recommended to use a virtual environment.
    ```bash
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    ```

3.  **Configure the System**:
    Copy `config.json` to `config.local.json` and populate it with your specific API keys and settings. The application will load `config.local.json` by default, which is git-ignored.

4.  **Run the Application**:
    ```bash
    python src/main.py
    ```
