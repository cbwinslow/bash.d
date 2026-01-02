#!/bin/bash
# System Monitor Setup Script
# Sets up monitoring system with custom alerts

set -e

echo "🔧 Setting up Advanced System Monitor..."

# Check if running as normal user
if [[ $EUID -eq 0 ]]; then
   echo "❌ Please run as normal user, not root"
   exit 1
fi

# Create bin directory if it doesn't exist
mkdir -p ~/bin
mkdir -p ~/.config/systemd/user

# Install required Python packages
echo "📦 Installing Python dependencies..."
pip3 install --user psutil 2>/dev/null || {
    echo "❌ Failed to install psutil. Please install with: pip3 install --user psutil"
    exit 1
}

# Make scripts executable
chmod +x ~/bash.d/system_monitor.py
chmod +x ~/bash.d/alert_daemon.py

# Create symlink for easy access
ln -sf ~/bash.d/system_monitor.py ~/bin/sysmon
ln -sf ~/bash.d/alert_daemon.py ~/bin/alertd

# Create log rotation configuration
echo "📝 Setting up log rotation..."
cat > ~/.config/logrotate-system-monitor << 'EOF'
~/.system_monitor_alerts.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF

# Add to PATH if not already there
if ! echo $PATH | grep -q "$HOME/bin"; then
    echo "export PATH=\"\$HOME/bin:\$PATH\"" >> ~/.bashrc
    export PATH="$HOME/bin:$PATH"
fi

# Setup systemd service
echo "🔧 Setting up alert daemon service..."
python3 ~/bash.d/alert_daemon.py setup

# Create desktop entry for the monitor
echo "🖥️  Creating desktop entry..."
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/system-monitor.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Advanced System Monitor
Comment=System monitoring with custom alerts
Exec=$HOME/bash.d/system_monitor.py
Icon=utilities-system-monitor
Terminal=true
Categories=System;Monitor;
Keywords=system;monitor;performance;alerts;
EOF

# Create config override for user preferences
cat > ~/.system_monitor_config.json << 'EOF'
{
  "theme": "dark",
  "update_interval": 2,
  "alert_sound": true,
  "auto_start_daemon": true,
  "custom_thresholds": {
    "memory_percent": 80,
    "cpu_load": 8.0,
    "disk_percent": 85
  }
}
EOF

echo ""
echo "✅ Setup completed!"
echo ""
echo "🚀 Getting started:"
echo "  • Run 'sysmon' to launch the TUI monitor"
echo "  • Run 'alertd' to start the alert daemon manually"
echo "  • Run 'systemctl --user start alert-daemon.service' for background service"
echo "  • Run 'systemctl --user enable alert-daemon.service' for auto-start"
echo ""
echo "⚙️  Configuration files:"
echo "  • Alert config: ~/.alert_daemon_config.json"
echo "  • Alert log: ~/.system_monitor_alerts.log"
echo "  • Log rotation: ~/.config/logrotate-system-monitor"
echo ""
echo "🎯 Features:"
echo "  • Real-time system monitoring TUI"
echo "  • Memory, CPU, disk, and temperature alerts"
echo "  • Process monitoring (Docker, Ollama, VS Code, etc.)"
echo "  • Desktop notifications for critical issues"
echo "  • Historical alert logging"
echo ""
echo "🔧 Customization:"
echo "  • Edit ~/.alert_daemon_config.json to change thresholds"
echo "  • Edit ~/bash.d/system_monitor.py to modify monitoring logic"
echo ""

# Ask if user wants to start services now
read -p "Do you want to start the alert daemon now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Starting alert daemon service..."
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable alert-daemon.service 2>/dev/null || true
    systemctl --user start alert-daemon.service 2>/dev/null || {
        echo "⚠️  Starting daemon in foreground instead..."
        nohup python3 ~/bash.d/alert_daemon.py > ~/.alert_daemon_output.log 2>&1 &
        echo $! > ~/.alert_daemon.pid
    }
    echo "✅ Alert daemon started!"
fi

read -p "Do you want to launch the system monitor now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🖥️  Launching system monitor..."
    python3 ~/bash.d/system_monitor.py
fi

echo ""
echo "🎉 Setup complete! Your system is now being monitored."