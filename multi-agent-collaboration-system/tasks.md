# Project Tasks & Todos

This document breaks down the work required to build the initial version of the Multi-Agent Collaboration System.

## Epic 1: Build the Foundational Framework

### Task 1.1: Project Setup & Structure
- **Micro-goal**: Create the initial project directory structure and documentation.
- **Test**: All files and directories listed in the initial plan exist. The project can be linted with `ruff` without errors.

### Task 1.2: Implement Agent Kernel
- **Micro-goal**: Create the base `Agent` class and a registry for managing agent instances.
- **Test**: A unit test can successfully create two different agent instances (e.g., `Code-Monkey Agent`, `GitHub Agent`) and register them in a central agent registry.

### Task 1.3: Implement Basic Orchestrator
- **Micro-goal**: Create an `Orchestrator` class that can hold a queue of tasks and delegate a simple task to a registered agent.
- **Test**: A unit test can add a task to the orchestrator's queue, and the orchestrator can successfully identify and "delegate" the task to the correct agent based on a simple role match. The delegation can be verified with a mock.

## Epic 2: Implement Core Modules

### Task 2.1: Develop In-Memory Shared Context
- **Micro-goal**: Implement a simple dictionary-based class that allows agents to set and get key-value pairs.
- **Test**: A test shows that Agent A can write a value to the context, and Agent B can successfully read that same value.

### Task 2.2: Build the GitHub Client (Read-Only)
- **Micro-goal**: Implement the `github_client.py` module with functions for searching repositories and getting file contents. The client must be authenticated.
- **Test**: 
    - A test can successfully search for a public repository (e.g., 'gemini-cli/gemini-cli') and get a result.
    - A test can successfully read the contents of a known file from that public repository (e.g., its `README.md`).

### Task 2.3: Implement Structured Logging
- **Micro-goal**: Configure the Python `logging` module to output structured JSON logs to the console.
- **Test**: Running the `main.py` script produces at least one log message on the console in a valid JSON format.
