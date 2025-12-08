#!/usr/bin/env python3
"""
Example: Run Code Generation Crew

Demonstrates running a democratic code generation crew with multiple agents
collaborating on code development with voting on key decisions.
"""

import asyncio
import yaml
import logging
from pathlib import Path

# Add parent directory to path for imports
import sys
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from crewai_config import (
    CrewConfig,
    CrewOrchestrator,
    CrewMessagingHub,
    CrewCommunication
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def main():
    """Run the code generation crew"""
    
    # Load crew configuration
    config_path = Path(__file__).parent.parent / "crews" / "code_generation_crew.yaml"
    
    logger.info(f"Loading crew configuration from: {config_path}")
    
    with open(config_path, 'r') as f:
        crew_dict = yaml.safe_load(f)
    
    # Create crew configuration
    crew_config = CrewConfig(**crew_dict)
    
    logger.info(f"Crew: {crew_config.name}")
    logger.info(f"Process Type: {crew_config.process_type.value}")
    logger.info(f"Governance: {crew_config.governance_model.value}")
    logger.info(f"Members: {len(crew_config.members)}")
    logger.info(f"Tasks: {len(crew_config.tasks)}")
    
    # Set up messaging (optional - for inter-agent communication)
    comm_config = CrewCommunication(
        crew_id=crew_config.id,
        rabbitmq_enabled=False,  # Set to True if RabbitMQ is available
        redis_enabled=False       # Set to True if Redis is available
    )
    
    # Create messaging hub if protocols are enabled
    messaging_hub = None
    if comm_config.rabbitmq_enabled or comm_config.redis_enabled:
        try:
            messaging_hub = CrewMessagingHub(
                crew_id=crew_config.id,
                config=comm_config
            )
            messaging_hub.connect()
            logger.info("Messaging hub connected")
        except Exception as e:
            logger.warning(f"Could not connect messaging hub: {e}")
            messaging_hub = None
    
    # Create orchestrator
    orchestrator = CrewOrchestrator(
        crew_config=crew_config,
        messaging_hub=messaging_hub
    )
    
    logger.info("\n" + "="*60)
    logger.info("Starting crew execution...")
    logger.info("="*60 + "\n")
    
    try:
        # Execute the crew
        results = await orchestrator.execute()
        
        # Display results
        logger.info("\n" + "="*60)
        logger.info("EXECUTION RESULTS")
        logger.info("="*60)
        
        logger.info(f"\nCrew: {results['crew_name']}")
        logger.info(f"Status: {results['status']}")
        logger.info(f"Started: {results['started_at']}")
        logger.info(f"Completed: {results['completed_at']}")
        
        logger.info("\nTasks:")
        logger.info(f"  Total: {results['tasks']['total']}")
        logger.info(f"  Completed: {results['tasks']['completed']}")
        logger.info(f"  Failed: {results['tasks']['failed']}")
        
        logger.info("\nMetrics:")
        metrics = results['metrics']
        logger.info(f"  Success Rate: {metrics['success_rate']:.2%}")
        logger.info(f"  Average Task Duration: {metrics['average_task_duration']:.2f}s")
        logger.info(f"  Total Runtime: {metrics['total_runtime_seconds']:.2f}s")
        
        logger.info("\nGovernance:")
        governance = results['governance']
        logger.info(f"  Model: {governance['model']}")
        logger.info(f"  Votes Conducted: {governance['votes_conducted']}")
        logger.info(f"  Consensus Reached: {governance['consensus_reached']}")
        
        if results['task_errors']:
            logger.error("\nTask Errors:")
            for task_id, error in results['task_errors'].items():
                logger.error(f"  {task_id}: {error}")
        
        logger.info("\nTask Status:")
        for task_id, status in results['tasks']['status'].items():
            logger.info(f"  {task_id}: {status}")
        
    except Exception as e:
        logger.error(f"Crew execution failed: {e}", exc_info=True)
        raise
    
    finally:
        # Cleanup
        if messaging_hub:
            messaging_hub.disconnect()
            logger.info("Messaging hub disconnected")
    
    logger.info("\n" + "="*60)
    logger.info("Execution complete!")
    logger.info("="*60)


if __name__ == "__main__":
    asyncio.run(main())
