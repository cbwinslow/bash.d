#!/usr/bin/env python3
"""
Example: Using the Master AI Agent

This script demonstrates how to use the Master AI Agent to
autonomously create a software application.
"""

import asyncio
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from agents.master_agent import create_autonomous_agent, DevelopmentWorkflow
from agents.base import AgentType


async def example_create_cli_tool():
    """Example: Create a simple CLI tool"""
    print("=" * 60)
    print("Example 1: Creating a CLI Tool")
    print("=" * 60)
    
    # Initialize master agent
    print("\n1. Initializing Master AI Agent...")
    agent = await create_autonomous_agent()
    print(f"   ✓ Master Agent: {agent.name}")
    
    # Create project
    print("\n2. Creating CLI Tool Project...")
    project = await agent.create_project(
        name="File Organizer CLI",
        description="A command-line tool that organizes files by extension into folders",
        workflow=DevelopmentWorkflow.CLI_TOOL,
        requirements={
            "language": "python",
            "features": ["organize_by_extension", "recursive_scan", "dry_run_mode"],
            "testing": "pytest",
            "cli_framework": "typer"
        }
    )
    print(f"   ✓ Project ID: {project.id}")
    print(f"   ✓ Phase: {project.phase.value}")
    print(f"   ✓ Tasks created: {len(project.tasks)}")
    
    print("\n✓ Example completed!")
    return agent, project


async def main():
    """Run examples"""
    print("\n" + "=" * 60)
    print("MASTER AI AGENT - EXAMPLES")
    print("=" * 60)
    
    try:
        await example_create_cli_tool()
        print("\n✓ ALL EXAMPLES COMPLETED!")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
