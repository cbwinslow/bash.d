"""
Autonomous Agent Crew System

This module implements fully autonomous agent crews that can:
- Work until task completion without human intervention
- Self-organize and adapt to changing conditions
- Make collective decisions through voting and consensus
- Handle failures and recovery automatically
- Learn from experience and optimize strategies
"""

import asyncio
import logging
from typing import List, Dict, Any, Optional, Callable, Tuple
from datetime import datetime, timedelta
from enum import Enum
from collections import defaultdict, Counter
import json

from .base import (
    BaseAgent,
    Task,
    TaskStatus,
    TaskPriority,
    AgentStatus,
    AgentType,
    AgentMessage
)
from .hierarchy import (
    ManagerAgent,
    CoordinatorAgent,
    WorkerAgent,
    TaskDecomposition,
    AgentRole
)

logger = logging.getLogger(__name__)


class CrewStrategy(str, Enum):
    """Crew organization strategies"""
    DEMOCRATIC = "democratic"          # All agents vote on decisions
    HIERARCHICAL = "hierarchical"      # Manager makes decisions
    COMPETITIVE = "competitive"        # Best solution wins
    COLLABORATIVE = "collaborative"   # Consensus building
    ADAPTIVE = "adaptive"             # Strategy changes based on context


class DecisionType(str, Enum):
    """Types of decisions crews can make"""
    TASK_DECOMPOSITION = "task_decomposition"
    AGENT_ASSIGNMENT = "agent_assignment"
    STRATEGY_CHANGE = "strategy_change"
    RESOURCE_ALLOCATION = "resource_allocation"
    ERROR_RECOVERY = "error_recovery"
    COMPLETION_CHECK = "completion_check"


class Vote:
    """Represents a vote from an agent"""
    def __init__(self, agent_id: str, choice: Any, confidence: float = 1.0, reasoning: str = ""):
        self.agent_id = agent_id
        self.choice = choice
        self.confidence = confidence
        self.reasoning = reasoning
        self.timestamp = datetime.utcnow()


class Decision:
    """Represents a collective decision"""
    def __init__(self, decision_type: DecisionType, context: Dict[str, Any]):
        self.id = f"decision_{datetime.utcnow().timestamp()}"
        self.decision_type = decision_type
        self.context = context
        self.votes: List[Vote] = []
        self.result: Optional[Any] = None
        self.consensus_reached = False
        self.created_at = datetime.utcnow()


