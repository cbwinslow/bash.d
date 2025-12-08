#!/usr/bin/env python3
"""
Example: Democratic Voting System

Demonstrates various voting strategies and consensus building in multi-agent crews.
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from crewai_config import (
    DemocraticVotingSystem,
    ConsensusBuilder,
    VotingSession,
    VotingStrategy,
    CrewMember,
    CrewRole
)

import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def create_sample_members():
    """Create sample crew members"""
    return [
        CrewMember(
            agent_id="agent_1",
            agent_name="Senior Developer",
            role=CrewRole.SPECIALIST,
            expertise_weight=3.0,
            can_vote=True,
            capabilities=["architecture", "coding"]
        ),
        CrewMember(
            agent_id="agent_2",
            agent_name="Security Expert",
            role=CrewRole.SPECIALIST,
            expertise_weight=2.8,
            can_vote=True,
            capabilities=["security", "review"]
        ),
        CrewMember(
            agent_id="agent_3",
            agent_name="Junior Developer",
            role=CrewRole.SPECIALIST,
            expertise_weight=1.5,
            can_vote=True,
            capabilities=["coding", "testing"]
        ),
        CrewMember(
            agent_id="agent_4",
            agent_name="DevOps Engineer",
            role=CrewRole.SPECIALIST,
            expertise_weight=2.2,
            can_vote=True,
            capabilities=["deployment", "infrastructure"]
        ),
        CrewMember(
            agent_id="agent_5",
            agent_name="Tech Lead",
            role=CrewRole.MANAGER,
            expertise_weight=2.5,
            can_vote=True,
            capabilities=["coordination", "decision"]
        )
    ]


def demo_simple_majority():
    """Demonstrate simple majority voting"""
    logger.info("\n" + "="*60)
    logger.info("DEMO: Simple Majority Voting (>50%)")
    logger.info("="*60)
    
    members = create_sample_members()
    
    voting_session = VotingSession(
        proposal_id="use_microservices",
        proposal_description="Adopt microservices architecture",
        strategy=VotingStrategy.SIMPLE_MAJORITY
    )
    
    voting_system = DemocraticVotingSystem(voting_session, members)
    
    # Cast votes
    votes = [
        ("agent_1", True, "Better scalability"),
        ("agent_2", True, "Improved security isolation"),
        ("agent_3", False, "Too complex for our needs"),
        ("agent_4", True, "Easier deployment"),
        ("agent_5", False, "Higher operational overhead")
    ]
    
    for agent_id, vote, reasoning in votes:
        member = next(m for m in members if m.agent_id == agent_id)
        logger.info(f"{member.agent_name} votes {vote}: {reasoning}")
        voting_system.cast_vote(agent_id, vote, reasoning)
    
    status = voting_system.get_status()
    logger.info(f"\nResult: {'PASSED' if status['passed'] else 'FAILED'}")
    logger.info(f"Details: {status['result']}")


def demo_weighted_voting():
    """Demonstrate weighted voting based on expertise"""
    logger.info("\n" + "="*60)
    logger.info("DEMO: Weighted Voting (by expertise)")
    logger.info("="*60)
    
    members = create_sample_members()
    
    voting_session = VotingSession(
        proposal_id="security_approach",
        proposal_description="Implement zero-trust security model",
        strategy=VotingStrategy.WEIGHTED_VOTE,
        threshold=0.6
    )
    
    voting_system = DemocraticVotingSystem(voting_session, members)
    
    # Show member weights
    logger.info("\nMember expertise weights:")
    for member in members:
        logger.info(f"  {member.agent_name}: {member.expertise_weight}")
    
    # Cast votes
    votes = [
        ("agent_1", True, "Industry best practice"),
        ("agent_2", True, "Critical for security"),  # Security expert - higher weight
        ("agent_3", False, "Learning curve too steep"),
        ("agent_4", True, "Necessary for compliance"),
        ("agent_5", False, "Implementation timeline concerns")
    ]
    
    logger.info("\nVotes:")
    for agent_id, vote, reasoning in votes:
        member = next(m for m in members if m.agent_id == agent_id)
        logger.info(f"{member.agent_name} (weight: {member.expertise_weight}) votes {vote}: {reasoning}")
        voting_system.cast_vote(agent_id, vote, reasoning)
    
    status = voting_system.get_status()
    logger.info(f"\nResult: {'PASSED' if status['passed'] else 'FAILED'}")
    logger.info(f"Weighted result: {status['result']}")


def demo_supermajority():
    """Demonstrate supermajority voting"""
    logger.info("\n" + "="*60)
    logger.info("DEMO: Supermajority Voting (>=66%)")
    logger.info("="*60)
    
    members = create_sample_members()
    
    voting_session = VotingSession(
        proposal_id="major_refactor",
        proposal_description="Major codebase refactoring",
        strategy=VotingStrategy.SUPERMAJORITY
    )
    
    voting_system = DemocraticVotingSystem(voting_session, members)
    
    # Cast votes - need 66% or more
    votes = [
        ("agent_1", True, "Technical debt is too high"),
        ("agent_2", True, "Will improve maintainability"),
        ("agent_3", True, "Good learning opportunity"),
        ("agent_4", False, "Too risky before release"),
        ("agent_5", True, "Long-term benefit")
    ]
    
    for agent_id, vote, reasoning in votes:
        member = next(m for m in members if m.agent_id == agent_id)
        logger.info(f"{member.agent_name} votes {vote}: {reasoning}")
        voting_system.cast_vote(agent_id, vote, reasoning)
    
    status = voting_system.get_status()
    logger.info(f"\nResult: {'PASSED' if status['passed'] else 'FAILED'}")
    logger.info(f"Percentage: {status['result']['yes_percentage']:.1%} (need 66%)")


def demo_consensus_builder():
    """Demonstrate consensus building with proposals"""
    logger.info("\n" + "="*60)
    logger.info("DEMO: Consensus Building")
    logger.info("="*60)
    
    members = create_sample_members()
    
    consensus_builder = ConsensusBuilder(
        crew_id="demo_crew",
        members=members
    )
    
    # Create a proposal
    proposal = consensus_builder.create_proposal(
        proposer_id="agent_2",
        title="Implement API Rate Limiting",
        description="Add rate limiting to all API endpoints to prevent abuse",
        proposal_type="security_enhancement",
        options=["redis_based", "nginx_based", "application_level"]
    )
    
    logger.info(f"Proposal created: {proposal.title}")
    logger.info(f"Proposer: {proposal.proposer_name}")
    logger.info(f"Options: {proposal.options}")
    
    # Start voting
    voting_session = consensus_builder.start_voting(
        proposal_id=proposal.id,
        strategy=VotingStrategy.APPROVAL,  # Can approve multiple options
        threshold=0.5
    )
    
    voting_system = DemocraticVotingSystem(voting_session, members)
    
    # Cast approval votes (can approve multiple)
    approvals = [
        ("agent_1", ["redis_based", "application_level"], "Both are viable"),
        ("agent_2", ["redis_based"], "Best performance"),
        ("agent_3", ["application_level"], "Simpler implementation"),
        ("agent_4", ["nginx_based", "redis_based"], "Either works"),
        ("agent_5", ["redis_based"], "Most flexible")
    ]
    
    logger.info("\nApproval votes:")
    for agent_id, approved_options, reasoning in approvals:
        member = next(m for m in members if m.agent_id == agent_id)
        logger.info(f"{member.agent_name} approves {approved_options}: {reasoning}")
        voting_system.cast_vote(agent_id, approved_options, reasoning)
    
    # Get consensus score
    consensus_score = consensus_builder.calculate_consensus_score(proposal.id)
    logger.info(f"\nConsensus score: {consensus_score:.1%}")
    
    status = consensus_builder.get_proposal_status(proposal.id)
    logger.info(f"Status: {status['status']}")
    logger.info(f"Winner: {status['voting_session']['result']['winner']}")
    logger.info(f"All approvals: {status['voting_session']['result']['all_approvals']}")


def main():
    """Run all voting demonstrations"""
    logger.info("Multi-Agent Democratic Voting Examples")
    
    demo_simple_majority()
    demo_weighted_voting()
    demo_supermajority()
    demo_consensus_builder()
    
    logger.info("\n" + "="*60)
    logger.info("All demonstrations complete!")
    logger.info("="*60)


if __name__ == "__main__":
    main()
