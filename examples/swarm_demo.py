#!/usr/bin/env python3
"""
Demo of AI Agent Swarms with Democratic Voting

This script demonstrates how to use the swarm, crew, and problem solver
systems to solve complex problems using democratic voting mechanisms.

Run with: python examples/swarm_demo.py
"""

import asyncio
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from agents.base import BaseAgent, AgentType
from agents.swarm import AgentSwarm, SwarmConfiguration, SwarmBehavior, SwarmTask
from agents.crew import AgentCrew, CrewConfiguration, CrewProcess, CrewRole, CrewTask
from agents.voting import DemocraticVoter, VotingStrategy, Vote, RankedVote, ApprovalVote
from agents.problem_solver import (
    ComplexProblemSolver,
    Problem,
    ProblemType,
    TaskPriority
)


def create_demo_agents():
    """Create demo agents for testing"""
    agents = []
    
    # Programming agents
    agents.append(BaseAgent(
        name="Python Developer",
        type=AgentType.PROGRAMMING,
        description="Expert Python backend developer",
        capabilities=["python", "fastapi", "django", "async"]
    ))
    
    agents.append(BaseAgent(
        name="JavaScript Developer",
        type=AgentType.PROGRAMMING,
        description="Full-stack JavaScript developer",
        capabilities=["javascript", "react", "node", "typescript"]
    ))
    
    # DevOps agent
    agents.append(BaseAgent(
        name="DevOps Engineer",
        type=AgentType.DEVOPS,
        description="Infrastructure and deployment specialist",
        capabilities=["docker", "kubernetes", "terraform", "ci/cd"]
    ))
    
    # Testing agent
    agents.append(BaseAgent(
        name="QA Engineer",
        type=AgentType.TESTING,
        description="Quality assurance and testing expert",
        capabilities=["pytest", "jest", "e2e", "performance"]
    ))
    
    # Documentation agent
    agents.append(BaseAgent(
        name="Technical Writer",
        type=AgentType.DOCUMENTATION,
        description="Technical documentation specialist",
        capabilities=["api-docs", "tutorials", "architecture"]
    ))
    
    return agents


async def demo_voting_mechanisms():
    """Demonstrate different voting mechanisms"""
    print("\n" + "="*80)
    print("DEMO 1: Voting Mechanisms")
    print("="*80)
    
    # Create votes
    votes = [
        Vote(voter_id="agent1", choice="option_a", confidence=0.9, reasoning="Best performance"),
        Vote(voter_id="agent2", choice="option_a", confidence=0.85, reasoning="Most scalable"),
        Vote(voter_id="agent3", choice="option_b", confidence=0.7, reasoning="Easier to maintain"),
        Vote(voter_id="agent4", choice="option_a", confidence=0.95, reasoning="Proven solution"),
        Vote(voter_id="agent5", choice="option_c", confidence=0.6, reasoning="Most innovative"),
    ]
    
    # 1. Majority Voting
    print("\n1. Majority Voting")
    print("-" * 40)
    voter = DemocraticVoter(strategy=VotingStrategy.MAJORITY)
    result = voter.conduct_vote(votes)
    print(f"Winner: {result.winner}")
    print(f"Percentage: {result.winning_percentage:.1%}")
    print(f"Confidence: {result.confidence_score:.2f}")
    print(f"Consensus: {result.is_consensus}")
    print(f"Vote distribution: {result.vote_counts}")


async def main():
    """Run all demos"""
    print("\n" + "="*80)
    print("AI AGENT SWARMS WITH DEMOCRATIC VOTING - DEMONSTRATION")
    print("="*80)
    print("\nThis demo showcases democratic voting and agent collaboration")
    
    try:
        await demo_voting_mechanisms()
        
        print("\n" + "="*80)
        print("DEMO COMPLETED SUCCESSFULLY")
        print("="*80)
        
    except Exception as e:
        print(f"\n❌ Error during demo: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == "__main__":
    exit(asyncio.run(main()))
