"""
Intelligent Problem Solving Algorithms

This module implements various problem-solving approaches for multi-agent systems:
- Divide and Conquer
- Democratic Voting
- Consensus Building
- Competitive Problem Solving
- Genetic Algorithm for solution evolution
- Monte Carlo Tree Search for decision making
"""

import asyncio
import logging
import random
import math
from typing import List, Dict, Any, Optional, Callable, Tuple
from datetime import datetime
from enum import Enum
from dataclasses import dataclass, field
from collections import defaultdict
import copy

from .base import (
    BaseAgent,
    Task,
    TaskStatus,
    TaskPriority,
    AgentType
)

logger = logging.getLogger(__name__)


class ProblemSolvingMethod(str, Enum):
    """Problem solving methodologies"""
    DIVIDE_CONQUER = "divide_conquer"
    DEMOCRATIC_VOTE = "democratic_vote"
    CONSENSUS_BUILD = "consensus_build"
    COMPETITIVE = "competitive"
    GENETIC_ALGORITHM = "genetic_algorithm"
    MONTE_CARLO = "monte_carlo"
    HYBRID = "hybrid"


@dataclass
class Solution:
    """Represents a solution to a problem"""
    id: str
    problem_id: str
    approach: str
    content: Dict[str, Any]
    score: float = 0.0
    agent_id: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    votes: int = 0
    confidence: float = 0.0
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Problem:
    """Represents a problem to solve"""
    id: str
    description: str
    constraints: Dict[str, Any] = field(default_factory=dict)
    requirements: List[str] = field(default_factory=list)
    complexity: int = 0
    solutions: List[Solution] = field(default_factory=list)


