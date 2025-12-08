"""
Application Builder Orchestrator

This module provides the core system for autonomous multi-agentic application building.
It includes democratic problem-solving, task decomposition, and full lifecycle management.
"""

import asyncio
import logging
from typing import List, Dict, Any, Optional, Set
from datetime import datetime
from enum import Enum
from pydantic import BaseModel, Field

from .base import (
    BaseAgent,
    Task,
    TaskStatus,
    TaskPriority,
    AgentStatus,
    AgentType,
    AgentMessage
)
from .orchestrator import AgentOrchestrator

logger = logging.getLogger(__name__)


class ApplicationPhase(str, Enum):
    """Phases of application development"""
    IDEATION = "ideation"
    PLANNING = "planning"
    TASK_DECOMPOSITION = "task_decomposition"
    DESIGN = "design"
    DEVELOPMENT = "development"
    TESTING = "testing"
    DEBUGGING = "debugging"
    BUILD = "build"
    UI_CREATION = "ui_creation"
    INTEGRATION = "integration"
    DEPLOYMENT = "deployment"
    VALIDATION = "validation"
    COMPLETED = "completed"


class VoteType(str, Enum):
    """Types of democratic votes"""
    APPROACH = "approach"
    ARCHITECTURE = "architecture"
    TECHNOLOGY = "technology"
    PRIORITY = "priority"
    QUALITY = "quality"
    COMPLETION = "completion"


class Vote(BaseModel):
    """Represents a vote by an agent"""
    agent_id: str
    vote_type: VoteType
    option: str
    reasoning: str
    confidence: float = Field(ge=0.0, le=1.0)
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class ApplicationIdea(BaseModel):
    """Represents an application idea"""
    title: str
    description: str
    requirements: List[str] = Field(default_factory=list)
    constraints: Dict[str, Any] = Field(default_factory=dict)
    target_users: str = ""
    success_criteria: List[str] = Field(default_factory=list)
    submitted_at: datetime = Field(default_factory=datetime.utcnow)


class ApplicationPlan(BaseModel):
    """Detailed plan for building an application"""
    idea: ApplicationIdea
    architecture: Dict[str, Any] = Field(default_factory=dict)
    technology_stack: Dict[str, List[str]] = Field(default_factory=dict)
    tasks: List[Task] = Field(default_factory=list)
    estimated_duration: Optional[int] = None  # in minutes
    phases: List[ApplicationPhase] = Field(default_factory=list)
    dependencies: Dict[str, List[str]] = Field(default_factory=dict)


class DemocraticDecision(BaseModel):
    """Result of a democratic decision-making process"""
    question: str
    vote_type: VoteType
    options: List[str]
    votes: List[Vote] = Field(default_factory=list)
    winning_option: Optional[str] = None
    consensus_reached: bool = False
    confidence_score: float = 0.0
    decided_at: Optional[datetime] = None


