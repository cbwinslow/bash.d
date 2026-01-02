"""
Main entry point for the Multi-Agent Collaboration System.
"""

import json
import os
from collections import deque
import time
from . import agent_registry # Import the agent registry

class Orchestrator:
    """
    The main orchestrator for the multi-agent system.
    Manages task queues and delegates tasks to appropriate agents.
    """
    def __init__(self, config):
        self.config = config
        self.task_queue = deque() # Use a deque for efficient task management
        print("Orchestrator initialized.")

    def add_task(self, task_description: str, assigned_agent_role: str):
        """
        Adds a new task to the orchestrator's queue.
        """
        task = {
            "description": task_description,
            "assigned_agent_role": assigned_agent_role,
            "status": "PENDING"
        }
        self.task_queue.append(task)
        print(f"Task '{task_description}' added to queue, assigned to role '{assigned_agent_role}'.")

    def delegate_task(self, task: dict):
        """
        Delegates a task to an agent based on its assigned role.
        """
        agent_role = task.get("assigned_agent_role")
        if not agent_role:
            print(f"Error: Task '{task['description']}' has no assigned agent role.")
            task["status"] = "FAILED"
            return

        try:
            # In a real system, we would match agent_role to agent_name more intelligently
            # For now, let's assume agent_role is directly the agent_name for simplicity
            agent_name = agent_role # Simplified for this basic implementation
            agent = agent_registry.get_agent(agent_name)
            
            print(f"Orchestrator delegating task '{task['description']}' to agent '{agent.name}'.")
            task["status"] = "IN_PROGRESS"
            result = agent.execute_task(task["description"])
            task["status"] = "COMPLETED"
            print(f"Agent '{agent.name}' completed task '{task['description']}' with result: {result}")
        except ValueError as e:
            print(f"Error delegating task '{task['description']}': {e}")
            task["status"] = "FAILED"
        except Exception as e:
            print(f"Unexpected error during task delegation for '{task['description']}': {e}")
            task["status"] = "FAILED"

    def run(self):
        """
        The main loop for the orchestrator, processing tasks from the queue.
        """
        print("Orchestrator is running. Processing tasks...")
        if not self.task_queue:
            print("Task queue is empty. Nothing to do.")
            return

        while self.task_queue:
            task = self.task_queue.popleft() # Get the oldest task
            print(f"Orchestrator picking up task: {task['description']}")
            self.delegate_task(task)
            time.sleep(1) # Simulate some work/delay between tasks
        
        print("All tasks processed.")
def load_config():
    """
    Loads the configuration from a local or default config file.
    """
    local_config_path = 'config.local.json'
    default_config_path = 'config.json'

    config_path = local_config_path if os.path.exists(local_config_path) else default_config_path

    with open(config_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def main():
    """
    Main function.
    """
    print("Starting Multi-Agent Collaboration System...")
    config = load_config()
    orchestrator = Orchestrator(config)
    orchestrator.run()
    print("System finished.")

if __name__ == "__main__":
    main()
