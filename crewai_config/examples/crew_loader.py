#!/usr/bin/env python3
"""
Crew Configuration Loader

Utilities for loading and validating crew configurations from YAML files.
"""

import yaml
import logging
from pathlib import Path
from typing import Dict, Any, List

import sys
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from crewai_config import CrewConfig, SwarmConfig

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class CrewLoader:
    """Load and validate crew configurations"""
    
    def __init__(self, config_dir: Path = None):
        """
        Initialize loader
        
        Args:
            config_dir: Directory containing crew configurations
        """
        if config_dir is None:
            config_dir = Path(__file__).parent.parent / "crews"
        
        self.config_dir = Path(config_dir)
        self.loaded_crews: Dict[str, CrewConfig] = {}
    
    def load_crew(self, crew_file: str) -> CrewConfig:
        """
        Load a crew configuration from YAML file
        
        Args:
            crew_file: Filename or path to crew YAML
            
        Returns:
            CrewConfig instance
        """
        # Resolve path
        if "/" in crew_file or "\\" in crew_file:
            config_path = Path(crew_file)
        else:
            config_path = self.config_dir / crew_file
        
        if not config_path.exists():
            raise FileNotFoundError(f"Crew config not found: {config_path}")
        
        logger.info(f"Loading crew from: {config_path}")
        
        # Load YAML
        with open(config_path, 'r') as f:
            crew_dict = yaml.safe_load(f)
        
        # Validate and create config
        try:
            crew_config = CrewConfig(**crew_dict)
            self.loaded_crews[crew_config.id] = crew_config
            
            logger.info(f"✓ Loaded crew: {crew_config.name}")
            logger.info(f"  - ID: {crew_config.id}")
            logger.info(f"  - Members: {len(crew_config.members)}")
            logger.info(f"  - Tasks: {len(crew_config.tasks)}")
            logger.info(f"  - Process: {crew_config.process_type.value}")
            logger.info(f"  - Governance: {crew_config.governance_model.value}")
            
            return crew_config
        
        except Exception as e:
            logger.error(f"✗ Failed to load crew: {e}")
            raise
    
    def load_all_crews(self) -> Dict[str, CrewConfig]:
        """
        Load all crew configurations from directory
        
        Returns:
            Dictionary of crew_id -> CrewConfig
        """
        logger.info(f"Loading all crews from: {self.config_dir}")
        
        yaml_files = list(self.config_dir.glob("*.yaml"))
        
        if not yaml_files:
            logger.warning(f"No YAML files found in {self.config_dir}")
            return {}
        
        for yaml_file in yaml_files:
            try:
                self.load_crew(yaml_file.name)
            except Exception as e:
                logger.error(f"Failed to load {yaml_file.name}: {e}")
        
        logger.info(f"Loaded {len(self.loaded_crews)} crews")
        return self.loaded_crews
    
    def validate_crew(self, crew_config: CrewConfig) -> List[str]:
        """
        Validate crew configuration
        
        Args:
            crew_config: Crew configuration to validate
            
        Returns:
            List of validation warnings/errors
        """
        issues = []
        
        # Check for members
        if not crew_config.members:
            issues.append("ERROR: No members defined")
        
        # Check for tasks
        if not crew_config.tasks:
            issues.append("WARNING: No tasks defined")
        
        # Validate manager for hierarchical crews
        if crew_config.process_type.value == "hierarchical":
            if not crew_config.manager_id:
                issues.append("WARNING: Hierarchical crew should have manager_id")
            else:
                manager_exists = any(
                    m.agent_id == crew_config.manager_id 
                    for m in crew_config.members
                )
                if not manager_exists:
                    issues.append(f"ERROR: Manager {crew_config.manager_id} not in members")
        
        # Validate task dependencies
        task_ids = {t.id for t in crew_config.tasks}
        for task in crew_config.tasks:
            for dep_id in task.dependencies:
                if dep_id not in task_ids:
                    issues.append(
                        f"ERROR: Task {task.id} depends on non-existent task {dep_id}"
                    )
        
        # Check for circular dependencies
        if self._has_circular_dependencies(crew_config.tasks):
            issues.append("ERROR: Circular task dependencies detected")
        
        # Validate voting requirements
        for task in crew_config.tasks:
            if task.requires_vote and not task.voting_strategy:
                issues.append(
                    f"WARNING: Task {task.id} requires vote but no strategy specified"
                )
        
        # Check agent assignments
        member_ids = {m.agent_id for m in crew_config.members}
        for task in crew_config.tasks:
            for agent_id in task.assigned_agent_ids:
                if agent_id not in member_ids:
                    issues.append(
                        f"WARNING: Task {task.id} assigned to non-existent agent {agent_id}"
                    )
        
        return issues
    
    def _has_circular_dependencies(self, tasks) -> bool:
        """Check for circular task dependencies"""
        # Build dependency graph
        graph = {task.id: set(task.dependencies) for task in tasks}
        
        # DFS to detect cycles
        visited = set()
        rec_stack = set()
        
        def has_cycle(node):
            visited.add(node)
            rec_stack.add(node)
            
            for neighbor in graph.get(node, []):
                if neighbor not in visited:
                    if has_cycle(neighbor):
                        return True
                elif neighbor in rec_stack:
                    return True
            
            rec_stack.remove(node)
            return False
        
        for node in graph:
            if node not in visited:
                if has_cycle(node):
                    return True
        
        return False
    
    def get_crew_summary(self, crew_id: str) -> Dict[str, Any]:
        """
        Get summary of crew configuration
        
        Args:
            crew_id: Crew ID
            
        Returns:
            Dictionary with crew summary
        """
        if crew_id not in self.loaded_crews:
            raise ValueError(f"Crew {crew_id} not loaded")
        
        crew = self.loaded_crews[crew_id]
        
        return {
            "id": crew.id,
            "name": crew.name,
            "description": crew.description,
            "version": crew.version,
            "process_type": crew.process_type.value,
            "governance_model": crew.governance_model.value,
            "members": {
                "total": len(crew.members),
                "by_role": self._count_by_role(crew.members),
                "can_vote": sum(1 for m in crew.members if m.can_vote)
            },
            "tasks": {
                "total": len(crew.tasks),
                "require_vote": sum(1 for t in crew.tasks if t.requires_vote),
                "parallel_eligible": self._count_parallel_tasks(crew.tasks)
            },
            "communication": {
                "protocol": crew.communication_protocol,
                "queue": crew.message_queue,
                "channel": crew.broadcast_channel
            },
            "execution": {
                "parallel_execution": crew.parallel_execution,
                "max_concurrent_tasks": crew.max_concurrent_tasks,
                "timeout_seconds": crew.timeout_seconds
            }
        }
    
    def _count_by_role(self, members):
        """Count members by role"""
        from collections import Counter
        return dict(Counter(m.role.value for m in members))
    
    def _count_parallel_tasks(self, tasks):
        """Count tasks that can run in parallel"""
        return sum(
            1 for t in tasks 
            if t.dependency_type.value in ["parallel", "optional"]
        )