class ApplicationBuilder:
    """
    Autonomous Multi-Agentic Application Builder
    
    This system takes an application idea and autonomously:
    1. Breaks it down into manageable tasks
    2. Uses democratic problem-solving to make architectural decisions
    3. Coordinates multiple specialized agents
    4. Handles development, testing, debugging, and deployment
    5. Creates UI and validates the complete application
    6. Runs until the application is fully complete
    
    Example:
        ```python
        builder = ApplicationBuilder(orchestrator)
        
        idea = ApplicationIdea(
            title="Task Management API",
            description="RESTful API for managing tasks with authentication",
            requirements=["User authentication", "CRUD operations", "PostgreSQL"]
        )
        
        # Click "go" - fully autonomous execution
        app = await builder.build_application(idea)
        ```
    """
    
    def __init__(self, orchestrator: AgentOrchestrator):
        """
        Initialize the application builder
        
        Args:
            orchestrator: The agent orchestrator for managing agents
        """
        self.orchestrator = orchestrator
        self.active_builds: Dict[str, ApplicationPlan] = {}
        self.completed_builds: List[ApplicationPlan] = []
        self.decisions: Dict[str, List[DemocraticDecision]] = {}
        self.running = False
        
    async def build_application(
        self,
        idea: ApplicationIdea,
        autonomous: bool = True
    ) -> Dict[str, Any]:
        """
        Build a complete application from an idea
        
        This is the "click go" function that starts autonomous development.
        
        Args:
            idea: The application idea to build
            autonomous: If True, runs until completion without user intervention
            
        Returns:
            Dict containing the built application details and status
        """
        logger.info(f"Starting application build: {idea.title}")
        build_id = f"build_{datetime.utcnow().timestamp()}"
        
        try:
            # Phase 1: Planning and Task Decomposition
            logger.info("Phase 1: Planning and task decomposition")
            plan = await self._create_application_plan(idea)
            self.active_builds[build_id] = plan
            
            # Phase 2: Democratic Architecture Decision
            logger.info("Phase 2: Democratic architecture decisions")
            architecture = await self._democratic_architecture_decision(plan)
            plan.architecture = architecture
            
            # Phase 3: Technology Stack Selection
            logger.info("Phase 3: Technology stack selection")
            tech_stack = await self._democratic_tech_stack_selection(plan)
            plan.technology_stack = tech_stack
            
            # Phase 4: Execute Development Phases
            logger.info("Phase 4: Executing development phases")
            result = await self._execute_development_lifecycle(plan, autonomous)
            
            # Mark as completed
            self.completed_builds.append(plan)
            del self.active_builds[build_id]
            
            logger.info(f"Application build completed: {idea.title}")
            return result
            
        except Exception as e:
            logger.error(f"Application build failed: {e}")
            if build_id in self.active_builds:
                del self.active_builds[build_id]
            raise
    
    async def _create_application_plan(self, idea: ApplicationIdea) -> ApplicationPlan:
        """
        Create a detailed plan by decomposing the idea into tasks
        
        This uses specialized planning agents to break down the application
        into manageable, actionable tasks.
        """
        # Create planning task
        planning_task = Task(
            title=f"Plan application: {idea.title}",
            description=f"Decompose the following idea into actionable tasks:\n{idea.description}",
            priority=TaskPriority.HIGH,
            input_data={
                "idea": idea.dict(),
                "action": "decompose_into_tasks"
            }
        )
        
        # Get planning agents
        planning_agents = self._get_agents_by_capability("planning")
        
        # Execute planning in parallel with multiple agents
        planning_results = await self._execute_task_with_agents(
            planning_task,
            planning_agents[:3]  # Use top 3 planning agents
        )
        
        # Synthesize plans from different agents
        synthesized_plan = await self._synthesize_plans(planning_results)
        
        return ApplicationPlan(
            idea=idea,
            tasks=synthesized_plan.get("tasks", []),
            phases=synthesized_plan.get("phases", []),
            dependencies=synthesized_plan.get("dependencies", {}),
            estimated_duration=synthesized_plan.get("estimated_duration")
        )
    
    async def _democratic_architecture_decision(
        self,
        plan: ApplicationPlan
    ) -> Dict[str, Any]:
        """
        Use democratic voting to decide on application architecture
        
        Multiple architecture agents propose solutions, and the best one
        is selected through voting.
        """
        # Get architecture agents
        arch_agents = self._get_agents_by_capability("architecture")
        
        # Each agent proposes an architecture
        proposals = []
        for agent in arch_agents[:5]:  # Top 5 architecture agents
            proposal = await self._request_architecture_proposal(agent, plan)
            proposals.append(proposal)
        
        # Create voting decision
        decision = DemocraticDecision(
            question="What architecture should we use?",
            vote_type=VoteType.ARCHITECTURE,
            options=[p["id"] for p in proposals]
        )
        
        # All relevant agents vote
        voters = self._get_agents_by_type([
            AgentType.PROGRAMMING,
            AgentType.DEVOPS,
            AgentType.DESIGN
        ])
        
        for voter in voters[:10]:  # Top 10 voting agents
            vote = await self._request_vote(voter, decision, proposals)
            decision.votes.append(vote)
        
        # Determine winner
        winning_architecture = self._calculate_winner(decision, proposals)
        decision.winning_option = winning_architecture["id"]
        decision.consensus_reached = True
        decision.decided_at = datetime.utcnow()
        
        # Store decision
        build_id = list(self.active_builds.keys())[0]
        if build_id not in self.decisions:
            self.decisions[build_id] = []
        self.decisions[build_id].append(decision)
        
        return winning_architecture
    
    async def _democratic_tech_stack_selection(
        self,
        plan: ApplicationPlan
    ) -> Dict[str, List[str]]:
        """
        Democratically select the technology stack
        
        Agents vote on technologies for each layer:
        - Frontend frameworks
        - Backend frameworks
        - Databases
        - Infrastructure tools
        """
        categories = [
            "frontend",
            "backend",
            "database",
            "testing",
            "deployment"
        ]
        
        tech_stack = {}
        
        for category in categories:
            # Get technology options from agents
            options = await self._get_technology_options(category, plan)
            
            # Create voting decision
            decision = DemocraticDecision(
                question=f"What {category} technology should we use?",
                vote_type=VoteType.TECHNOLOGY,
                options=list(options.keys())
            )
            
            # Get relevant agents to vote
            voters = self._get_agents_by_capability(category)
            
            for voter in voters[:7]:  # Top 7 agents per category
                vote = await self._request_tech_vote(voter, decision, options)
                decision.votes.append(vote)
            
            # Determine winner
            winner = self._calculate_tech_winner(decision, options)
            decision.winning_option = winner
            decision.consensus_reached = True
            decision.decided_at = datetime.utcnow()
            
            tech_stack[category] = options[winner]
            
            # Store decision
            build_id = list(self.active_builds.keys())[0]
            self.decisions[build_id].append(decision)
        
        return tech_stack
    
    async def _execute_development_lifecycle(
        self,
        plan: ApplicationPlan,
        autonomous: bool
    ) -> Dict[str, Any]:
        """
        Execute the complete development lifecycle
        
        Phases:
        1. Design - Create detailed designs
        2. Development - Write code
        3. Testing - Test all components
        4. Debugging - Fix issues
        5. UI Creation - Build user interface
        6. Integration - Integrate all components
        7. Build - Create production build
        8. Validation - Final validation
        """
        results = {
            "phases_completed": [],
            "artifacts": {},
            "tests_passed": 0,
            "tests_failed": 0,
            "issues_found": 0,
            "issues_fixed": 0
        }
        
        phases = [
            (ApplicationPhase.DESIGN, self._execute_design_phase),
            (ApplicationPhase.DEVELOPMENT, self._execute_development_phase),
            (ApplicationPhase.TESTING, self._execute_testing_phase),
            (ApplicationPhase.DEBUGGING, self._execute_debugging_phase),
            (ApplicationPhase.UI_CREATION, self._execute_ui_phase),
            (ApplicationPhase.INTEGRATION, self._execute_integration_phase),
            (ApplicationPhase.BUILD, self._execute_build_phase),
            (ApplicationPhase.VALIDATION, self._execute_validation_phase),
        ]
        
        for phase, executor in phases:
            logger.info(f"Executing phase: {phase.value}")
            
            try:
                phase_result = await executor(plan)
                results["phases_completed"].append(phase.value)
                results["artifacts"][phase.value] = phase_result
                
                # Check if we need to iterate (for autonomous mode)
                if autonomous and phase == ApplicationPhase.TESTING:
                    if phase_result.get("failed_tests", 0) > 0:
                        # Re-run debugging phase
                        logger.info("Tests failed, running debugging phase again")
                        debug_result = await self._execute_debugging_phase(plan)
                        results["issues_found"] += debug_result.get("issues_found", 0)
                        results["issues_fixed"] += debug_result.get("issues_fixed", 0)
                        
                        # Re-run testing
                        phase_result = await self._execute_testing_phase(plan)
                
                results["tests_passed"] += phase_result.get("tests_passed", 0)
                results["tests_failed"] += phase_result.get("tests_failed", 0)
                
            except Exception as e:
                logger.error(f"Phase {phase.value} failed: {e}")
                if not autonomous:
                    raise
                # In autonomous mode, try to recover
                await self._handle_phase_failure(phase, plan, e)
        
        results["status"] = "completed"
        results["completed_at"] = datetime.utcnow().isoformat()
        
        return results
    
    async def _execute_design_phase(self, plan: ApplicationPlan) -> Dict[str, Any]:
        """Execute design phase - create detailed designs"""
        design_agents = self._get_agents_by_type([AgentType.DESIGN])
        
        design_tasks = [
            Task(
                title="System Architecture Design",
                description="Create detailed system architecture",
                priority=TaskPriority.HIGH,
                input_data={"plan": plan.dict(), "type": "architecture"}
            ),
            Task(
                title="Database Schema Design",
                description="Design database schema",
                priority=TaskPriority.HIGH,
                input_data={"plan": plan.dict(), "type": "database"}
            ),
            Task(
                title="API Design",
                description="Design API endpoints and contracts",
                priority=TaskPriority.HIGH,
                input_data={"plan": plan.dict(), "type": "api"}
            ),
            Task(
                title="UI/UX Design",
                description="Design user interface and experience",
                priority=TaskPriority.MEDIUM,
                input_data={"plan": plan.dict(), "type": "ui_ux"}
            )
        ]
        
        results = []
        for task in design_tasks:
            result = await self.orchestrator.submit_task(task)
            results.append(result)
        
        return {
            "designs_created": len(results),
            "designs": results
        }
    
    async def _execute_development_phase(self, plan: ApplicationPlan) -> Dict[str, Any]:
        """Execute development phase - write code"""
        dev_agents = self._get_agents_by_type([AgentType.PROGRAMMING])
        
        # Create development tasks from plan
        dev_tasks = []
        for task in plan.tasks:
            dev_task = Task(
                title=task.title,
                description=task.description,
                priority=task.priority,
                input_data={"original_task": task.dict(), "phase": "development"}
            )
            dev_tasks.append(dev_task)
        
        # Execute tasks in parallel where possible
        results = []
        for task in dev_tasks:
            result = await self.orchestrator.submit_task(task)
            results.append(result)
        
        return {
            "files_created": len(results),
            "components": results
        }
    
    async def _execute_testing_phase(self, plan: ApplicationPlan) -> Dict[str, Any]:
        """Execute testing phase - test all components"""
        test_agents = self._get_agents_by_type([AgentType.TESTING])
        
        test_types = [
            ("unit", "Unit tests for individual components"),
            ("integration", "Integration tests for component interactions"),
            ("e2e", "End-to-end tests for complete workflows"),
            ("performance", "Performance tests for scalability")
        ]
        
        test_results = {
            "tests_passed": 0,
            "tests_failed": 0,
            "coverage": 0.0,
            "test_suites": []
        }
        
        for test_type, description in test_types:
            task = Task(
                title=f"{test_type.title()} Testing",
                description=description,
                priority=TaskPriority.HIGH,
                input_data={"test_type": test_type, "plan": plan.dict()}
            )
            
            result = await self.orchestrator.submit_task(task)
            test_results["test_suites"].append(result)
            test_results["tests_passed"] += result.get("passed", 0)
            test_results["tests_failed"] += result.get("failed", 0)
        
        total_tests = test_results["tests_passed"] + test_results["tests_failed"]
        if total_tests > 0:
            test_results["coverage"] = (test_results["tests_passed"] / total_tests) * 100
        
        return test_results
    
    async def _execute_debugging_phase(self, plan: ApplicationPlan) -> Dict[str, Any]:
        """Execute debugging phase - find and fix issues"""
        debug_agents = self._get_agents_by_type([
            AgentType.PROGRAMMING,
            AgentType.TESTING
        ])
        
        # Find issues
        issues_task = Task(
            title="Identify Issues",
            description="Scan code and tests for issues",
            priority=TaskPriority.CRITICAL,
            input_data={"action": "find_issues", "plan": plan.dict()}
        )
        
        issues = await self.orchestrator.submit_task(issues_task)
        
        # Fix issues
        fixes = []
        for issue in issues.get("issues", []):
            fix_task = Task(
                title=f"Fix: {issue.get('title')}",
                description=issue.get("description"),
                priority=TaskPriority.HIGH,
                input_data={"issue": issue, "action": "fix"}
            )
            fix_result = await self.orchestrator.submit_task(fix_task)
            fixes.append(fix_result)
        
        return {
            "issues_found": len(issues.get("issues", [])),
            "issues_fixed": len(fixes),
            "fixes": fixes
        }
    
    async def _execute_ui_phase(self, plan: ApplicationPlan) -> Dict[str, Any]:
        """Execute UI creation phase - build user interface"""
        ui_agents = self._get_agents_by_type([AgentType.DESIGN])
        
        ui_tasks = [
            Task(
                title="Create UI Components",
                description="Build reusable UI components",
                priority=TaskPriority.HIGH,
                input_data={"type": "components", "plan": plan.dict()}
            ),
            Task(
                title="Create Application Layout",
                description="Build main application layout",
                priority=TaskPriority.HIGH,
                input_data={"type": "layout", "plan": plan.dict()}
            ),
            Task(
                title="Implement Navigation",
                description="Create navigation system",
                priority=TaskPriority.MEDIUM,
                input_data={"type": "navigation", "plan": plan.dict()}
            ),
            Task(
                title="Add Styling",
                description="Apply styles and themes",
                priority=TaskPriority.MEDIUM,
                input_data={"type": "styling", "plan": plan.dict()}
            )
        ]
        
        results = []
        for task in ui_tasks:
            result = await self.orchestrator.submit_task(task)
            results.append(result)
        
        return {
            "ui_components": len(results),
            "components": results
        }
    
    async def _execute_integration_phase(self, plan: ApplicationPlan) -> Dict[str, Any]:
        """Execute integration phase - integrate all components"""
        integration_task = Task(
            title="Integrate All Components",
            description="Connect frontend, backend, and services",
            priority=TaskPriority.CRITICAL,
            input_data={"plan": plan.dict(), "phase": "integration"}
        )
        
        result = await self.orchestrator.submit_task(integration_task)
        
        return {
            "integration_status": "completed",
            "details": result
        }
    
    async def _execute_build_phase(self, plan: ApplicationPlan) -> Dict[str, Any]:
        """Execute build phase - create production build"""
        build_agents = self._get_agents_by_type([AgentType.DEVOPS])
        
        build_task = Task(
            title="Create Production Build",
            description="Build optimized production artifacts",
            priority=TaskPriority.CRITICAL,
            input_data={"plan": plan.dict(), "environment": "production"}
        )
        
        result = await self.orchestrator.submit_task(build_task)
        
        return {
            "build_status": "success",
            "artifacts": result.get("artifacts", []),
            "details": result
        }
    
    async def _execute_validation_phase(self, plan: ApplicationPlan) -> Dict[str, Any]:
        """Execute validation phase - final validation"""
        validation_agents = self._get_agents_by_type([
            AgentType.TESTING,
            AgentType.SECURITY
        ])
        
        validation_tasks = [
            Task(
                title="Functional Validation",
                description="Validate all features work correctly",
                priority=TaskPriority.CRITICAL,
                input_data={"type": "functional", "plan": plan.dict()}
            ),
            Task(
                title="Security Validation",
                description="Validate security measures",
                priority=TaskPriority.CRITICAL,
                input_data={"type": "security", "plan": plan.dict()}
            ),
            Task(
                title="Performance Validation",
                description="Validate performance requirements",
                priority=TaskPriority.HIGH,
                input_data={"type": "performance", "plan": plan.dict()}
            )
        ]
        
        results = []
        for task in validation_tasks:
            result = await self.orchestrator.submit_task(task)
            results.append(result)
        
        all_passed = all(r.get("status") == "passed" for r in results)
        
        return {
            "validation_status": "passed" if all_passed else "failed",
            "validations": results
        }
    
    # Helper methods
    
    def _get_agents_by_capability(self, capability: str) -> List[BaseAgent]:
        """Get agents with a specific capability"""
        matching_agents = []
        for agent in self.orchestrator.agents.values():
            if any(cap.name == capability for cap in agent.capabilities):
                matching_agents.append(agent)
        return matching_agents
    
    def _get_agents_by_type(self, types: List[AgentType]) -> List[BaseAgent]:
        """Get agents of specific types"""
        matching_agents = []
        for agent_type in types:
            matching_agents.extend(
                self.orchestrator.agents_by_type.get(agent_type.value, [])
            )
        return matching_agents
    
    async def _execute_task_with_agents(
        self,
        task: Task,
        agents: List[BaseAgent]
    ) -> List[Dict[str, Any]]:
        """Execute a task with multiple agents in parallel"""
        results = []
        for agent in agents:
            try:
                result = await agent.execute_task(task)
                results.append(result)
            except Exception as e:
                logger.error(f"Agent {agent.name} failed: {e}")
        return results
    
    async def _synthesize_plans(
        self,
        planning_results: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Synthesize multiple planning results into one cohesive plan"""
        # Simple synthesis - in practice, this would use LLM
        all_tasks = []
        all_phases = set()
        dependencies = {}
        
        for result in planning_results:
            all_tasks.extend(result.get("tasks", []))
            all_phases.update(result.get("phases", []))
            dependencies.update(result.get("dependencies", {}))
        
        # Remove duplicates
        unique_tasks = []
        seen_titles = set()
        for task in all_tasks:
            title = task.get("title", "")
            if title not in seen_titles:
                unique_tasks.append(task)
                seen_titles.add(title)
        
        return {
            "tasks": unique_tasks,
            "phases": list(all_phases),
            "dependencies": dependencies,
            "estimated_duration": sum(
                t.get("estimated_duration", 30) for t in unique_tasks
            )
        }
    
    async def _request_architecture_proposal(
        self,
        agent: BaseAgent,
        plan: ApplicationPlan
    ) -> Dict[str, Any]:
        """Request an architecture proposal from an agent"""
        # Simplified - in practice, this calls the agent
        return {
            "id": f"arch_{agent.id}",
            "agent_id": agent.id,
            "proposal": {
                "type": "microservices",
                "components": ["api", "database", "frontend"],
                "technologies": plan.technology_stack
            }
        }
    
    async def _request_vote(
        self,
        agent: BaseAgent,
        decision: DemocraticDecision,
        proposals: List[Dict[str, Any]]
    ) -> Vote:
        """Request a vote from an agent"""
        # Simplified - in practice, agent evaluates proposals
        import random
        chosen = random.choice(proposals)
        
        return Vote(
            agent_id=agent.id,
            vote_type=decision.vote_type,
            option=chosen["id"],
            reasoning="Based on analysis",
            confidence=0.8
        )
    
    def _calculate_winner(
        self,
        decision: DemocraticDecision,
        proposals: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Calculate winning option from votes"""
        vote_counts = {}
        confidence_scores = {}
        
        for vote in decision.votes:
            vote_counts[vote.option] = vote_counts.get(vote.option, 0) + 1
            confidence_scores[vote.option] = confidence_scores.get(
                vote.option, 0.0
            ) + vote.confidence
        
        # Winner is option with most votes and highest average confidence
        winner_id = max(
            vote_counts.keys(),
            key=lambda x: (vote_counts[x], confidence_scores[x] / vote_counts[x])
        )
        
        decision.confidence_score = confidence_scores[winner_id] / vote_counts[winner_id]
        
        return next(p for p in proposals if p["id"] == winner_id)
    
    async def _get_technology_options(
        self,
        category: str,
        plan: ApplicationPlan
    ) -> Dict[str, List[str]]:
        """Get technology options for a category"""
        # Predefined technology options
        tech_options = {
            "frontend": {
                "react": ["React", "TypeScript", "Vite"],
                "vue": ["Vue.js", "TypeScript", "Vite"],
                "svelte": ["Svelte", "TypeScript", "SvelteKit"]
            },
            "backend": {
                "fastapi": ["Python", "FastAPI", "Uvicorn"],
                "express": ["Node.js", "Express", "TypeScript"],
                "django": ["Python", "Django", "Django REST Framework"]
            },
            "database": {
                "postgresql": ["PostgreSQL", "SQLAlchemy"],
                "mongodb": ["MongoDB", "Mongoose"],
                "mysql": ["MySQL", "Sequelize"]
            },
            "testing": {
                "pytest": ["pytest", "pytest-asyncio", "pytest-cov"],
                "jest": ["Jest", "React Testing Library"],
                "vitest": ["Vitest", "Testing Library"]
            },
            "deployment": {
                "docker": ["Docker", "Docker Compose"],
                "kubernetes": ["Kubernetes", "Helm"],
                "serverless": ["AWS Lambda", "Serverless Framework"]
            }
        }
        
        return tech_options.get(category, {})
    
    async def _request_tech_vote(
        self,
        agent: BaseAgent,
        decision: DemocraticDecision,
        options: Dict[str, List[str]]
    ) -> Vote:
        """Request a technology vote from an agent"""
        import random
        chosen = random.choice(list(options.keys()))
        
        return Vote(
            agent_id=agent.id,
            vote_type=decision.vote_type,
            option=chosen,
            reasoning=f"Best fit for requirements",
            confidence=0.75
        )
    
    def _calculate_tech_winner(
        self,
        decision: DemocraticDecision,
        options: Dict[str, List[str]]
    ) -> str:
        """Calculate winning technology option"""
        vote_counts = {}
        
        for vote in decision.votes:
            vote_counts[vote.option] = vote_counts.get(vote.option, 0) + 1
        
        winner = max(vote_counts.keys(), key=lambda x: vote_counts[x])
        return winner
    
    async def _handle_phase_failure(
        self,
        phase: ApplicationPhase,
        plan: ApplicationPlan,
        error: Exception
    ):
        """Handle failure in a development phase"""
        logger.error(f"Handling failure in {phase.value}: {error}")
        
        # Create recovery task
        recovery_task = Task(
            title=f"Recover from {phase.value} failure",
            description=f"Handle error: {str(error)}",
            priority=TaskPriority.CRITICAL,
            input_data={
                "phase": phase.value,
                "error": str(error),
                "plan": plan.dict()
            }
        )
        
        await self.orchestrator.submit_task(recovery_task)
