"""
Swarm Intelligence Coordination System

This module implements various swarm intelligence algorithms for agent coordination:
- Particle Swarm Optimization (PSO) for task optimization
- Ant Colony Optimization (ACO) for task routing
- Bee Colony Algorithm for resource allocation
- Emergent behavior through decentralized coordination
"""

import asyncio
import random
import logging
from typing import List, Dict, Any, Optional, Callable, Tuple
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
import math

from .base import (
    BaseAgent,
    Task,
    TaskStatus,
    TaskPriority,
    AgentStatus,
    AgentType
)

logger = logging.getLogger(__name__)


class SwarmStrategy(str, Enum):
    """Swarm coordination strategies"""
    PARTICLE_SWARM = "particle_swarm"
    ANT_COLONY = "ant_colony"
    BEE_COLONY = "bee_colony"
    FIREFLY = "firefly"
    WOLF_PACK = "wolf_pack"


@dataclass
class Particle:
    """Particle in PSO algorithm representing an agent's solution state"""
    agent_id: str
    position: List[float]  # Current solution
    velocity: List[float]  # Movement direction
    best_position: List[float]  # Personal best
    best_fitness: float = float('-inf')
    fitness: float = 0.0


@dataclass
class Pheromone:
    """Pheromone trail for ACO algorithm"""
    source: str
    target: str
    strength: float = 1.0
    evaporation_rate: float = 0.1
    last_updated: datetime = field(default_factory=datetime.utcnow)
    
    def evaporate(self, delta_time: float) -> None:
        """Reduce pheromone strength over time"""
        self.strength *= (1 - self.evaporation_rate * delta_time)
        self.strength = max(0.01, self.strength)


@dataclass
class FoodSource:
    """Food source for Bee Colony algorithm (represents a task/solution)"""
    id: str
    quality: float
    position: List[float]
    visits: int = 0
    abandonment_limit: int = 10


