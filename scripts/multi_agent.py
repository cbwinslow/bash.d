#!/usr/bin/env python3
"""
Multi-Agent System Controller
AI agent with specialized sub-agents for system control.
"""

import os
import json
import asyncio
import subprocess
from datetime import datetime
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from enum import Enum
import signal

# Config
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "qwen3:4b")
BASHD_DIR = os.path.expanduser("~/bash.d")

class AgentStatus(Enum):
    IDLE = "idle"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"

@dataclass
class Agent:
    """Represents a sub-agent."""
    name: str
    role: str
    description: str
    command: str
    status: AgentStatus = AgentStatus.IDLE
    output: str = ""
    pid: Optional[int] = None
    started_at: Optional[datetime] = None

@dataclass
class Task:
    """Represents a task to be executed."""
    id: str
    description: str
    assigned_agent: Optional[str] = None
    status: str = "pending"
    result: str = ""
    created_at: datetime = field(default_factory=datetime.utcnow)

class SubAgent:
    """A specialized sub-agent for specific tasks."""
    
    def __init__(self, name: str, role: str, prompt_template: str):
        self.name = name
        self.role = role
        self.prompt_template = prompt_template
        self.history: List[Dict] = []
    
    def prepare_prompt(self, task: str, context: Dict = None) -> str:
        """Prepare the prompt for the agent."""
        context_str = ""
        if context:
            context_str = "\nContext:\n" + "\n".join([f"{k}: {v}" for k, v in context.items()])
        
        return self.prompt_template.format(task=task, context=context_str)
    
    async def run(self, task: str, context: Dict = None) -> str:
        """Run the agent with a task."""
        prompt = self.prepare_prompt(task, context)
        
        # Run ollama
        cmd = f'echo "{prompt}" | ollama run {OLLAMA_MODEL}'
        
        try:
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=120
            )
            
            output = result.stdout if result.returncode == 0 else result.stderr
            
            self.history.append({
                "task": task,
                "output": output,
                "timestamp": datetime.utcnow().isoformat()
            })
            
            return output
        except subprocess.TimeoutExpired:
            return "Agent timeout"
        except Exception as e:
            return f"Agent error: {e}"


# ====================
# Specialized Sub-Agents
# ====================

class MonitorAgent(SubAgent):
    """Agent for monitoring system resources."""
    
    def __init__(self):
        super().__init__(
            name="monitor",
            role="System Monitor",
            prompt_template="""You are a system monitoring agent. Analyze the current system state and provide recommendations.

Task: {task}
{context}

Provide a brief analysis and any actionable recommendations."""
        )
    
    def get_context(self) -> Dict:
        """Get current system context."""
        try:
            # Memory
            mem_result = subprocess.run("free -h", shell=True, capture_output=True, text=True)
            # CPU
            cpu_result = subprocess.run("top -bn1 | head -5", shell=True, capture_output=True, text=True)
            # Disk
            disk_result = subprocess.run("df -h", shell=True, capture_output=True, text=True)
            
            return {
                "memory": mem_result.stdout,
                "cpu": cpu_result.stdout,
                "disk": disk_result.stdout
            }
        except:
            return {}


class DebugAgent(SubAgent):
    """Agent for debugging issues."""
    
    def __init__(self):
        super().__init__(
            name="debug",
            role="Debug Agent",
            prompt_template="""You are a debugging agent. Analyze the error or issue and provide solutions.

Task: {task}
{context}

Provide:
1. Root cause analysis
2. Specific fix commands
3. Prevention tips"""
        )


class SecurityAgent(SubAgent):
    """Agent for security analysis."""
    
    def __init__(self):
        super().__init__(
            name="security",
            role="Security Analyst",
            prompt_template="""You are a security agent. Analyze for potential security issues.

Task: {task}
{context}

Check for:
1. Unusual processes
2. Open ports
3. Failed login attempts
4. Suspicious files

Provide findings and recommendations."""
        )
    
    def get_context(self) -> Dict:
        """Get security context."""
        try:
            # Processes
            proc_result = subprocess.run("ps aux --sort=-%mem | head -10", shell=True, capture_output=True, text=True)
            # Connections
            conn_result = subprocess.run("ss -tunap | head -10", shell=True, capture_output=True, text=True)
            # Auth logs
            auth_result = subprocess.run("tail -20 /var/log/auth.log 2>/dev/null || tail -20 /var/log/secure 2>/dev/null || echo 'No auth logs'", 
                                       shell=True, capture_output=True, text=True)
            
            return {
                "top_processes": proc_result.stdout,
                "connections": conn_result.stdout,
                "auth_logs": auth_result.stdout
            }
        except:
            return {}


class NetworkAgent(SubAgent):
    """Agent for network analysis."""
    
    def __init__(self):
        super().__init__(
            name="network",
            role="Network Analyst",
            prompt_template="""You are a network analysis agent.

Task: {task}
{context}

Analyze network state and provide recommendations."""
        )


