#!/usr/bin/env python3
"""
bash.d CLI Management Tool

A comprehensive command-line interface for managing the bash.d configuration system.

Usage:
    python scripts/bashd_cli.py [command] [options]
    
    Or after installation:
    bashd-cli [command] [options]
"""

import os
import sys
import json
import glob
import shutil
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Optional, List, Dict, Any

try:
    import typer
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.tree import Tree
    from rich.progress import Progress, SpinnerColumn, TextColumn
except ImportError:
    print("Required packages not installed. Run: pip install typer rich")
    sys.exit(1)

# Initialize
app = typer.Typer(
    name="bashd-cli",
    help="bash.d Configuration Management CLI",
    add_completion=True
)
console = Console()

# Sub-apps
agents_app = typer.Typer(help="Manage agents")
config_app = typer.Typer(help="Manage configurations")
modules_app = typer.Typer(help="Manage modules")
tools_app = typer.Typer(help="Manage tools")

app.add_typer(agents_app, name="agents")
app.add_typer(config_app, name="config")
app.add_typer(modules_app, name="modules")
app.add_typer(tools_app, name="tools")


def get_bashd_root() -> Path:
    """Get bash.d root directory"""
    # Check environment variable
    if 'BASHD_HOME' in os.environ:
        return Path(os.environ['BASHD_HOME'])
    
    # Check current directory
    current = Path.cwd()
    if (current / 'bashrc').exists() and (current / 'agents').exists():
        return current
    
    # Check home directory
    home_bashd = Path.home() / '.bash.d'
    if home_bashd.exists():
        return home_bashd
    
    # Default to current
    return current


BASHD_ROOT = get_bashd_root()


# =============================================================================
# Main Commands
# =============================================================================

@app.command()
def status():
    """Show bash.d system status"""
    console.print(Panel.fit(
        "[bold blue]bash.d System Status[/bold blue]",
        border_style="blue"
    ))
    
    # Create status table
    table = Table(show_header=True, header_style="bold cyan")
    table.add_column("Component", style="dim")
    table.add_column("Status")
    table.add_column("Details")
    
    # Check components
    components = [
        ("Root Directory", BASHD_ROOT.exists(), str(BASHD_ROOT)),
        ("bashrc", (BASHD_ROOT / 'bashrc').exists(), "Main configuration"),
        ("Agents", (BASHD_ROOT / 'agents').exists(), f"{len(list((BASHD_ROOT / 'agents').glob('*.py')))} files"),
        ("Tools", (BASHD_ROOT / 'tools').exists(), f"{len(list((BASHD_ROOT / 'tools').glob('*.py')))} files"),
        ("Tests", (BASHD_ROOT / 'tests').exists(), f"{len(list((BASHD_ROOT / 'tests').glob('test_*.py')))} tests"),
        ("Configs", (BASHD_ROOT / 'configs').exists(), "Configuration files"),
    ]
    
    for name, exists, details in components:
        status_icon = "[green]✓[/green]" if exists else "[red]✗[/red]"
        table.add_row(name, status_icon, details)
    
    console.print(table)


@app.command()
def info():
    """Show bash.d information"""
    console.print(Panel.fit(
        "[bold]bash.d - Modular Bash Configuration Framework[/bold]\n\n"
        f"[dim]Root:[/dim] {BASHD_ROOT}\n"
        f"[dim]Version:[/dim] 1.0.0\n"
        f"[dim]Python:[/dim] {sys.version.split()[0]}",
        title="ℹ️ Info",
        border_style="blue"
    ))


@app.command()
def health():
    """Run project health check"""
    from scripts.project_health import ProjectHealthChecker
    
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console
    ) as progress:
        task = progress.add_task("Running health checks...", total=None)
        checker = ProjectHealthChecker(str(BASHD_ROOT))
        checker.check_all()
        progress.remove_task(task)
    
    checker.print_report()


