#!/usr/bin/env python3
"""
Terminal Dashboard using Textual.
Shows real-time hardware and network metrics.
"""

import asyncio
from datetime import datetime
from typing import Optional

import psutil
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.widgets import Header, Footer, Static, ProgressBar, DataTable
from textual.widget import Widget
from textual.widgets.data_table import RowKey

# Import db
from db import get_database_url, HardwareMetric, NetworkMetric, SystemEvent, Conversation


class MetricCard(Widget):
    """Display a single metric with label and value."""
    
    def __init__(self, label: str, **kwargs):
        super().__init__(**kwargs)
        self.label = label
        self.value = "N/A"
    
    def update(self, value: str):
        """Update the displayed value."""
        self.value = value
        self.refresh()
    
    def compose(self) -> ComposeResult:
        yield Static(f"{self.label}: {self.value}", id="value")


class HardwarePanel(Vertical):
    """Hardware metrics panel."""
    
    def compose(self) -> ComposeResult:
        yield Static("🖥️  Hardware", classes="panel-title")
        
        yield Horizontal(
            MetricCard("CPU", id="cpu"),
            MetricCard("Memory", id="memory"),
            MetricCard("Disk", id="disk"),
            classes="metrics-row"
        )


class NetworkPanel(Vertical):
    """Network metrics panel."""
    
    def compose(self) -> ComposeResult:
        yield Static("🌐  Network", classes="panel-title")
        
        yield Horizontal(
            MetricCard("Sent", id="net-sent"),
            MetricCard("Recv", id="net-recv"),
            MetricCard("TCP", id="tcp"),
            MetricCard("UDP", id="udp"),
            classes="metrics-row"
        )


class GPUPanel(Vertical):
    """GPU metrics panel."""
    
    def compose(self) -> ComposeResult:
        yield Static("🎮  GPU", classes="panel-title")
        
        yield Horizontal(
            MetricCard("GPU%", id="gpu"),
            MetricCard("VRAM", id="vram"),
            MetricCard("Temp", id="gpu-temp"),
            classes="metrics-row"
        )


class EventsTable(Vertical):
    """System events table."""
    
    def compose(self) -> ComposeResult:
        yield Static("⚠️  Events", classes="panel-title")
        table = DataTable(id="events")
        table.add_columns("Time", "Severity", "Source", "Message")
        yield table


class ConversationsPanel(Vertical):
    """Recent AI conversations."""
    
    def compose(self) -> ComposeResult:
        yield Static("💬  Conversations", classes="panel-title")
        table = DataTable(id="conversations")
        table.add_columns("Time", "Tool", "Model", "Prompt")
        yield table


class Dashboard(App):
    """Main dashboard application."""
    
    CSS = """
    Screen {
        background: $surface;
    }
    
    .panel-title {
        text-style: bold;
        color: $accent;
        margin-bottom: 1;
    }
    
    .metrics-row {
        height: 3;
    }
    
    #cpu, #memory, #disk, #net-sent, #net-recv, #tcp, #udp, #gpu, #vram, #gpu-temp {
        content-align: center middle;
        width: 1fr;
        border: solid $border;
        padding: 1;
        margin: 1;
    }
    
    #events, #conversations {
        height: 10;
    }
    
    DataTable {
        margin: 1;
    }
    """
    
    def __init__(self):
        super().__init__()
        self.engine = None
        self.running = True
    
    def compose(self) -> ComposeResult:
        yield Header()
        
        yield Horizontal(
            Vertical(
                HardwarePanel(),
                NetworkPanel(),
                GPUPanel(),
                id="left-panel"
            ),
            Vertical(
                EventsTable(),
                ConversationsPanel(),
                id="right-panel"
            ),
            id="main"
        )
        
        yield Footer()
    
    async def on_mount(self):
        """Start the dashboard."""
        # Connect to database
        self.engine = create_async_engine(
            get_database_url(),
            echo=False
        )
        
        # Start update loop
        self.update_loop = asyncio.create_task(self.update_loop())
    
    async def update_loop(self):
        """Update metrics every 2 seconds."""
        while self.running:
            try:
                await self.update_metrics()
            except Exception as e:
                print(f"Error updating: {e}")
            
            await asyncio.sleep(2)
    
    async def update_metrics(self):
        """Update all metrics from database."""
        
        # Hardware
        try:
            async with AsyncSession(self.engine) as session:
                # Get latest hardware
                result = await session.execute(
                    select(HardwareMetric).order_by(HardwareMetric.timestamp.desc()).limit(1)
                )
                hw = result.scalar_one_or_none()
                
                if hw:
                    # Update CPU
                    cpu_widget = self.query_one("#cpu", Static)
                    cpu_widget.update(f"CPU: {hw.cpu_percent:.1f}%")
                    
                    # Update Memory
                    mem_widget = self.query_one("#memory", Static)
                    mem_widget.update(f"MEM: {hw.memory_percent:.1f}%")
                    
                    # Update Disk
                    disk_widget = self.query_one("#disk", Static)
                    disk_widget.update(f"DISK: {hw.disk_percent:.1f}%")
                    
                    # Update GPU
                    gpu_widget = self.query_one("#gpu", Static)
                    if hw.gpu_percent:
                        gpu_widget.update(f"GPU: {hw.gpu_percent:.1f}%")
                    else:
                        gpu_widget.update("GPU: N/A")
                    
                    # Update VRAM
                    vram_widget = self.query_one("#vram", Static)
                    if hw.gpu_memory_used and hw.gpu_memory_total:
                        vram_widget.update(f"VRAM: {hw.gpu_memory_used:.1f}/{hw.gpu_memory_total:.1f}GB")
                    else:
                        vram_widget.update("VRAM: N/A")
                    
                    # Update GPU Temp
                    temp_widget = self.query_one("#gpu-temp", Static)
                    if hw.gpu_temperature:
                        temp_widget.update(f"Temp: {hw.gpu_temperature}°C")
                    else:
                        temp_widget.update("Temp: N/A")
                
                # Get latest network
                result = await session.execute(
                    select(NetworkMetric).order_by(NetworkMetric.timestamp.desc()).limit(1)
                )
                net = result.scalar_one_or_none()
                
                if net:
                    # Update network widgets
                    sent_widget = self.query_one("#net-sent", Static)
                    recv_widget = self.query_one("#net-recv", Static)
                    tcp_widget = self.query_one("#tcp", Static)
                    udp_widget = self.query_one("#udp", Static)
                    
                    sent_widget.update(f"↑ {self.format_bytes(net.bytes_sent)}")
                    recv_widget.update(f"↓ {self.format_bytes(net.bytes_recv)}")
                    tcp_widget.update(f"TCP: {net.tcp_connections}")
                    udp_widget.update(f"UDP: {net.udp_connections}")
                
                # Get recent events
                result = await session.execute(
                    select(SystemEvent).order_by(SystemEvent.timestamp.desc()).limit(5)
                )
                events = result.scalars().all()
                
                events_table = self.query_one("#events", DataTable)
                events_table.clear()
                for event in events:
                    events_table.add_row(
                        event.timestamp.strftime("%H:%M:%S"),
                        event.severity.upper(),
                        event.source,
                        event.message[:50]
                    )
                
                # Get recent conversations
                result = await session.execute(
                    select(Conversation).order_by(Conversation.timestamp.desc()).limit(5)
                )
                convs = result.scalars().all()
                
                conv_table = self.query_one("#conversations", DataTable)
                conv_table.clear()
                for conv in convs:
                    conv_table.add_row(
                        conv.timestamp.strftime("%H:%M:%S"),
                        conv.tool,
                        conv.model or "N/A",
                        conv.prompt[:40] + "..." if len(conv.prompt) > 40 else conv.prompt
                    )
                    
        except Exception as e:
            print(f"DB Error: {e}")
    
    def format_bytes(self, bytes_val: int) -> str:
        """Format bytes to human readable."""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_val < 1024.0:
                return f"{bytes_val:.1f}{unit}"
            bytes_val /= 1024.0
        return f"{bytes_val:.1f}PB"
    
    def on_unmount(self):
        """Clean up."""
        self.running = False
        if self.engine:
            asyncio.create_task(self.engine.dispose())


