"""
Algorithms Module for Multi-Agentic Systems

This module provides various code generation and problem-solving algorithms
that can be used by multi-agentic systems to solve complex problems.

Key Components:
- Code Generation Algorithms: Template-based, AST-based, Pattern-based, AI-assisted
- Problem Solving Algorithms: Divide & Conquer, Backtracking, Dynamic Programming, Greedy, CSP
- Optimization Algorithms: Genetic, Simulated Annealing, Particle Swarm
"""

from .base import Algorithm, AlgorithmType, AlgorithmResult
from .code_generation import *
from .problem_solving import *
from .optimization import *

__all__ = [
    "Algorithm",
    "AlgorithmType", 
    "AlgorithmResult",
]
