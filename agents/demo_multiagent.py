#!/usr/bin/env python3
"""
Multi-Agent System Demonstration

This script demonstrates the complete multi-agent system with:
- Swarm intelligence coordination
- Hierarchical organization
- Autonomous crews
- Intelligent problem solving
- Various collaboration patterns
"""

import asyncio
import logging
from datetime import timedelta
from typing import List

from .base import (
    BaseAgent,
    Task,
    TaskPriority,
    AgentType,
    AgentConfig
)
from .hierarchy import (
    ManagerAgent,
    CoordinatorAgent,
    WorkerAgent
)
from .swarm import SwarmCoordinator, SwarmStrategy
from .autonomous_crew import AutonomousCrew, CrewStrategy
from .problem_solving import (
    IntelligentProblemSolver,
    Problem,
    ProblemSolvingMethod
)
from .orchestrator import AgentOrchestrator, OrchestrationStrategy

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class MultiAgentDemo:
    """Demonstration of multi-agent system capabilities"""
    
    def __init__(self):
        self.agents: List[BaseAgent] = []
        self.orchestrator = AgentOrchestrator(
            strategy=OrchestrationStrategy.SPECIALIZED
        )
    
    def create_agent_team(self, size: int = 10) -> None:
        """Create a diverse team of agents"""
        logger.info(f"Creating team of {size} agents...")
        
        # Create manager
        manager = ManagerAgent(
            name="Team Manager",
            type=AgentType.GENERAL,
            description="Manages team and decomposes complex tasks"
        )
        self.agents.append(manager)
        
        # Create coordinator
        coordinator = CoordinatorAgent(
            name="Team Coordinator",
            type=AgentType.GENERAL,
            description="Coordinates parallel execution and synchronization"
        )
        self.agents.append(coordinator)
        
        # Create specialized workers
        agent_types = [
            (AgentType.PROGRAMMING, "Python Developer"),
            (AgentType.PROGRAMMING, "JavaScript Developer"),
            (AgentType.TESTING, "Test Engineer"),
            (AgentType.DEVOPS, "DevOps Engineer"),
            (AgentType.SECURITY, "Security Specialist"),
            (AgentType.DOCUMENTATION, "Technical Writer"),
            (AgentType.DATA, "Data Engineer"),
            (AgentType.DESIGN, "System Architect"),
        ]
        
        for i, (agent_type, role) in enumerate(agent_types[:size-2]):
            worker = WorkerAgent(
                name=f"{role} {i+1}",
                type=agent_type,
                description=f"Specialized {role.lower()}"
            )
            manager.add_subordinate(worker.id)
            self.agents.append(worker)
        
        # Register with orchestrator
        for agent in self.agents:
            self.orchestrator.register_agent(agent)
        
        logger.info(f"Created {len(self.agents)} agents")
    
    async def demo_swarm_intelligence(self) -> None:
        """Demonstrate swarm intelligence coordination"""
        logger.info("\n" + "="*60)
        logger.info("DEMO 1: Swarm Intelligence Coordination")
        logger.info("="*60)
        
        # Create swarm coordinator with PSO
        swarm = SwarmCoordinator(
            strategy=SwarmStrategy.PARTICLE_SWARM,
            population_size=len(self.agents)
        )
        
        for agent in self.agents:
            swarm.add_agent(agent)
        
        # Optimize task assignment
        tasks = [
            Task(
                title=f"Task {i+1}",
                description=f"Complex task requiring optimization {i+1}",
                priority=TaskPriority.HIGH,
                agent_type=AgentType.PROGRAMMING if i % 2 == 0 else AgentType.TESTING
            )
            for i in range(5)
        ]
        
        logger.info(f"Optimizing assignment of {len(tasks)} tasks using PSO...")
        result = await swarm.coordinate_swarm(tasks, "completion_time")
        
        logger.info(f"Swarm optimization completed:")
        logger.info(f"  Strategy: {result['strategy']}")
        logger.info(f"  Fitness: {result.get('fitness', 'N/A')}")
        logger.info(f"  Assignments: {len(result.get('assignments', {}))}")
    
    async def demo_hierarchical_organization(self) -> None:
        """Demonstrate hierarchical agent organization"""
        logger.info("\n" + "="*60)
        logger.info("DEMO 2: Hierarchical Organization")
        logger.info("="*60)
        
        # Find manager
        manager = next((a for a in self.agents if isinstance(a, ManagerAgent)), None)
        if not manager:
            logger.warning("No manager found")
            return
        
        # Complex task for decomposition
        complex_task = Task(
            title="Build Complete E-commerce Platform",
            description="""
            Create a full-featured e-commerce platform with:
            - User authentication and authorization
            - Product catalog with search
            - Shopping cart and checkout
            - Payment processing integration
            - Order management system
            - Admin dashboard
            - API documentation
            - Comprehensive testing
            - Security audit
            """,
            priority=TaskPriority.CRITICAL,
            agent_type=AgentType.PROGRAMMING
        )
        
        logger.info(f"Manager decomposing complex task: {complex_task.title}")
        decomposition = await manager.decompose_task(complex_task)
        
        logger.info(f"Task decomposition result:")
        logger.info(f"  Original task complexity: {manager._analyze_complexity(complex_task)}")
        logger.info(f"  Number of subtasks: {len(decomposition.subtasks)}")
        logger.info(f"  Execution stages: {len(decomposition.execution_plan)}")
        logger.info(f"  Estimated time: {decomposition.estimated_time}s")
        
        for i, stage in enumerate(decomposition.execution_plan):
            logger.info(f"  Stage {i+1}: {len(stage)} parallel tasks")
    
    async def demo_autonomous_crew(self) -> None:
        """Demonstrate autonomous crew operation"""
        logger.info("\n" + "="*60)
        logger.info("DEMO 3: Autonomous Crew Operation")
        logger.info("="*60)
        
        # Create democratic crew
        crew = AutonomousCrew(
            name="Development Crew",
            strategy=CrewStrategy.DEMOCRATIC,
            max_iterations=50,
            consensus_threshold=0.7
        )
        
        crew.add_agents(self.agents[:6])  # Use subset of agents
        
        # Task for autonomous execution
        task = Task(
            title="Implement REST API with Tests",
            description="""
            Create a RESTful API service with:
            - CRUD endpoints for resources
            - Input validation
            - Error handling
            - Unit tests (90% coverage)
            - Integration tests
            - API documentation
            """,
            priority=TaskPriority.HIGH,
            agent_type=AgentType.PROGRAMMING
        )
        
        logger.info(f"Autonomous crew executing: {task.title}")
        logger.info(f"Strategy: {crew.strategy.value}")
        logger.info(f"Crew size: {len(crew.agents)} agents")
        
        # Execute autonomously with timeout
        result = await crew.execute_autonomously(
            task,
            max_runtime=timedelta(seconds=30)
        )
        
        logger.info(f"\nAutonomous execution completed:")
        logger.info(f"  Duration: {result['duration_seconds']:.2f}s")
        logger.info(f"  Iterations: {result['iterations']}")
        logger.info(f"  Tasks completed: {result['tasks']['completed']}/{result['tasks']['total']}")
        logger.info(f"  Success rate: {result['tasks']['success_rate']:.2%}")
        logger.info(f"  Decisions made: {result['decisions_made']}")
        logger.info(f"  Final status: {result['final_status']}")
    
    async def demo_problem_solving_methods(self) -> None:
        """Demonstrate different problem-solving methods"""
        logger.info("\n" + "="*60)
        logger.info("DEMO 4: Problem Solving Methods")
        logger.info("="*60)
        
        solver = IntelligentProblemSolver()
        
        problem = Problem(
            id="complex_problem_1",
            description="Optimize distributed system architecture",
            complexity=25,
            requirements=[
                "High availability",
                "Horizontal scalability",
                "Data consistency",
                "Low latency",
                "Cost efficiency"
            ]
        )
        
        methods_to_test = [
            ProblemSolvingMethod.DIVIDE_CONQUER,
            ProblemSolvingMethod.DEMOCRATIC_VOTE,
            ProblemSolvingMethod.COMPETITIVE,
            ProblemSolvingMethod.GENETIC_ALGORITHM
        ]
        
        for method in methods_to_test:
            logger.info(f"\nTesting {method.value}...")
            solution = await solver.solve(problem, self.agents[:5], method)
            logger.info(f"  Solution ID: {solution.id}")
            logger.info(f"  Score: {solution.score:.4f}")
            logger.info(f"  Agent: {solution.agent_id or 'Multiple'}")
            logger.info(f"  Metadata: {solution.metadata}")
        
        # Show performance stats
        stats = solver.get_performance_stats()
        logger.info("\nPerformance Statistics:")
        for method, data in stats.items():
            logger.info(f"  {method}:")
            logger.info(f"    Average score: {data['avg_score']:.4f}")
            logger.info(f"    Best score: {data['best_score']:.4f}")
            logger.info(f"    Times used: {data['uses']}")
    
    async def demo_collaboration_patterns(self) -> None:
        """Demonstrate different collaboration patterns"""
        logger.info("\n" + "="*60)
        logger.info("DEMO 5: Collaboration Patterns")
        logger.info("="*60)
        
        coordinator = next((a for a in self.agents if isinstance(a, CoordinatorAgent)), None)
        if not coordinator:
            logger.warning("No coordinator found")
            return
        
        # Create tasks with dependencies
        tasks = [
            Task(
                title="Design system architecture",
                description="Create architectural design",
                priority=TaskPriority.HIGH,
                agent_type=AgentType.DESIGN
            ),
            Task(
                title="Implement backend services",
                description="Build backend APIs",
                priority=TaskPriority.HIGH,
                agent_type=AgentType.PROGRAMMING,
                dependencies=[]  # Will be set below
            ),
            Task(
                title="Implement frontend",
                description="Build user interface",
                priority=TaskPriority.MEDIUM,
                agent_type=AgentType.PROGRAMMING,
                dependencies=[]
            ),
            Task(
                title="Write tests",
                description="Create test suite",
                priority=TaskPriority.HIGH,
                agent_type=AgentType.TESTING,
                dependencies=[]
            )
        ]
        
        # Set dependencies
        tasks[1].dependencies = [tasks[0].id]  # Backend depends on design
        tasks[2].dependencies = [tasks[0].id]  # Frontend depends on design
        tasks[3].dependencies = [tasks[1].id, tasks[2].id]  # Tests depend on implementation
        
        logger.info(f"Coordinating {len(tasks)} tasks with dependencies...")
        
        agent_dict = {agent.id: agent for agent in self.agents}
        result = await coordinator.coordinate_parallel_execution(tasks, agent_dict)
        
        logger.info(f"\nCoordination completed:")
        logger.info(f"  Duration: {result['duration']:.2f}s")
        logger.info(f"  Tasks completed: {result['tasks_completed']}")
        logger.info(f"  Tasks failed: {result['tasks_failed']}")
        logger.info(f"  Synchronization points: {result['sync_points']}")
    
    async def demo_adaptive_strategies(self) -> None:
        """Demonstrate adaptive strategy selection"""
        logger.info("\n" + "="*60)
        logger.info("DEMO 6: Adaptive Strategy Selection")
        logger.info("="*60)
        
        # Create adaptive crew
        adaptive_crew = AutonomousCrew(
            name="Adaptive Crew",
            strategy=CrewStrategy.ADAPTIVE,
            learning_enabled=True
        )
        
        adaptive_crew.add_agents(self.agents[:5])
        
        # Run multiple tasks to show adaptation
        tasks = [
            Task(
                title=f"Task {i+1}",
                description=f"Various complexity task {i+1}",
                priority=TaskPriority.MEDIUM
            )
            for i in range(3)
        ]
        
        logger.info("Testing adaptive strategy with multiple tasks...")
        
        for i, task in enumerate(tasks):
            logger.info(f"\nTask {i+1}: {task.title}")
            result = await adaptive_crew.execute_autonomously(
                task,
                max_runtime=timedelta(seconds=15)
            )
            logger.info(f"  Success rate: {result['tasks']['success_rate']:.2%}")
            logger.info(f"  Strategy used: {result['strategy']}")
        
        # Show learning results
        logger.info("\nStrategy Performance:")
        for strategy, score in adaptive_crew.strategy_scores.items():
            logger.info(f"  {strategy}: {score:.2f}")
    
    async def run_all_demos(self) -> None:
        """Run all demonstrations"""
        logger.info("="*60)
        logger.info("MULTI-AGENT SYSTEM COMPREHENSIVE DEMONSTRATION")
        logger.info("="*60)
        
        # Create agent team
        self.create_agent_team(10)
        
        # Run all demos
        await self.demo_swarm_intelligence()
        await self.demo_hierarchical_organization()
        await self.demo_autonomous_crew()
        await self.demo_problem_solving_methods()
        await self.demo_collaboration_patterns()
        await self.demo_adaptive_strategies()
        
        logger.info("\n" + "="*60)
        logger.info("ALL DEMONSTRATIONS COMPLETED")
        logger.info("="*60)
        
        # Show final statistics
        status = self.orchestrator.get_status()
        logger.info("\nFinal System Status:")
        logger.info(f"  Total agents: {status['agents']['total']}")
        logger.info(f"  Available agents: {status['agents']['available']}")
        logger.info(f"  Tasks completed: {status['metrics']['tasks_completed']}")
        logger.info(f"  Tasks failed: {status['metrics']['tasks_failed']}")


async def main():
    """Main demonstration entry point"""
    demo = MultiAgentDemo()
    await demo.run_all_demos()


if __name__ == "__main__":
    asyncio.run(main())