def main():
    """Demonstrate crew loader"""
    logger.info("="*60)
    logger.info("Crew Configuration Loader Demo")
    logger.info("="*60)
    
    loader = CrewLoader()
    
    # Load all crews
    crews = loader.load_all_crews()
    
    logger.info("\n" + "="*60)
    logger.info("LOADED CREWS")
    logger.info("="*60)
    
    for crew_id, crew_config in crews.items():
        logger.info(f"\n{crew_config.name}")
        logger.info("-" * 40)
        
        # Validate
        issues = loader.validate_crew(crew_config)
        if issues:
            logger.warning("Validation issues:")
            for issue in issues:
                logger.warning(f"  - {issue}")
        else:
            logger.info("  ✓ Validation passed")
        
        # Show summary
        summary = loader.get_crew_summary(crew_id)
        logger.info(f"  Process: {summary['process_type']}")
        logger.info(f"  Governance: {summary['governance_model']}")
        logger.info(f"  Members: {summary['members']['total']}")
        logger.info(f"  Tasks: {summary['tasks']['total']}")
        logger.info(f"  Democratic votes: {summary['tasks']['require_vote']}")
    
    logger.info("\n" + "="*60)
    logger.info("Loading complete!")
    logger.info("="*60)


if __name__ == "__main__":
    main()
