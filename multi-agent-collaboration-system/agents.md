# Agents

This document defines the structure and roles of agents within the Multi-Agent Collaboration System.

## Agent Architecture

An Agent is a Python object that encapsulates the following properties:

- **`name`**: A unique identifier for the agent (e.g., `github_researcher`).
- **`role`**: A high-level description of the agent's purpose (e.g., "Researches and analyzes GitHub repositories").
- **`goal`**: The agent's primary objective.
- **`backstory`**: A narrative description of the agent's background and expertise.
- **`tools`**: A list of tools the agent is equipped to use (e.g., `[github_client, web_search]`).
- **`llm`**: The language model configuration the agent uses.

## Core Agents

The framework will be initialized with a set of core agents:

### 1. Orchestrator Agent
- **Role**: Project Manager
- **Goal**: To understand the user's high-level goal, break it down into tasks, and delegate those tasks to the appropriate specialist agents.
- **Tools**: Task management tools, communication bus.

### 2. Code-Monkey Agent
- **Role**: Software Developer
- **Goal**: To write, modify, and review code based on instructions from the Orchestrator.
- **Tools**: File I/O, Code linters, testing frameworks.

### 3. GitHub Agent
- **Role**: DevOps & GitHub Specialist
- **Goal**: To interact with GitHub repositories, manage issues, pull requests, and perform repository analysis.
- **Tools**: A comprehensive `github_client` with methods for search, file access, and repository modifications.

### 4. Memory Agent
- **Role**: Librarian / Archivist
- **Goal**: To manage the shared memory. It is responsible for storing new information and retrieving relevant context for other agents.
- **Tools**: `memory_client` for interfacing with the shared memory store (e.g., Mem0).

## Agent Onboarding

New agents can be defined and registered with the system. The process for onboarding a new agent is detailed in `docs/procedures/agent_onboarding.md`.
