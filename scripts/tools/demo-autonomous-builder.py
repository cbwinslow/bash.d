#!/usr/bin/env python3
"""
Demo: Autonomous Application Builder

This script demonstrates the autonomous application builder system
by simulating a complete build process with all phases.
"""

import asyncio
import sys
from pathlib import Path
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn
from rich.table import Table
from rich import box
from rich.live import Live
from rich.layout import Layout

console = Console()


def print_banner():
    """Print demo banner"""
    banner = """
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║           🤖 AUTONOMOUS APPLICATION BUILDER DEMO 🤖                  ║
║                                                                      ║
║          Watch AI agents build a complete application                ║
║              using democratic problem-solving!                       ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
    """
    console.print(banner, style="bold cyan")


async def demo_democratic_voting():
    """Demonstrate democratic voting process"""
    console.print("\n[bold yellow]Phase: Democratic Architecture Decision[/bold yellow]\n")
    
    # Show proposals
    proposals_table = Table(title="Architecture Proposals", box=box.ROUNDED)
    proposals_table.add_column("Agent", style="cyan")
    proposals_table.add_column("Proposal")
    proposals_table.add_column("Confidence", justify="right")
    
    proposals_table.add_row(
        "Python Architect",
        "Microservices with FastAPI + PostgreSQL",
        "95%"
    )
    proposals_table.add_row(
        "JavaScript Architect",
        "Serverless with Node.js + DynamoDB",
        "88%"
    )
    proposals_table.add_row(
        "Go Architect",
        "Monolith with Go + PostgreSQL",
        "92%"
    )
    
    console.print(proposals_table)
    await asyncio.sleep(2)
    
    # Show voting
    console.print("\n[bold]Agents are voting...[/bold]\n")
    
    votes_table = Table(box=box.SIMPLE)
    votes_table.add_column("Agent", style="cyan")
    votes_table.add_column("Vote", style="green")
    votes_table.add_column("Reasoning")
    
    voters = [
        ("Backend Dev 1", "Microservices", "Best for scalability"),
        ("Backend Dev 2", "Microservices", "Flexible deployment"),
        ("DevOps Agent", "Microservices", "Container-friendly"),
        ("Database Agent", "Microservices", "Good data isolation"),
        ("Security Agent", "Microservices", "Better security boundaries"),
        ("Frontend Dev", "Microservices", "Clean API contracts"),
        ("Testing Agent", "Microservices", "Easier to test"),
    ]
    
    for agent, vote, reasoning in voters:
        votes_table.add_row(agent, vote, reasoning)
        console.print(votes_table)
        await asyncio.sleep(0.3)
    
    console.print("\n[bold green]✓ Consensus reached: Microservices Architecture[/bold green]")
    console.print("[dim]7/7 agents voted for this approach (100% agreement)[/dim]\n")


async def demo_task_decomposition():
    """Demonstrate task decomposition"""
    console.print("\n[bold yellow]Phase: Task Decomposition[/bold yellow]\n")
    
    tasks_table = Table(title="Generated Tasks", box=box.ROUNDED)
    tasks_table.add_column("#", style="cyan", width=4)
    tasks_table.add_column("Task", style="white")
    tasks_table.add_column("Priority", justify="center")
    tasks_table.add_column("Assigned To")
    
    tasks = [
        ("1", "Design database schema", "HIGH", "Database Agent"),
        ("2", "Create API endpoints", "HIGH", "Backend Agent"),
        ("3", "Implement authentication", "CRITICAL", "Security Agent"),
        ("4", "Build frontend UI", "MEDIUM", "UI Agent"),
        ("5", "Write unit tests", "HIGH", "Testing Agent"),
        ("6", "Create Docker containers", "MEDIUM", "DevOps Agent"),
        ("7", "Set up CI/CD pipeline", "LOW", "DevOps Agent"),
        ("8", "Generate API docs", "MEDIUM", "Documentation Agent"),
    ]
    
    for num, task, priority, agent in tasks:
        tasks_table.add_row(num, task, priority, agent)
        await asyncio.sleep(0.2)
    
    console.print(tasks_table)
    console.print("\n[bold green]✓ 8 tasks created and assigned[/bold green]\n")


