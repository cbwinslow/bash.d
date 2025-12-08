#!/usr/bin/env python3
"""
Main Entry Point for Master AI Agent System

This module provides the CLI and entry point for running the autonomous
AI agent system capable of creating and managing software projects.
"""

import asyncio
import argparse
import logging
import sys
import json
from pathlib import Path
from typing import Optional
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.logging import RichHandler

from .master_agent import (
    MasterAgent,
    create_autonomous_agent,
    DevelopmentWorkflow,
    ProjectPhase
)
from .base import TaskPriority, AgentType

# Setup rich console
console = Console()

# Setup logging with rich
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    datefmt="[%X]",
    handlers=[RichHandler(console=console, rich_tracebacks=True)]
)
logger = logging.getLogger(__name__)


def display_banner():
    """Display welcome banner"""
    banner = """
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          MASTER AI AGENT - AUTONOMOUS DEVELOPMENT            ║
║                                                              ║
║  An intelligent system that can summon sub-agents and        ║
║  autonomously create, code, debug, and test applications     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    """
    console.print(banner, style="bold cyan")


def display_status(agent: MasterAgent):
    """Display master agent status"""
    status = agent.get_status()
    
    # Master Agent Info
    console.print("\n[bold cyan]Master Agent Status[/bold cyan]")
    table = Table(show_header=True, header_style="bold magenta")
    table.add_column("Property", style="cyan")
    table.add_column("Value", style="green")
    
    table.add_row("Name", status["master_agent"]["name"])
    table.add_row("Status", status["master_agent"]["status"])
    table.add_row("Uptime", f"{status['master_agent']['uptime']:.1f}s")
    
    console.print(table)
    
    # Projects
    console.print("\n[bold cyan]Projects[/bold cyan]")
    proj_table = Table(show_header=True, header_style="bold magenta")
    proj_table.add_column("Status", style="cyan")
    proj_table.add_column("Count", style="green")
    
    proj_table.add_row("Active", str(status["projects"]["active"]))
    proj_table.add_row("Completed", str(status["projects"]["completed"]))
    proj_table.add_row("Failed", str(status["projects"]["failed"]))
    
    console.print(proj_table)
    
    # Active Projects Details
    if status["projects"]["details"]:
        console.print("\n[bold cyan]Active Projects[/bold cyan]")
        for proj in status["projects"]["details"]:
            console.print(
                f"  • {proj['name']} - Phase: {proj['phase']} - "
                f"Progress: {proj['progress_percent']:.1f}% "
                f"({proj['tasks_completed']}/{proj['tasks_total']} tasks)"
            )
    
    # Agents
    console.print("\n[bold cyan]Agent Pool[/bold cyan]")
    agent_table = Table(show_header=True, header_style="bold magenta")
    agent_table.add_column("Agent Type", style="cyan")
    agent_table.add_column("Count", style="green")
    
    for agent_type, count in status["agents"]["by_type"].items():
        agent_table.add_row(agent_type, str(count))
    
    agent_table.add_row("[bold]Total Summoned[/bold]", str(status["agents"]["summoned"]))
    
    console.print(agent_table)
    
    # Tools
    console.print("\n[bold cyan]Tools[/bold cyan]")
    console.print(f"  Available: {status['tools']['available']}")
    console.print(f"  Used: {status['tools']['used']}")
    
    # Orchestrator
    orch = status["orchestrator"]
    console.print("\n[bold cyan]Orchestrator[/bold cyan]")
    console.print(f"  Running: {orch['running']}")
    console.print(f"  Total Agents: {orch['agents']['total']}")
    console.print(f"  Available Agents: {orch['agents']['available']}")
    console.print(f"  Pending Tasks: {orch['tasks']['pending']}")
    console.print(f"  Active Tasks: {orch['tasks']['active']}")
    console.print(f"  Completed Tasks: {orch['tasks']['completed']}")
    console.print(f"  Failed Tasks: {orch['tasks']['failed']}")