class CleanupAgent(SubAgent):
    """Agent for system cleanup tasks."""
    
    def __init__(self):
        super().__init__(
            name="cleanup",
            role="Cleanup Agent",
            prompt_template="""You are a cleanup agent. Analyze what can be cleaned up and provide commands.

Task: {task}
{context}

Analyze:
1. Docker resources
2. Cache files
3. Old logs
4. Temporary files

Provide safe cleanup commands. Ask for confirmation before executing."""
        )
    
    def get_context(self) -> Dict:
        """Get cleanup context."""
        try:
            docker_result = subprocess.run("docker system df", shell=True, capture_output=True, text=True)
            cache_result = subprocess.run("du -sh ~/.cache 2>/dev/null || echo 'No cache'", shell=True, capture_output=True, text=True)
            
            return {
                "docker": docker_result.stdout,
                "cache": cache_result.stdout
            }
        except:
            return {}


# ====================
# Multi-Agent Controller
# ====================

class MultiAgentController:
    """Main controller for multi-agent system."""
    
    def __init__(self):
        self.agents: Dict[str, SubAgent] = {
            "monitor": MonitorAgent(),
            "debug": DebugAgent(),
            "security": SecurityAgent(),
            "network": NetworkAgent(),
            "cleanup": CleanupAgent(),
        }
        self.tasks: List[Task] = []
        self.task_id_counter = 0
    
    def create_task(self, description: str, agent_name: str = None) -> Task:
        """Create a new task."""
        self.task_id_counter += 1
        task = Task(
            id=f"task_{self.task_id_counter}",
            description=description,
            assigned_agent=agent_name
        )
        self.tasks.append(task)
        return task
    
    async def route_task(self, task: Task) -> str:
        """Route task to appropriate agent."""
        # Auto-route based on task description
        description = task.description.lower()
        
        if any(w in description for w in ["monitor", "memory", "cpu", "process", "performance"]):
            agent_name = "monitor"
        elif any(w in description for w in ["debug", "error", "issue", "problem", "fix"]):
            agent_name = "debug"
        elif any(w in description for w in ["security", "secure", "port", "login", "intrusion"]):
            agent_name = "security"
        elif any(w in description for w in ["network", "connection", "dns", "firewall"]):
            agent_name = "network"
        elif any(w in description for w in ["cleanup", "clean", "remove", "delete", "free space"]):
            agent_name = "cleanup"
        else:
            # Default to monitor
            agent_name = "monitor"
        
        task.assigned_agent = agent_name
        agent = self.agents[agent_name]
        
        # Get context for the agent
        context = {}
        if hasattr(agent, 'get_context'):
            context = agent.get_context()
        
        # Run the agent
        result = await agent.run(task.description, context)
        
        task.status = "completed"
        task.result = result
        
        return result
    
    async def run_task(self, task_description: str) -> str:
        """Run a task with automatic routing."""
        task = self.create_task(task_description)
        return await self.route_task(task)
    
    async def run_multi(self, tasks: List[str]) -> Dict[str, str]:
        """Run multiple tasks in parallel."""
        results = {}
        
        # Run all tasks concurrently
        task_coroutines = [self.run_task(t) for t in tasks]
        results_list = await asyncio.gather(*task_coroutines)
        
        for task, result in zip(self.tasks, results_list):
            results[task.id] = result
        
        return results
    
    def list_agents(self) -> List[Dict]:
        """List available agents."""
        return [
            {
                "name": agent.name,
                "role": agent.role,
                "history_count": len(agent.history)
            }
            for agent in self.agents.values()
        ]
    
    def get_agent_history(self, agent_name: str) -> List[Dict]:
        """Get agent execution history."""
        if agent_name in self.agents:
            return self.agents[agent_name].history
        return []


# ====================
# CLI Interface
# ====================

async def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Multi-Agent System Controller")
    parser.add_argument("task", nargs="?", help="Task to execute")
    parser.add_argument("--agent", "-a", help="Specific agent to use")
    parser.add_argument("--list", "-l", action="store_true", help="List available agents")
    parser.add_argument("--history", help="Show agent history")
    
    args = parser.parse_args()
    
    controller = MultiAgentController()
    
    if args.list:
        print("━━━ Available Agents ━━━")
        for agent in controller.list_agents():
            print(f"  {agent['name']:12} - {agent['role']} (history: {agent['history_count']})")
        return
    
    if args.history:
        history = controller.get_agent_history(args.history)
        print(f"━━━ {args.history} History ━━━")
        for h in history[-5:]:
            print(f"\nTask: {h['task']}")
            print(f"Output: {h['output'][:200]}...")
        return
    
    if args.task:
        print(f"━━━ Running Task ━━━")
        print(f"Task: {args.task}\n")
        
        result = await controller.run_task(args.task)
        
        print(f"\n━━━ Result ━━━")
        print(result)
    else:
        print("Usage: multi_agent.py <task> [--agent <name>]")
        print("       multi_agent.py --list")
        print("       multi_agent.py --history <agent>")


if __name__ == "__main__":
    asyncio.run(main())
