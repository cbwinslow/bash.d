#!/usr/bin/env python3
"""
Comprehensive Demo of AI Swarms, Crews, and Democratic Voting

Full demonstration of all features including:
- All voting mechanisms
- Swarm coordination
- Crew workflows  
- Complex problem solving
- Consensus building
"""

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from agents.base import BaseAgent, AgentType, TaskPriority
from agents.swarm import AgentSwarm, SwarmConfiguration, SwarmBehavior, SwarmTask
from agents.crew import AgentCrew, CrewConfiguration, CrewProcess, CrewRole, CrewTask
from agents.voting import DemocraticVoter, VotingStrategy, Vote, RankedVote, ApprovalVote
from agents.problem_solver import ComplexProblemSolver, Problem, ProblemType


def create_agents():
    """Create a diverse set of agents"""
    return [
        BaseAgent(name="Python Expert", type=AgentType.PROGRAMMING, 
                 description="Python specialist", capabilities=["python", "fastapi"]),
        BaseAgent(name="JS Developer", type=AgentType.PROGRAMMING,
                 description="JavaScript expert", capabilities=["js", "react"]),
        BaseAgent(name="DevOps Pro", type=AgentType.DEVOPS,
                 description="Infrastructure expert", capabilities=["docker", "k8s"]),
        BaseAgent(name="QA Engineer", type=AgentType.TESTING,
                 description="Testing specialist", capabilities=["pytest", "selenium"]),
        BaseAgent(name="Tech Writer", type=AgentType.DOCUMENTATION,
                 description="Documentation expert", capabilities=["markdown", "api-docs"]),
    ]


async def main():
    """Run comprehensive demonstration"""
    print("\n" + "="*80)
    print("COMPREHENSIVE AI SWARMS DEMONSTRATION")
    print("="*80)
    
    agents = create_agents()
    
    # Demo 1: Voting mechanisms
    print("\n1. VOTING MECHANISMS")
    print("-"*80)
    voter = DemocraticVoter(strategy=VotingStrategy.MAJORITY)
    votes = [Vote(voter_id=f"agent{i}", choice="solution_a" if i < 3 else "solution_b", 
                  confidence=0.8+i*0.02) for i in range(5)]
    result = voter.conduct_vote(votes)
    print(f"✓ Winner: {result.winner} ({result.winning_percentage:.0%} consensus)")
    
    # Demo 2: Agent Swarm
    print("\n2. AGENT SWARM WITH DEMOCRATIC VOTING")
    print("-"*80)
    config = SwarmConfiguration(name="Dev Swarm", behavior=SwarmBehavior.DEMOCRATIC,
                                voting_strategy=VotingStrategy.MAJORITY, min_agents=3)
    swarm = AgentSwarm(config)
    for agent in agents[:3]:
        swarm.add_agent(agent)
    task = SwarmTask(title="API Design", description="Design REST API")
    result = await swarm.execute_task(task)
    print(f"✓ Swarm completed: {result['success']} (consensus: {result.get('consensus', False)})")
    
    # Demo 3: Agent Crew
    print("\n3. ORGANIZED CREW WITH ROLES")
    print("-"*80)
    crew_config = CrewConfiguration(name="Dev Crew", process=CrewProcess.SEQUENTIAL)
    crew = AgentCrew(crew_config)
    crew.add_member(agents[0], CrewRole.LEADER)
    crew.add_member(agents[1], CrewRole.SPECIALIST)
    crew.add_member(agents[3], CrewRole.REVIEWER)
    tasks = [CrewTask(title=f"Task {i}", description=f"Work item {i}") for i in range(2)]
    result = await crew.execute_workflow(tasks)
    print(f"✓ Crew completed: {result['success']} ({result.get('tasks_completed', 0)} tasks)")
    
    # Demo 4: Complex Problem Solver
    print("\n4. COMPLEX PROBLEM SOLVING")
    print("-"*80)
    solver = ComplexProblemSolver()
    solver.register_agents(agents)
    problem = Problem(
        title="Build Microservices Platform",
        description="Create scalable microservices with monitoring",
        problem_type=ProblemType.DEVELOPMENT,
        required_agent_types=[AgentType.PROGRAMMING, AgentType.DEVOPS, AgentType.TESTING]
    )
    solution = await solver.solve(problem, voting_strategy=VotingStrategy.MAJORITY)
    print(f"✓ Problem solved: {solution.approach_used}")
    print(f"  Confidence: {solution.confidence:.0%}")
    print(f"  Consensus: {solution.consensus_achieved}")
    print(f"  Agents used: {len(solution.agents_used)}")
    print(f"  Swarms: {len(solution.swarms_used)}, Crews: {len(solution.crews_used)}")
    
    # Statistics
    stats = solver.get_statistics()
    print(f"\n5. STATISTICS")
    print("-"*80)
    print(f"✓ Problems solved: {stats['problems_solved']}")
    print(f"✓ Average confidence: {stats['avg_confidence']:.0%}")
    print(f"✓ Consensus rate: {stats['consensus_rate']:.0%}")
    
    print("\n" + "="*80)
    print("✓ ALL DEMOS COMPLETED SUCCESSFULLY")
    print("="*80)
    print("\nKey Features Demonstrated:")
    print("  • Democratic voting with multiple strategies")
    print("  • Self-organizing agent swarms")
    print("  • Structured crews with defined roles")
    print("  • Automatic problem decomposition")
    print("  • Consensus building mechanisms")
    print("  • OpenAI-compatible architecture")
    
    return 0


if __name__ == "__main__":
    exit(asyncio.run(main()))
