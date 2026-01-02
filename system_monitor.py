#!/usr/bin/env python3
"""
Advanced System Monitor with Alerts
Customized for the user's specific system issues
"""

import os
import sys
import time
import psutil
import subprocess
import curses
from datetime import datetime
from collections import deque
import json
import socket


class SystemMonitor:
    def __init__(self):
        self.hostname = socket.gethostname()
        self.alert_history = deque(maxlen=50)
        self.thresholds = {
            "memory_percent": 80,
            "memory_gb": 70,
            "cpu_percent": 90,
            "disk_percent": 85,
            "load_1min": 10.0,
            "swap_percent": 50,
            "process_memory_mb": 2000,  # Alert for single process >2GB
        }
        self.problematic_processes = ["ollama", "docker", "proton.vpn", "code", "node"]
        self.colors = {"normal": 1, "warning": 3, "critical": 1, "header": 4, "good": 2}

    def get_system_info(self):
        """Collect comprehensive system information"""
        info = {
            "timestamp": datetime.now().strftime("%H:%M:%S"),
            "memory": psutil.virtual_memory(),
            "swap": psutil.swap_memory(),
            "cpu": psutil.cpu_percent(interval=1, percpu=True),
            "cpu_avg": psutil.cpu_percent(interval=1),
            "load_avg": os.getloadavg(),
            "disk": psutil.disk_usage("/"),
            "processes": self.get_problematic_processes(),
            "temperature": self.get_temperature(),
            "network": self.get_network_info(),
        }
        return info

    def get_problematic_processes(self):
        """Monitor memory-intensive processes"""
        processes = []
        for proc in psutil.process_iter(
            ["pid", "name", "memory_percent", "memory_info", "cpu_percent"]
        ):
            try:
                if (
                    proc.info["memory_percent"] > 5
                ):  # Only show processes using >5% memory
                    processes.append(proc.info)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue

        # Sort by memory usage
        processes.sort(key=lambda x: x["memory_percent"], reverse=True)
        return processes[:15]  # Top 15 processes

    def get_temperature(self):
        """Get system temperature if available"""
        try:
            temps = psutil.sensors_temperatures()
            if temps:
                # Return highest temperature
                highest_temp = 0
                for name, entries in temps.items():
                    for entry in entries:
                        if entry.current and entry.current > highest_temp:
                            highest_temp = entry.current
                return highest_temp
        except:
            pass
        return None

    def get_network_info(self):
        """Get network connection info"""
        try:
            net_io = psutil.net_io_counters()
            return {
                "bytes_sent": net_io.bytes_sent,
                "bytes_recv": net_io.bytes_recv,
                "packets_sent": net_io.packets_sent,
                "packets_recv": net_io.packets_recv,
            }
        except:
            return None

    def check_alerts(self, info):
        """Check for system alerts based on thresholds"""
        alerts = []

        # Memory alerts
        if info["memory"].percent > self.thresholds["memory_percent"]:
            alerts.append(
                {
                    "level": "critical" if info["memory"].percent > 90 else "warning",
                    "message": f"High memory usage: {info['memory'].percent:.1f}%",
                    "type": "memory",
                }
            )

        if info["memory"].used / (1024**3) > self.thresholds["memory_gb"]:
            alerts.append(
                {
                    "level": "critical",
                    "message": f"Memory >{self.thresholds['memory_gb']}GB: {info['memory'].used / (1024**3):.1f}GB used",
                    "type": "memory",
                }
            )

        # Swap usage
        if info["swap"].percent > self.thresholds["swap_percent"]:
            alerts.append(
                {
                    "level": "warning",
                    "message": f"High swap usage: {info['swap'].percent:.1f}%",
                    "type": "swap",
                }
            )

        # CPU load
        if info["load_avg"][0] > self.thresholds["load_1min"]:
            alerts.append(
                {
                    "level": "warning",
                    "message": f"High load average: {info['load_avg'][0]:.1f}",
                    "type": "cpu",
                }
            )

        # Disk usage
        if info["disk"].percent > self.thresholds["disk_percent"]:
            alerts.append(
                {
                    "level": "critical" if info["disk"].percent > 95 else "warning",
                    "message": f"High disk usage: {info['disk'].percent:.1f}%",
                    "type": "disk",
                }
            )

        # Process-specific alerts
        for proc in info["processes"]:
            proc_memory_mb = proc["memory_info"].rss / (1024 * 1024)
            if proc_memory_mb > self.thresholds["process_memory_mb"]:
                alerts.append(
                    {
                        "level": "warning",
                        "message": f"High memory process: {proc['name']} ({proc_memory_mb:.0f}MB)",
                        "type": "process",
                    }
                )

            # Alert for known problematic processes
            if any(
                problem in proc["name"].lower()
                for problem in self.problematic_processes
            ):
                if proc["memory_percent"] > 15:
                    alerts.append(
                        {
                            "level": "warning",
                            "message": f"High memory in {proc['name']}: {proc['memory_percent']:.1f}%",
                            "type": "process",
                        }
                    )

        # Temperature alerts
        if info["temperature"] and info["temperature"] > 75:
            alerts.append(
                {
                    "level": "critical" if info["temperature"] > 85 else "warning",
                    "message": f"High temperature: {info['temperature']:.0f}°C",
                    "type": "temperature",
                }
            )

        return alerts

    def format_bytes(self, bytes_val):
        """Format bytes to human readable format"""
        for unit in ["B", "KB", "MB", "GB", "TB"]:
            if bytes_val < 1024.0:
                return f"{bytes_val:.1f}{unit}"
            bytes_val /= 1024.0
        return f"{bytes_val:.1f}PB"

    def draw_header(self, stdscr, info):
        """Draw the main header with system info"""
        stdscr.attron(curses.color_pair(self.colors["header"]))
        header = f"=== {self.hostname} System Monitor - {info['timestamp']} ==="
        stdscr.addstr(0, 0, header)
        stdscr.clrtoeol()
        stdscr.attroff(curses.color_pair(self.colors["header"]))

    def draw_system_stats(self, stdscr, info, row):
        """Draw system statistics"""
        # Memory bar
        mem_percent = info["memory"].percent
        mem_color = (
            self.colors["good"]
            if mem_percent < 70
            else (
                self.colors["warning"] if mem_percent < 85 else self.colors["critical"]
            )
        )

        stdscr.addstr(
            row,
            0,
            f"Memory: {mem_percent:5.1f}% ({info['memory'].used / (1024**3):.1f}GB / {info['memory'].total / (1024**3):.1f}GB)",
        )

        # Memory bar visualization
        bar_width = 30
        filled = int(bar_width * mem_percent / 100)
        stdscr.addstr(row, 45, "[")
        stdscr.attron(curses.color_pair(mem_color))
        stdscr.addstr(row, 46, "=" * filled)
        stdscr.attroff(curses.color_pair(mem_color))
        stdscr.addstr(
            row, 46 + filled, " " * (bar_width - filled) + f"] {mem_percent:.0f}%"
        )

        row += 1

        # CPU and load
        load_color = (
            self.colors["good"]
            if info["load_avg"][0] < 5
            else (
                self.colors["warning"]
                if info["load_avg"][0] < 10
                else self.colors["critical"]
            )
        )
        stdscr.addstr(
            row,
            0,
            f"Load:   {info['load_avg'][0]:5.2f} {info['load_avg'][1]:5.2f} {info['load_avg'][2]:5.2f}",
        )
        stdscr.addstr(row, 25, f"CPU: {info['cpu_avg']:5.1f}%")

        # CPU cores visualization
        stdscr.addstr(row, 40, "[")
        for i, cpu in enumerate(info["cpu"][:8]):  # Show first 8 cores
            cpu_color = (
                self.colors["good"]
                if cpu < 50
                else (self.colors["warning"] if cpu < 80 else self.colors["critical"])
            )
            stdscr.attron(curses.color_pair(cpu_color))
            stdscr.addstr(row, 41 + i, "█" if cpu > 0 else "·")
            stdscr.attroff(curses.color_pair(cpu_color))
        stdscr.addstr(row, 49, f"+{len(info['cpu']) - 8}]")

        row += 1

        # Swap and disk
        swap_color = (
            self.colors["good"]
            if info["swap"].percent < 30
            else (
                self.colors["warning"]
                if info["swap"].percent < 50
                else self.colors["critical"]
            )
        )
        stdscr.addstr(
            row,
            0,
            f"Swap:   {info['swap'].percent:5.1f}% ({info['swap'].used / (1024**3):.1f}GB)",
        )
        stdscr.addstr(
            row,
            25,
            f"Disk: {info['disk'].percent:5.1f}% ({info['disk'].used / (1024**3):.1f}GB / {info['disk'].total / (1024**3):.0f}GB)",
        )

        # Temperature
        if info["temperature"]:
            temp_color = (
                self.colors["good"]
                if info["temperature"] < 60
                else (
                    self.colors["warning"]
                    if info["temperature"] < 75
                    else self.colors["critical"]
                )
            )
            stdscr.addstr(row, 60, f"Temp: {info['temperature']:.0f}°C")

        return row + 2

    def draw_processes(self, stdscr, processes, start_row):
        """Draw top processes"""
        stdscr.addstr(start_row, 0, "TOP PROCESSES (by memory)")
        stdscr.addstr(start_row, 50, "PID     MEM%     CPU%    NAME")
        stdscr.addstr(start_row + 1, 0, "─" * 80)

        row = start_row + 2
        for proc in processes:
            if row >= curses.LINES - 5:  # Leave space for alerts
                break

            # Highlight problematic processes
            proc_color = self.colors["normal"]
            if any(
                problem in proc["name"].lower()
                for problem in self.problematic_processes
            ):
                proc_color = (
                    self.colors["warning"]
                    if proc["memory_percent"] < 20
                    else self.colors["critical"]
                )

            stdscr.attron(curses.color_pair(proc_color))

            # Truncate long names
            name = proc["name"][:30] + ("..." if len(proc["name"]) > 30 else "")

            line = f"{proc['memory_percent']:6.1f}%  {proc['cpu_percent']:6.1f}%  {proc['pid']:6d}  {name}"
            stdscr.addstr(row, 50, line[:40])

            stdscr.attroff(curses.color_pair(proc_color))
            row += 1

        return row

    def draw_alerts(self, stdscr, alerts):
        """Draw active alerts"""
        if not alerts:
            return curses.LINES - 3

        stdscr.addstr(curses.LINES - len(alerts) - 3, 0, "⚠ ALERTS:")

        row = curses.LINES - len(alerts) - 2
        for alert in alerts[-5:]:  # Show last 5 alerts
            alert_color = (
                self.colors["warning"]
                if alert["level"] == "warning"
                else self.colors["critical"]
            )
            stdscr.attron(curses.color_pair(alert_color))

            prefix = "⚠ " if alert["level"] == "warning" else "🔥 "
            alert_text = f"{prefix}{alert['message']}"

            # Truncate if too long
            if len(alert_text) > curses.COLS - 1:
                alert_text = alert_text[: curses.COLS - 4] + "..."

            stdscr.addstr(row, 0, alert_text)
            stdscr.clrtoeol()
            stdscr.attroff(curses.color_pair(alert_color))
            row += 1

        return row

    def save_alert_to_log(self, alert):
        """Save alert to log file"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "hostname": self.hostname,
            "alert": alert,
        }

        try:
            with open(os.path.expanduser("~/.system_monitor_alerts.log"), "a") as f:
                f.write(json.dumps(log_entry) + "\n")
        except:
            pass

    def run(self, stdscr):
        """Main monitoring loop"""
        # Setup colors
        curses.start_color()
        curses.use_default_colors()
        curses.init_pair(1, curses.COLOR_WHITE, curses.COLOR_RED)  # critical - red bg
        curses.init_pair(2, curses.COLOR_WHITE, curses.COLOR_GREEN)  # good - green bg
        curses.init_pair(
            3, curses.COLOR_WHITE, curses.COLOR_YELLOW
        )  # warning - yellow bg
        curses.init_pair(4, curses.COLOR_BLACK, curses.COLOR_CYAN)  # header - cyan bg

        curses.curs_set(0)  # Hide cursor
        stdscr.nodelay(1)  # Non-blocking input

        while True:
            try:
                stdscr.clear()

                # Get system info
                info = self.get_system_info()
                alerts = self.check_alerts(info)

                # Save new alerts to log
                for alert in alerts:
                    alert_key = f"{alert['type']}_{alert['message']}"
                    if not any(
                        alert_key in existing["message"]
                        for existing in self.alert_history
                    ):
                        self.alert_history.append(alert)
                        self.save_alert_to_log(alert)

                # Draw interface
                self.draw_header(stdscr, info)

                # System stats
                row = self.draw_system_stats(stdscr, info, 2)

                # Network stats (if available)
                if info["network"]:
                    net_info = info["network"]
                    stdscr.addstr(
                        row,
                        0,
                        f"Network ↓ {self.format_bytes(net_info['bytes_recv'])} ↑ {self.format_bytes(net_info['bytes_sent'])}",
                    )
                    row += 1

                row += 1

                # Processes
                self.draw_processes(stdscr, info["processes"], row)

                # Alerts
                self.draw_alerts(stdscr, alerts)

                # Instructions
                stdscr.addstr(
                    curses.LINES - 1,
                    0,
                    "Press 'q' to quit, 'r' to reset alerts, 'h' for help",
                )

                # Handle input
                char = stdscr.getch()
                if char == ord("q"):
                    break
                elif char == ord("r"):
                    self.alert_history.clear()
                elif char == ord("h"):
                    self.show_help(stdscr)

                stdscr.refresh()
                time.sleep(2)

            except KeyboardInterrupt:
                break
            except Exception as e:
                # Display error briefly
                stdscr.addstr(curses.LINES // 2, 0, f"Error: {str(e)}")
                stdscr.refresh()
                time.sleep(1)

    def show_help(self, stdscr):
        """Show help screen"""
        stdscr.clear()
        stdscr.addstr(0, 0, "SYSTEM MONITOR HELP")
        stdscr.addstr(2, 0, "Commands:")
        stdscr.addstr(3, 0, "  q - Quit")
        stdscr.addstr(4, 0, "  r - Reset alert history")
        stdscr.addstr(5, 0, "  h - Show this help")
        stdscr.addstr(7, 0, "Alert Thresholds:")
        stdscr.addstr(
            8,
            0,
            f"  Memory: {self.thresholds['memory_percent']}% or {self.thresholds['memory_gb']}GB",
        )
        stdscr.addstr(9, 0, f"  CPU Load: {self.thresholds['load_1min']}")
        stdscr.addstr(10, 0, f"  Disk: {self.thresholds['disk_percent']}%")
        stdscr.addstr(
            11, 0, f"  Process Memory: {self.thresholds['process_memory_mb']}MB"
        )
        stdscr.addstr(
            13, 0, "Monitored Processes: " + ", ".join(self.problematic_processes)
        )
        stdscr.addstr(15, 0, "Press any key to continue...")
        stdscr.getch()


def main():
    monitor = SystemMonitor()
    curses.wrapper(monitor.run)


if __name__ == "__main__":
    main()
