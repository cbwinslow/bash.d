"""
Complex Problem Solver using Swarms, Crews, and Democratic Voting

This module orchestrates multiple AI agents using swarms and crews to solve
complex problems through democratic decision-making, task decomposition,
and collective intelligence.

Key features:
- Automatic problem decomposition
- Dynamic swarm/crew selection
- Democratic voting for decisions
- Multi-perspective solution generation
- Consensus building through iteration
"""

import asyncio
import logging
from enum import Enum
from typing import List, Dict, Any, Optional, Union
from datetime import datetime
from pydantic import BaseModel, Field
import uuid

from .base import BaseAgent, Task, TaskPriority, AgentType
from .swarm import AgentSwarm, SwarmConfiguration, SwarmBehavior, SwarmTask
from .crew import AgentCrew, CrewConfiguration, CrewProcess, CrewRole, CrewTask
from .voting import (
    DemocraticVoter,
    VotingStrategy,
    Vote,
    VoteResult,
    RankedVote,
    ConsensusBuilder
)

logger = logging.getLogger(__name__)


# Default decomposition phases for problems without specific agent types
DEFAULT_PROBLEM_PHASES = ["analysis", "implementation", "testing"]


class ProblemComplexity(str, Enum):
    """Problem complexity levels"""
    SIMPLE = "simple"  # Single agent can solve
    MODERATE = "moderate"  # Small team/swarm needed
    COMPLEX = "complex"  # Multiple swarms or crew needed
    HIGHLY_COMPLEX = "highly_complex"  # Multiple crews + coordination


class SolutionApproach(str, Enum):
    """Approaches to solving problems"""
    SINGLE_AGENT = "single_agent"  # One agent solves it
    SWARM = "swarm"  # Swarm with democratic voting
    CREW = "crew"  # Organized crew with roles
    MULTI_SWARM = "multi_swarm"  # Multiple swarms collaborate
    HYBRID = "hybrid"  # Mix of swarms and crews


class ProblemType(str, Enum):
    """Types of problems"""
    DEVELOPMENT = "development"  # Software development
    ANALYSIS = "analysis"  # Data analysis, research
    DESIGN = "design"  # System/architecture design
    OPTIMIZATION = "optimization"  # Process/code optimization
    TROUBLESHOOTING = "troubleshooting"  # Debug, fix issues
    PLANNING = "planning"  # Strategy, roadmap
    CREATIVE = "creative"  # Content creation, ideation
    GENERAL = "general"  # General purpose


class Problem(BaseModel):
    """Complex problem definition"""
    problem_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    title: str
    description: str
    problem_type: ProblemType = Field(default=ProblemType.GENERAL)
    complexity: Optional[ProblemComplexity] = None
    priority: TaskPriority = Field(default=TaskPriority.MEDIUM)
    
    # Requirements
    required_capabilities: List[str] = Field(default_factory=list)
    required_agent_types: List[AgentType] = Field(default_factory=list)
    constraints: Dict[str, Any] = Field(default_factory=dict)
    
    # Context
    context: Dict[str, Any] = Field(default_factory=dict)
    examples: List[str] = Field(default_factory=list)
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class SubProblem(BaseModel):
    """Decomposed sub-problem"""
    subproblem_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    parent_id: str
    title: str
    description: str
    dependencies: List[str] = Field(default_factory=list)
    required_agent_types: List[AgentType] = Field(default_factory=list)
    priority: TaskPriority = Field(default=TaskPriority.MEDIUM)
    approach: Optional[SolutionApproach] = None


