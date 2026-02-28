#!/usr/bin/env python3
"""
Telemetry collector - gathers hardware and network metrics.
Can run as a background service.
"""

import asyncio
import os
import sys
import signal
from datetime import datetime
from typing import Optional

import psutil
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

# Import our db module
from db import (
    get_database_url, Base, HardwareMetric, NetworkMetric, SystemEvent,
    save_hardware_metric, save_network_metric, save_system_event
)


class TelemetryCollector:
    """Main telemetry collector class."""
    
    def __init__(self, interval: int = 10):
        self.interval = interval  # seconds
        self.running = False
        self.engine = None
        
        # Track previous network counters for delta calculations
        self.prev_net = None
        
        # Track boot time
        self.boot_time = datetime.fromtimestamp(psutil.boot_time())
        
    async def start(self):
        """Start the collector."""
        print(f"Starting telemetry collector (interval: {self.interval}s)")
        
        # Create engine
        self.engine = create_async_engine(
            get_database_url(),
            echo=False
        )
        
        # Create tables
        async with self.engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        self.running = True
        
        # Collect immediately
        await self.collect_all()
        
        # Then collect on interval
        while self.running:
            await asyncio.sleep(self.interval)
            await self.collect_all()
    
    async def stop(self):
        """Stop the collector."""
        print("Stopping telemetry collector...")
        self.running = False
        if self.engine:
            await self.engine.dispose()
    
    async def collect_all(self):
        """Collect all metrics."""
        try:
            await self.collect_hardware()
            await self.collect_network()
        except Exception as e:
            print(f"Error collecting metrics: {e}")
    
    async def collect_hardware(self):
        """Collect hardware metrics."""
        # CPU
        cpu_percent = psutil.cpu_percent(interval=0.1)
        cpu_count = psutil.cpu_count()
        cpu_freq = psutil.cpu_freq()
        cpu_freq_mhz = cpu_freq.current if cpu_freq else None
        
        # Memory
        mem = psutil.virtual_memory()
        
        # Disk
        disk = psutil.disk_usage('/')
        
        # Temperature (if available)
        temp = None
        try:
            temps = psutil.sensors_temperatures()
            for name, entries in temps.items():
                if entries:
                    temp = entries[0].current
                    break
        except Exception:
            pass
        
        # GPU (if available)
        gpu_percent = None
        gpu_mem_used = None
        gpu_mem_total = None
        gpu_temp = None
        
        try:
            import pynvml
            pynvml.nvmlInit()
            handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            util = pynvml.nvmlDeviceGetUtilizationRates(handle)
            mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
            gpu_percent = util.gpu
            gpu_mem_used = mem_info.used / (1024**3)  # GB
            gpu_mem_total = mem_info.total / (1024**3)  # GB
            
            # Temperature
            try:
                gpu_temp = pynvml.nvmlDeviceGetTemperature(handle, pynvml.NVML_TEMPERATURE_GPU)
            except Exception:
                pass
            
            pynvml.nvmlShutdown()
        except Exception:
            pass
        
        # Build metric data
        data = {
            'timestamp': datetime.utcnow(),
            'cpu_percent': cpu_percent,
            'cpu_count': cpu_count,
            'cpu_freq': cpu_freq_mhz,
            'memory_total': mem.total / (1024**3),  # GB
            'memory_used': mem.used / (1024**3),
            'memory_percent': mem.percent,
            'disk_total': disk.total / (1024**3),
            'disk_used': disk.used / (1024**3),
            'disk_percent': disk.percent,
            'temperature': temp,
            'gpu_percent': gpu_percent,
            'gpu_memory_used': gpu_mem_used,
            'gpu_memory_total': gpu_mem_total,
            'gpu_temperature': gpu_temp,
            'boot_time': self.boot_time,
        }
        
        # Check for warnings
        if cpu_percent > 90:
            await self.log_event('warning', 'high', 'cpu', f'CPU usage at {cpu_percent}%')
        if mem.percent > 90:
            await self.log_event('warning', 'high', 'memory', f'Memory usage at {mem.percent}%')
        if disk.percent > 90:
            await self.log_event('warning', 'high', 'disk', f'Disk usage at {disk.percent}%')
        
        # Save to database
        async with AsyncSession(self.engine) as session:
            await save_hardware_metric(session, data)
        
        print(f"[{datetime.now().strftime('%H:%M:%S')}] CPU: {cpu_percent}% | MEM: {mem.percent}% | DISK: {disk.percent}%")
    
    async def collect_network(self):
        """Collect network metrics."""
        net = psutil.net_io_counters()
        
        # Calculate delta if we have previous data
        if self.prev_net:
            bytes_sent_delta = net.bytes_sent - self.prev_net.bytes_sent
            bytes_recv_delta = net.bytes_recv - self.prev_net.bytes_recv
        else:
            bytes_sent_delta = 0
            bytes_recv_delta = 0
        
        self.prev_net = net
        
        # Count connections
        connections = psutil.net_connections()
        tcp_count = sum(1 for c in connections if c.type == 1)  # TCP
        udp_count = sum(1 for c in connections if c.type == 2)  # UDP
        established = sum(1 for c in connections if c.state == 'ESTABLISHED')
        
        # Per-interface stats
        per_nic = psutil.net_io_counters(pernic=True)
        interfaces = {}
        for name, stats in per_nic.items():
            interfaces[name] = {
                'bytes_sent': stats.bytes_sent,
                'bytes_recv': stats.bytes_recv,
                'packets_sent': stats.packets_sent,
                'packets_recv': stats.packets_recv,
            }
        
        data = {
            'timestamp': datetime.utcnow(),
            'bytes_sent': net.bytes_sent,
            'bytes_recv': net.bytes_recv,
            'packets_sent': net.packets_sent,
            'packets_recv': net.packets_recv,
            'errin': net.errin,
            'errout': net.errout,
            'dropin': net.dropin,
            'dropout': net.dropout,
            'tcp_connections': tcp_count,
            'udp_connections': udp_count,
            'established_connections': established,
            'interfaces': interfaces,
        }
        
        # Check for issues
        if net.errin > 0:
            await self.log_event('warning', 'medium', 'network', f'Network errors: {net.errin} in, {net.errout} out')
        if net.dropin > 0:
            await self.log_event('warning', 'medium', 'network', f'Packets dropped: {net.dropin} in, {net.dropout} out')
        
        async with AsyncSession(self.engine) as session:
            await save_network_metric(session, data)
    
    async def log_event(self, event_type: str, severity: str, source: str, message: str):
        """Log a system event."""
        data = {
            'event_type': event_type,
            'severity': severity,
            'source': source,
            'message': message,
            'timestamp': datetime.utcnow(),
        }
        
        async with AsyncSession(self.engine) as session:
            await save_system_event(session, **data)


# ====================
# CLI
# ====================

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Telemetry Collector')
    parser.add_argument('--interval', '-i', type=int, default=10, 
                       help='Collection interval in seconds (default: 10)')
    parser.add_argument('--once', '-o', action='store_true',
                       help='Collect once and exit')
    
    args = parser.parse_args()
    
    collector = TelemetryCollector(interval=args.interval)
    
    # Handle signals
    def signal_handler(sig, frame):
        asyncio.create_task(collector.stop())
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    if args.once:
        asyncio.run(collector.collect_all())
    else:
        asyncio.run(collector.start())


if __name__ == "__main__":
    main()