async def create_project_interactive(agent: MasterAgent):
    """Interactive project creation"""
    console.print("\n[bold cyan]Create New Project[/bold cyan]\n")
    
    # Get project details
    name = console.input("[yellow]Project Name:[/yellow] ")
    description = console.input("[yellow]Project Description:[/yellow] ")
    
    # Show workflow options
    console.print("\n[yellow]Select Workflow:[/yellow]")
    workflows = list(DevelopmentWorkflow)
    for i, wf in enumerate(workflows, 1):
        console.print(f"  {i}. {wf.value}")
    
    workflow_idx = int(console.input("[yellow]Enter number:[/yellow] ")) - 1
    workflow = workflows[workflow_idx]
    
    # Get requirements
    console.print("\n[yellow]Enter requirements (JSON format or press Enter to skip):[/yellow]")
    req_input = console.input().strip()
    requirements = {}
    if req_input:
        try:
            requirements = json.loads(req_input)
        except json.JSONDecodeError as e:
            console.print(f"[red]Invalid JSON: {e}[/red]")
            console.print("[yellow]Using empty requirements[/yellow]")
            requirements = {}
    
    # Create project
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console
    ) as progress:
        task = progress.add_task(description="Creating project...", total=None)
        project = await agent.create_project(name, description, workflow, requirements)
        progress.update(task, completed=True)
    
    console.print(f"\n[bold green]✓ Project created: {project.id}[/bold green]")
    console.print(f"  Name: {project.name}")
    console.print(f"  Workflow: {project.workflow.value}")
    console.print(f"  Phase: {project.phase.value}")
    console.print(f"  Tasks: {len(project.tasks)}")
    
    # Ask to execute
    execute = console.input("\n[yellow]Execute project now? (y/n):[/yellow] ")
    if execute.lower() == 'y':
        await execute_project_interactive(agent, project.id)


async def execute_project_interactive(agent: MasterAgent, project_id: str):
    """Interactive project execution"""
    console.print(f"\n[bold cyan]Executing Project: {project_id}[/bold cyan]\n")
    
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console
    ) as progress:
        task = progress.add_task(description="Executing project...", total=None)
        
        # Start execution in background
        execute_task = asyncio.create_task(agent.execute_project(project_id))
        
        # Monitor progress
        while not execute_task.done():
            await asyncio.sleep(2)
            status = agent.get_status()
            
            # Find project in status
            proj_details = next(
                (p for p in status["projects"]["details"] if p["project_id"] == project_id),
                None
            )
            
            if proj_details:
                progress.update(
                    task,
                    description=f"Phase: {proj_details['phase']} - "
                                f"Progress: {proj_details['progress_percent']:.1f}%"
                )
        
        # Get result
        success = await execute_task
        progress.update(task, completed=True)
    
    if success:
        console.print("\n[bold green]✓ Project completed successfully![/bold green]")
    else:
        console.print("\n[bold red]✗ Project execution failed[/bold red]")


