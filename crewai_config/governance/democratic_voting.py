"""
Democratic Voting System for Multi-Agent Crews

Implements various voting strategies and consensus mechanisms for democratic
decision-making in agent swarms.
"""

import logging
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime
from collections import Counter

from ..schemas.crew_models import (
    VotingSession,
    VoteRecord,
    VotingStrategy,
    DemocraticProposal,
    CrewMember
)

logger = logging.getLogger(__name__)


class DemocraticVotingSystem:
    """
    Democratic voting system for agent crews
    
    Supports multiple voting strategies:
    - Simple Majority (>50%)
    - Supermajority (>=66%)
    - Unanimous (100%)
    - Weighted Voting (based on expertise)
    - Ranked Choice
    - Approval Voting
    """
    
    def __init__(self, voting_session: VotingSession, members: List[CrewMember]):
        """
        Initialize voting system
        
        Args:
            voting_session: The voting session configuration
            members: Crew members eligible to vote
        """
        self.session = voting_session
        self.members = {m.agent_id: m for m in members if m.can_vote}
        self.required_votes = voting_session.required_votes or len(self.members)
    
    def cast_vote(
        self,
        agent_id: str,
        vote: Any,
        reasoning: Optional[str] = None
    ) -> bool:
        """
        Cast a vote in the session
        
        Args:
            agent_id: ID of voting agent
            vote: The vote value
            reasoning: Optional reasoning for the vote
            
        Returns:
            True if vote was recorded successfully
        """
        if agent_id not in self.members:
            logger.warning(f"Agent {agent_id} not eligible to vote")
            return False
        
        # Check if already voted
        if any(v.voter_id == agent_id for v in self.session.votes):
            logger.warning(f"Agent {agent_id} already voted")
            return False
        
        member = self.members[agent_id]
        
        vote_record = VoteRecord(
            voter_id=agent_id,
            voter_name=member.agent_name,
            vote=vote,
            weight=member.expertise_weight,
            reasoning=reasoning
        )
        
        self.session.votes.append(vote_record)
        logger.info(f"Vote recorded: {member.agent_name} -> {vote}")
        
        # Check if voting is complete
        if len(self.session.votes) >= self.required_votes:
            self._finalize_voting()
        
        return True
    
    def _finalize_voting(self) -> None:
        """Finalize voting and determine result"""
        self.session.completed_at = datetime.utcnow()
        
        if self.session.strategy == VotingStrategy.SIMPLE_MAJORITY:
            self.session.passed, self.session.result = self._simple_majority()
        
        elif self.session.strategy == VotingStrategy.SUPERMAJORITY:
            self.session.passed, self.session.result = self._supermajority()
        
        elif self.session.strategy == VotingStrategy.UNANIMOUS:
            self.session.passed, self.session.result = self._unanimous()
        
        elif self.session.strategy == VotingStrategy.WEIGHTED_VOTE:
            self.session.passed, self.session.result = self._weighted_vote()
        
        elif self.session.strategy == VotingStrategy.RANKED_CHOICE:
            self.session.passed, self.session.result = self._ranked_choice()
        
        elif self.session.strategy == VotingStrategy.APPROVAL:
            self.session.passed, self.session.result = self._approval_voting()
        
        else:
            logger.error(f"Unknown voting strategy: {self.session.strategy}")
            self.session.passed = False
            self.session.result = {"error": "Unknown strategy"}
        
        logger.info(
            f"Voting completed: {self.session.proposal_description} - "
            f"{'PASSED' if self.session.passed else 'FAILED'}"
        )
    
    def _simple_majority(self) -> Tuple[bool, Dict[str, Any]]:
        """Simple majority voting (>50%)"""
        votes = [v.vote for v in self.session.votes]
        total = len(votes)
        
        if not votes:
            return False, {"reason": "No votes cast"}
        
        # Count boolean votes
        yes_votes = sum(1 for v in votes if v is True or v == "yes")
        no_votes = sum(1 for v in votes if v is False or v == "no")
        
        yes_percentage = yes_votes / total
        
        passed = yes_percentage > 0.5
        
        return passed, {
            "yes_votes": yes_votes,
            "no_votes": no_votes,
            "total_votes": total,
            "yes_percentage": yes_percentage,
            "threshold": 0.5
        }
    
    def _supermajority(self) -> Tuple[bool, Dict[str, Any]]:
        """Supermajority voting (>=66%)"""
        votes = [v.vote for v in self.session.votes]
        total = len(votes)
        
        if not votes:
            return False, {"reason": "No votes cast"}
        
        yes_votes = sum(1 for v in votes if v is True or v == "yes")
        yes_percentage = yes_votes / total
        
        passed = yes_percentage >= 0.66
        
        return passed, {
            "yes_votes": yes_votes,
            "total_votes": total,
            "yes_percentage": yes_percentage,
            "threshold": 0.66
        }
    
    def _unanimous(self) -> Tuple[bool, Dict[str, Any]]:
        """Unanimous voting (100% agreement)"""
        votes = [v.vote for v in self.session.votes]
        total = len(votes)
        
        if not votes:
            return False, {"reason": "No votes cast"}
        
        yes_votes = sum(1 for v in votes if v is True or v == "yes")
        
        passed = yes_votes == total
        
        return passed, {
            "yes_votes": yes_votes,
            "total_votes": total,
            "unanimous": passed
        }
    
    def _weighted_vote(self) -> Tuple[bool, Dict[str, Any]]:
        """Weighted voting based on expertise"""
        if not self.session.votes:
            return False, {"reason": "No votes cast"}
        
        total_weight = sum(v.weight for v in self.session.votes)
        yes_weight = sum(
            v.weight for v in self.session.votes
            if v.vote is True or v.vote == "yes"
        )
        
        yes_percentage = yes_weight / total_weight if total_weight > 0 else 0
        
        passed = yes_percentage > self.session.threshold
        
        return passed, {
            "yes_weight": yes_weight,
            "total_weight": total_weight,
            "yes_percentage": yes_percentage,
            "threshold": self.session.threshold,
            "vote_count": len(self.session.votes)
        }
    
    def _ranked_choice(self) -> Tuple[bool, Dict[str, Any]]:
        """Ranked choice voting"""
        if not self.session.votes:
            return False, {"reason": "No votes cast"}
        
        # Assume votes are lists of ranked choices
        # Implement instant runoff voting
        votes = [v.vote for v in self.session.votes if isinstance(v.vote, list)]
        
        if not votes:
            # Fallback to simple majority if not ranked
            return self._simple_majority()
        
        # Count first preferences
        first_preferences = Counter(v[0] for v in votes if v)
        total = len(votes)
        
        # Check if any option has majority
        for option, count in first_preferences.items():
            if count / total > 0.5:
                return True, {
                    "winner": option,
                    "first_preference_count": count,
                    "total_votes": total,
                    "percentage": count / total
                }
        
        # If no majority, would need to implement full IRV
        # For simplicity, return most popular
        winner = first_preferences.most_common(1)[0]
        
        return True, {
            "winner": winner[0],
            "first_preference_count": winner[1],
            "total_votes": total,
            "method": "plurality"
        }
    
    def _approval_voting(self) -> Tuple[bool, Dict[str, Any]]:
        """Approval voting - agents can approve multiple options"""
        if not self.session.votes:
            return False, {"reason": "No votes cast"}
        
        # Votes should be lists of approved options
        approvals = Counter()
        total_voters = len(self.session.votes)
        
        for vote_record in self.session.votes:
            vote = vote_record.vote
            if isinstance(vote, list):
                for option in vote:
                    approvals[option] += 1
            else:
                approvals[vote] += 1
        
        if not approvals:
            return False, {"reason": "No approvals"}
        
        # Winner is option with most approvals
        winner, approval_count = approvals.most_common(1)[0]
        approval_percentage = approval_count / total_voters
        
        passed = approval_percentage >= self.session.threshold
        
        return passed, {
            "winner": winner,
            "approval_count": approval_count,
            "total_voters": total_voters,
            "approval_percentage": approval_percentage,
            "threshold": self.session.threshold,
            "all_approvals": dict(approvals)
        }
    
    def get_status(self) -> Dict[str, Any]:
        """Get current voting status"""
        return {
            "proposal_id": self.session.proposal_id,
            "strategy": self.session.strategy.value,
            "votes_cast": len(self.session.votes),
            "required_votes": self.required_votes,
            "completed": self.session.completed_at is not None,
            "passed": self.session.passed,
            "result": self.session.result
        }


