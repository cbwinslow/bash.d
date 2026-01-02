#!/usr/bin/env python3
"""
System Alert Daemon
Runs in background and sends desktop notifications for critical alerts
"""

import os
import sys
import time
import psutil
import subprocess
import json
import socket
from datetime import datetime, timedelta
import threading


class AlertDaemon:
    def __init__(self):
        self.hostname = socket.gethostname()
        self.config_file = os.path.expanduser("~/.alert_daemon_config.json")
        self.alert_log = os.path.expanduser("~/.system_monitor_alerts.log")
        self.cooldown_period = 300  # 5 minutes between same alert types
        self.last_alerts = {}
        self.running = True

        # Load or create config
        self.load_config()

    def load_config(self):
        """Load configuration from file"""
        default_config = {
            "enabled": True,
            "thresholds": {
                "memory_percent": 85,
                "memory_gb": 70,
                "cpu_load": 8.0,
                "disk_percent": 90,
                "temperature": 80,
                "process_memory_mb": 3000,
            },
            "notifications": {
                "desktop": True,
                "sound": True,
                "email": False,
                "discord_webhook": None,
            },
            "monitored_processes": [
                "ollama",
                "docker",
                "proton.vpn",
                "code",
                "node",
                "mysql",
            ],
        }

        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, "r") as f:
                    self.config = json.load(f)
            else:
                self.config = default_config
                self.save_config()
        except:
            self.config = default_config

    def save_config(self):
        """Save configuration to file"""
        try:
            with open(self.config_file, "w") as f:
                json.dump(self.config, f, indent=2)
        except:
            pass

    def check_system_health(self):
        """Check system health and return alerts"""
        alerts = []

        # Memory checks
        memory = psutil.virtual_memory()
        if memory.percent > self.config["thresholds"]["memory_percent"]:
            alerts.append(
                {
                    "type": "memory_critical",
                    "title": "Critical Memory Usage",
                    "message": f"Memory usage is {memory.percent:.1f}% ({memory.used / (1024**3):.1f}GB used)",
                    "urgency": "critical",
                }
            )
        elif memory.used / (1024**3) > self.config["thresholds"]["memory_gb"]:
            alerts.append(
                {
                    "type": "memory_volume",
                    "title": "High Memory Volume",
                    "message": f"Memory usage: {memory.used / (1024**3):.1f}GB used",
                    "urgency": "normal",
                }
            )

        # CPU load check
        load_avg = os.getloadavg()[0]
        if load_avg > self.config["thresholds"]["cpu_load"]:
            alerts.append(
                {
                    "type": "cpu_load",
                    "title": "High CPU Load",
                    "message": f"Load average: {load_avg:.1f}",
                    "urgency": "normal",
                }
            )

        # Disk check
        disk = psutil.disk_usage("/")
        if disk.percent > self.config["thresholds"]["disk_percent"]:
            alerts.append(
                {
                    "type": "disk_space",
                    "title": "Low Disk Space",
                    "message": f"Disk usage: {disk.percent:.1f}% ({disk.free / (1024**3):.1f}GB free)",
                    "urgency": "critical",
                }
            )

        # Temperature check
        try:
            temps = psutil.sensors_temperatures()
            if temps:
                max_temp = 0
                for name, entries in temps.items():
                    for entry in entries:
                        if entry.current and entry.current > max_temp:
                            max_temp = entry.current

                if max_temp > self.config["thresholds"]["temperature"]:
                    alerts.append(
                        {
                            "type": "temperature",
                            "title": "High Temperature",
                            "message": f"System temperature: {max_temp:.0f}°C",
                            "urgency": "normal",
                        }
                    )
        except:
            pass

        # Process-specific checks
        for proc in psutil.process_iter(["pid", "name", "memory_info", "cpu_percent"]):
            try:
                proc_name = proc.info["name"].lower()
                proc_memory_mb = proc.info["memory_info"].rss / (1024 * 1024)

                # Check monitored processes
                if any(
                    monitored in proc_name
                    for monitored in self.config["monitored_processes"]
                ):
                    if proc_memory_mb > self.config["thresholds"]["process_memory_mb"]:
                        alerts.append(
                            {
                                "type": "process_memory",
                                "title": "High Memory Process",
                                "message": f"{proc.info['name']}: {proc_memory_mb:.0f}MB ({proc.info['cpu_percent']:.1f}% CPU)",
                                "urgency": "normal",
                            }
                        )
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue

        return alerts

    def send_notification(self, alert):
        """Send desktop notification"""
        if not self.config["notifications"]["desktop"]:
            return

        try:
            # Try different notification methods
            commands = [
                [
                    "notify-send",
                    "-u",
                    alert["urgency"],
                    alert["title"],
                    alert["message"],
                ],
                [
                    "zenity",
                    "--info",
                    "--title",
                    alert["title"],
                    "--text",
                    alert["message"],
                ],
                ["kdialog", "--title", alert["title"], "--msgbox", alert["message"]],
            ]

            for cmd in commands:
                try:
                    subprocess.run(cmd, check=True, capture_output=True, timeout=5)
                    break
                except (
                    subprocess.CalledProcessError,
                    FileNotFoundError,
                    subprocess.TimeoutExpired,
                ):
                    continue
        except:
            pass

    def play_sound(self, alert):
        """Play alert sound"""
        if not self.config["notifications"]["sound"]:
            return

        if alert["urgency"] == "critical":
            # Play critical alert sound
            sounds = [
                ["paplay", "/usr/share/sounds/freedesktop/stereo/complete.oga"],
                ["aplay", "/usr/share/sounds/alsa/Front_Left.wav"],
                ["echo", "\a"],  # Bell character as fallback
            ]
        else:
            # Play normal alert sound
            sounds = [
                [
                    "paplay",
                    "/usr/share/sounds/freedesktop/stereo/dialog-information.oga",
                ],
                ["echo", "\a"],
            ]

        for sound_cmd in sounds:
            try:
                subprocess.run(sound_cmd, check=True, capture_output=True, timeout=2)
                break
            except (
                subprocess.CalledProcessError,
                FileNotFoundError,
                subprocess.TimeoutExpired,
            ):
                continue

    def log_alert(self, alert):
        """Log alert to file"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "hostname": self.hostname,
            "alert": alert,
        }

        try:
            with open(self.alert_log, "a") as f:
                f.write(json.dumps(log_entry) + "\n")
        except:
            pass

    def should_send_alert(self, alert):
        """Check if alert should be sent (cooldown logic)"""
        alert_key = alert["type"]
        now = datetime.now()

        if alert_key in self.last_alerts:
            time_since_last = now - self.last_alerts[alert_key]
            if time_since_last.total_seconds() < self.cooldown_period:
                return False

        self.last_alerts[alert_key] = now
        return True

    def handle_alert(self, alert):
        """Handle a single alert"""
        if not self.should_send_alert(alert):
            return

        # Log the alert
        self.log_alert(alert)

        # Send notification
        self.send_notification(alert)

        # Play sound
        self.play_sound(alert)

        print(
            f"[{datetime.now().strftime('%H:%M:%S')}] ALERT: {alert['title']} - {alert['message']}"
        )

    def daemon_loop(self):
        """Main daemon loop"""
        print(f"Alert daemon started on {self.hostname}")
        print(f"Config file: {self.config_file}")
        print(f"Alert log: {self.alert_log}")
        print("Press Ctrl+C to stop...")

        while self.running:
            try:
                if self.config["enabled"]:
                    alerts = self.check_system_health()

                    for alert in alerts:
                        self.handle_alert(alert)

                time.sleep(30)  # Check every 30 seconds

            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"Error in daemon loop: {e}")
                time.sleep(10)  # Wait before retrying

    def stop(self):
        """Stop the daemon"""
        self.running = False


def setup_service():
    """Setup systemd service file"""
    service_content = f"""[Unit]
Description=System Alert Daemon
After=graphical-session.target

[Service]
Type=simple
User={os.getenv("USER")}
WorkingDirectory={os.path.expanduser("~")}
ExecStart=/usr/bin/python3 {os.path.expanduser("~/bash.d/alert_daemon.py")}
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
"""

    service_path = os.path.expanduser("~/.config/systemd/user/alert-daemon.service")
    os.makedirs(os.path.dirname(service_path), exist_ok=True)

    try:
        with open(service_path, "w") as f:
            f.write(service_content)
        print(f"Service file created: {service_path}")
        print("Run these commands to enable the service:")
        print("  systemctl --user daemon-reload")
        print("  systemctl --user enable alert-daemon.service")
        print("  systemctl --user start alert-daemon.service")
    except Exception as e:
        print(f"Error creating service file: {e}")


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "setup":
        setup_service()
        return

    daemon = AlertDaemon()

    try:
        daemon.daemon_loop()
    except KeyboardInterrupt:
        print("\nShutting down daemon...")
        daemon.stop()


if __name__ == "__main__":
    main()
