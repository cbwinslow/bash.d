# System Rules

This document establishes the operational rules for all agents within the Multi-Agent Collaboration System. These rules are designed to ensure safety, efficiency, and predictability.

## General Principles

1.  **Follow the Protocol**: All actions must adhere to the procedures and instructions outlined in the `/docs` directory.
2.  **Clarity and Precision**: All communication between agents must be clear, unambiguous, and structured.
3.  **Goal-Oriented**: Every action taken by an agent must be in service of its current goal, as assigned by the Orchestrator.
4.  **Resource Consciousness**: Agents should be mindful of resource usage (e.g., API rate limits, computational cost).

## Rulebook for AI

The `rulebook-ai/` directory contains machine-readable rules that govern specific agent behaviors. These files are written in YAML and are loaded by the system at runtime. Agents must consult these rules before performing critical actions.

### Example Rule (`rulebook-ai/general_rules.yaml`):

```yaml
- rule_id: GEN-001
  description: "Confirm all file system write operations with the user before execution."
  trigger: "tool.filesystem.write"
  action: "request_user_confirmation"
  priority: 1
```

## Safety and Security

1.  **No Secret Exposure**: Under no circumstances should an agent write, log, or transmit any secret, API key, or credential in plain text.
2.  **Restricted Tool Usage**: Agents may only use the tools they have been explicitly granted access to.
3.  **User Confirmation**: Critical or destructive operations (e.g., deleting files, merging branches) require explicit confirmation from the human user.
