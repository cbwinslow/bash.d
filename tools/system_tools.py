"""
System and Process Management Tools

This module provides system operation, process management, and monitoring tools
that are OpenAI-compatible and follow the MCP protocol.
"""

from typing import Dict, Any, List, Optional
from .base import BaseTool, ToolCategory, ToolParameter, ToolResult
import subprocess
import os
import platform
import psutil


class GetSystemInfo(BaseTool):
    """Get comprehensive system information."""
    
    def __init__(self):
        super().__init__(
            name="get_system_info",
            category=ToolCategory.MONITORING,
            description="Get comprehensive system information including OS, CPU, memory",
            parameters=[],
            tags=["system", "info", "monitoring"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        return {
            "os": {
                "name": platform.system(),
                "release": platform.release(),
                "version": platform.version(),
                "machine": platform.machine(),
                "processor": platform.processor()
            },
            "python": {
                "version": platform.python_version(),
                "implementation": platform.python_implementation()
            },
            "hostname": platform.node()
        }


class GetCPUInfo(BaseTool):
    """Get CPU information and usage."""
    
    def __init__(self):
        super().__init__(
            name="get_cpu_info",
            category=ToolCategory.MONITORING,
            description="Get CPU information, core count, and usage statistics",
            parameters=[
                ToolParameter(
                    name="per_cpu",
                    type="boolean",
                    description="Get per-CPU statistics",
                    required=False,
                    default=False
                )
            ],
            tags=["cpu", "system", "monitoring"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        per_cpu = kwargs.get("per_cpu", False)
        
        return {
            "physical_cores": psutil.cpu_count(logical=False),
            "logical_cores": psutil.cpu_count(logical=True),
            "cpu_percent": psutil.cpu_percent(interval=1, percpu=per_cpu),
            "cpu_freq": {
                "current": psutil.cpu_freq().current,
                "min": psutil.cpu_freq().min,
                "max": psutil.cpu_freq().max
            } if psutil.cpu_freq() else None
        }


class GetMemoryInfo(BaseTool):
    """Get memory information and usage."""
    
    def __init__(self):
        super().__init__(
            name="get_memory_info",
            category=ToolCategory.MONITORING,
            description="Get memory (RAM) usage statistics",
            parameters=[],
            tags=["memory", "ram", "system", "monitoring"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        mem = psutil.virtual_memory()
        swap = psutil.swap_memory()
        
        return {
            "total_gb": round(mem.total / (1024**3), 2),
            "available_gb": round(mem.available / (1024**3), 2),
            "used_gb": round(mem.used / (1024**3), 2),
            "percent_used": mem.percent,
            "swap": {
                "total_gb": round(swap.total / (1024**3), 2),
                "used_gb": round(swap.used / (1024**3), 2),
                "percent_used": swap.percent
            }
        }


class GetDiskInfo(BaseTool):
    """Get disk usage information."""
    
    def __init__(self):
        super().__init__(
            name="get_disk_info",
            category=ToolCategory.MONITORING,
            description="Get disk usage information for all partitions",
            parameters=[
                ToolParameter(
                    name="path",
                    type="string",
                    description="Specific path to check (optional)",
                    required=False
                )
            ],
            tags=["disk", "storage", "system", "monitoring"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        path = kwargs.get("path", "/")
        
        if path:
            usage = psutil.disk_usage(path)
            return {
                "path": path,
                "total_gb": round(usage.total / (1024**3), 2),
                "used_gb": round(usage.used / (1024**3), 2),
                "free_gb": round(usage.free / (1024**3), 2),
                "percent_used": usage.percent
            }
        else:
            partitions = []
            for partition in psutil.disk_partitions():
                try:
                    usage = psutil.disk_usage(partition.mountpoint)
                    partitions.append({
                        "device": partition.device,
                        "mountpoint": partition.mountpoint,
                        "fstype": partition.fstype,
                        "total_gb": round(usage.total / (1024**3), 2),
                        "used_gb": round(usage.used / (1024**3), 2),
                        "free_gb": round(usage.free / (1024**3), 2),
                        "percent_used": usage.percent
                    })
                except PermissionError:
                    continue
            
            return {
                "partitions": partitions,
                "count": len(partitions)
            }


class GetNetworkInfo(BaseTool):
    """Get network interface information."""
    
    def __init__(self):
        super().__init__(
            name="get_network_info",
            category=ToolCategory.MONITORING,
            description="Get network interface information and statistics",
            parameters=[],
            tags=["network", "system", "monitoring"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        interfaces = []
        
        for interface, addrs in psutil.net_if_addrs().items():
            stats = psutil.net_if_stats().get(interface)
            
            addresses = []
            for addr in addrs:
                addresses.append({
                    "family": str(addr.family),
                    "address": addr.address,
                    "netmask": addr.netmask,
                    "broadcast": addr.broadcast
                })
            
            interfaces.append({
                "name": interface,
                "addresses": addresses,
                "is_up": stats.isup if stats else None,
                "speed": stats.speed if stats else None
            })
        
        # Get network I/O stats
        io_counters = psutil.net_io_counters()
        
        return {
            "interfaces": interfaces,
            "io_counters": {
                "bytes_sent": io_counters.bytes_sent,
                "bytes_recv": io_counters.bytes_recv,
                "packets_sent": io_counters.packets_sent,
                "packets_recv": io_counters.packets_recv
            }
        }


class ListProcesses(BaseTool):
    """List running processes."""
    
    def __init__(self):
        super().__init__(
            name="list_processes",
            category=ToolCategory.MONITORING,
            description="List running processes with CPU and memory usage",
            parameters=[
                ToolParameter(
                    name="sort_by",
                    type="string",
                    description="Sort processes by field",
                    required=False,
                    default="cpu_percent",
                    enum=["cpu_percent", "memory_percent", "name", "pid"]
                ),
                ToolParameter(
                    name="limit",
                    type="integer",
                    description="Maximum number of processes to return",
                    required=False,
                    default=20
                )
            ],
            tags=["process", "system", "monitoring"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        sort_by = kwargs.get("sort_by", "cpu_percent")
        limit = kwargs.get("limit", 20)
        
        processes = []
        
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'status']):
            try:
                pinfo = proc.info
                processes.append({
                    "pid": pinfo['pid'],
                    "name": pinfo['name'],
                    "cpu_percent": pinfo['cpu_percent'],
                    "memory_percent": round(pinfo['memory_percent'], 2),
                    "status": pinfo['status']
                })
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        
        # Sort processes
        processes.sort(key=lambda x: x.get(sort_by, 0), reverse=True)
        
        return {
            "processes": processes[:limit],
            "total_count": len(processes)
        }


class GetProcessInfo(BaseTool):
    """Get detailed information about a specific process."""
    
    def __init__(self):
        super().__init__(
            name="get_process_info",
            category=ToolCategory.MONITORING,
            description="Get detailed information about a specific process by PID",
            parameters=[
                ToolParameter(
                    name="pid",
                    type="integer",
                    description="Process ID",
                    required=True
                )
            ],
            tags=["process", "system", "monitoring"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        pid = kwargs["pid"]
        
        try:
            proc = psutil.Process(pid)
            
            return {
                "pid": proc.pid,
                "name": proc.name(),
                "status": proc.status(),
                "created": proc.create_time(),
                "cpu_percent": proc.cpu_percent(interval=0.1),
                "memory_percent": round(proc.memory_percent(), 2),
                "memory_info": {
                    "rss_mb": round(proc.memory_info().rss / (1024**2), 2),
                    "vms_mb": round(proc.memory_info().vms / (1024**2), 2)
                },
                "num_threads": proc.num_threads(),
                "username": proc.username(),
                "cmdline": proc.cmdline()
            }
        except psutil.NoSuchProcess:
            raise ValueError(f"Process {pid} not found")
        except psutil.AccessDenied:
            raise ValueError(f"Access denied to process {pid}")


class KillProcess(BaseTool):
    """Terminate a process."""
    
    def __init__(self):
        super().__init__(
            name="kill_process",
            category=ToolCategory.BUILD,
            description="Terminate a process by PID",
            parameters=[
                ToolParameter(
                    name="pid",
                    type="integer",
                    description="Process ID to terminate",
                    required=True
                ),
                ToolParameter(
                    name="force",
                    type="boolean",
                    description="Force kill (SIGKILL) instead of graceful termination",
                    required=False,
                    default=False
                )
            ],
            tags=["process", "kill", "system"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        pid = kwargs["pid"]
        force = kwargs.get("force", False)
        
        try:
            proc = psutil.Process(pid)
            name = proc.name()
            
            if force:
                proc.kill()
            else:
                proc.terminate()
            
            return {
                "success": True,
                "pid": pid,
                "name": name,
                "method": "kill" if force else "terminate"
            }
        except psutil.NoSuchProcess:
            raise ValueError(f"Process {pid} not found")
        except psutil.AccessDenied:
            raise ValueError(f"Access denied to process {pid}")


class RunCommand(BaseTool):
    """Execute a shell command."""
    
    def __init__(self):
        super().__init__(
            name="run_command",
            category=ToolCategory.BUILD,
            description="Execute a shell command and return output",
            parameters=[
                ToolParameter(
                    name="command",
                    type="string",
                    description="Command to execute",
                    required=True
                ),
                ToolParameter(
                    name="shell",
                    type="boolean",
                    description="Execute through shell",
                    required=False,
                    default=True
                ),
                ToolParameter(
                    name="timeout",
                    type="integer",
                    description="Timeout in seconds",
                    required=False,
                    default=30
                ),
                ToolParameter(
                    name="cwd",
                    type="string",
                    description="Working directory",
                    required=False
                )
            ],
            tags=["command", "shell", "execute", "system"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        command = kwargs["command"]
        shell = kwargs.get("shell", True)
        timeout = kwargs.get("timeout", 30)
        cwd = kwargs.get("cwd")
        
        result = subprocess.run(
            command,
            shell=shell,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=cwd
        )
        
        return {
            "command": command,
            "return_code": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "success": result.returncode == 0
        }


class GetEnvironmentVariable(BaseTool):
    """Get environment variable value."""
    
    def __init__(self):
        super().__init__(
            name="get_environment_variable",
            category=ToolCategory.BUILD,
            description="Get the value of an environment variable",
            parameters=[
                ToolParameter(
                    name="variable_name",
                    type="string",
                    description="Name of the environment variable",
                    required=True
                ),
                ToolParameter(
                    name="default",
                    type="string",
                    description="Default value if variable not set",
                    required=False
                )
            ],
            tags=["env", "environment", "system"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        variable_name = kwargs["variable_name"]
        default = kwargs.get("default")
        
        value = os.getenv(variable_name, default)
        
        return {
            "variable_name": variable_name,
            "value": value,
            "is_set": variable_name in os.environ
        }


class SetEnvironmentVariable(BaseTool):
    """Set environment variable."""
    
    def __init__(self):
        super().__init__(
            name="set_environment_variable",
            category=ToolCategory.BUILD,
            description="Set an environment variable",
            parameters=[
                ToolParameter(
                    name="variable_name",
                    type="string",
                    description="Name of the environment variable",
                    required=True
                ),
                ToolParameter(
                    name="value",
                    type="string",
                    description="Value to set",
                    required=True
                )
            ],
            tags=["env", "environment", "system"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        variable_name = kwargs["variable_name"]
        value = kwargs["value"]
        
        os.environ[variable_name] = value
        
        return {
            "variable_name": variable_name,
            "value": value,
            "success": True
        }


class GetUptime(BaseTool):
    """Get system uptime."""
    
    def __init__(self):
        super().__init__(
            name="get_uptime",
            category=ToolCategory.MONITORING,
            description="Get system uptime in seconds and formatted string",
            parameters=[],
            tags=["uptime", "system", "monitoring"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        import time
        from datetime import timedelta
        
        try:
            boot_time = psutil.boot_time()
        except:
            boot_time = 0
        uptime_seconds = time.time() - boot_time
        uptime_delta = timedelta(seconds=int(uptime_seconds))
        
        return {
            "uptime_seconds": int(uptime_seconds),
            "uptime_formatted": str(uptime_delta),
            "boot_time": boot_time
        }


class GetLoadAverage(BaseTool):
    """Get system load average."""
    
    def __init__(self):
        super().__init__(
            name="get_load_average",
            category=ToolCategory.MONITORING,
            description="Get system load average (1, 5, 15 minutes)",
            parameters=[],
            tags=["load", "system", "monitoring"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        load1, load5, load15 = psutil.getloadavg()
        cpu_count = psutil.cpu_count()
        
        return {
            "load_1min": round(load1, 2),
            "load_5min": round(load5, 2),
            "load_15min": round(load15, 2),
            "cpu_count": cpu_count,
            "load_per_cpu": {
                "1min": round(load1 / cpu_count, 2),
                "5min": round(load5 / cpu_count, 2),
                "15min": round(load15 / cpu_count, 2)
            }
        }


class GetBatteryStatus(BaseTool):
    """Get battery status (for laptops)."""
    
    def __init__(self):
        super().__init__(
            name="get_battery_status",
            category=ToolCategory.MONITORING,
            description="Get battery status and charge level (for devices with battery)",
            parameters=[],
            tags=["battery", "power", "system", "monitoring"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        battery = psutil.sensors_battery()
        
        if battery is None:
            return {
                "has_battery": False,
                "message": "No battery detected"
            }
        
        from datetime import timedelta
        
        return {
            "has_battery": True,
            "percent": battery.percent,
            "plugged_in": battery.power_plugged,
            "time_left_seconds": battery.secsleft if battery.secsleft != psutil.POWER_TIME_UNLIMITED else None,
            "time_left_formatted": str(timedelta(seconds=battery.secsleft)) if battery.secsleft > 0 and battery.secsleft != psutil.POWER_TIME_UNLIMITED else None
        }