async def cli_main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="Master AI Agent - Autonomous Software Development System",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Start interactive mode
  %(prog)s interactive
  
  # Create a project from command line
  %(prog)s create --name "My API" --workflow api_service --description "REST API for users"
  
  # Show status
  %(prog)s status
  
  # Execute a project
  %(prog)s execute <project_id>
        """
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")
    
    # Interactive mode
    subparsers.add_parser("interactive", help="Start interactive mode")
    
    # Create project
    create_parser = subparsers.add_parser("create", help="Create a new project")
    create_parser.add_argument("--name", required=True, help="Project name")
    create_parser.add_argument("--description", required=True, help="Project description")
    create_parser.add_argument(
        "--workflow",
        required=True,
        choices=[w.value for w in DevelopmentWorkflow],
        help="Development workflow"
    )
    create_parser.add_argument("--requirements", help="Requirements JSON file")
    create_parser.add_argument("--execute", action="store_true", help="Execute immediately")
    
    # Execute project
    execute_parser = subparsers.add_parser("execute", help="Execute a project")
    execute_parser.add_argument("project_id", help="Project ID to execute")
    
    # Status
    subparsers.add_parser("status", help="Show agent status")
    
    # List projects
    subparsers.add_parser("projects", help="List all projects")
    
    args = parser.parse_args()
    
    # Display banner
    display_banner()
    
    # Create master agent
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console
    ) as progress:
        task = progress.add_task(description="Initializing Master AI Agent...", total=None)
        agent = await create_autonomous_agent()
        progress.update(task, completed=True)
    
    console.print("[bold green]✓ Master Agent initialized[/bold green]\n")
    
    # Handle commands
    if args.command == "interactive":
        # Interactive mode
        while True:
            console.print("\n[bold cyan]Commands:[/bold cyan]")
            console.print("  1. Create project")
            console.print("  2. Execute project")
            console.print("  3. Show status")
            console.print("  4. List projects")
            console.print("  5. Exit")
            
            choice = console.input("\n[yellow]Enter choice:[/yellow] ")
            
            if choice == "1":
                await create_project_interactive(agent)
            elif choice == "2":
                project_id = console.input("[yellow]Enter project ID:[/yellow] ")
                if project_id in agent.active_projects:
                    await execute_project_interactive(agent, project_id)
                else:
                    console.print("[red]Project not found[/red]")
            elif choice == "3":
                display_status(agent)
            elif choice == "4":
                console.print("\n[bold cyan]Active Projects:[/bold cyan]")
                for proj in agent.active_projects.values():
                    console.print(f"  • {proj.id}: {proj.name} ({proj.phase.value})")
                console.print("\n[bold cyan]Completed Projects:[/bold cyan]")
                for proj in agent.completed_projects:
                    console.print(f"  • {proj.id}: {proj.name}")
            elif choice == "5":
                console.print("\n[bold cyan]Goodbye![/bold cyan]")
                break
            else:
                console.print("[red]Invalid choice[/red]")
    
    elif args.command == "create":
        # Load requirements
        requirements = {}
        if args.requirements:
            try:
                with open(args.requirements) as f:
                    requirements = json.load(f)
            except FileNotFoundError:
                console.print(f"[red]Requirements file not found: {args.requirements}[/red]")
                sys.exit(1)
            except json.JSONDecodeError as e:
                console.print(f"[red]Invalid JSON in requirements file: {e}[/red]")
                sys.exit(1)
        
        # Create project
        workflow = DevelopmentWorkflow(args.workflow)
        project = await agent.create_project(
            args.name,
            args.description,
            workflow,
            requirements
        )
        
        console.print(f"\n[bold green]✓ Project created: {project.id}[/bold green]")
        
        # Execute if requested
        if args.execute:
            await execute_project_interactive(agent, project.id)
    
    elif args.command == "execute":
        await execute_project_interactive(agent, args.project_id)
    
    elif args.command == "status":
        display_status(agent)
    
    elif args.command == "projects":
        console.print("\n[bold cyan]Active Projects:[/bold cyan]")
        for proj in agent.active_projects.values():
            prog = proj.get_progress()
            console.print(
                f"  • {proj.id}: {proj.name}\n"
                f"    Phase: {prog['phase']}, Progress: {prog['progress_percent']:.1f}%"
            )
        
        console.print("\n[bold cyan]Completed Projects:[/bold cyan]")
        for proj in agent.completed_projects:
            console.print(f"  • {proj.id}: {proj.name}")
    
    else:
        parser.print_help()


def main():
    """Entry point"""
    try:
        asyncio.run(cli_main())
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted by user[/yellow]")
        sys.exit(0)
    except Exception as e:
        console.print(f"\n[bold red]Error: {e}[/bold red]")
        logger.exception("Unexpected error")
        sys.exit(1)


if __name__ == "__main__":
    main()
