# Task Execution Protocol

This document outlines the protocol for how tasks are assigned, executed, and completed by agents. All agents must adhere to this protocol.

## 1. Task Lifecycle

A task progresses through the following states:
- `PENDING`: The task has been created but not yet assigned.
- `ASSIGNED`: The task has been assigned to an agent by the Orchestrator.
- `IN_PROGRESS`: The agent has started working on the task.
- `COMPLETED`: The agent has successfully completed the task and produced an output.
- `FAILED`: The agent was unable to complete the task.

## 2. Protocol Steps

1.  **Task Creation**: A new task is created with a clear, specific goal and any necessary context.
2.  **Task Assignment**: The `Orchestrator` agent dequeues a `PENDING` task. It analyzes the task goal and selects the agent with the most appropriate `role` from the agent registry. The task state is changed to `ASSIGNED`.
3.  **Task Execution**:
    - The assigned agent receives the task. It's state becomes `IN_PROGRESS`.
    - The agent develops a step-by-step plan to achieve the task's goal.
    - The agent executes the plan, using its assigned `tools` as needed.
    - Throughout the process, the agent logs its actions and intermediate results to the `Shared Memory` module. This provides a "train of thought" that is visible to other agents and the user.
4.  **Task Completion**:
    - Upon successful completion, the agent saves its final output to the `Shared Memory` with a reference to the original task.
    - The agent reports the completion to the `Orchestrator`.
    - The task state is changed to `COMPLETED`.
5.  **Error Handling**:
    - If an agent fails to complete a task, it must log the error details to the `Shared Memory`.
    - The agent reports the failure to the `Orchestrator`.
    - The task state is changed to `FAILED`. The `Orchestrator` may then decide to re-assign the task or alert the user.
