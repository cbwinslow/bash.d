"""
Democratic Voting Mechanisms for Multi-Agent Systems

This module implements various voting and consensus mechanisms for agent swarms
to make democratic decisions when solving complex problems.

Based on research from:
- Voting or Consensus? Decision-Making in Multi-Agent Debate (arXiv:2502.19130)
- VotingAI: AI agents orchestration with democratic voting
- Swarms API: Multi-agent majority voting systems
"""

from enum import Enum
from typing import List, Dict, Any, Optional, Tuple
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pydantic import BaseModel, Field
import uuid


class VotingStrategy(str, Enum):
    """Available voting strategies for agent decision-making"""
    MAJORITY = "majority"  # Simple majority wins
    PLURALITY = "plurality"  # Most votes wins (can be < 50%)
    UNANIMITY = "unanimity"  # All agents must agree
    WEIGHTED = "weighted"  # Agents have different vote weights
    RANKED_CHOICE = "ranked_choice"  # Ranked choice/instant runoff
    APPROVAL = "approval"  # Agents can approve multiple options
    CONSENSUS = "consensus"  # Iterative consensus building
    THRESHOLD = "threshold"  # Requires specific percentage


class Vote(BaseModel):
    """Individual vote from an agent"""
    voter_id: str = Field(..., description="ID of the voting agent")
    choice: Any = Field(..., description="The vote choice")
    weight: float = Field(default=1.0, description="Weight of this vote")
    confidence: float = Field(default=1.0, ge=0.0, le=1.0, description="Confidence level (0-1)")
    reasoning: Optional[str] = Field(None, description="Reasoning behind the vote")
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class RankedVote(BaseModel):
    """Ranked choice vote from an agent"""
    voter_id: str = Field(..., description="ID of the voting agent")
    rankings: List[Any] = Field(..., description="Ordered list of preferences")
    weight: float = Field(default=1.0, description="Weight of this vote")
    reasoning: Optional[str] = Field(None, description="Reasoning behind rankings")
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class ApprovalVote(BaseModel):
    """Approval vote where agent can approve multiple options"""
    voter_id: str = Field(..., description="ID of the voting agent")
    approved_choices: List[Any] = Field(..., description="All approved choices")
    weight: float = Field(default=1.0, description="Weight of this vote")
    reasoning: Optional[str] = Field(None, description="Reasoning behind approvals")
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class VoteResult(BaseModel):
    """Result of a voting session"""
    session_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    strategy: VotingStrategy
    winner: Optional[Any] = Field(None, description="Winning choice")
    vote_counts: Dict[str, int] = Field(default_factory=dict, description="Vote distribution")
    total_votes: int = Field(default=0, description="Total votes cast")
    winning_percentage: float = Field(default=0.0, description="Percentage of votes for winner")
    confidence_score: float = Field(default=0.0, description="Average confidence")
    is_unanimous: bool = Field(default=False, description="Whether vote was unanimous")
    is_consensus: bool = Field(default=False, description="Whether consensus was reached")
    metadata: Dict[str, Any] = Field(default_factory=dict)
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class DemocraticVoter:
    """
    Democratic voting system for AI agent swarms
    
    Implements multiple voting strategies for agent consensus and decision-making.
    Research shows majority voting can improve reasoning task performance by 13.2%.
    
    Example:
        ```python
        voter = DemocraticVoter(strategy=VotingStrategy.MAJORITY)
        
        votes = [
            Vote(voter_id="agent1", choice="option_a", confidence=0.9),
            Vote(voter_id="agent2", choice="option_a", confidence=0.8),
            Vote(voter_id="agent3", choice="option_b", confidence=0.7),
        ]
        
        result = voter.conduct_vote(votes)
        print(f"Winner: {result.winner}")
        ```
    """
    
    def __init__(
        self,
        strategy: VotingStrategy = VotingStrategy.MAJORITY,
        threshold: float = 0.5,
        min_votes: int = 1,
        require_quorum: bool = False,
        quorum_percentage: float = 0.5
    ):
        """
        Initialize democratic voter
        
        Args:
            strategy: Voting strategy to use
            threshold: Percentage threshold for threshold voting (0-1)
            min_votes: Minimum votes required
            require_quorum: Whether to require quorum
            quorum_percentage: Minimum participation rate (0-1)
        """
        self.strategy = strategy
        self.threshold = threshold
        self.min_votes = min_votes
        self.require_quorum = require_quorum
        self.quorum_percentage = quorum_percentage
    
    def conduct_vote(
        self,
        votes: List[Vote],
        total_agents: Optional[int] = None
    ) -> VoteResult:
        """
        Conduct a vote using the configured strategy
        
        Args:
            votes: List of votes from agents
            total_agents: Total number of agents (for quorum)
        
        Returns:
            VoteResult with winner and statistics
        """
        if not votes:
            return VoteResult(
                strategy=self.strategy,
                total_votes=0,
                metadata={"error": "No votes cast"}
            )
        
        # Check minimum votes
        if len(votes) < self.min_votes:
            return VoteResult(
                strategy=self.strategy,
                total_votes=len(votes),
                metadata={"error": f"Insufficient votes: {len(votes)} < {self.min_votes}"}
            )
        
        # Check quorum
        if self.require_quorum and total_agents:
            participation = len(votes) / total_agents
            if participation < self.quorum_percentage:
                return VoteResult(
                    strategy=self.strategy,
                    total_votes=len(votes),
                    metadata={
                        "error": f"Quorum not met: {participation:.1%} < {self.quorum_percentage:.1%}"
                    }
                )
        
        # Route to appropriate voting method
        if self.strategy == VotingStrategy.MAJORITY:
            return self._majority_vote(votes)
        elif self.strategy == VotingStrategy.PLURALITY:
            return self._plurality_vote(votes)
        elif self.strategy == VotingStrategy.UNANIMITY:
            return self._unanimity_vote(votes)
        elif self.strategy == VotingStrategy.WEIGHTED:
            return self._weighted_vote(votes)
        elif self.strategy == VotingStrategy.THRESHOLD:
            return self._threshold_vote(votes)
        else:
            return VoteResult(
                strategy=self.strategy,
                total_votes=len(votes),
                metadata={"error": f"Unsupported strategy: {self.strategy}"}
            )
    
    def _majority_vote(self, votes: List[Vote]) -> VoteResult:
        """Simple majority voting - winner needs > 50% of votes"""
        vote_counts = Counter(str(v.choice) for v in votes)
        total = len(votes)
        
        if not vote_counts:
            return VoteResult(strategy=self.strategy, total_votes=0)
        
        winner, count = vote_counts.most_common(1)[0]
        percentage = count / total
        
        # Calculate average confidence
        winner_votes = [v for v in votes if str(v.choice) == winner]
        avg_confidence = sum(v.confidence for v in winner_votes) / len(winner_votes)
        
        return VoteResult(
            strategy=self.strategy,
            winner=winner if percentage > 0.5 else None,
            vote_counts=dict(vote_counts),
            total_votes=total,
            winning_percentage=percentage,
            confidence_score=avg_confidence,
            is_unanimous=(len(vote_counts) == 1),
            is_consensus=(percentage > 0.5),
            metadata={"requires_majority": True}
        )
    
    def _plurality_vote(self, votes: List[Vote]) -> VoteResult:
        """Plurality voting - most votes wins (even if < 50%)"""
        vote_counts = Counter(str(v.choice) for v in votes)
        total = len(votes)
        
        if not vote_counts:
            return VoteResult(strategy=self.strategy, total_votes=0)
        
        winner, count = vote_counts.most_common(1)[0]
        percentage = count / total
        
        # Calculate average confidence
        winner_votes = [v for v in votes if str(v.choice) == winner]
        avg_confidence = sum(v.confidence for v in winner_votes) / len(winner_votes)
        
        return VoteResult(
            strategy=self.strategy,
            winner=winner,
            vote_counts=dict(vote_counts),
            total_votes=total,
            winning_percentage=percentage,
            confidence_score=avg_confidence,
            is_unanimous=(len(vote_counts) == 1),
            is_consensus=(percentage > 0.5),
            metadata={"most_votes": count}
        )
    
    def _unanimity_vote(self, votes: List[Vote]) -> VoteResult:
        """Unanimity voting - all agents must agree"""
        vote_counts = Counter(str(v.choice) for v in votes)
        total = len(votes)
        
        if not vote_counts:
            return VoteResult(strategy=self.strategy, total_votes=0)
        
        # Unanimity requires exactly one unique choice
        is_unanimous = len(vote_counts) == 1
        winner = list(vote_counts.keys())[0] if is_unanimous else None
        
        if winner:
            avg_confidence = sum(v.confidence for v in votes) / len(votes)
        else:
            avg_confidence = 0.0
        
        return VoteResult(
            strategy=self.strategy,
            winner=winner,
            vote_counts=dict(vote_counts),
            total_votes=total,
            winning_percentage=1.0 if is_unanimous else 0.0,
            confidence_score=avg_confidence,
            is_unanimous=is_unanimous,
            is_consensus=is_unanimous,
            metadata={"unique_choices": len(vote_counts)}
        )
    
    def _weighted_vote(self, votes: List[Vote]) -> VoteResult:
        """Weighted voting - agents have different vote weights"""
        weighted_counts: Dict[str, float] = defaultdict(float)
        total_weight = sum(v.weight for v in votes)
        
        for vote in votes:
            weighted_counts[str(vote.choice)] += vote.weight
        
        if not weighted_counts:
            return VoteResult(strategy=self.strategy, total_votes=0)
        
        winner = max(weighted_counts.items(), key=lambda x: x[1])[0]
        winner_weight = weighted_counts[winner]
        percentage = winner_weight / total_weight if total_weight > 0 else 0
        
        # Calculate weighted average confidence
        winner_votes = [v for v in votes if str(v.choice) == winner]
        if winner_votes:
            weighted_conf = sum(v.confidence * v.weight for v in winner_votes)
            total_winner_weight = sum(v.weight for v in winner_votes)
            avg_confidence = weighted_conf / total_winner_weight if total_winner_weight > 0 else 0
        else:
            avg_confidence = 0.0
        
        return VoteResult(
            strategy=self.strategy,
            winner=winner,
            vote_counts={k: int(v) for k, v in weighted_counts.items()},
            total_votes=len(votes),
            winning_percentage=percentage,
            confidence_score=avg_confidence,
            is_unanimous=(len(weighted_counts) == 1),
            is_consensus=(percentage > 0.5),
            metadata={"total_weight": total_weight, "winner_weight": winner_weight}
        )
    
    def _threshold_vote(self, votes: List[Vote]) -> VoteResult:
        """Threshold voting - winner needs specific percentage"""
        vote_counts = Counter(str(v.choice) for v in votes)
        total = len(votes)
        
        if not vote_counts:
            return VoteResult(strategy=self.strategy, total_votes=0)
        
        winner_candidate, count = vote_counts.most_common(1)[0]
        percentage = count / total
        
        # Winner only if threshold met
        winner = winner_candidate if percentage >= self.threshold else None
        
        if winner:
            winner_votes = [v for v in votes if str(v.choice) == winner]
            avg_confidence = sum(v.confidence for v in winner_votes) / len(winner_votes)
        else:
            avg_confidence = 0.0
        
        return VoteResult(
            strategy=self.strategy,
            winner=winner,
            vote_counts=dict(vote_counts),
            total_votes=total,
            winning_percentage=percentage,
            confidence_score=avg_confidence,
            is_unanimous=(len(vote_counts) == 1),
            is_consensus=(percentage >= self.threshold),
            metadata={"threshold": self.threshold, "threshold_met": percentage >= self.threshold}
        )
    
    def conduct_ranked_vote(
        self,
        ranked_votes: List[RankedVote],
        total_agents: Optional[int] = None
    ) -> VoteResult:
        """
        Conduct ranked choice voting (instant runoff)
        
        Args:
            ranked_votes: List of ranked votes
            total_agents: Total number of agents (for quorum)
        
        Returns:
            VoteResult with winner determined by instant runoff
        """
        if not ranked_votes:
            return VoteResult(
                strategy=VotingStrategy.RANKED_CHOICE,
                total_votes=0,
                metadata={"error": "No ranked votes cast"}
            )
        
        # Check quorum
        if self.require_quorum and total_agents:
            participation = len(ranked_votes) / total_agents
            if participation < self.quorum_percentage:
                return VoteResult(
                    strategy=VotingStrategy.RANKED_CHOICE,
                    total_votes=len(ranked_votes),
                    metadata={"error": "Quorum not met"}
                )
        
        # Instant runoff voting
        votes_by_round = [[str(rv.rankings[0]) for rv in ranked_votes if rv.rankings]]
        all_candidates = set()
        for rv in ranked_votes:
            all_candidates.update(str(r) for r in rv.rankings)
        
        eliminated = set()
        round_num = 0
        
        while True:
            round_num += 1
            current_votes = votes_by_round[-1]
            vote_counts = Counter(current_votes)
            total = len(current_votes)
            
            if not vote_counts:
                return VoteResult(
                    strategy=VotingStrategy.RANKED_CHOICE,
                    total_votes=len(ranked_votes),
                    metadata={"error": "No valid votes in final round"}
                )
            
            # Check for majority
            winner_candidate, count = vote_counts.most_common(1)[0]
            if count > total / 2:
                return VoteResult(
                    strategy=VotingStrategy.RANKED_CHOICE,
                    winner=winner_candidate,
                    vote_counts=dict(vote_counts),
                    total_votes=len(ranked_votes),
                    winning_percentage=count / total,
                    confidence_score=1.0,
                    is_unanimous=(len(vote_counts) == 1),
                    is_consensus=True,
                    metadata={
                        "rounds": round_num,
                        "eliminated": list(eliminated)
                    }
                )
            
            # No majority - eliminate lowest
            if len(vote_counts) == 1:
                # Only one candidate left
                winner = list(vote_counts.keys())[0]
                return VoteResult(
                    strategy=VotingStrategy.RANKED_CHOICE,
                    winner=winner,
                    vote_counts=dict(vote_counts),
                    total_votes=len(ranked_votes),
                    winning_percentage=1.0,
                    confidence_score=0.8,
                    is_unanimous=False,
                    is_consensus=True,
                    metadata={
                        "rounds": round_num,
                        "eliminated": list(eliminated)
                    }
                )
            
            # Eliminate lowest scorer
            lowest = vote_counts.most_common()[-1][0]
            eliminated.add(lowest)
            
            # Redistribute votes
            new_round = []
            for rv in ranked_votes:
                # Find next non-eliminated choice
                for choice in rv.rankings:
                    if str(choice) not in eliminated:
                        new_round.append(str(choice))
                        break
            
            if not new_round:
                # No more votes to redistribute
                return VoteResult(
                    strategy=VotingStrategy.RANKED_CHOICE,
                    winner=winner_candidate,
                    vote_counts=dict(vote_counts),
                    total_votes=len(ranked_votes),
                    winning_percentage=count / total,
                    confidence_score=0.6,
                    is_unanimous=False,
                    is_consensus=False,
                    metadata={
                        "rounds": round_num,
                        "eliminated": list(eliminated),
                        "note": "No clear winner by majority"
                    }
                )
            
            votes_by_round.append(new_round)
    
    def conduct_approval_vote(
        self,
        approval_votes: List[ApprovalVote],
        total_agents: Optional[int] = None
    ) -> VoteResult:
        """
        Conduct approval voting - agents can approve multiple options
        
        Args:
            approval_votes: List of approval votes
            total_agents: Total number of agents (for quorum)
        
        Returns:
            VoteResult with winner having most approvals
        """
        if not approval_votes:
            return VoteResult(
                strategy=VotingStrategy.APPROVAL,
                total_votes=0,
                metadata={"error": "No approval votes cast"}
            )
        
        # Check quorum
        if self.require_quorum and total_agents:
            participation = len(approval_votes) / total_agents
            if participation < self.quorum_percentage:
                return VoteResult(
                    strategy=VotingStrategy.APPROVAL,
                    total_votes=len(approval_votes),
                    metadata={"error": "Quorum not met"}
                )
        
        # Count approvals
        approval_counts: Dict[str, int] = defaultdict(int)
        for av in approval_votes:
            for choice in av.approved_choices:
                approval_counts[str(choice)] += 1
        
        if not approval_counts:
            return VoteResult(
                strategy=VotingStrategy.APPROVAL,
                total_votes=len(approval_votes),
                metadata={"error": "No approvals given"}
            )
        
        winner, count = max(approval_counts.items(), key=lambda x: x[1])
        percentage = count / len(approval_votes)
        
        return VoteResult(
            strategy=VotingStrategy.APPROVAL,
            winner=winner,
            vote_counts=dict(approval_counts),
            total_votes=len(approval_votes),
            winning_percentage=percentage,
            confidence_score=percentage,
            is_unanimous=(len(approval_counts) == 1),
            is_consensus=(percentage > 0.5),
            metadata={"total_approvals": sum(approval_counts.values())}
        )


