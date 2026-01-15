"""
Master AI Agent - Autonomous Software Development System

This module implements a master AI agent capable of:
- Summoning and managing sub-agents for specialized tasks
- Coordinating coding, debugging, and testing agents
- Using available tools for autonomous software development
- Creating complete software applications without human intervention
"""

import asyncio
import logging
from typing import List, Dict, Any, Optional, Set
from datetime import datetime, timezone
from enum import Enum

from .base import (
    BaseAgent,
    Task,
    TaskStatus,
    TaskPriority,
    AgentStatus,
    AgentType,
    AgentMessage,
    CommunicationProtocol
)
from .orchestrator import AgentOrchestrator, OrchestrationStrategy
from tools.registry import ToolRegistry

logger = logging.getLogger(__name__)


class ProjectPhase(str, Enum):
    """Software development project phases"""
    PLANNING = "planning"
    DESIGN = "design"
    IMPLEMENTATION = "implementation"
    TESTING = "testing"
    DEBUGGING = "debugging"
    DOCUMENTATION = "documentation"
    DEPLOYMENT = "deployment"
    COMPLETED = "completed"
    FAILED = "failed"


class DevelopmentWorkflow(str, Enum):
    """Common development workflows"""
    WEB_APP = "web_app"
    API_SERVICE = "api_service"
    CLI_TOOL = "cli_tool"
    LIBRARY = "library"
    MICROSERVICE = "microservice"
    FULL_STACK = "full_stack"
    DATA_PIPELINE = "data_pipeline"
    ML_MODEL = "ml_model"


class SoftwareProject:
    """Represents a software development project"""
    
    def __init__(
        self,
        name: str,
        description: str,
        workflow: DevelopmentWorkflow,
        requirements: Dict[str, Any]
    ):
        self.id = f"project_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}"
        self.name = name
        self.description = description
        self.workflow = workflow
        self.requirements = requirements
        self.phase = ProjectPhase.PLANNING
        self.tasks: List[Task] = []
        self.completed_tasks: List[Task] = []
        self.agents_assigned: Set[str] = set()
        self.artifacts: Dict[str, Any] = {}
        self.created_at = datetime.now(timezone.utc)
        self.updated_at = datetime.now(timezone.utc)
        self.error_log: List[str] = []
        
    def update_phase(self, phase: ProjectPhase):
        """Update project phase"""
        self.phase = phase
        self.updated_at = datetime.now(timezone.utc)
        logger.info(f"Project {self.name} moved to phase: {phase.value}")
    
    def add_task(self, task: Task):
        """Add a task to the project"""
        self.tasks.append(task)
        task.metadata["project_id"] = self.id
    
    def complete_task(self, task: Task):
        """Mark a task as completed"""
        if task in self.tasks:
            self.tasks.remove(task)
            self.completed_tasks.append(task)
    
    def log_error(self, error: str):
        """Log an error in the project"""
        self.error_log.append(f"[{datetime.now(timezone.utc).isoformat()}] {error}")
        logger.error(f"Project {self.name} error: {error}")
    
    def get_progress(self) -> Dict[str, Any]:
        """Get project progress summary"""
        total_tasks = len(self.tasks) + len(self.completed_tasks)
        completed = len(self.completed_tasks)
        progress_pct = (completed / total_tasks * 100) if total_tasks > 0 else 0
        
        return {
            "project_id": self.id,
            "name": self.name,
            "phase": self.phase.value,
            "progress_percent": progress_pct,
            "tasks_total": total_tasks,
            "tasks_completed": completed,
            "tasks_pending": len(self.tasks),
            "agents_working": len(self.agents_assigned),
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat()
        }