async def demo_phase_execution(phase_name: str, subtasks: list):
    """Demonstrate a phase execution"""
    console.print(f"\n[bold yellow]Phase: {phase_name}[/bold yellow]\n")
    
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        console=console
    ) as progress:
        
        main_task = progress.add_task(f"[cyan]{phase_name}", total=len(subtasks))
        
        for subtask in subtasks:
            task_id = progress.add_task(f"[white]{subtask}", total=100)
            
            for i in range(0, 101, 20):
                await asyncio.sleep(0.15)
                progress.update(task_id, completed=i)
            
            progress.update(task_id, description=f"[green]✓ {subtask}")
            progress.update(main_task, advance=1)
    
    console.print(f"[bold green]✓ {phase_name} completed[/bold green]\n")


async def demo_testing_and_debugging():
    """Demonstrate testing and automatic debugging"""
    console.print("\n[bold yellow]Phase: Testing[/bold yellow]\n")
    
    console.print("Running test suite...\n")
    
    test_results = Table(box=box.ROUNDED)
    test_results.add_column("Test Suite", style="cyan")
    test_results.add_column("Passed", style="green", justify="right")
    test_results.add_column("Failed", style="red", justify="right")
    test_results.add_column("Coverage", justify="right")
    
    test_results.add_row("Unit Tests", "45", "2", "94%")
    test_results.add_row("Integration Tests", "12", "1", "88%")
    test_results.add_row("E2E Tests", "8", "0", "100%")
    
    console.print(test_results)
    
    console.print("\n[yellow]⚠ 3 tests failed[/yellow]")
    
    await asyncio.sleep(1)
    
    console.print("\n[bold yellow]Phase: Automatic Debugging[/bold yellow]\n")
    console.print("Analyzing failures...\n")
    
    issues = [
        ("TypeError in authentication", "Fixed: Added null check"),
        ("Database connection timeout", "Fixed: Increased timeout"),
        ("Missing validation", "Fixed: Added input validation")
    ]
    
    for issue, fix in issues:
        console.print(f"[red]✗ Issue:[/red] {issue}")
        await asyncio.sleep(0.5)
        console.print(f"[green]✓ {fix}[/green]\n")
        await asyncio.sleep(0.3)
    
    console.print("[bold]Re-running tests...[/bold]\n")
    await asyncio.sleep(1)
    
    test_results_fixed = Table(box=box.ROUNDED)
    test_results_fixed.add_column("Test Suite", style="cyan")
    test_results_fixed.add_column("Passed", style="green", justify="right")
    test_results_fixed.add_column("Failed", style="red", justify="right")
    test_results_fixed.add_column("Coverage", justify="right")
    
    test_results_fixed.add_row("Unit Tests", "47", "0", "96%")
    test_results_fixed.add_row("Integration Tests", "13", "0", "92%")
    test_results_fixed.add_row("E2E Tests", "8", "0", "100%")
    
    console.print(test_results_fixed)
    console.print("\n[bold green]✓ All tests passing! Coverage: 95%[/bold green]\n")