class LiveMonitor(App):
    """Simple live monitor without database."""
    
    CSS = """
    Screen {
        background: $surface;
    }
    
    .metric {
        width: 1fr;
        height: 5;
        border: solid $border;
        content-align: center middle;
    }
    
    .metric-label {
        color: $text-muted;
    }
    
    .metric-value {
        text-style: bold;
        color: $accent;
        font-size: 2;
    }
    """
    
    def compose(self) -> ComposeResult:
        yield Header()
        
        yield Horizontal(
            Container(Static("CPU", classes="metric-label"), Static("0%", id="cpu-value", classes="metric-value"), classes="metric", id="cpu"),
            Container(Static("Memory", classes="metric-label"), Static("0%", id="mem-value", classes="metric-value"), classes="metric", id="memory"),
            Container(Static("Disk", classes="metric-label"), Static("0%", id="disk-value", classes="metric-value"), classes="metric", id="disk"),
            Container(Static("Network ↑", classes="metric-label"), Static("0B", id="net-up-value", classes="metric-value"), classes="metric", id="net-up"),
            Container(Static("Network ↓", classes="metric-label"), Static("0B", id="net-down-value", classes="metric-value"), classes="metric", id="net-down"),
        )
        
        yield Footer()
    
    async def on_mount(self):
        """Start monitoring."""
        self.prev_net = psutil.net_io_counters()
        self.update_loop = asyncio.create_task(self.update_loop())
    
    async def update_loop(self):
        """Update metrics."""
        while True:
            # CPU
            cpu = psutil.cpu_percent(interval=0.5)
            self.query_one("#cpu-value", Static).update(f"{cpu:.1f}%")
            
            # Memory
            mem = psutil.virtual_memory()
            self.query_one("#mem-value", Static).update(f"{mem.percent:.1f}%")
            
            # Disk
            disk = psutil.disk_usage('/')
            self.query_one("#disk-value", Static).update(f"{disk.percent:.1f}%")
            
            # Network
            net = psutil.net_io_counters()
            if self.prev_net:
                up = net.bytes_sent - self.prev_net.bytes_sent
                down = net.prev_net.bytes_recv.bytes_recv - self
                self.query_one("#net-up-value", Static).update(self.format_bytes(up))
                self.query_one("#net-down-value", Static).update(self.format_bytes(down))
            
            self.prev_net = net
            
            await asyncio.sleep(1)
    
    def format_bytes(self, bytes_val: int) -> str:
        """Format bytes."""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if bytes_val < 1024.0:
                return f"{bytes_val:.1f}{unit}"
            bytes_val /= 1024.0
        return f"{bytes_val:.1f}GB"


def main():
    """Entry point."""
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "--live":
        # Simple live monitor without DB
        app = LiveMonitor()
    else:
        # Full dashboard with DB
        app = Dashboard()
    
    app.run()


if __name__ == "__main__":
    main()