class MasterAgent:
    """
    Master AI Agent - Autonomous Software Development Orchestrator
    
    This agent serves as the central intelligence that:
    1. Analyzes requirements and creates development plans
    2. Summons specialized sub-agents (coding, testing, debugging, etc.)
    3. Coordinates agent teams for complex projects
    4. Uses available tools for code generation, testing, and deployment
    5. Monitors progress and adapts strategies
    6. Ensures quality through automated testing and review
    7. Operates autonomously without human intervention
    
    Capabilities:
    - Intelligent task decomposition
    - Agent summoning and coordination
    - Tool utilization and integration
    - Error detection and self-correction
    - Continuous learning and improvement
    - Multi-project management
    """
    
    def __init__(self, name: str = "Master AI Agent", agent_type: AgentType = AgentType.AUTOMATION):
        # Core identity
        self.name = name
        self.type = agent_type
        self.description = (
            "Master orchestrator capable of autonomous software development. "
            "Can summon sub-agents, coordinate development teams, and use tools "
            "to create complete software applications."
        )
        self.created_at = datetime.now(timezone.utc)
        self.status = AgentStatus.IDLE
        
        # Master agent components
        self.orchestrator = AgentOrchestrator(
            strategy=OrchestrationStrategy.SPECIALIZED,
            max_concurrent_tasks=50,
            health_check_interval=30
        )
        
        self.tool_registry = ToolRegistry()
        
        # Project management
        self.active_projects: Dict[str, SoftwareProject] = {}
        self.completed_projects: List[SoftwareProject] = []
        
        # Agent pool
        self.agent_pool: Dict[AgentType, List[BaseAgent]] = {}
        
        # Learning and adaptation
        self.success_patterns: List[Dict[str, Any]] = []
        self.failure_patterns: List[Dict[str, Any]] = []
        
        # Statistics
        self.projects_completed = 0
        self.projects_failed = 0
        self.agents_summoned = 0
        self.tools_used = 0
    
    def summon_agent(self, agent_type: AgentType, count: int = 1) -> List[BaseAgent]:
        """
        Summon specialized sub-agents
        
        Args:
            agent_type: Type of agent to summon
            count: Number of agents to summon
            
        Returns:
            List of summoned agents
        """
        summoned = []
        
        for i in range(count):
            # Create agent based on type
            agent = self._create_specialized_agent(agent_type, i)
            
            # Register with orchestrator
            self.orchestrator.register_agent(agent)
            
            # Add to pool
            if agent_type not in self.agent_pool:
                self.agent_pool[agent_type] = []
            self.agent_pool[agent_type].append(agent)
            
            summoned.append(agent)
            self.agents_summoned += 1
            
            logger.info(f"Summoned {agent_type.value} agent: {agent.name}")
        
        return summoned
    
    def _create_specialized_agent(self, agent_type: AgentType, index: int) -> BaseAgent:
        """Create a specialized agent instance"""
        agent_configs = {
            AgentType.PROGRAMMING: {
                "name": f"Coding Agent #{index + 1}",
                "description": "Specialized in writing clean, efficient code"
            },
            AgentType.TESTING: {
                "name": f"Testing Agent #{index + 1}",
                "description": "Specialized in creating comprehensive tests"
            },
            AgentType.SECURITY: {
                "name": f"Security Agent #{index + 1}",
                "description": "Specialized in security analysis and vulnerability detection"
            },
            AgentType.DEVOPS: {
                "name": f"DevOps Agent #{index + 1}",
                "description": "Specialized in deployment and infrastructure"
            },
            AgentType.DOCUMENTATION: {
                "name": f"Documentation Agent #{index + 1}",
                "description": "Specialized in creating clear documentation"
            }
        }
        
        config = agent_configs.get(agent_type, {
            "name": f"{agent_type.value} Agent #{index + 1}",
            "description": f"Specialized {agent_type.value} agent"
        })
        
        return BaseAgent(
            type=agent_type,
            name=config["name"],
            description=config["description"]
        )
    
    async def create_project(
        self,
        name: str,
        description: str,
        workflow: DevelopmentWorkflow,
        requirements: Dict[str, Any]
    ) -> SoftwareProject:
        """
        Create and initialize a new software project
        
        Args:
            name: Project name
            description: Project description
            workflow: Development workflow type
            requirements: Project requirements and specifications
            
        Returns:
            Created project
        """
        project = SoftwareProject(name, description, workflow, requirements)
        self.active_projects[project.id] = project
        
        logger.info(f"Created project: {name} ({workflow.value})")
        
        # Analyze and plan
        await self._analyze_requirements(project)
        await self._create_development_plan(project)
        
        return project
    
    async def _analyze_requirements(self, project: SoftwareProject):
        """Analyze project requirements and determine needed resources"""
        logger.info(f"Analyzing requirements for {project.name}")
        
        # Determine required agent types
        agent_needs = self._determine_agent_needs(project.workflow)
        
        # Summon required agents
        for agent_type, count in agent_needs.items():
            self.summon_agent(agent_type, count)
        
        project.update_phase(ProjectPhase.DESIGN)
    
    def _determine_agent_needs(self, workflow: DevelopmentWorkflow) -> Dict[AgentType, int]:
        """Determine what agents are needed for a workflow"""
        workflow_agents = {
            DevelopmentWorkflow.WEB_APP: {
                AgentType.PROGRAMMING: 2,
                AgentType.TESTING: 1,
                AgentType.DOCUMENTATION: 1
            },
            DevelopmentWorkflow.API_SERVICE: {
                AgentType.PROGRAMMING: 2,
                AgentType.TESTING: 1,
                AgentType.SECURITY: 1,
                AgentType.DOCUMENTATION: 1
            },
            DevelopmentWorkflow.CLI_TOOL: {
                AgentType.PROGRAMMING: 1,
                AgentType.TESTING: 1,
                AgentType.DOCUMENTATION: 1
            },
            DevelopmentWorkflow.LIBRARY: {
                AgentType.PROGRAMMING: 2,
                AgentType.TESTING: 1,
                AgentType.DOCUMENTATION: 1
            },
            DevelopmentWorkflow.MICROSERVICE: {
                AgentType.PROGRAMMING: 2,
                AgentType.TESTING: 1,
                AgentType.SECURITY: 1,
                AgentType.DEVOPS: 1,
                AgentType.DOCUMENTATION: 1
            },
            DevelopmentWorkflow.FULL_STACK: {
                AgentType.PROGRAMMING: 3,
                AgentType.TESTING: 2,
                AgentType.SECURITY: 1,
                AgentType.DEVOPS: 1,
                AgentType.DOCUMENTATION: 1
            },
            DevelopmentWorkflow.DATA_PIPELINE: {
                AgentType.PROGRAMMING: 2,
                AgentType.DATA: 1,
                AgentType.TESTING: 1,
                AgentType.DOCUMENTATION: 1
            },
            DevelopmentWorkflow.ML_MODEL: {
                AgentType.PROGRAMMING: 2,
                AgentType.DATA: 2,
                AgentType.TESTING: 1,
                AgentType.DOCUMENTATION: 1
            }
        }
        
        return workflow_agents.get(workflow, {
            AgentType.PROGRAMMING: 1,
            AgentType.TESTING: 1
        })
    
    async def _create_development_plan(self, project: SoftwareProject):
        """Create a detailed development plan with tasks"""
        logger.info(f"Creating development plan for {project.name}")
        
        # Generate tasks based on workflow
        tasks = self._generate_workflow_tasks(project)
        
        # Add tasks to project
        for task in tasks:
            project.add_task(task)
            self.orchestrator.submit_task(task)
        
        project.update_phase(ProjectPhase.IMPLEMENTATION)
    
    def _generate_workflow_tasks(self, project: SoftwareProject) -> List[Task]:
        """Generate tasks for a project based on its workflow"""
        tasks = []
        
        # Common tasks for all workflows
        base_tasks = [
            Task(
                title=f"Setup Project Structure - {project.name}",
                description="Create project directory structure and configuration files",
                agent_type=AgentType.PROGRAMMING,
                priority=TaskPriority.HIGH,
                input_data={"project": project.name, "workflow": project.workflow.value}
            ),
            Task(
                title=f"Implement Core Functionality - {project.name}",
                description=f"Implement main features: {project.description}",
                agent_type=AgentType.PROGRAMMING,
                priority=TaskPriority.HIGH,
                input_data={"requirements": project.requirements}
            ),
            Task(
                title=f"Create Unit Tests - {project.name}",
                description="Write comprehensive unit tests for core functionality",
                agent_type=AgentType.TESTING,
                priority=TaskPriority.MEDIUM,
                input_data={"project": project.name}
            ),
            Task(
                title=f"Generate Documentation - {project.name}",
                description="Create README, API docs, and usage examples",
                agent_type=AgentType.DOCUMENTATION,
                priority=TaskPriority.MEDIUM,
                input_data={"project": project.name}
            )
        ]
        
        tasks.extend(base_tasks)
        
        # Workflow-specific tasks
        if project.workflow == DevelopmentWorkflow.API_SERVICE:
            tasks.append(Task(
                title=f"Security Audit - {project.name}",
                description="Perform security analysis and vulnerability scanning",
                agent_type=AgentType.SECURITY,
                priority=TaskPriority.HIGH
            ))
        
        elif project.workflow == DevelopmentWorkflow.MICROSERVICE:
            tasks.append(Task(
                title=f"Setup Deployment Pipeline - {project.name}",
                description="Configure CI/CD and containerization",
                agent_type=AgentType.DEVOPS,
                priority=TaskPriority.MEDIUM
            ))
        
        return tasks
    
    async def execute_project(self, project_id: str) -> bool:
        """
        Execute a project autonomously
        
        Args:
            project_id: ID of the project to execute
            
        Returns:
            True if successful, False otherwise
        """
        if project_id not in self.active_projects:
            logger.error(f"Project not found: {project_id}")
            return False
        
        project = self.active_projects[project_id]
        
        logger.info(f"Starting execution of project: {project.name}")
        
        try:
            # Start orchestrator to execute tasks
            orchestrator_task = asyncio.create_task(self.orchestrator.run())
            
            # Monitor progress
            while project.tasks:
                await asyncio.sleep(5)
                
                # Check for completed tasks
                completed = [t for t in project.tasks if t.status == TaskStatus.COMPLETED]
                for task in completed:
                    project.complete_task(task)
                
                # Check for failed tasks
                failed = [t for t in project.tasks if t.status == TaskStatus.FAILED]
                if failed:
                    logger.warning(f"Found {len(failed)} failed tasks, initiating debugging")
                    await self._handle_failures(project, failed)
            
            # All tasks completed
            project.update_phase(ProjectPhase.COMPLETED)
            self.active_projects.pop(project_id)
            self.completed_projects.append(project)
            self.projects_completed += 1
            
            logger.info(f"Project completed: {project.name}")
            
            # Cancel orchestrator
            orchestrator_task.cancel()
            
            return True
        
        except Exception as e:
            logger.error(f"Project execution failed: {e}")
            project.log_error(str(e))
            project.update_phase(ProjectPhase.FAILED)
            self.projects_failed += 1
            return False
    
    async def _handle_failures(self, project: SoftwareProject, failed_tasks: List[Task]):
        """Handle failed tasks through debugging and retry"""
        logger.info(f"Handling {len(failed_tasks)} failures in {project.name}")
        
        # Summon debugging agent if needed
        if AgentType.PROGRAMMING not in self.agent_pool or len(self.agent_pool[AgentType.PROGRAMMING]) < 2:
            self.summon_agent(AgentType.PROGRAMMING, 1)
        
        # Create debugging tasks
        for failed_task in failed_tasks:
            debug_task = Task(
                title=f"Debug: {failed_task.title}",
                description=f"Analyze and fix failure: {failed_task.error}",
                agent_type=AgentType.PROGRAMMING,
                priority=TaskPriority.CRITICAL,
                input_data={
                    "original_task": failed_task.id,
                    "error": failed_task.error,
                    "context": failed_task.input_data
                }
            )
            project.add_task(debug_task)
            self.orchestrator.submit_task(debug_task)
    
    def get_status(self) -> Dict[str, Any]:
        """Get master agent status"""
        return {
            "master_agent": {
                "name": self.name,
                "status": self.status.value,
                "uptime": (datetime.now(timezone.utc) - self.created_at).total_seconds()
            },
            "orchestrator": self.orchestrator.get_status(),
            "projects": {
                "active": len(self.active_projects),
                "completed": self.projects_completed,
                "failed": self.projects_failed,
                "details": [p.get_progress() for p in self.active_projects.values()]
            },
            "agents": {
                "summoned": self.agents_summoned,
                "by_type": {k.value: len(v) for k, v in self.agent_pool.items()}
            },
            "tools": {
                "available": self._get_tool_count(),
                "used": self.tools_used
            }
        }
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """
        Execute a task (implementation for BaseAgent compatibility)
        
        Args:
            task: Task to execute
            
        Returns:
            Task execution results
        """
        # Master agent delegates tasks to sub-agents
        # This is called by the orchestrator
        return {
            "delegated": True,
            "task_id": task.id,
            "message": "Task delegated to specialized agent"
        }
    
    def learn_from_project(self, project: SoftwareProject):
        """Learn from completed project to improve future performance"""
        if project.phase == ProjectPhase.COMPLETED:
            pattern = {
                "workflow": project.workflow.value,
                "tasks_count": len(project.completed_tasks),
                "duration": (project.updated_at - project.created_at).total_seconds(),
                "agents_used": len(project.agents_assigned),
                "success": True
            }
            self.success_patterns.append(pattern)
        else:
            pattern = {
                "workflow": project.workflow.value,
                "errors": project.error_log,
                "success": False
            }
            self.failure_patterns.append(pattern)
        
        logger.info(f"Learned from project: {project.name}")


    def _get_tool_count(self) -> int:
        """Get count of available tools, handling potential errors"""
        try:
            return self.tool_registry.get_tool_count()
        except (AttributeError, Exception):
            return 0
    
    def update_status(self, new_status: AgentStatus):
        """Update agent status"""
        self.status = new_status
        logger.info(f"Master Agent status updated to: {new_status.value}")


# Module-level convenience function
async def create_autonomous_agent() -> MasterAgent:
    """
    Create and initialize a master agent ready for autonomous operation
    
    Returns:
        Initialized MasterAgent instance
    """
    agent = MasterAgent()
    agent.update_status(AgentStatus.IDLE)
    
    logger.info("Master AI Agent initialized and ready")
    
    return agent
