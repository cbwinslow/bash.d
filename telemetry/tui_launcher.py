#!/usr/bin/env python3
"""
Unified TUI Launcher for bash.d
A beautiful terminal menu to access all scripts and tools.
"""

from textual.app import App, ComposeResult
from textual.containers import Container, VerticalScroll, Horizontal
from textual.widgets import Header, Footer, Static, Button, ListView, ListItem, Label
from textual.binding import Binding
import subprocess
import os

# Get bash.d directory
BASHD_DIR = os.path.expanduser("~/bash.d")

# Define all menu items
MENU_ITEMS = [
    ("System", [
        ("sys-analyze", "Analyze system processes & memory", "scripts/system_analyzer.sh"),
        ("sysmon", "Continuous system monitor", "scripts/monitor.sh"),
        ("ai-sys", "AI System Agent", "scripts/ai_sys_agent.sh"),
    ]),
    ("Inventory & Backup", [
        ("inventory", "System inventory", "scripts/inventory.sh"),
        ("backup", "Backup system", "scripts/backup.sh"),
    ]),
    ("AI Agents", [
        ("ai", "AI Agent (general)", "scripts/ai_agent.sh"),
        ("ai-chat", "AI Chat", "scripts/ai_agent.sh chat"),
        ("ai-code", "AI Code Helper", "scripts/ai_agent.sh code"),
    ]),
    ("API & Cloud", [
        ("github-api", "GitHub API", "apis/api_manager.sh github"),
        ("cf-api", "Cloudflare API", "apis/api_manager.sh cloudflare"),
    ]),
    ("Utilities", [
        ("chatlog", "Conversation Logger", "scripts/conversation_logger.sh"),
        ("dockerps", "Docker PS", "docker ps"),
    ]),
    ("Telemetry", [
        ("telemetry-db", "View telemetry DB", "docker exec telemetry-postgres psql -U cbwinslow -d telemetry"),
    ]),
]

class MenuItem(ListItem):
    """A clickable menu item."""
    
    def __init__(self, name: str, description: str, command: str):
        super().__init__()
        self.name = name
        self.description = description
        self.command = command
    
    def compose(self) -> ComposeResult:
        yield Label(f"[b]{self.name}[/b] - {self.description}", markup=True)


class LauncherApp(App):
    """Unified bash.d Launcher TUI."""
    
    CSS = """
    Screen {
        background: $surface;
    }
    
    #sidebar {
        width: 30;
        background: $panel;
        border-right: solid $border;
    }
    
    #main {
        padding: 1 2;
    }
    
    ListView {
        height: 100%;
        border: none;
    }
    
    ListItem {
        padding: 0 1;
    }
    
    ListItem:hover {
        background: $accent;
    }
    
    #title {
        text-align: center;
        background: $primary;
        color: $text;
        padding: 1;
    }
    
    #info-panel {
        dock: bottom;
        height: 3;
        background: $panel;
        border-top: solid $border;
    }
    
    Button {
        margin: 1;
    }
    """
    
    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("r", "run_selected", "Run"),
        Binding("escape", "quit", "Quit"),
    ]
    
    def __init__(self):
        super().__init__()
        self.selected_command = None
    
    def compose(self) -> ComposeResult:
        yield Header()
        
        with Container(id="sidebar"):
            yield Static("🎯 bash.d\nLauncher", id="title")
            yield ListView(id="menu")
        
        with Container(id="main"):
            yield Static("Welcome to bash.d!", id="welcome")
            yield Static("Select an option from the menu and press [b]Enter[/b] or [b]r[/b] to run.", id="instructions")
        
        yield Footer()
    
    def on_mount(self) -> None:
        """Populate menu on mount."""
        menu = self.query_one("#menu", ListView)
        
        for category, items in MENU_ITEMS:
            # Add category header as a disabled item
            menu.append(ListItem(Static(f"━━━ {category} ━━━", markup=True)))
            
            for name, description, command in items:
                menu.append(MenuItem(name, description, command))
    
    def on_list_view_selected(self, event: ListItem) -> None:
        """Handle item selection."""
        if isinstance(event.item, MenuItem):
            self.selected_command = event.item.command
            self.query_one("#instructions", Static).update(
                f"Selected: [b]{event.item.name}[/b]\nPress [b]r[/b] to run or [b]Enter[/b]"
            )
    
    def action_run_selected(self) -> None:
        """Run the selected command."""
        if self.selected_command:
            self.run_command(self.selected_command)
    
    def run_command(self, command: str) -> None:
        """Execute a command."""
        self.exit(message=f"Running: {command}")
        # In a real implementation, you'd run this
        # For now, just print what would run
        print(f"\n🔄 Running: {command}\n")
        
        # Actually run the command
        os.system(command)


class SimpleLauncher(App):
    """Simpler launcher - just a list."""
    
    CSS = """
    Screen {
        background: $surface;
    }
    
    ListView {
        height: 100%;
        margin: 1 2;
    }
    
    ListItem {
        padding: 0 2;
    }
    """
    
    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("enter", "run_item", "Run"),
        Binding("escape", "quit", "Quit"),
    ]
    
    def compose(self) -> ComposeResult:
        yield Header("🎯 bash.d Launcher", show_clock=True)
        
        with ListView(id="menu"):
            for category, items in MENU_ITEMS:
                yield ListItem(Static(f"━━━ {category} ━━━", markup=True, classes="category"))
                
                for name, description, command in items:
                    yield MenuItem(name, description, command)
        
        yield Footer()
    
    def on_mount(self) -> None:
        menu = self.query_one("#menu", ListView)
        # Focus the first real item (skip category header)
        menu.index = 1
    
    def action_run_item(self) -> None:
        """Run the selected item."""
        menu = self.query_one("#menu", ListView)
        try:
            item = menu.index
            selected = menu.children[item]
            
            if isinstance(selected, MenuItem):
                command = selected.command
                print(f"\n🔄 Running: {command}\n")
                os.system(command)
        except Exception as e:
            print(f"Error: {e}")


if __name__ == "__main__":
    # Try simple launcher first
    try:
        app = SimpleLauncher()
        app.run()
    except Exception as e:
        print(f"Textual not available or error: {e}")
        print("\n=== bash.d Menu ===")
        print("Use these commands instead:\n")
        
        for category, items in MENU_ITEMS:
            print(f"\n━━━ {category} ━━━")
            for name, description, command in items:
                print(f"  {name:15} - {description}")
        
        print("\nOr run: sys-analyze, sysmon, ai-sys, etc.")