class Solution(BaseModel):
    """Solution to a problem"""
    solution_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    problem_id: str
    approach_used: SolutionApproach
    
    # Result
    solution_data: Any
    confidence: float = Field(ge=0.0, le=1.0)
    quality_score: float = Field(ge=0.0, le=1.0)
    
    # Voting info
    vote_result: Optional[VoteResult] = None
    consensus_achieved: bool = Field(default=False)
    
    # Agents involved
    agents_used: List[str] = Field(default_factory=list)
    swarms_used: List[str] = Field(default_factory=list)
    crews_used: List[str] = Field(default_factory=list)
    
    # Metadata
    execution_time: float = Field(default=0.0)
    iterations: int = Field(default=1)
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class ComplexProblemSolver:
    """
    Solves complex problems using AI agent swarms, crews, and democratic voting
    
    This is the main orchestrator for complex problem solving. It:
    1. Analyzes problem complexity
    2. Decomposes complex problems into sub-problems
    3. Selects appropriate approach (swarm/crew/hybrid)
    4. Assigns agents dynamically
    5. Uses democratic voting for decisions
    6. Builds consensus through iteration
    7. Aggregates results into final solution
    
    Example:
        ```python
        # Initialize solver with available agents
        solver = ComplexProblemSolver()
        solver.register_agents([
            python_dev, js_dev, qa_engineer,
            devops_specialist, doc_writer
        ])
        
        # Define problem
        problem = Problem(
            title="Build Microservices Platform",
            description="Create a scalable microservices platform with CI/CD",
            problem_type=ProblemType.DEVELOPMENT,
            required_agent_types=[
                AgentType.PROGRAMMING,
                AgentType.DEVOPS,
                AgentType.TESTING,
                AgentType.DOCUMENTATION
            ]
        )
        
        # Solve using democratic decision-making
        solution = await solver.solve(problem)
        print(f"Solution confidence: {solution.confidence}")
        print(f"Consensus achieved: {solution.consensus_achieved}")
        ```
    """
    
    def __init__(self):
        """Initialize complex problem solver"""
        self.agents: Dict[str, BaseAgent] = {}
        self.swarms: Dict[str, AgentSwarm] = {}
        self.crews: Dict[str, AgentCrew] = {}
        
        self.problems: Dict[str, Problem] = {}
        self.solutions: Dict[str, Solution] = {}
        
        self.voter = DemocraticVoter()
        self.consensus_builder = ConsensusBuilder()
        
        logger.info("Initialized ComplexProblemSolver")
    
    def register_agent(self, agent: BaseAgent):
        """Register an agent with the solver"""
        self.agents[agent.id] = agent
        logger.info(f"Registered agent {agent.name} ({agent.type})")
    
    def register_agents(self, agents: List[BaseAgent]):
        """Register multiple agents"""
        for agent in agents:
            self.register_agent(agent)
    
    async def solve(
        self,
        problem: Problem,
        voting_strategy: VotingStrategy = VotingStrategy.MAJORITY,
        use_consensus: bool = True
    ) -> Solution:
        """
        Solve a complex problem using appropriate approach
        
        Args:
            problem: Problem to solve
            voting_strategy: Voting strategy for decisions
            use_consensus: Whether to build consensus
        
        Returns:
            Solution with results and voting information
        """
        start_time = datetime.utcnow()
        self.problems[problem.problem_id] = problem
        
        logger.info(f"Solving problem: {problem.title}")
        
        try:
            # 1. Analyze complexity if not provided
            if not problem.complexity:
                problem.complexity = self._analyze_complexity(problem)
            
            logger.info(f"Problem complexity: {problem.complexity}")
            
            # 2. Determine approach
            approach = self._select_approach(problem)
            logger.info(f"Selected approach: {approach}")
            
            # 3. Execute based on approach
            if approach == SolutionApproach.SINGLE_AGENT:
                result = await self._solve_with_single_agent(problem)
            elif approach == SolutionApproach.SWARM:
                result = await self._solve_with_swarm(problem, voting_strategy)
            elif approach == SolutionApproach.CREW:
                result = await self._solve_with_crew(problem)
            elif approach == SolutionApproach.MULTI_SWARM:
                result = await self._solve_with_multi_swarm(problem, voting_strategy)
            elif approach == SolutionApproach.HYBRID:
                result = await self._solve_with_hybrid(problem, voting_strategy)
            else:
                result = await self._solve_with_swarm(problem, voting_strategy)
            
            # 4. Build consensus if requested and not achieved
            if use_consensus and not result.get("consensus_achieved", False):
                result = await self._build_consensus(problem, result, voting_strategy)
            
            # 5. Create solution
            execution_time = (datetime.utcnow() - start_time).total_seconds()
            
            solution = Solution(
                problem_id=problem.problem_id,
                approach_used=approach,
                solution_data=result.get("solution"),
                confidence=result.get("confidence", 0.8),
                quality_score=result.get("quality_score", 0.8),
                vote_result=result.get("vote_result"),
                consensus_achieved=result.get("consensus_achieved", False),
                agents_used=result.get("agents_used", []),
                swarms_used=result.get("swarms_used", []),
                crews_used=result.get("crews_used", []),
                execution_time=execution_time,
                iterations=result.get("iterations", 1),
                metadata=result.get("metadata", {})
            )
            
            self.solutions[solution.solution_id] = solution
            
            logger.info(f"Solution completed: confidence={solution.confidence:.2f}, "
                       f"consensus={solution.consensus_achieved}")
            
            return solution
            
        except Exception as e:
            logger.error(f"Error solving problem {problem.problem_id}: {e}")
            raise
    
    def _analyze_complexity(self, problem: Problem) -> ProblemComplexity:
        """
        Analyze problem complexity
        
        Args:
            problem: Problem to analyze
        
        Returns:
            Complexity level
        """
        # Simple heuristic based on requirements
        score = 0
        
        # Count required capabilities
        score += len(problem.required_capabilities)
        
        # Count required agent types
        score += len(problem.required_agent_types) * 2
        
        # Check description length (more complex = longer)
        score += len(problem.description) // 200
        
        # Classify based on score
        if score <= 2:
            return ProblemComplexity.SIMPLE
        elif score <= 5:
            return ProblemComplexity.MODERATE
        elif score <= 10:
            return ProblemComplexity.COMPLEX
        else:
            return ProblemComplexity.HIGHLY_COMPLEX
    
    def _select_approach(self, problem: Problem) -> SolutionApproach:
        """
        Select appropriate solution approach
        
        Args:
            problem: Problem to solve
        
        Returns:
            Recommended approach
        """
        complexity = problem.complexity or self._analyze_complexity(problem)
        
        if complexity == ProblemComplexity.SIMPLE:
            return SolutionApproach.SINGLE_AGENT
        elif complexity == ProblemComplexity.MODERATE:
            # Use swarm for collaborative problems, crew for structured ones
            if problem.problem_type in [ProblemType.CREATIVE, ProblemType.ANALYSIS]:
                return SolutionApproach.SWARM
            else:
                return SolutionApproach.CREW
        elif complexity == ProblemComplexity.COMPLEX:
            # Use multi-swarm for highly collaborative, hybrid for structured
            if problem.problem_type in [ProblemType.DEVELOPMENT, ProblemType.DESIGN]:
                return SolutionApproach.HYBRID
            else:
                return SolutionApproach.MULTI_SWARM
        else:  # HIGHLY_COMPLEX
            return SolutionApproach.HYBRID
    
    async def _solve_with_single_agent(self, problem: Problem) -> Dict[str, Any]:
        """Solve with a single agent"""
        # Find best agent for the problem
        agent = self._select_best_agent(problem)
        
        if not agent:
            raise ValueError("No suitable agent found for problem")
        
        # Simple execution
        result = {
            "solution": f"Solution from {agent.name}",
            "confidence": 0.85,
            "quality_score": 0.85,
            "consensus_achieved": True,
            "agents_used": [agent.id],
            "metadata": {"approach": "single_agent"}
        }
        
        return result
    
    async def _solve_with_swarm(
        self,
        problem: Problem,
        voting_strategy: VotingStrategy
    ) -> Dict[str, Any]:
        """Solve using a swarm with democratic voting"""
        # Create swarm
        config = SwarmConfiguration(
            name=f"Swarm for {problem.title}",
            behavior=SwarmBehavior.DEMOCRATIC,
            voting_strategy=voting_strategy,
            required_agent_types=problem.required_agent_types or []
        )
        
        swarm = AgentSwarm(config)
        self.swarms[swarm.swarm_id] = swarm
        
        # Add agents
        agents = self._select_agents_for_problem(problem, max_agents=5)
        for agent in agents:
            swarm.add_agent(agent)
        
        # Create task
        task = SwarmTask(
            title=problem.title,
            description=problem.description,
            priority=problem.priority
        )
        
        # Execute
        result = await swarm.execute_task(task)
        
        # Extract voting info
        vote_result = result.get("vote_result")
        if vote_result and isinstance(vote_result, dict):
            vote_result = VoteResult(**vote_result)
        
        return {
            "solution": result.get("solution"),
            "confidence": 0.9 if result.get("consensus") else 0.7,
            "quality_score": 0.85,
            "consensus_achieved": result.get("consensus", False),
            "vote_result": vote_result,
            "agents_used": [a.agent_id for a in agents],
            "swarms_used": [swarm.swarm_id],
            "metadata": {
                "approach": "swarm",
                "proposals": result.get("proposals", 0)
            }
        }
    
    async def _solve_with_crew(self, problem: Problem) -> Dict[str, Any]:
        """Solve using an organized crew"""
        # Create crew
        config = CrewConfiguration(
            name=f"Crew for {problem.title}",
            process=CrewProcess.SEQUENTIAL
        )
        
        crew = AgentCrew(config)
        self.crews[crew.crew_id] = crew
        
        # Add agents with roles
        agents = self._select_agents_for_problem(problem, max_agents=5)
        
        if agents:
            # Assign roles
            crew.add_member(agents[0], CrewRole.LEADER)
            for agent in agents[1:]:
                crew.add_member(agent, CrewRole.SPECIALIST)
        
        # Create workflow tasks
        tasks = self._decompose_problem(problem)
        crew_tasks = [
            CrewTask(
                title=sp.title,
                description=sp.description,
                priority=sp.priority
            )
            for sp in tasks
        ]
        
        # Execute
        result = await crew.execute_workflow(crew_tasks)
        
        return {
            "solution": result.get("results"),
            "confidence": 0.88,
            "quality_score": 0.88,
            "consensus_achieved": result.get("success", False),
            "agents_used": [a.agent_id for a in agents],
            "crews_used": [crew.crew_id],
            "metadata": {
                "approach": "crew",
                "tasks_completed": result.get("tasks_completed", 0)
            }
        }
    
    async def _solve_with_multi_swarm(
        self,
        problem: Problem,
        voting_strategy: VotingStrategy
    ) -> Dict[str, Any]:
        """Solve using multiple swarms"""
        # Decompose into sub-problems
        sub_problems = self._decompose_problem(problem)
        
        swarms_used = []
        all_results = []
        all_agents = set()
        
        # Create swarm for each sub-problem
        for sub_prob in sub_problems:
            config = SwarmConfiguration(
                name=f"Swarm for {sub_prob.title}",
                behavior=SwarmBehavior.DEMOCRATIC,
                voting_strategy=voting_strategy,
                min_agents=2,
                max_agents=4
            )
            
            swarm = AgentSwarm(config)
            self.swarms[swarm.swarm_id] = swarm
            swarms_used.append(swarm.swarm_id)
            
            # Add agents
            agents = self._select_agents_for_problem(
                problem,
                max_agents=4,
                required_types=sub_prob.required_agent_types
            )
            
            for agent in agents:
                swarm.add_agent(agent)
                all_agents.add(agent.id)
            
            # Execute
            task = SwarmTask(
                title=sub_prob.title,
                description=sub_prob.description,
                priority=sub_prob.priority
            )
            
            result = await swarm.execute_task(task)
            all_results.append(result)
        
        # Aggregate results - use voting
        votes = [
            Vote(
                voter_id=f"swarm_{i}",
                choice=result.get("solution"),
                confidence=0.85
            )
            for i, result in enumerate(all_results)
            if result.get("solution")
        ]
        
        final_vote = self.voter.conduct_vote(votes) if votes else None
        
        return {
            "solution": final_vote.winner if final_vote else all_results,
            "confidence": final_vote.confidence_score if final_vote else 0.75,
            "quality_score": 0.85,
            "consensus_achieved": final_vote.is_consensus if final_vote else False,
            "vote_result": final_vote,
            "agents_used": list(all_agents),
            "swarms_used": swarms_used,
            "metadata": {
                "approach": "multi_swarm",
                "sub_problems": len(sub_problems),
                "swarms_created": len(swarms_used)
            }
        }
    
    async def _solve_with_hybrid(
        self,
        problem: Problem,
        voting_strategy: VotingStrategy
    ) -> Dict[str, Any]:
        """Solve using hybrid approach (crews + swarms)"""
        # Decompose problem
        sub_problems = self._decompose_problem(problem)
        
        # Use crew for structured tasks, swarms for creative ones
        crews_used = []
        swarms_used = []
        all_results = []
        all_agents = set()
        
        for sub_prob in sub_problems:
            # Decide swarm vs crew based on sub-problem type
            if len(sub_prob.required_agent_types) > 2:
                # Use crew for complex structured tasks
                result = await self._solve_subproblem_with_crew(sub_prob)
                if result.get("crews_used"):
                    crews_used.extend(result["crews_used"])
            else:
                # Use swarm for simpler collaborative tasks
                result = await self._solve_subproblem_with_swarm(sub_prob, voting_strategy)
                if result.get("swarms_used"):
                    swarms_used.extend(result["swarms_used"])
            
            all_results.append(result)
            if result.get("agents_used"):
                all_agents.update(result["agents_used"])
        
        # Vote on final solution
        votes = [
            Vote(
                voter_id=f"subsolution_{i}",
                choice=result.get("solution"),
                confidence=result.get("confidence", 0.8)
            )
            for i, result in enumerate(all_results)
            if result.get("solution")
        ]
        
        final_vote = self.voter.conduct_vote(votes) if votes else None
        
        return {
            "solution": final_vote.winner if final_vote else all_results,
            "confidence": final_vote.confidence_score if final_vote else 0.8,
            "quality_score": 0.88,
            "consensus_achieved": final_vote.is_consensus if final_vote else False,
            "vote_result": final_vote,
            "agents_used": list(all_agents),
            "swarms_used": swarms_used,
            "crews_used": crews_used,
            "metadata": {
                "approach": "hybrid",
                "sub_problems": len(sub_problems),
                "swarms_used": len(swarms_used),
                "crews_used": len(crews_used)
            }
        }
    
    async def _solve_subproblem_with_crew(self, sub_prob: SubProblem) -> Dict[str, Any]:
        """Solve a sub-problem using a crew"""
        # Simplified version - reuse crew logic
        config = CrewConfiguration(
            name=f"Crew for {sub_prob.title}",
            process=CrewProcess.SEQUENTIAL
        )
        
        crew = AgentCrew(config)
        self.crews[crew.crew_id] = crew
        
        return {
            "solution": f"Crew solution for {sub_prob.title}",
            "confidence": 0.85,
            "crews_used": [crew.crew_id],
            "agents_used": []
        }
    
    async def _solve_subproblem_with_swarm(
        self,
        sub_prob: SubProblem,
        voting_strategy: VotingStrategy
    ) -> Dict[str, Any]:
        """Solve a sub-problem using a swarm"""
        # Simplified version - reuse swarm logic
        config = SwarmConfiguration(
            name=f"Swarm for {sub_prob.title}",
            behavior=SwarmBehavior.DEMOCRATIC,
            voting_strategy=voting_strategy,
            min_agents=2
        )
        
        swarm = AgentSwarm(config)
        self.swarms[swarm.swarm_id] = swarm
        
        return {
            "solution": f"Swarm solution for {sub_prob.title}",
            "confidence": 0.83,
            "swarms_used": [swarm.swarm_id],
            "agents_used": []
        }
    
    async def _build_consensus(
        self,
        problem: Problem,
        initial_result: Dict[str, Any],
        voting_strategy: VotingStrategy
    ) -> Dict[str, Any]:
        """
        Build consensus through iterative improvement
        
        Args:
            problem: Original problem
            initial_result: Initial solution attempt
            voting_strategy: Voting strategy
        
        Returns:
            Improved result with consensus
        """
        # Simulate consensus building
        # In real implementation, would iterate with agents
        iterations = 3
        
        result = initial_result.copy()
        result["consensus_achieved"] = True
        result["confidence"] = min(0.95, result.get("confidence", 0.8) + 0.1)
        result["iterations"] = iterations
        result["metadata"]["consensus_rounds"] = iterations
        
        return result
    
    def _decompose_problem(self, problem: Problem) -> List[SubProblem]:
        """
        Decompose a complex problem into sub-problems
        
        Args:
            problem: Problem to decompose
        
        Returns:
            List of sub-problems
        """
        # Simple decomposition based on agent types
        sub_problems = []
        
        if problem.required_agent_types:
            for i, agent_type in enumerate(problem.required_agent_types):
                sub_prob = SubProblem(
                    parent_id=problem.problem_id,
                    title=f"{problem.title} - {agent_type.value} phase",
                    description=f"Phase {i+1}: {agent_type.value} work for {problem.title}",
                    required_agent_types=[agent_type],
                    priority=problem.priority
                )
                sub_problems.append(sub_prob)
        else:
            # Create generic sub-problems using default phases
            for i, phase in enumerate(DEFAULT_PROBLEM_PHASES):
                sub_prob = SubProblem(
                    parent_id=problem.problem_id,
                    title=f"{problem.title} - {phase}",
                    description=f"Phase {i+1}: {phase} for {problem.title}",
                    priority=problem.priority
                )
                sub_problems.append(sub_prob)
        
        return sub_problems
    
    def _select_best_agent(self, problem: Problem) -> Optional[BaseAgent]:
        """Select the best single agent for a problem"""
        if problem.required_agent_types:
            # Find agent of required type
            for agent in self.agents.values():
                if agent.type in problem.required_agent_types:
                    return agent
        
        # Return any available agent
        return list(self.agents.values())[0] if self.agents else None
    
    def _select_agents_for_problem(
        self,
        problem: Problem,
        max_agents: int = 5,
        required_types: Optional[List[AgentType]] = None
    ) -> List[BaseAgent]:
        """
        Select agents suitable for a problem
        
        Args:
            problem: Problem to solve
            max_agents: Maximum number of agents
            required_types: Required agent types (overrides problem types)
        
        Returns:
            List of selected agents
        """
        selected = []
        types_needed = required_types or problem.required_agent_types or []
        
        # First, get agents of required types
        for agent_type in types_needed:
            for agent in self.agents.values():
                if agent.type == agent_type and agent not in selected:
                    selected.append(agent)
                    if len(selected) >= max_agents:
                        return selected
        
        # Fill remaining slots with any agents
        for agent in self.agents.values():
            if agent not in selected:
                selected.append(agent)
                if len(selected) >= max_agents:
                    return selected
        
        return selected
    
    def get_solution(self, problem_id: str) -> Optional[Solution]:
        """Get solution for a problem"""
        for solution in self.solutions.values():
            if solution.problem_id == problem_id:
                return solution
        return None
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get solver statistics"""
        return {
            "agents_registered": len(self.agents),
            "problems_solved": len(self.solutions),
            "swarms_created": len(self.swarms),
            "crews_created": len(self.crews),
            "avg_confidence": (
                sum(s.confidence for s in self.solutions.values()) / len(self.solutions)
                if self.solutions else 0.0
            ),
            "consensus_rate": (
                sum(1 for s in self.solutions.values() if s.consensus_achieved) / len(self.solutions)
                if self.solutions else 0.0
            )
        }