async def demo_build_summary():
    """Show final build summary"""
    console.print("\n[bold green]═══════════════════════════════════════════════════════════[/bold green]")
    console.print("[bold green]           🎉 APPLICATION BUILD COMPLETED! 🎉              [/bold green]")
    console.print("[bold green]═══════════════════════════════════════════════════════════[/bold green]\n")
    
    summary = Table(title="Build Summary", box=box.DOUBLE)
    summary.add_column("Metric", style="cyan")
    summary.add_column("Value", style="green", justify="right")
    
    summary.add_row("Total Phases", "11/11")
    summary.add_row("Tasks Completed", "47")
    summary.add_row("Tests Passed", "68/68")
    summary.add_row("Test Coverage", "95%")
    summary.add_row("Issues Found", "12")
    summary.add_row("Issues Fixed", "12")
    summary.add_row("Files Generated", "156")
    summary.add_row("Build Time", "~5 minutes")
    summary.add_row("Democratic Votes", "3")
    summary.add_row("Agent Collaborations", "24")
    
    console.print(summary)
    
    console.print("\n[bold cyan]Generated Artifacts:[/bold cyan]")
    artifacts = [
        "✓ Backend API (FastAPI + Python)",
        "✓ Frontend UI (React + TypeScript)",
        "✓ Database Schema (PostgreSQL)",
        "✓ Docker Configuration",
        "✓ Test Suite (Unit, Integration, E2E)",
        "✓ API Documentation (OpenAPI)",
        "✓ CI/CD Pipeline (GitHub Actions)",
        "✓ Deployment Scripts"
    ]
    
    for artifact in artifacts:
        console.print(f"  [green]{artifact}[/green]")
    
    console.print("\n[bold cyan]Ready for deployment! 🚀[/bold cyan]\n")


async def run_demo():
    """Run the complete demo"""
    print_banner()
    
    # Show application idea
    idea_panel = Panel.fit(
        "[bold]Task Management API[/bold]\n\n"
        "A RESTful API for managing tasks with user authentication,\n"
        "CRUD operations, and real-time notifications.\n\n"
        "[cyan]Requirements:[/cyan]\n"
        "• User authentication with JWT\n"
        "• CRUD operations for tasks\n"
        "• PostgreSQL database\n"
        "• Real-time WebSocket notifications\n"
        "• API documentation\n",
        title="Application Idea",
        border_style="green"
    )
    console.print(idea_panel)
    
    console.print("\n[bold]🚀 Starting autonomous build process...[/bold]\n")
    await asyncio.sleep(2)
    
    # Phase 1: Democratic voting
    await demo_democratic_voting()
    await asyncio.sleep(1)
    
    # Phase 2: Task decomposition
    await demo_task_decomposition()
    await asyncio.sleep(1)
    
    # Phase 3: Design
    await demo_phase_execution(
        "Design",
        [
            "Create system architecture diagram",
            "Design database schema",
            "Define API endpoints",
            "Create UI mockups"
        ]
    )
    
    # Phase 4: Development
    await demo_phase_execution(
        "Development",
        [
            "Implement authentication system",
            "Create database models",
            "Build API endpoints",
            "Develop frontend components",
            "Integrate WebSocket support"
        ]
    )
    
    # Phase 5: Testing and Debugging
    await demo_testing_and_debugging()
    
    # Phase 6: UI Creation
    await demo_phase_execution(
        "UI Creation",
        [
            "Build component library",
            "Create page layouts",
            "Implement navigation",
            "Apply styling and themes"
        ]
    )
    
    # Phase 7: Integration
    await demo_phase_execution(
        "Integration",
        [
            "Connect frontend to backend",
            "Set up WebSocket connection",
            "Integrate authentication flow",
            "Test end-to-end workflows"
        ]
    )
    
    # Phase 8: Build
    await demo_phase_execution(
        "Build",
        [
            "Create production build",
            "Optimize assets",
            "Generate Docker images",
            "Prepare deployment artifacts"
        ]
    )
    
    # Phase 9: Final Validation
    await demo_phase_execution(
        "Final Validation",
        [
            "Security scan",
            "Performance testing",
            "Accessibility check",
            "Final quality assurance"
        ]
    )
    
    # Show summary
    await demo_build_summary()
    
    console.print("[dim]This was a demonstration. In a real build, agents would generate actual code![/dim]\n")


if __name__ == "__main__":
    try:
        asyncio.run(run_demo())
    except KeyboardInterrupt:
        console.print("\n\n[yellow]Demo interrupted by user[/yellow]")
        sys.exit(0)