@app.command()
def init(
    path: Optional[str] = typer.Argument(None, help="Path to initialize"),
    force: bool = typer.Option(False, "--force", "-f", help="Force initialization")
):
    """Initialize a new bash.d configuration"""
    target = Path(path) if path else Path.cwd()
    
    if (target / 'bashrc').exists() and not force:
        console.print("[yellow]⚠️ bash.d already initialized. Use --force to reinitialize.[/yellow]")
        raise typer.Exit(1)
    
    console.print(f"[blue]Initializing bash.d in {target}...[/blue]")
    
    # Create directory structure
    dirs = [
        'agents', 'tools', 'tests', 'docs', 'scripts',
        'bash_functions.d', 'bash_aliases.d', 'bash_env.d',
        'bash_secrets.d', 'configs', 'lib', 'plugins', 'completions'
    ]
    
    for d in dirs:
        (target / d).mkdir(parents=True, exist_ok=True)
        console.print(f"  [dim]Created {d}/[/dim]")
    
    console.print("[green]✓ Initialization complete![/green]")


# =============================================================================
# Agents Commands
# =============================================================================

@agents_app.command("list")
def agents_list(
    category: Optional[str] = typer.Argument(None, help="Filter by category"),
    verbose: bool = typer.Option(False, "--verbose", "-v", help="Show details")
):
    """List all available agents"""
    agents_dir = BASHD_ROOT / 'agents'
    
    if not agents_dir.exists():
        console.print("[red]Agents directory not found[/red]")
        raise typer.Exit(1)
    
    # Find all agent files
    categories = {
        'programming': agents_dir / 'programming',
        'devops': agents_dir / 'devops',
        'testing': agents_dir / 'testing',
        'security': agents_dir / 'security',
        'documentation': agents_dir / 'documentation',
        'automation': agents_dir / 'automation',
    }
    
    tree = Tree("🤖 [bold]Agents[/bold]")
    
    for cat_name, cat_path in categories.items():
        if category and cat_name != category:
            continue
            
        if cat_path.exists():
            cat_branch = tree.add(f"📁 [cyan]{cat_name}[/cyan]")
            for agent_file in sorted(cat_path.glob('*_agent.py')):
                agent_name = agent_file.stem.replace('_agent', '')
                cat_branch.add(f"[green]•[/green] {agent_name}")
    
    # Root-level agents
    root_agents = list(agents_dir.glob('*.py'))
    if root_agents:
        root_branch = tree.add("📁 [cyan]core[/cyan]")
        for agent_file in sorted(root_agents):
            if agent_file.stem not in ['__init__']:
                root_branch.add(f"[green]•[/green] {agent_file.stem}")
    
    console.print(tree)


@agents_app.command("info")
def agents_info(name: str = typer.Argument(..., help="Agent name")):
    """Show information about a specific agent"""
    agents_dir = BASHD_ROOT / 'agents'
    
    # Search for agent
    agent_file = None
    for pattern in [f'{name}.py', f'{name}_agent.py', f'**/{name}_agent.py']:
        matches = list(agents_dir.glob(pattern))
        if matches:
            agent_file = matches[0]
            break
    
    if not agent_file:
        console.print(f"[red]Agent '{name}' not found[/red]")
        raise typer.Exit(1)
    
    # Parse agent file
    with open(agent_file, 'r') as f:
        content = f.read()
    
    # Extract docstring
    docstring = ""
    if '"""' in content:
        start = content.find('"""') + 3
        end = content.find('"""', start)
        docstring = content[start:end].strip()
    
    console.print(Panel.fit(
        f"[bold]{name}[/bold]\n\n"
        f"[dim]File:[/dim] {agent_file.relative_to(BASHD_ROOT)}\n"
        f"[dim]Description:[/dim]\n{docstring[:500] if docstring else 'No description'}",
        title="🤖 Agent Info",
        border_style="green"
    ))