class SwarmCoordinator:
    """
    Swarm Intelligence Coordinator
    
    Coordinates multiple agents using swarm intelligence algorithms for:
    - Distributed problem solving
    - Emergent optimization
    - Self-organizing task distribution
    - Adaptive resource allocation
    
    Example:
        ```python
        coordinator = SwarmCoordinator(strategy=SwarmStrategy.PARTICLE_SWARM)
        coordinator.add_agents(agents)
        await coordinator.optimize(task)
        ```
    """
    
    def __init__(
        self,
        strategy: SwarmStrategy = SwarmStrategy.PARTICLE_SWARM,
        population_size: int = 20,
        max_iterations: int = 100
    ):
        self.strategy = strategy
        self.population_size = population_size
        self.max_iterations = max_iterations
        
        # Swarm state
        self.agents: Dict[str, BaseAgent] = {}
        self.particles: Dict[str, Particle] = {}
        self.pheromones: List[Pheromone] = []
        self.food_sources: List[FoodSource] = []
        
        # Global best for PSO
        self.global_best_position: Optional[List[float]] = None
        self.global_best_fitness: float = float('-inf')
        
        # Statistics
        self.iteration_count = 0
        self.convergence_history: List[float] = []
        
    def add_agent(self, agent: BaseAgent) -> None:
        """Add an agent to the swarm"""
        self.agents[agent.id] = agent
        
        # Initialize particle for PSO
        if self.strategy == SwarmStrategy.PARTICLE_SWARM:
            dim = 5  # Solution space dimensions
            self.particles[agent.id] = Particle(
                agent_id=agent.id,
                position=[random.uniform(-10, 10) for _ in range(dim)],
                velocity=[random.uniform(-1, 1) for _ in range(dim)],
                best_position=[random.uniform(-10, 10) for _ in range(dim)]
            )
    
    def add_agents(self, agents: List[BaseAgent]) -> None:
        """Add multiple agents to the swarm"""
        for agent in agents:
            self.add_agent(agent)
    
    async def optimize_pso(
        self,
        fitness_func: Callable[[List[float]], float],
        w: float = 0.7,  # Inertia weight
        c1: float = 1.5,  # Cognitive parameter
        c2: float = 1.5   # Social parameter
    ) -> Tuple[List[float], float]:
        """
        Particle Swarm Optimization
        
        Args:
            fitness_func: Function to evaluate solution quality
            w: Inertia weight (exploration vs exploitation)
            c1: Cognitive parameter (personal best influence)
            c2: Social parameter (global best influence)
            
        Returns:
            Tuple of (best_solution, best_fitness)
        """
        logger.info(f"Starting PSO optimization with {len(self.particles)} particles")
        
        for iteration in range(self.max_iterations):
            for particle_id, particle in self.particles.items():
                # Evaluate fitness
                particle.fitness = fitness_func(particle.position)
                
                # Update personal best
                if particle.fitness > particle.best_fitness:
                    particle.best_fitness = particle.fitness
                    particle.best_position = particle.position.copy()
                
                # Update global best
                if particle.fitness > self.global_best_fitness:
                    self.global_best_fitness = particle.fitness
                    self.global_best_position = particle.position.copy()
            
            # Update velocities and positions
            for particle in self.particles.values():
                if self.global_best_position:
                    for i in range(len(particle.velocity)):
                        r1, r2 = random.random(), random.random()
                        
                        cognitive = c1 * r1 * (particle.best_position[i] - particle.position[i])
                        social = c2 * r2 * (self.global_best_position[i] - particle.position[i])
                        
                        particle.velocity[i] = w * particle.velocity[i] + cognitive + social
                        particle.position[i] += particle.velocity[i]
            
            self.convergence_history.append(self.global_best_fitness)
            
            if iteration % 10 == 0:
                logger.info(f"Iteration {iteration}: Best fitness = {self.global_best_fitness:.4f}")
            
            await asyncio.sleep(0)  # Yield control
        
        return self.global_best_position, self.global_best_fitness
    
    async def optimize_aco(
        self,
        graph: Dict[str, List[str]],
        start: str,
        goal: str,
        num_ants: int = 20,
        alpha: float = 1.0,  # Pheromone importance
        beta: float = 2.0,   # Heuristic importance
        evaporation: float = 0.1
    ) -> List[str]:
        """
        Ant Colony Optimization for path finding
        
        Args:
            graph: Task dependency graph
            start: Starting task/node
            goal: Goal task/node
            num_ants: Number of ant agents
            alpha: Pheromone trail importance
            beta: Heuristic information importance
            evaporation: Pheromone evaporation rate
            
        Returns:
            Best path from start to goal
        """
        logger.info(f"Starting ACO optimization from {start} to {goal}")
        
        # Initialize pheromones
        for node in graph:
            for neighbor in graph.get(node, []):
                self.pheromones.append(Pheromone(node, neighbor, 1.0, evaporation))
        
        best_path: List[str] = []
        best_length = float('inf')
        
        for iteration in range(self.max_iterations):
            paths = []
            
            # Each ant constructs a path
            for ant in range(num_ants):
                path = await self._construct_path_aco(
                    graph, start, goal, alpha, beta
                )
                if path and len(path) < best_length:
                    best_path = path
                    best_length = len(path)
                    paths.append(path)
            
            # Update pheromones
            await self._update_pheromones(paths, evaporation)
            
            if iteration % 10 == 0:
                logger.info(f"Iteration {iteration}: Best path length = {best_length}")
            
            await asyncio.sleep(0)
        
        return best_path
    
    async def _construct_path_aco(
        self,
        graph: Dict[str, List[str]],
        start: str,
        goal: str,
        alpha: float,
        beta: float
    ) -> List[str]:
        """Construct a path using ACO probabilistic selection"""
        path = [start]
        current = start
        visited = {start}
        
        max_steps = len(graph) * 2  # Prevent infinite loops
        
        for _ in range(max_steps):
            if current == goal:
                return path
            
            neighbors = [n for n in graph.get(current, []) if n not in visited]
            if not neighbors:
                break
            
            # Calculate probabilities based on pheromones and heuristic
            probabilities = []
            for neighbor in neighbors:
                pheromone = self._get_pheromone_strength(current, neighbor)
                heuristic = 1.0  # Could be distance-based
                prob = (pheromone ** alpha) * (heuristic ** beta)
                probabilities.append(prob)
            
            # Normalize probabilities
            total = sum(probabilities)
            if total > 0:
                probabilities = [p / total for p in probabilities]
            else:
                probabilities = [1.0 / len(neighbors)] * len(neighbors)
            
            # Select next node
            next_node = random.choices(neighbors, probabilities)[0]
            path.append(next_node)
            visited.add(next_node)
            current = next_node
            
            await asyncio.sleep(0)
        
        return path if current == goal else []
    
    def _get_pheromone_strength(self, source: str, target: str) -> float:
        """Get pheromone strength between two nodes"""
        for pheromone in self.pheromones:
            if pheromone.source == source and pheromone.target == target:
                return pheromone.strength
        return 0.1  # Minimum pheromone level
    
    async def _update_pheromones(self, paths: List[List[str]], evaporation: float) -> None:
        """Update pheromone trails based on ant paths"""
        # Evaporate existing pheromones
        current_time = datetime.utcnow()
        for pheromone in self.pheromones:
            delta = (current_time - pheromone.last_updated).total_seconds()
            pheromone.evaporate(delta)
            pheromone.last_updated = current_time
        
        # Deposit new pheromones
        for path in paths:
            deposit = 1.0 / len(path)  # Shorter paths get more pheromone
            for i in range(len(path) - 1):
                source, target = path[i], path[i + 1]
                for pheromone in self.pheromones:
                    if pheromone.source == source and pheromone.target == target:
                        pheromone.strength += deposit
                        break
    
    async def optimize_bee_colony(
        self,
        objective_func: Callable[[List[float]], float],
        dimension: int = 5,
        num_bees: int = 30,
        num_employed: int = 15,
        num_onlooker: int = 15,
        limit: int = 10
    ) -> Tuple[List[float], float]:
        """
        Artificial Bee Colony Optimization
        
        Args:
            objective_func: Function to minimize
            dimension: Problem dimension
            num_bees: Total number of bees
            num_employed: Number of employed bees
            num_onlooker: Number of onlooker bees
            limit: Abandonment limit
            
        Returns:
            Tuple of (best_solution, best_value)
        """
        logger.info(f"Starting Bee Colony optimization with {num_bees} bees")
        
        # Initialize food sources
        for i in range(num_employed):
            position = [random.uniform(-10, 10) for _ in range(dimension)]
            quality = objective_func(position)
            self.food_sources.append(FoodSource(
                id=f"source_{i}",
                quality=quality,
                position=position,
                abandonment_limit=limit
            ))
        
        best_source = max(self.food_sources, key=lambda s: s.quality)
        
        for iteration in range(self.max_iterations):
            # Employed bees phase
            for source in self.food_sources:
                new_position = source.position.copy()
                k = random.randint(0, dimension - 1)
                phi = random.uniform(-1, 1)
                
                # Select random neighbor
                neighbor = random.choice(self.food_sources)
                new_position[k] = source.position[k] + phi * (
                    source.position[k] - neighbor.position[k]
                )
                
                new_quality = objective_func(new_position)
                
                if new_quality > source.quality:
                    source.position = new_position
                    source.quality = new_quality
                    source.visits = 0
                else:
                    source.visits += 1
            
            # Onlooker bees phase
            total_fitness = sum(s.quality for s in self.food_sources)
            for _ in range(num_onlooker):
                # Select source based on probability
                probabilities = [s.quality / total_fitness for s in self.food_sources]
                source = random.choices(self.food_sources, probabilities)[0]
                
                # Exploit source
                new_position = source.position.copy()
                k = random.randint(0, dimension - 1)
                phi = random.uniform(-1, 1)
                neighbor = random.choice(self.food_sources)
                new_position[k] = source.position[k] + phi * (
                    source.position[k] - neighbor.position[k]
                )
                
                new_quality = objective_func(new_position)
                if new_quality > source.quality:
                    source.position = new_position
                    source.quality = new_quality
                    source.visits = 0
            
            # Scout bees phase - abandon exhausted sources
            for source in self.food_sources:
                if source.visits > source.abandonment_limit:
                    source.position = [random.uniform(-10, 10) for _ in range(dimension)]
                    source.quality = objective_func(source.position)
                    source.visits = 0
            
            # Update best
            current_best = max(self.food_sources, key=lambda s: s.quality)
            if current_best.quality > best_source.quality:
                best_source = current_best
            
            self.convergence_history.append(best_source.quality)
            
            if iteration % 10 == 0:
                logger.info(f"Iteration {iteration}: Best quality = {best_source.quality:.4f}")
            
            await asyncio.sleep(0)
        
        return best_source.position, best_source.quality
    
    async def coordinate_swarm(
        self,
        tasks: List[Task],
        optimization_target: str = "completion_time"
    ) -> Dict[str, Any]:
        """
        Coordinate swarm to optimize task execution
        
        Args:
            tasks: List of tasks to execute
            optimization_target: What to optimize (completion_time, quality, resource_usage)
            
        Returns:
            Optimization results and task assignments
        """
        logger.info(f"Coordinating swarm of {len(self.agents)} agents for {len(tasks)} tasks")
        
        if self.strategy == SwarmStrategy.PARTICLE_SWARM:
            # Define fitness function for task assignment
            def fitness(solution: List[float]) -> float:
                # solution encodes agent-task assignments
                score = 0.0
                for i, task in enumerate(tasks[:len(solution)]):
                    agent_idx = int(abs(solution[i])) % len(self.agents)
                    agent = list(self.agents.values())[agent_idx]
                    
                    # Prefer matching agent types
                    if task.agent_type and task.agent_type == agent.type:
                        score += 10.0
                    
                    # Consider agent load
                    score -= len(agent.task_queue) * 0.5
                    
                    # Consider agent success rate
                    score += agent.metrics.success_rate * 5.0
                
                return score
            
            best_solution, best_fitness = await self.optimize_pso(fitness)
            
            # Assign tasks based on solution
            assignments = {}
            for i, task in enumerate(tasks):
                if i < len(best_solution):
                    agent_idx = int(abs(best_solution[i])) % len(self.agents)
                    agent = list(self.agents.values())[agent_idx]
                    assignments[task.id] = agent.id
            
            return {
                "strategy": "particle_swarm",
                "assignments": assignments,
                "fitness": best_fitness,
                "iterations": self.iteration_count,
                "convergence": self.convergence_history
            }
        
        elif self.strategy == SwarmStrategy.ANT_COLONY:
            # Build task dependency graph
            graph = self._build_task_graph(tasks)
            
            # Find optimal execution path
            if tasks:
                start_task = tasks[0].id
                end_task = tasks[-1].id
                best_path = await self.optimize_aco(graph, start_task, end_task)
                
                return {
                    "strategy": "ant_colony",
                    "execution_path": best_path,
                    "path_length": len(best_path)
                }
        
        elif self.strategy == SwarmStrategy.BEE_COLONY:
            # Optimize resource allocation
            def objective(allocation: List[float]) -> float:
                score = 0.0
                for i, val in enumerate(allocation[:len(self.agents)]):
                    agent = list(self.agents.values())[i]
                    # Reward balanced load
                    target_load = len(tasks) / len(self.agents)
                    score -= abs(val - target_load)
                return score
            
            best_allocation, best_value = await self.optimize_bee_colony(objective)
            
            return {
                "strategy": "bee_colony",
                "resource_allocation": best_allocation,
                "optimization_value": best_value
            }
        
        return {"strategy": self.strategy.value, "status": "not_implemented"}
    
    def _build_task_graph(self, tasks: List[Task]) -> Dict[str, List[str]]:
        """Build a task dependency graph"""
        graph: Dict[str, List[str]] = {task.id: [] for task in tasks}
        
        for task in tasks:
            for dep_id in task.dependencies:
                if dep_id in graph:
                    graph[dep_id].append(task.id)
        
        return graph
    
    def get_swarm_metrics(self) -> Dict[str, Any]:
        """Get swarm coordination metrics"""
        return {
            "strategy": self.strategy.value,
            "population_size": len(self.agents),
            "iterations": self.iteration_count,
            "global_best_fitness": self.global_best_fitness,
            "convergence_history": self.convergence_history[-10:],  # Last 10 values
            "num_pheromones": len(self.pheromones),
            "num_food_sources": len(self.food_sources)
        }