class ConsensusBuilder:
    """
    Build consensus among agents through iterative refinement
    
    Uses multi-round discussion and voting to reach agreement.
    Based on research showing collective improvement (CI) can increase
    performance by 7.4% over baseline protocols.
    """
    
    def __init__(
        self,
        max_rounds: int = 5,
        consensus_threshold: float = 0.75,
        improvement_threshold: float = 0.05
    ):
        """
        Initialize consensus builder
        
        Args:
            max_rounds: Maximum consensus rounds
            consensus_threshold: Required agreement level (0-1)
            improvement_threshold: Minimum improvement between rounds
        """
        self.max_rounds = max_rounds
        self.consensus_threshold = consensus_threshold
        self.improvement_threshold = improvement_threshold
    
    async def build_consensus(
        self,
        agents: List[Any],
        problem: str,
        initial_solutions: List[Any]
    ) -> Tuple[Any, List[VoteResult]]:
        """
        Build consensus through iterative voting and refinement
        
        Args:
            agents: List of agents participating
            problem: Problem description
            initial_solutions: Initial proposed solutions
        
        Returns:
            Tuple of (final solution, list of vote results per round)
        """
        # This would be implemented with actual agent communication
        # For now, return structure showing the pattern
        raise NotImplementedError(
            "Consensus building requires async agent communication - "
            "implement with actual agent message passing"
        )