class ConsensusBuilder:
    """
    Consensus building system for multi-agent collaboration
    
    Helps agents reach consensus through iterative refinement and discussion.
    """
    
    def __init__(self, crew_id: str, members: List[CrewMember]):
        self.crew_id = crew_id
        self.members = members
        self.proposals: List[DemocraticProposal] = []
        self.consensus_history: List[Dict[str, Any]] = []
    
    def create_proposal(
        self,
        proposer_id: str,
        title: str,
        description: str,
        proposal_type: str,
        options: Optional[List[str]] = None
    ) -> DemocraticProposal:
        """Create a new proposal for consensus"""
        member = next((m for m in self.members if m.agent_id == proposer_id), None)
        
        if not member:
            raise ValueError(f"Agent {proposer_id} not found in crew")
        
        proposal = DemocraticProposal(
            crew_id=self.crew_id,
            proposer_id=proposer_id,
            proposer_name=member.agent_name,
            title=title,
            description=description,
            proposal_type=proposal_type,
            options=options or []
        )
        
        self.proposals.append(proposal)
        logger.info(f"Proposal created: {title} by {member.agent_name}")
        
        return proposal
    
    def start_voting(
        self,
        proposal_id: str,
        strategy: VotingStrategy,
        threshold: float = 0.5
    ) -> VotingSession:
        """Start voting on a proposal"""
        proposal = next((p for p in self.proposals if p.id == proposal_id), None)
        
        if not proposal:
            raise ValueError(f"Proposal {proposal_id} not found")
        
        voting_session = VotingSession(
            proposal_id=proposal_id,
            proposal_description=proposal.description,
            strategy=strategy,
            threshold=threshold,
            required_votes=len([m for m in self.members if m.can_vote])
        )
        
        proposal.voting_session = voting_session
        proposal.status = "voting"
        
        logger.info(f"Voting started on: {proposal.title}")
        
        return voting_session
    
    def calculate_consensus_score(self, proposal_id: str) -> float:
        """
        Calculate consensus score (0.0 to 1.0)
        
        Based on vote alignment and reasoning similarity
        """
        proposal = next((p for p in self.proposals if p.id == proposal_id), None)
        
        if not proposal or not proposal.voting_session:
            return 0.0
        
        votes = proposal.voting_session.votes
        
        if not votes:
            return 0.0
        
        # Simple consensus: percentage of agreement
        yes_votes = sum(1 for v in votes if v.vote in [True, "yes"])
        consensus_score = yes_votes / len(votes)
        
        return consensus_score
    
    def get_proposal_status(self, proposal_id: str) -> Dict[str, Any]:
        """Get status of a proposal"""
        proposal = next((p for p in self.proposals if p.id == proposal_id), None)
        
        if not proposal:
            return {"error": "Proposal not found"}
        
        return {
            "id": proposal.id,
            "title": proposal.title,
            "proposer": proposal.proposer_name,
            "status": proposal.status,
            "type": proposal.proposal_type,
            "created_at": proposal.created_at.isoformat(),
            "voting_session": (
                self._get_voting_summary(proposal.voting_session)
                if proposal.voting_session else None
            ),
            "consensus_score": self.calculate_consensus_score(proposal.id)
        }
    
    def _get_voting_summary(self, session: VotingSession) -> Dict[str, Any]:
        """Get summary of voting session"""
        return {
            "strategy": session.strategy.value,
            "votes_cast": len(session.votes),
            "required_votes": session.required_votes,
            "completed": session.completed_at is not None,
            "passed": session.passed,
            "result": session.result
        }