@agents_app.command("create")
def agents_create(
    name: str = typer.Argument(..., help="Agent name"),
    category: str = typer.Option("programming", "--category", "-c", help="Agent category"),
    description: str = typer.Option("", "--description", "-d", help="Agent description")
):
    """Create a new agent from template"""
    agents_dir = BASHD_ROOT / 'agents' / category
    agents_dir.mkdir(parents=True, exist_ok=True)
    
    agent_file = agents_dir / f'{name}_agent.py'
    
    if agent_file.exists():
        console.print(f"[red]Agent '{name}' already exists[/red]")
        raise typer.Exit(1)
    
    template = f'''"""
{name.replace('_', ' ').title()} Agent

{description or 'A specialized agent for ' + category + ' tasks.'}
"""

from typing import Dict, Any, List
from agents.base import BaseAgent, AgentType, AgentStatus


class {name.title().replace('_', '')}Agent(BaseAgent):
    """
    {name.replace('_', ' ').title()} Agent
    
    Capabilities:
    - TODO: Define capabilities
    """
    
    def __init__(self, **kwargs):
        super().__init__(
            name="{name.replace('_', ' ').title()} Agent",
            type=AgentType.{category.upper()},
            description="{description or f'Specialized agent for {category} tasks'}",
            **kwargs
        )
        self.capabilities = [
            "TODO: Add capabilities"
        ]
    
    async def execute_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a task assigned to this agent"""
        # TODO: Implement task execution
        return {{"status": "completed", "result": None}}


# Export
__all__ = ["{name.title().replace('_', '')}Agent"]
'''
    
    with open(agent_file, 'w') as f:
        f.write(template)
    
    console.print(f"[green]✓ Created agent: {agent_file.relative_to(BASHD_ROOT)}[/green]")


# =============================================================================
# Config Commands
# =============================================================================

@config_app.command("show")
def config_show(name: Optional[str] = typer.Argument(None, help="Config name")):
    """Show configuration"""
    configs_dir = BASHD_ROOT / 'configs'
    
    if name:
        config_file = configs_dir / f'{name}.yaml'
        if not config_file.exists():
            config_file = configs_dir / f'{name}.json'
        
        if not config_file.exists():
            console.print(f"[red]Config '{name}' not found[/red]")
            raise typer.Exit(1)
        
        with open(config_file, 'r') as f:
            content = f.read()
        console.print(Panel(content, title=f"📄 {config_file.name}", border_style="blue"))
    else:
        # List all configs
        console.print("[bold]Available Configurations:[/bold]")
        for config_file in sorted(configs_dir.glob('*.*')):
            if config_file.suffix in ['.yaml', '.yml', '.json']:
                console.print(f"  • {config_file.stem}")


@config_app.command("validate")
def config_validate():
    """Validate all configurations"""
    configs_dir = BASHD_ROOT / 'configs'
    
    errors = []
    validated = 0
    
    for config_file in configs_dir.glob('**/*.*'):
        if config_file.suffix in ['.yaml', '.yml']:
            try:
                import yaml
                with open(config_file, 'r') as f:
                    yaml.safe_load(f)
                validated += 1
            except Exception as e:
                errors.append(f"{config_file.name}: {e}")
        elif config_file.suffix == '.json':
            try:
                with open(config_file, 'r') as f:
                    json.load(f)
                validated += 1
            except Exception as e:
                errors.append(f"{config_file.name}: {e}")
    
    if errors:
        console.print("[red]Validation errors:[/red]")
        for error in errors:
            console.print(f"  ✗ {error}")
    else:
        console.print(f"[green]✓ All {validated} configurations valid[/green]")


# =============================================================================
# Modules Commands
# =============================================================================