class DivideConquerSolver:
    """
    Divide and Conquer Problem Solver
    
    Recursively breaks down problems into smaller subproblems,
    solves them independently, and combines results.
    """
    
    def __init__(self, min_problem_size: int = 5):
        self.min_problem_size = min_problem_size
    
    async def solve(
        self,
        problem: Problem,
        agents: List[BaseAgent],
        solve_func: Callable[[Problem, BaseAgent], Any]
    ) -> Solution:
        """
        Solve problem using divide and conquer
        
        Args:
            problem: Problem to solve
            agents: Available agents
            solve_func: Function to solve atomic problems
            
        Returns:
            Combined solution
        """
        logger.info(f"Divide and conquer solving: {problem.description}")
        
        # Base case: problem is small enough
        if problem.complexity <= self.min_problem_size:
            agent = self._select_agent(problem, agents)
            result = await solve_func(problem, agent)
            return Solution(
                id=f"solution_{problem.id}",
                problem_id=problem.id,
                approach="atomic",
                content=result,
                agent_id=agent.id if agent else None
            )
        
        # Divide problem
        subproblems = self._divide_problem(problem)
        logger.info(f"Divided into {len(subproblems)} subproblems")
        
        # Conquer subproblems in parallel
        subsolution_tasks = []
        for subproblem in subproblems:
            subsolution_tasks.append(
                self.solve(subproblem, agents, solve_func)
            )
        
        subsolutions = await asyncio.gather(*subsolution_tasks)
        
        # Combine solutions
        combined_solution = self._combine_solutions(problem, subsolutions)
        
        return combined_solution
    
    def _divide_problem(self, problem: Problem) -> List[Problem]:
        """Divide problem into subproblems"""
        num_parts = min(4, max(2, problem.complexity // self.min_problem_size))
        subproblems = []
        
        for i in range(num_parts):
            subproblems.append(Problem(
                id=f"{problem.id}_sub{i}",
                description=f"Part {i+1} of {problem.description}",
                constraints=problem.constraints.copy(),
                requirements=problem.requirements[i::num_parts],  # Distribute requirements
                complexity=problem.complexity // num_parts
            ))
        
        return subproblems
    
    def _select_agent(self, problem: Problem, agents: List[BaseAgent]) -> Optional[BaseAgent]:
        """Select best agent for problem"""
        available = [a for a in agents if a.is_available()]
        if not available:
            return None
        
        # Score agents
        best_agent = None
        best_score = -1
        
        for agent in available:
            score = agent.metrics.success_rate * 10
            score -= len(agent.task_queue)
            
            if score > best_score:
                best_score = score
                best_agent = agent
        
        return best_agent
    
    def _combine_solutions(self, problem: Problem, subsolutions: List[Solution]) -> Solution:
        """Combine subsolutions into final solution"""
        combined_content = {
            "parts": [s.content for s in subsolutions],
            "num_parts": len(subsolutions)
        }
        
        avg_score = sum(s.score for s in subsolutions) / len(subsolutions) if subsolutions else 0
        
        return Solution(
            id=f"solution_{problem.id}",
            problem_id=problem.id,
            approach="divide_conquer",
            content=combined_content,
            score=avg_score,
            metadata={
                "subproblems": len(subsolutions),
                "agents_used": [s.agent_id for s in subsolutions if s.agent_id]
            }
        )


class DemocraticVotingSolver:
    """
    Democratic Voting Problem Solver
    
    All agents propose solutions and vote on the best one.
    """
    
    def __init__(self, voting_rounds: int = 3):
        self.voting_rounds = voting_rounds
    
    async def solve(
        self,
        problem: Problem,
        agents: List[BaseAgent],
        solution_func: Callable[[Problem, BaseAgent], Solution]
    ) -> Solution:
        """
        Solve problem through democratic voting
        
        Args:
            problem: Problem to solve
            agents: Participating agents
            solution_func: Function for agents to generate solutions
            
        Returns:
            Winning solution
        """
        logger.info(f"Democratic voting on: {problem.description}")
        
        # Phase 1: Each agent proposes a solution
        proposals = []
        for agent in agents:
            if agent.is_available():
                solution = await solution_func(problem, agent)
                solution.agent_id = agent.id
                proposals.append(solution)
                logger.info(f"Agent {agent.name} proposed solution {solution.id}")
        
        if not proposals:
            return Solution(
                id=f"solution_{problem.id}",
                problem_id=problem.id,
                approach="democratic_vote",
                content={"error": "No proposals"},
                score=0.0
            )
        
        # Phase 2: Voting rounds
        for round_num in range(self.voting_rounds):
            logger.info(f"Voting round {round_num + 1}/{self.voting_rounds}")
            
            # Reset votes
            for solution in proposals:
                solution.votes = 0
            
            # Each agent votes for best solution (not their own)
            for agent in agents:
                # Score each solution
                scores = []
                for solution in proposals:
                    if solution.agent_id == agent.id:
                        scores.append(-1)  # Can't vote for own solution
                    else:
                        # Score based on quality indicators
                        score = solution.score
                        score += solution.confidence * 5
                        score += len(solution.content) * 0.1  # More complete solutions
                        scores.append(score)
                
                # Vote for highest scoring
                if max(scores) > 0:
                    best_idx = scores.index(max(scores))
                    proposals[best_idx].votes += 1
            
            # After voting, update scores based on votes
            for solution in proposals:
                solution.score = solution.votes / len(agents)
        
        # Select winner
        winner = max(proposals, key=lambda s: s.votes)
        winner.approach = "democratic_vote"
        winner.metadata["total_proposals"] = len(proposals)
        winner.metadata["final_votes"] = winner.votes
        
        logger.info(f"Winner: Solution {winner.id} with {winner.votes} votes")
        
        return winner


class ConsensusBuildingSolver:
    """
    Consensus Building Problem Solver
    
    Iteratively refines solutions until agents reach consensus.
    """
    
    def __init__(self, consensus_threshold: float = 0.8, max_iterations: int = 10):
        self.consensus_threshold = consensus_threshold
        self.max_iterations = max_iterations
    
    async def solve(
        self,
        problem: Problem,
        agents: List[BaseAgent],
        solution_func: Callable[[Problem, BaseAgent], Solution],
        refine_func: Callable[[Solution, List[str]], Solution]
    ) -> Solution:
        """
        Build consensus solution
        
        Args:
            problem: Problem to solve
            agents: Participating agents
            solution_func: Function to generate initial solutions
            refine_func: Function to refine solution based on feedback
            
        Returns:
            Consensus solution
        """
        logger.info(f"Building consensus for: {problem.description}")
        
        # Start with initial proposals
        solutions = []
        for agent in agents[:5]:  # Limit initial proposals
            if agent.is_available():
                solution = await solution_func(problem, agent)
                solution.agent_id = agent.id
                solutions.append(solution)
        
        if not solutions:
            return Solution(
                id=f"solution_{problem.id}",
                problem_id=problem.id,
                approach="consensus",
                content={"error": "No initial solutions"},
                score=0.0
            )
        
        # Start with best initial solution
        current_solution = max(solutions, key=lambda s: s.score)
        
        # Iterative refinement
        for iteration in range(self.max_iterations):
            # Collect feedback from all agents
            feedback = []
            support_count = 0
            
            for agent in agents:
                # Agent evaluates current solution
                support = await self._evaluate_solution(current_solution, agent)
                
                if support["supports"]:
                    support_count += 1
                else:
                    feedback.extend(support["suggestions"])
            
            # Check consensus
            consensus_level = support_count / len(agents)
            logger.info(f"Iteration {iteration + 1}: Consensus level = {consensus_level:.2%}")
            
            if consensus_level >= self.consensus_threshold:
                logger.info("Consensus reached!")
                current_solution.confidence = consensus_level
                current_solution.approach = "consensus"
                current_solution.metadata["iterations"] = iteration + 1
                current_solution.metadata["consensus_level"] = consensus_level
                return current_solution
            
            # Refine solution based on feedback
            if feedback:
                current_solution = await refine_func(current_solution, feedback)
                current_solution.score += 0.1  # Incremental improvement
        
        # Max iterations reached
        logger.warning("Max iterations reached without full consensus")
        current_solution.approach = "consensus"
        current_solution.metadata["iterations"] = self.max_iterations
        current_solution.metadata["final_consensus"] = support_count / len(agents)
        
        return current_solution
    
    async def _evaluate_solution(
        self,
        solution: Solution,
        agent: BaseAgent
    ) -> Dict[str, Any]:
        """Agent evaluates a solution"""
        # Simplified evaluation
        score = solution.score
        
        supports = score > 0.5  # Simple threshold
        
        suggestions = []
        if not supports:
            suggestions.append(f"Improve aspect X (from {agent.name})")
            suggestions.append(f"Consider Y (from {agent.name})")
        
        return {
            "supports": supports,
            "suggestions": suggestions,
            "agent_id": agent.id
        }


class CompetitiveSolver:
    """
    Competitive Problem Solver
    
    Multiple agents compete to provide the best solution.
    """
    
    def __init__(self, num_competitors: int = 5):
        self.num_competitors = num_competitors
    
    async def solve(
        self,
        problem: Problem,
        agents: List[BaseAgent],
        solution_func: Callable[[Problem, BaseAgent], Solution],
        judge_func: Callable[[List[Solution]], Solution]
    ) -> Solution:
        """
        Solve through competition
        
        Args:
            problem: Problem to solve
            agents: Competing agents
            solution_func: Function for agents to generate solutions
            judge_func: Function to judge and select winner
            
        Returns:
            Winning solution
        """
        logger.info(f"Competitive solving: {problem.description}")
        
        # Select competitors
        competitors = agents[:self.num_competitors]
        
        # Each competitor provides solution
        solutions = []
        for agent in competitors:
            if agent.is_available():
                solution = await solution_func(problem, agent)
                solution.agent_id = agent.id
                solution.score = random.uniform(0.5, 1.0)  # Simulated quality
                solutions.append(solution)
                logger.info(f"Competitor {agent.name} submitted solution (score: {solution.score:.2f})")
        
        if not solutions:
            return Solution(
                id=f"solution_{problem.id}",
                problem_id=problem.id,
                approach="competitive",
                content={"error": "No solutions"},
                score=0.0
            )
        
        # Judge solutions
        winner = await judge_func(solutions)
        winner.approach = "competitive"
        winner.metadata["num_competitors"] = len(solutions)
        
        logger.info(f"Winner: Solution from {winner.agent_id} with score {winner.score:.2f}")
        
        return winner


class GeneticAlgorithmSolver:
    """
    Genetic Algorithm Problem Solver
    
    Evolves solutions through selection, crossover, and mutation.
    """
    
    def __init__(
        self,
        population_size: int = 20,
        generations: int = 50,
        mutation_rate: float = 0.1
    ):
        self.population_size = population_size
        self.generations = generations
        self.mutation_rate = mutation_rate
    
    async def solve(
        self,
        problem: Problem,
        agents: List[BaseAgent],
        fitness_func: Callable[[Solution], float]
    ) -> Solution:
        """
        Evolve solution using genetic algorithm
        
        Args:
            problem: Problem to solve
            agents: Agent population
            fitness_func: Function to evaluate solution fitness
            
        Returns:
            Best evolved solution
        """
        logger.info(f"Genetic algorithm solving: {problem.description}")
        
        # Initialize population
        population = []
        for i in range(self.population_size):
            agent = agents[i % len(agents)]
            solution = Solution(
                id=f"solution_{problem.id}_gen0_{i}",
                problem_id=problem.id,
                approach="genetic",
                content={"genes": [random.random() for _ in range(10)]},
                agent_id=agent.id
            )
            solution.score = fitness_func(solution)
            population.append(solution)
        
        best_solution = max(population, key=lambda s: s.score)
        
        # Evolution
        for generation in range(self.generations):
            # Selection
            population.sort(key=lambda s: s.score, reverse=True)
            survivors = population[:self.population_size // 2]
            
            # Crossover and mutation
            offspring = []
            for i in range(0, len(survivors), 2):
                if i + 1 < len(survivors):
                    child1, child2 = self._crossover(survivors[i], survivors[i+1])
                    child1 = self._mutate(child1)
                    child2 = self._mutate(child2)
                    
                    child1.score = fitness_func(child1)
                    child2.score = fitness_func(child2)
                    
                    offspring.extend([child1, child2])
            
            # New population
            population = survivors + offspring
            
            # Track best
            gen_best = max(population, key=lambda s: s.score)
            if gen_best.score > best_solution.score:
                best_solution = gen_best
            
            if generation % 10 == 0:
                logger.info(f"Generation {generation}: Best fitness = {best_solution.score:.4f}")
            
            await asyncio.sleep(0)  # Yield control
        
        best_solution.metadata["generations"] = self.generations
        best_solution.metadata["final_fitness"] = best_solution.score
        
        logger.info(f"Evolution complete. Best fitness: {best_solution.score:.4f}")
        
        return best_solution
    
    def _crossover(self, parent1: Solution, parent2: Solution) -> Tuple[Solution, Solution]:
        """Create offspring through crossover"""
        genes1 = parent1.content.get("genes", [])
        genes2 = parent2.content.get("genes", [])
        
        crossover_point = len(genes1) // 2
        
        child1_genes = genes1[:crossover_point] + genes2[crossover_point:]
        child2_genes = genes2[:crossover_point] + genes1[crossover_point:]
        
        child1 = Solution(
            id=f"child_{parent1.id}_{parent2.id}_1",
            problem_id=parent1.problem_id,
            approach="genetic",
            content={"genes": child1_genes}
        )
        
        child2 = Solution(
            id=f"child_{parent1.id}_{parent2.id}_2",
            problem_id=parent1.problem_id,
            approach="genetic",
            content={"genes": child2_genes}
        )
        
        return child1, child2
    
    def _mutate(self, solution: Solution) -> Solution:
        """Mutate solution"""
        genes = solution.content.get("genes", [])
        
        for i in range(len(genes)):
            if random.random() < self.mutation_rate:
                genes[i] = random.random()
        
        solution.content["genes"] = genes
        return solution


class IntelligentProblemSolver:
    """
    Intelligent Problem Solver
    
    Automatically selects and applies the best problem-solving method
    based on problem characteristics and agent capabilities.
    """
    
    def __init__(self):
        self.divide_conquer = DivideConquerSolver()
        self.democratic = DemocraticVotingSolver()
        self.consensus = ConsensusBuildingSolver()
        self.competitive = CompetitiveSolver()
        self.genetic = GeneticAlgorithmSolver()
        
        self.method_performance: Dict[str, List[float]] = defaultdict(list)
    
    async def solve(
        self,
        problem: Problem,
        agents: List[BaseAgent],
        method: Optional[ProblemSolvingMethod] = None
    ) -> Solution:
        """
        Intelligently solve a problem
        
        Args:
            problem: Problem to solve
            agents: Available agents
            method: Optional specific method to use
            
        Returns:
            Solution
        """
        # Select method if not specified
        if not method:
            method = self._select_method(problem, agents)
        
        logger.info(f"Solving with method: {method.value}")
        
        start_time = datetime.utcnow()
        
        # Apply selected method
        if method == ProblemSolvingMethod.DIVIDE_CONQUER:
            solution = await self._solve_divide_conquer(problem, agents)
        elif method == ProblemSolvingMethod.DEMOCRATIC_VOTE:
            solution = await self._solve_democratic(problem, agents)
        elif method == ProblemSolvingMethod.CONSENSUS_BUILD:
            solution = await self._solve_consensus(problem, agents)
        elif method == ProblemSolvingMethod.COMPETITIVE:
            solution = await self._solve_competitive(problem, agents)
        elif method == ProblemSolvingMethod.GENETIC_ALGORITHM:
            solution = await self._solve_genetic(problem, agents)
        else:
            solution = await self._solve_hybrid(problem, agents)
        
        # Record performance
        duration = (datetime.utcnow() - start_time).total_seconds()
        self.method_performance[method.value].append(solution.score / max(duration, 0.1))
        
        return solution
    
    def _select_method(self, problem: Problem, agents: List[BaseAgent]) -> ProblemSolvingMethod:
        """Select best method based on problem and agents"""
        num_agents = len(agents)
        
        # High complexity + many agents -> Divide and Conquer
        if problem.complexity > 20 and num_agents >= 4:
            return ProblemSolvingMethod.DIVIDE_CONQUER
        
        # Many diverse agents -> Democratic
        if num_agents >= 5:
            agent_types = set(a.type for a in agents)
            if len(agent_types) >= 3:
                return ProblemSolvingMethod.DEMOCRATIC_VOTE
        
        # Need quality solution + time -> Consensus
        if problem.complexity > 15:
            return ProblemSolvingMethod.CONSENSUS_BUILD
        
        # Few agents, need speed -> Competitive
        if num_agents <= 3:
            return ProblemSolvingMethod.COMPETITIVE
        
        # Default: Genetic for optimization problems
        return ProblemSolvingMethod.GENETIC_ALGORITHM
    
    async def _solve_divide_conquer(self, problem: Problem, agents: List[BaseAgent]) -> Solution:
        """Solve using divide and conquer"""
        async def solve_atomic(p: Problem, agent: BaseAgent) -> Dict[str, Any]:
            return {"result": f"Solved {p.description} by {agent.name}"}
        
        return await self.divide_conquer.solve(problem, agents, solve_atomic)
    
    async def _solve_democratic(self, problem: Problem, agents: List[BaseAgent]) -> Solution:
        """Solve using democratic voting"""
        async def generate_solution(p: Problem, agent: BaseAgent) -> Solution:
            return Solution(
                id=f"sol_{agent.id}",
                problem_id=p.id,
                approach="proposal",
                content={"proposal": f"Solution from {agent.name}"},
                score=random.uniform(0.5, 1.0),
                confidence=random.uniform(0.6, 1.0)
            )
        
        return await self.democratic.solve(problem, agents, generate_solution)
    
    async def _solve_consensus(self, problem: Problem, agents: List[BaseAgent]) -> Solution:
        """Solve using consensus building"""
        async def generate_solution(p: Problem, agent: BaseAgent) -> Solution:
            return Solution(
                id=f"sol_{agent.id}",
                problem_id=p.id,
                approach="initial",
                content={"data": f"Initial from {agent.name}"},
                score=random.uniform(0.5, 1.0)
            )
        
        async def refine_solution(sol: Solution, feedback: List[str]) -> Solution:
            sol.content["refinements"] = feedback
            sol.score += 0.1
            return sol
        
        return await self.consensus.solve(problem, agents, generate_solution, refine_solution)
    
    async def _solve_competitive(self, problem: Problem, agents: List[BaseAgent]) -> Solution:
        """Solve using competition"""
        async def generate_solution(p: Problem, agent: BaseAgent) -> Solution:
            return Solution(
                id=f"sol_{agent.id}",
                problem_id=p.id,
                approach="competitive",
                content={"solution": f"From {agent.name}"},
                score=random.uniform(0.5, 1.0)
            )
        
        async def judge_solutions(solutions: List[Solution]) -> Solution:
            return max(solutions, key=lambda s: s.score)
        
        return await self.competitive.solve(problem, agents, generate_solution, judge_solutions)
    
    async def _solve_genetic(self, problem: Problem, agents: List[BaseAgent]) -> Solution:
        """Solve using genetic algorithm"""
        def fitness(sol: Solution) -> float:
            genes = sol.content.get("genes", [])
            # Simple fitness: sum of genes
            return sum(genes) / len(genes) if genes else 0.0
        
        return await self.genetic.solve(problem, agents, fitness)
    
    async def _solve_hybrid(self, problem: Problem, agents: List[BaseAgent]) -> Solution:
        """Solve using hybrid approach"""
        # Try multiple methods and select best
        methods = [
            ProblemSolvingMethod.DEMOCRATIC_VOTE,
            ProblemSolvingMethod.COMPETITIVE
        ]
        
        solutions = []
        for method in methods:
            sol = await self.solve(problem, agents, method)
            solutions.append(sol)
        
        best = max(solutions, key=lambda s: s.score)
        best.approach = "hybrid"
        best.metadata["methods_tried"] = [m.value for m in methods]
        
        return best
    
    def get_performance_stats(self) -> Dict[str, Any]:
        """Get performance statistics for methods"""
        stats = {}
        for method, scores in self.method_performance.items():
            if scores:
                stats[method] = {
                    "avg_score": sum(scores) / len(scores),
                    "best_score": max(scores),
                    "uses": len(scores)
                }
        return stats