class AutonomousCrew:
    """
    Autonomous Agent Crew
    
    A self-organizing, self-managing group of agents that can:
    - Accept complex problems and work until completion
    - Make collective decisions through voting
    - Adapt strategies based on performance
    - Handle errors and recover automatically
    - Learn from experience
    
    Example:
        ```python
        crew = AutonomousCrew(name="Development Crew", strategy=CrewStrategy.DEMOCRATIC)
        crew.add_agents([python_agent, test_agent, doc_agent])
        
        task = Task(
            title="Build REST API",
            description="Create a complete REST API with tests and docs"
        )
        
        result = await crew.execute_autonomously(task)
        ```
    """
    
    def __init__(
        self,
        name: str,
        strategy: CrewStrategy = CrewStrategy.DEMOCRATIC,
        max_iterations: int = 100,
        consensus_threshold: float = 0.7,
        auto_recovery: bool = True,
        learning_enabled: bool = True
    ):
        self.name = name
        self.strategy = strategy
        self.max_iterations = max_iterations
        self.consensus_threshold = consensus_threshold
        self.auto_recovery = auto_recovery
        self.learning_enabled = learning_enabled
        
        # Crew composition
        self.agents: Dict[str, BaseAgent] = {}
        self.manager: Optional[ManagerAgent] = None
        self.coordinator: Optional[CoordinatorAgent] = None
        self.workers: List[WorkerAgent] = []
        
        # State
        self.active_task: Optional[Task] = None
        self.subtasks: List[Task] = []
        self.completed_tasks: List[Task] = []
        self.failed_tasks: List[Task] = []
        self.running = False
        
        # Decision making
        self.pending_decisions: List[Decision] = []
        self.decision_history: List[Decision] = []
        
        # Learning and adaptation
        self.performance_history: List[Dict[str, Any]] = []
        self.strategy_scores: Dict[str, float] = {s.value: 0.0 for s in CrewStrategy}
        
        # Metrics
        self.iterations_count = 0
        self.total_tasks_completed = 0
        self.total_tasks_failed = 0
        self.total_decisions_made = 0
        self.started_at: Optional[datetime] = None
        self.completed_at: Optional[datetime] = None
    
    def add_agent(self, agent: BaseAgent) -> None:
        """Add an agent to the crew"""
        self.agents[agent.id] = agent
        
        # Organize by role if hierarchical
        if isinstance(agent, ManagerAgent):
            self.manager = agent
        elif isinstance(agent, CoordinatorAgent):
            self.coordinator = agent
        elif isinstance(agent, WorkerAgent):
            self.workers.append(agent)
        
        logger.info(f"Added agent {agent.name} to crew {self.name}")
    
    def add_agents(self, agents: List[BaseAgent]) -> None:
        """Add multiple agents to the crew"""
        for agent in agents:
            self.add_agent(agent)
    
    async def execute_autonomously(
        self,
        task: Task,
        max_runtime: Optional[timedelta] = None
    ) -> Dict[str, Any]:
        """
        Execute a task autonomously until completion
        
        Args:
            task: Main task to complete
            max_runtime: Maximum runtime (None for unlimited)
            
        Returns:
            Execution results
        """
        logger.info(f"Crew {self.name} starting autonomous execution of: {task.title}")
        
        self.active_task = task
        self.running = True
        self.started_at = datetime.utcnow()
        
        try:
            # Phase 1: Planning and decomposition
            decomposition = await self._plan_execution(task)
            self.subtasks = decomposition.subtasks
            
            # Phase 2: Execute until completion
            while self.running and self.iterations_count < self.max_iterations:
                # Check if we're done
                if await self._check_completion():
                    logger.info(f"Crew {self.name} completed all tasks")
                    break
                
                # Check max runtime
                if max_runtime and (datetime.utcnow() - self.started_at) > max_runtime:
                    logger.warning(f"Crew {self.name} reached max runtime")
                    break
                
                # Execute next iteration
                await self._execute_iteration()
                
                # Learn and adapt
                if self.learning_enabled and self.iterations_count % 10 == 0:
                    await self._learn_and_adapt()
                
                self.iterations_count += 1
                await asyncio.sleep(0.1)  # Brief pause
            
            # Phase 3: Finalization
            results = await self._finalize_execution()
            
            return results
        
        except Exception as e:
            logger.error(f"Crew {self.name} encountered fatal error: {e}")
            
            if self.auto_recovery:
                logger.info("Attempting auto-recovery...")
                recovery_result = await self._auto_recover(e)
                if recovery_result:
                    return await self.execute_autonomously(task, max_runtime)
            
            raise
        
        finally:
            self.running = False
            self.completed_at = datetime.utcnow()
    
    async def _plan_execution(self, task: Task) -> TaskDecomposition:
        """Plan execution strategy through collective decision"""
        logger.info(f"Crew {self.name} planning execution strategy")
        
        # Get multiple decomposition proposals
        proposals = []
        
        if self.manager:
            # Manager provides decomposition
            manager_proposal = await self.manager.decompose_task(task)
            proposals.append(("manager", manager_proposal))
        
        # Get proposals from experienced workers
        for worker in self.workers[:3]:  # Top 3 workers
            if worker.metrics.tasks_completed > 5:
                # Workers can also propose based on experience
                worker_proposal = await self._worker_decompose(worker, task)
                proposals.append((worker.id, worker_proposal))
        
        # Vote on best decomposition if multiple proposals
        if len(proposals) > 1:
            best_decomposition = await self._vote_on_decomposition(proposals)
        else:
            best_decomposition = proposals[0][1] if proposals else TaskDecomposition(
                original_task=task,
                subtasks=[task]
            )
        
        logger.info(f"Selected decomposition with {len(best_decomposition.subtasks)} subtasks")
        return best_decomposition
    
    async def _worker_decompose(self, worker: WorkerAgent, task: Task) -> TaskDecomposition:
        """Simple decomposition by worker based on experience"""
        # Workers provide simpler decomposition
        num_subtasks = min(3, max(1, len(task.description) // 100))
        
        decomposition = TaskDecomposition(original_task=task)
        for i in range(num_subtasks):
            decomposition.subtasks.append(Task(
                title=f"{task.title} - Part {i+1}",
                description=f"Part {i+1} of {num_subtasks}",
                priority=task.priority,
                agent_type=worker.type
            ))
        
        return decomposition
    
    async def _vote_on_decomposition(
        self,
        proposals: List[Tuple[str, TaskDecomposition]]
    ) -> TaskDecomposition:
        """Vote on best task decomposition"""
        decision = Decision(DecisionType.TASK_DECOMPOSITION, {
            "proposals": proposals
        })
        
        # Each agent votes
        for agent in self.agents.values():
            # Simple scoring: prefer fewer subtasks but not too few
            scores = []
            for proposer_id, decomp in proposals:
                score = 0.0
                
                # Prefer moderate number of subtasks
                num_subtasks = len(decomp.subtasks)
                if 3 <= num_subtasks <= 10:
                    score += 10.0
                else:
                    score += max(0, 10.0 - abs(num_subtasks - 5))
                
                # Prefer proposals from managers
                if proposer_id == "manager":
                    score += 5.0
                
                # Prefer proposals matching agent's expertise
                if any(st.agent_type == agent.type for st in decomp.subtasks):
                    score += 3.0
                
                scores.append(score)
            
            # Vote for highest scoring proposal
            best_idx = scores.index(max(scores))
            vote = Vote(
                agent_id=agent.id,
                choice=best_idx,
                confidence=scores[best_idx] / max(scores) if max(scores) > 0 else 1.0
            )
            decision.votes.append(vote)
        
        # Count votes
        vote_counts = Counter(vote.choice for vote in decision.votes)
        winning_idx = vote_counts.most_common(1)[0][0]
        
        decision.result = winning_idx
        decision.consensus_reached = True
        self.decision_history.append(decision)
        self.total_decisions_made += 1
        
        return proposals[winning_idx][1]
    
    async def _execute_iteration(self) -> None:
        """Execute one iteration of work"""
        # Find tasks ready to execute
        ready_tasks = [
            task for task in self.subtasks
            if task.status in [TaskStatus.PENDING, TaskStatus.QUEUED] and
            all(dep_task.status == TaskStatus.COMPLETED 
                for dep_task in self.subtasks 
                if dep_task.id in task.dependencies)
        ]
        
        if not ready_tasks:
            return
        
        # Assign tasks to agents
        if self.strategy == CrewStrategy.DEMOCRATIC:
            assignments = await self._democratic_assignment(ready_tasks)
        elif self.strategy == CrewStrategy.COMPETITIVE:
            assignments = await self._competitive_assignment(ready_tasks)
        else:
            assignments = await self._hierarchical_assignment(ready_tasks)
        
        # Execute assigned tasks
        execution_tasks = []
        for task, agent in assignments:
            execution_tasks.append(self._execute_task_with_agent(task, agent))
        
        if execution_tasks:
            await asyncio.gather(*execution_tasks, return_exceptions=True)
    
    async def _democratic_assignment(
        self,
        tasks: List[Task]
    ) -> List[Tuple[Task, BaseAgent]]:
        """Assign tasks through democratic voting"""
        assignments = []
        
        for task in tasks:
            # Each agent votes on who should handle the task
            decision = Decision(DecisionType.AGENT_ASSIGNMENT, {"task": task})
            
            for agent in self.agents.values():
                if not agent.is_available():
                    continue
                
                # Score how well this agent fits
                score = 0.0
                if task.agent_type and task.agent_type == agent.type:
                    score += 10.0
                score += agent.metrics.success_rate * 5.0
                score -= len(agent.task_queue) * 2.0
                
                # Vote for self if good fit
                if score > 5.0:
                    vote = Vote(
                        agent_id=agent.id,
                        choice=agent.id,
                        confidence=min(score / 20.0, 1.0)
                    )
                    decision.votes.append(vote)
            
            if decision.votes:
                # Select agent with most votes (weighted by confidence)
                vote_scores = defaultdict(float)
                for vote in decision.votes:
                    vote_scores[vote.choice] += vote.confidence
                
                best_agent_id = max(vote_scores.items(), key=lambda x: x[1])[0]
                best_agent = self.agents[best_agent_id]
                
                assignments.append((task, best_agent))
                decision.result = best_agent_id
                decision.consensus_reached = True
                self.decision_history.append(decision)
        
        return assignments
    
    async def _competitive_assignment(
        self,
        tasks: List[Task]
    ) -> List[Tuple[Task, BaseAgent]]:
        """Assign tasks competitively - multiple agents work on same task"""
        assignments = []
        
        for task in tasks:
            # Assign to multiple agents for competitive solving
            candidates = [
                agent for agent in self.agents.values()
                if agent.is_available() and (
                    not task.agent_type or task.agent_type == agent.type
                )
            ]
            
            # Select top 2-3 agents
            num_competitors = min(3, len(candidates))
            for agent in candidates[:num_competitors]:
                assignments.append((task, agent))
        
        return assignments
    
    async def _hierarchical_assignment(
        self,
        tasks: List[Task]
    ) -> List[Tuple[Task, BaseAgent]]:
        """Assign tasks hierarchically through manager"""
        assignments = []
        
        if self.manager:
            for task in tasks:
                # Manager decides assignment
                for worker in self.workers:
                    if worker.is_available():
                        if not task.agent_type or task.agent_type == worker.type:
                            assignments.append((task, worker))
                            break
        else:
            # Fallback to round-robin
            available = [a for a in self.agents.values() if a.is_available()]
            for i, task in enumerate(tasks):
                if available:
                    agent = available[i % len(available)]
                    assignments.append((task, agent))
        
        return assignments
    
    async def _execute_task_with_agent(
        self,
        task: Task,
        agent: BaseAgent
    ) -> None:
        """Execute a task with an agent, handling errors"""
        try:
            task.status = TaskStatus.IN_PROGRESS
            task.assigned_agent_id = agent.id
            
            # Execute task (simplified - would use agent's execute_task method)
            if isinstance(agent, WorkerAgent):
                result = await agent.execute_task(task)
            else:
                # Simulate execution
                await asyncio.sleep(0.5)
                result = {"status": "completed"}
            
            task.status = TaskStatus.COMPLETED
            task.output_data = result
            self.completed_tasks.append(task)
            self.total_tasks_completed += 1
            
            logger.info(f"Task {task.title} completed by {agent.name}")
        
        except Exception as e:
            logger.error(f"Task {task.title} failed: {e}")
            task.status = TaskStatus.FAILED
            task.error = str(e)
            
            # Auto retry if enabled
            if self.auto_recovery and task.retry_count < task.max_retries:
                task.retry_count += 1
                task.status = TaskStatus.PENDING
                logger.info(f"Retrying task {task.title} (attempt {task.retry_count})")
            else:
                self.failed_tasks.append(task)
                self.total_tasks_failed += 1
    
    async def _check_completion(self) -> bool:
        """Check if all tasks are completed"""
        all_completed = all(
            task.status == TaskStatus.COMPLETED
            for task in self.subtasks
        )
        
        if all_completed:
            # Verify through voting if democratic
            if self.strategy == CrewStrategy.DEMOCRATIC:
                decision = Decision(DecisionType.COMPLETION_CHECK, {
                    "completed_tasks": len(self.completed_tasks),
                    "failed_tasks": len(self.failed_tasks)
                })
                
                for agent in self.agents.values():
                    # Agents vote on whether work is complete
                    vote = Vote(
                        agent_id=agent.id,
                        choice=all_completed,
                        confidence=1.0 if all_completed else 0.5
                    )
                    decision.votes.append(vote)
                
                # Count yes votes
                yes_votes = sum(1 for v in decision.votes if v.choice)
                consensus = yes_votes / len(decision.votes) >= self.consensus_threshold
                
                decision.result = consensus
                decision.consensus_reached = consensus
                self.decision_history.append(decision)
                
                return consensus
        
        return all_completed
    
    async def _learn_and_adapt(self) -> None:
        """Learn from performance and adapt strategy"""
        if not self.learning_enabled:
            return
        
        # Calculate current performance
        total_tasks = len(self.completed_tasks) + len(self.failed_tasks)
        if total_tasks == 0:
            return
        
        success_rate = len(self.completed_tasks) / total_tasks
        avg_time = sum(
            (t.completed_at - t.started_at).total_seconds()
            for t in self.completed_tasks if t.started_at and t.completed_at
        ) / max(len(self.completed_tasks), 1)
        
        # Record performance
        self.performance_history.append({
            "timestamp": datetime.utcnow(),
            "strategy": self.strategy.value,
            "success_rate": success_rate,
            "avg_time": avg_time,
            "iterations": self.iterations_count
        })
        
        # Update strategy scores
        self.strategy_scores[self.strategy.value] += success_rate * 10.0
        
        # Adapt strategy if adaptive mode
        if self.strategy == CrewStrategy.ADAPTIVE:
            # Switch to best performing strategy
            if len(self.performance_history) > 10:
                best_strategy = max(self.strategy_scores.items(), key=lambda x: x[1])[0]
                if best_strategy != self.strategy.value:
                    logger.info(f"Adapting strategy from {self.strategy.value} to {best_strategy}")
                    self.strategy = CrewStrategy(best_strategy)
    
    async def _auto_recover(self, error: Exception) -> bool:
        """Attempt automatic recovery from error"""
        logger.info(f"Crew {self.name} attempting auto-recovery from: {error}")
        
        # Strategy 1: Reset failed tasks
        for task in self.failed_tasks[:]:
            if task.retry_count < task.max_retries:
                task.status = TaskStatus.PENDING
                task.retry_count += 1
                task.error = None
                self.subtasks.append(task)
                self.failed_tasks.remove(task)
        
        # Strategy 2: Reassign stuck tasks
        stuck_tasks = [
            task for task in self.subtasks
            if task.status == TaskStatus.IN_PROGRESS and
            task.started_at and
            (datetime.utcnow() - task.started_at).total_seconds() > 300
        ]
        
        for task in stuck_tasks:
            task.status = TaskStatus.PENDING
            task.assigned_agent_id = None
        
        # Strategy 3: Request additional agents if available
        # (Would be implemented with agent pool)
        
        return True  # Recovery attempted
    
    async def _finalize_execution(self) -> Dict[str, Any]:
        """Finalize execution and gather results"""
        duration = (self.completed_at - self.started_at).total_seconds() if self.completed_at and self.started_at else 0
        
        results = {
            "crew_name": self.name,
            "strategy": self.strategy.value,
            "task": self.active_task.title if self.active_task else None,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "duration_seconds": duration,
            "iterations": self.iterations_count,
            "tasks": {
                "total": len(self.subtasks),
                "completed": self.total_tasks_completed,
                "failed": self.total_tasks_failed,
                "success_rate": self.total_tasks_completed / max(len(self.subtasks), 1)
            },
            "decisions_made": self.total_decisions_made,
            "agents_used": len(self.agents),
            "performance_history": self.performance_history[-10:],  # Last 10 entries
            "final_status": "completed" if self.total_tasks_failed == 0 else "completed_with_errors"
        }
        
        logger.info(f"Crew {self.name} finalized execution: {results['tasks']['success_rate']:.2%} success rate")
        
        return results
    
    def get_status(self) -> Dict[str, Any]:
        """Get current crew status"""
        return {
            "name": self.name,
            "strategy": self.strategy.value,
            "running": self.running,
            "iterations": self.iterations_count,
            "agents": len(self.agents),
            "active_task": self.active_task.title if self.active_task else None,
            "subtasks": {
                "total": len(self.subtasks),
                "pending": len([t for t in self.subtasks if t.status == TaskStatus.PENDING]),
                "in_progress": len([t for t in self.subtasks if t.status == TaskStatus.IN_PROGRESS]),
                "completed": len(self.completed_tasks),
                "failed": len(self.failed_tasks)
            },
            "decisions": {
                "pending": len(self.pending_decisions),
                "total": self.total_decisions_made
            }
        }