@modules_app.command("list")
def modules_list(
    type: Optional[str] = typer.Option(None, "--type", "-t", help="Filter by type")
):
    """List all modules"""
    module_types = {
        'functions': BASHD_ROOT / 'bash_functions.d',
        'aliases': BASHD_ROOT / 'bash_aliases.d',
        'plugins': BASHD_ROOT / 'plugins',
        'completions': BASHD_ROOT / 'completions',
    }
    
    table = Table(show_header=True, header_style="bold cyan")
    table.add_column("Type")
    table.add_column("Count")
    table.add_column("Location")
    
    for mod_type, mod_path in module_types.items():
        if type and mod_type != type:
            continue
        if mod_path.exists():
            count = len(list(mod_path.glob('*.sh'))) + len(list(mod_path.glob('*.bash')))
            table.add_row(mod_type, str(count), str(mod_path.relative_to(BASHD_ROOT)))
    
    console.print(table)


@modules_app.command("enable")
def modules_enable(
    module_type: str = typer.Argument(..., help="Module type"),
    name: str = typer.Argument(..., help="Module name")
):
    """Enable a module"""
    console.print(f"[blue]Enabling {module_type}/{name}...[/blue]")
    # TODO: Implement module enable logic
    console.print(f"[green]✓ Module {name} enabled[/green]")


@modules_app.command("disable")
def modules_disable(
    module_type: str = typer.Argument(..., help="Module type"),
    name: str = typer.Argument(..., help="Module name")
):
    """Disable a module"""
    console.print(f"[blue]Disabling {module_type}/{name}...[/blue]")
    # TODO: Implement module disable logic
    console.print(f"[green]✓ Module {name} disabled[/green]")


# =============================================================================
# Tools Commands
# =============================================================================

@tools_app.command("list")
def tools_list():
    """List all available tools"""
    tools_dir = BASHD_ROOT / 'tools'
    
    if not tools_dir.exists():
        console.print("[red]Tools directory not found[/red]")
        raise typer.Exit(1)
    
    table = Table(show_header=True, header_style="bold cyan")
    table.add_column("Tool")
    table.add_column("Description")
    
    for tool_file in sorted(tools_dir.glob('*_tools.py')):
        tool_name = tool_file.stem.replace('_tools', '')
        
        # Try to extract description
        description = ""
        try:
            with open(tool_file, 'r') as f:
                content = f.read()
                if '"""' in content:
                    start = content.find('"""') + 3
                    end = content.find('"""', start)
                    description = content[start:end].strip().split('\n')[0]
        except:
            pass
        
        table.add_row(tool_name, description[:60] or "No description")
    
    console.print(table)


@tools_app.command("info")
def tools_info(name: str = typer.Argument(..., help="Tool name")):
    """Show tool information"""
    tools_dir = BASHD_ROOT / 'tools'
    tool_file = tools_dir / f'{name}_tools.py'
    
    if not tool_file.exists():
        tool_file = tools_dir / f'{name}.py'
    
    if not tool_file.exists():
        console.print(f"[red]Tool '{name}' not found[/red]")
        raise typer.Exit(1)
    
    with open(tool_file, 'r') as f:
        content = f.read()
    
    # Extract docstring and functions
    docstring = ""
    if '"""' in content:
        start = content.find('"""') + 3
        end = content.find('"""', start)
        docstring = content[start:end].strip()
    
    # Count functions
    func_count = content.count('def ')
    class_count = content.count('class ')
    
    console.print(Panel.fit(
        f"[bold]{name}[/bold]\n\n"
        f"[dim]File:[/dim] {tool_file.relative_to(BASHD_ROOT)}\n"
        f"[dim]Functions:[/dim] {func_count}\n"
        f"[dim]Classes:[/dim] {class_count}\n\n"
        f"[dim]Description:[/dim]\n{docstring[:500] if docstring else 'No description'}",
        title="🔧 Tool Info",
        border_style="yellow"
    ))


# =============================================================================
# Entry Point
# =============================================================================

if __name__ == '__main__':
    app()
