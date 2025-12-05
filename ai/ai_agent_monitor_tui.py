#!/usr/bin/env python3
"""
AI Agent Monitoring TUI - Text-based User Interface
for monitoring and measuring AI agent vitals in bash.d

Features:
- Real-time monitoring of all AI agents
- Agent selection and detailed vitals
- Performance metrics visualization
- Alert system for abnormal behavior
- Feedback and optimization recommendations
"""

import curses
import json
import os
import time
import subprocess
import threading
from datetime import datetime
from collections import defaultdict
from typing import Dict, List, Any

class AIAgentMonitorTUI:
    def __init__(self, stdscr):
        self.stdscr = stdscr
        self.ai_config_dir = os.path.expanduser("~/.config/bashd/ai")
        self.ai_state_dir = os.path.expanduser("~/.cache/bashd/ai")
        self.monitor_log = os.path.join(self.ai_state_dir, "agent_monitor_tui.log")
        self.feedback_log = os.path.join(self.ai_state_dir, "agent_feedback.log")

        # Initialize data structures
        self.agents = {}
        self.selected_agent = None
        self.running = True
        self.update_interval = 2  # seconds
        self.alerts = []

        # Setup directories
        os.makedirs(self.ai_state_dir, exist_ok=True)

        # Initialize curses
        curses.curs_set(0)  # Hide cursor
        self.stdscr.nodelay(1)  # Non-blocking input
        self.stdscr.timeout(100)  # Refresh rate

        # Color setup
        self._setup_colors()

        # Load initial agent data
        self._load_agents()

        # Start monitoring thread
        self.monitoring_thread = threading.Thread(target=self._monitor_agents, daemon=True)
        self.monitoring_thread.start()

    def _setup_colors(self):
        """Setup color pairs for the TUI"""
        curses.start_color()
        curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)  # Normal
        curses.init_pair(2, curses.COLOR_YELLOW, curses.COLOR_BLACK)  # Warning
        curses.init_pair(3, curses.COLOR_RED, curses.COLOR_BLACK)     # Alert
        curses.init_pair(4, curses.COLOR_CYAN, curses.COLOR_BLACK)   # Selected
        curses.init_pair(5, curses.COLOR_MAGENTA, curses.COLOR_BLACK) # Title
        curses.init_pair(6, curses.COLOR_BLUE, curses.COLOR_BLACK)   # Info

    def _load_agents(self):
        """Load AI agent configuration and status"""
        config_file = os.path.join(self.ai_config_dir, "config.json")

        if os.path.exists(config_file):
            try:
                with open(config_file, 'r') as f:
                    config = json.load(f)

                # Load AI agents from config
                if 'ai_agents' in config:
                    for agent_name, agent_data in config['ai_agents'].items():
                        self.agents[agent_name] = {
                            'enabled': agent_data.get('enabled', False),
                            'specialization': agent_data.get('specialization', 'general'),
                            'model': agent_data.get('model', 'openrouter/auto'),
                            'vitals': {
                                'status': 'unknown',
                                'last_check': None,
                                'response_time': 0,
                                'success_rate': 0,
                                'memory_usage': 0,
                                'cpu_usage': 0,
                                'tasks_completed': 0,
                                'errors': 0,
                                'warnings': 0
                            },
                            'history': []
                        }

                # Set first enabled agent as selected
                for agent_name in self.agents:
                    if self.agents[agent_name]['enabled']:
                        self.selected_agent = agent_name
                        break

                if not self.selected_agent and self.agents:
                    self.selected_agent = next(iter(self.agents))

            except Exception as e:
                self._log_error(f"Failed to load agents: {e}")

    def _monitor_agents(self):
        """Continuous monitoring of AI agents"""
        while self.running:
            start_time = time.time()

            for agent_name in self.agents:
                if self.agents[agent_name]['enabled']:
                    self._check_agent_vitals(agent_name)

            # Sleep for remaining time to maintain update interval
            elapsed = time.time() - start_time
            sleep_time = max(0, self.update_interval - elapsed)
            time.sleep(sleep_time)

    def _check_agent_vitals(self, agent_name: str):
        """Check vitals for a specific AI agent"""
        try:
            agent = self.agents[agent_name]
            vitals = agent['vitals']

            # Get current timestamp
            now = datetime.now().isoformat()

            # Simulate checking agent status (in real implementation, call bash functions)
            # For now, we'll use some simulated data that would come from actual agent checks

            # Check if agent process is running
            status = "active" if self._is_agent_active(agent_name) else "inactive"

            # Get performance metrics (simulated for now)
            response_time = self._get_agent_response_time(agent_name)
            success_rate = self._get_agent_success_rate(agent_name)
            memory_usage = self._get_agent_memory_usage(agent_name)
            cpu_usage = self._get_agent_cpu_usage(agent_name)
            tasks_completed = self._get_agent_tasks_completed(agent_name)
            errors = self._get_agent_errors(agent_name)
            warnings = self._get_agent_warnings(agent_name)

            # Update vitals
            vitals.update({
                'status': status,
                'last_check': now,
                'response_time': response_time,
                'success_rate': success_rate,
                'memory_usage': memory_usage,
                'cpu_usage': cpu_usage,
                'tasks_completed': tasks_completed,
                'errors': errors,
                'warnings': warnings
            })

            # Add to history (keep last 10 entries)
            history_entry = {
                'timestamp': now,
                'status': status,
                'response_time': response_time,
                'success_rate': success_rate,
                'memory_usage': memory_usage,
                'cpu_usage': cpu_usage
            }

            agent['history'].append(history_entry)
            if len(agent['history']) > 10:
                agent['history'].pop(0)

            # Check for alerts
            self._check_for_alerts(agent_name, vitals)

        except Exception as e:
            self._log_error(f"Error checking vitals for {agent_name}: {e}")

    def _is_agent_active(self, agent_name: str) -> bool:
        """Check if agent is actively running"""
        # In real implementation, this would check process status
        # For simulation, we'll return True for most agents
        return agent_name != "disabled_agent"

    def _get_agent_response_time(self, agent_name: str) -> float:
        """Get agent response time in seconds"""
        # Simulated data - in real implementation, measure actual response times
        base_time = 0.5
        if "documentation" in agent_name:
            return base_time * 1.2
        elif "automation" in agent_name:
            return base_time * 0.8
        else:
            return base_time

    def _get_agent_success_rate(self, agent_name: str) -> float:
        """Get agent success rate (0-1)"""
        # Simulated data
        base_rate = 0.95
        if "decision" in agent_name:
            return base_rate * 0.98
        else:
            return base_rate

    def _get_agent_memory_usage(self, agent_name: str) -> float:
        """Get agent memory usage in MB"""
        # Simulated data
        base_memory = 50.0
        if "automation" in agent_name:
            return base_memory * 1.5
        else:
            return base_memory

    def _get_agent_cpu_usage(self, agent_name: str) -> float:
        """Get agent CPU usage percentage"""
        # Simulated data
        base_cpu = 5.0
        if "automation" in agent_name:
            return base_cpu * 2.0
        else:
            return base_cpu

    def _get_agent_tasks_completed(self, agent_name: str) -> int:
        """Get number of tasks completed"""
        # Simulated data that increases over time
        if agent_name in self._task_counts:
            self._task_counts[agent_name] += 1
        else:
            self._task_counts[agent_name] = 10
        return self._task_counts[agent_name]

    def _get_agent_errors(self, agent_name: str) -> int:
        """Get number of errors"""
        # Simulated data
        return 0 if "documentation" in agent_name else 1

    def _get_agent_warnings(self, agent_name: str) -> int:
        """Get number of warnings"""
        # Simulated data
        return 1 if "automation" in agent_name else 0

    def _check_for_alerts(self, agent_name: str, vitals: Dict[str, Any]):
        """Check for alert conditions and add to alerts list"""
        alerts = []

        if vitals['status'] == 'inactive' and vitals['enabled']:
            alerts.append(f"🚨 {agent_name}: Agent is enabled but inactive")

        if vitals['success_rate'] < 0.8:
            alerts.append(f"⚠️  {agent_name}: Low success rate ({vitals['success_rate']:.1%})")

        if vitals['response_time'] > 2.0:
            alerts.append(f"⏱️  {agent_name}: High response time ({vitals['response_time']:.2f}s)")

        if vitals['memory_usage'] > 200:
            alerts.append(f"💾 {agent_name}: High memory usage ({vitals['memory_usage']:.1f}MB)")

        if vitals['cpu_usage'] > 20:
            alerts.append(f"🔥 {agent_name}: High CPU usage ({vitals['cpu_usage']:.1f}%)")

        if vitals['errors'] > 5:
            alerts.append(f"❌ {agent_name}: High error count ({vitals['errors']})")

        # Add new alerts to the list (avoid duplicates)
        for alert in alerts:
            if alert not in self.alerts:
                self.alerts.append(alert)
                self._log_alert(alert)

        # Remove resolved alerts
        self.alerts = [alert for alert in self.alerts
                      if any(alert.startswith(f"🚨 {agent_name}") and vitals['status'] == 'active') or
                         not alert.startswith(f"🚨 {agent_name}")]

    def _log_alert(self, alert: str):
        """Log alert to file"""
        with open(self.monitor_log, 'a') as f:
            f.write(f"[{datetime.now().isoformat()}] ALERT: {alert}\n")

    def _log_error(self, error: str):
        """Log error to file"""
        with open(self.monitor_log, 'a') as f:
            f.write(f"[{datetime.now().isoformat()}] ERROR: {error}\n")

    def _log_feedback(self, feedback: str):
        """Log feedback to feedback log"""
        with open(self.feedback_log, 'a') as f:
            f.write(f"[{datetime.now().isoformat()}] FEEDBACK: {feedback}\n")

    def _draw_header(self):
        """Draw the header section"""
        height, width = self.stdscr.getmaxyx()

        # Title
        title = " AI Agent Monitoring TUI - bash.d "
        self.stdscr.addstr(0, 0, title, curses.color_pair(5) | curses.A_BOLD)

        # Subtitle
        subtitle = "Real-time monitoring and vitals measurement"
        self.stdscr.addstr(1, 0, subtitle, curses.color_pair(6))

        # Status info
        status_info = f"Agents: {len(self.agents)} | Active: {sum(1 for a in self.agents.values() if a['enabled'] and a['vitals']['status'] == 'active')} | Alerts: {len(self.alerts)}"
        self.stdscr.addstr(1, width - len(status_info) - 1, status_info, curses.color_pair(2))

        # Separator
        self.stdscr.addstr(2, 0, "=" * width, curses.color_pair(4))

    def _draw_agent_list(self):
        """Draw the agent list panel"""
        height, width = self.stdscr.getmaxyx()
        list_height = height - 8  # Leave room for header and footer

        # Panel title
        self.stdscr.addstr(3, 0, " AI Agents ", curses.color_pair(5) | curses.A_BOLD)
        self.stdscr.addstr(3, width//3, " Agent Vitals ", curses.color_pair(5) | curses.A_BOLD)
        self.stdscr.addstr(3, width//3 * 2, " Alerts ", curses.color_pair(5) | curses.A_BOLD)

        # Draw agent list
        for i, (agent_name, agent_data) in enumerate(self.agents.items()):
            if i >= list_height - 4:  # Don't overflow
                break

            y_pos = 4 + i
            display_name = f"• {agent_name}"

            # Highlight selected agent
            if agent_name == self.selected_agent:
                self.stdscr.addstr(y_pos, 0, display_name, curses.color_pair(4) | curses.A_BOLD)
            else:
                # Color based on status
                if agent_data['enabled']:
                    if agent_data['vitals']['status'] == 'active':
                        self.stdscr.addstr(y_pos, 0, display_name, curses.color_pair(1))
                    else:
                        self.stdscr.addstr(y_pos, 0, display_name, curses.color_pair(3))
                else:
                    self.stdscr.addstr(y_pos, 0, display_name, curses.color_pair(6))

            # Show specialization
            spec = f"[{agent_data['specialization']}]"
            self.stdscr.addstr(y_pos, 25, spec, curses.color_pair(2))

            # Show status
            status = f"Status: {agent_data['vitals']['status']}"
            self.stdscr.addstr(y_pos, 40, status)

    def _draw_agent_details(self):
        """Draw detailed vitals for selected agent"""
        if not self.selected_agent or self.selected_agent not in self.agents:
            return

        height, width = self.stdscr.getmaxyx()
        agent = self.agents[self.selected_agent]
        vitals = agent['vitals']

        # Panel title
        title = f" {self.selected_agent} Details "
        self.stdscr.addstr(3, width//3, title, curses.color_pair(5) | curses.A_BOLD)

        # Vitals display
        y_pos = 5
        vitals_data = [
            (f"Status: {vitals['status']}", 1 if vitals['status'] == 'active' else 3),
            (f"Response Time: {vitals['response_time']:.3f}s", 1),
            (f"Success Rate: {vitals['success_rate']:.1%}", 1),
            (f"Memory Usage: {vitals['memory_usage']:.1f}MB", 2 if vitals['memory_usage'] > 150 else 1),
            (f"CPU Usage: {vitals['cpu_usage']:.1f}%", 2 if vitals['cpu_usage'] > 15 else 1),
            (f"Tasks Completed: {vitals['tasks_completed']}", 1),
            (f"Errors: {vitals['errors']}", 3 if vitals['errors'] > 0 else 1),
            (f"Warnings: {vitals['warnings']}", 2 if vitals['warnings'] > 0 else 1),
            (f"Last Check: {vitals['last_check'] or 'Never'}", 1)
        ]

        for item, color in vitals_data:
            if y_pos < height - 5:  # Don't overflow
                self.stdscr.addstr(y_pos, width//3, item, curses.color_pair(color))
                y_pos += 1

        # Performance chart (simple ASCII)
        if y_pos + 5 < height - 5:
            self.stdscr.addstr(y_pos, width//3, " Performance History ", curses.color_pair(5))
            y_pos += 1

            # Simple response time chart
            if agent['history']:
                self.stdscr.addstr(y_pos, width//3, "Response Time:", curses.color_pair(1))
                y_pos += 1

                # Draw simple bar chart
                chart_width = 30
                max_response = max(entry['response_time'] for entry in agent['history'])
                for entry in reversed(agent['history'][-5:]):  # Last 5 entries
                    bar_length = int((entry['response_time'] / max_response) * chart_width)
                    bar = '█' * bar_length
                    time_str = f"{entry['response_time']:.2f}s"
                    self.stdscr.addstr(y_pos, width//3, f"{bar} {time_str}", curses.color_pair(1))
                    y_pos += 1

    def _draw_alerts(self):
        """Draw alerts panel"""
        height, width = self.stdscr.getmaxyx()

        # Panel title
        self.stdscr.addstr(3, width//3 * 2, " Alerts ", curses.color_pair(5) | curses.A_BOLD)

        # Draw alerts
        for i, alert in enumerate(self.alerts[:height-8]):  # Limit to available space
            y_pos = 4 + i
            color = 3 if alert.startswith("🚨") else 2
            self.stdscr.addstr(y_pos, width//3 * 2, alert, curses.color_pair(color))

    def _draw_footer(self):
        """Draw the footer with controls"""
        height, width = self.stdscr.getmaxyx()
        footer_y = height - 3

        # Controls
        controls = " Controls: ↑/↓ Select Agent | Q Quit | F Feedback | R Refresh | O Optimize "
        self.stdscr.addstr(footer_y, 0, controls, curses.color_pair(2))

        # Selected agent info
        if self.selected_agent:
            agent_info = f"Selected: {self.selected_agent} | Status: {self.agents[self.selected_agent]['vitals']['status']}"
            self.stdscr.addstr(footer_y + 1, 0, agent_info, curses.color_pair(4))

        # Separator
        self.stdscr.addstr(footer_y + 2, 0, "=" * width, curses.color_pair(4))

    def _handle_input(self):
        """Handle user input"""
        key = self.stdscr.getch()

        if key == ord('q') or key == ord('Q'):
            self.running = False
            return False

        elif key == curses.KEY_UP:
            self._select_previous_agent()

        elif key == curses.KEY_DOWN:
            self._select_next_agent()

        elif key == ord('f') or key == ord('F'):
            self._provide_feedback()

        elif key == ord('r') or key == ord('R'):
            self._refresh_data()

        elif key == ord('o') or key == ord('O'):
            self._optimize_selected_agent()

        return True

    def _select_previous_agent(self):
        """Select the previous agent in the list"""
        if not self.agents:
            return

        agent_names = list(self.agents.keys())
        if self.selected_agent not in agent_names:
            self.selected_agent = agent_names[0]
            return

        current_index = agent_names.index(self.selected_agent)
        prev_index = (current_index - 1) % len(agent_names)
        self.selected_agent = agent_names[prev_index]

    def _select_next_agent(self):
        """Select the next agent in the list"""
        if not self.agents:
            return

        agent_names = list(self.agents.keys())
        if self.selected_agent not in agent_names:
            self.selected_agent = agent_names[0]
            return

        current_index = agent_names.index(self.selected_agent)
        next_index = (current_index + 1) % len(agent_names)
        self.selected_agent = agent_names[next_index]

    def _provide_feedback(self):
        """Provide feedback for the selected agent"""
        if not self.selected_agent:
            return

        # In a real implementation, this would open a feedback dialog
        # For now, we'll just log some sample feedback
        feedback = f"User provided feedback for {self.selected_agent} agent"
        self._log_feedback(feedback)

        # Also provide optimization suggestion
        self._provide_optimization_feedback()

    def _provide_optimization_feedback(self):
        """Provide AI-driven optimization feedback"""
        if not self.selected_agent:
            return

        agent = self.agents[self.selected_agent]
        vitals = agent['vitals']

        # Generate optimization suggestions based on vitals
        suggestions = []

        if vitals['response_time'] > 1.0:
            suggestions.append(f"Consider optimizing {self.selected_agent} response time (current: {vitals['response_time']:.2f}s)")

        if vitals['memory_usage'] > 100:
            suggestions.append(f"High memory usage detected in {self.selected_agent} ({vitals['memory_usage']:.1f}MB) - consider memory optimization")

        if vitals['success_rate'] < 0.9:
            suggestions.append(f"Success rate could be improved for {self.selected_agent} (current: {vitals['success_rate']:.1%})")

        if suggestions:
            feedback = " | ".join(suggestions)
            self._log_feedback(f"OPTIMIZATION: {feedback}")

    def _refresh_data(self):
        """Manually refresh agent data"""
        self._load_agents()
        for agent_name in self.agents:
            if self.agents[agent_name]['enabled']:
                self._check_agent_vitals(agent_name)

    def _optimize_selected_agent(self):
        """Optimize the selected agent"""
        if not self.selected_agent:
            return

        # In real implementation, this would call bash.d optimization functions
        # For simulation, we'll just log the optimization attempt
        self._log_feedback(f"User initiated optimization for {self.selected_agent} agent")

        # Simulate optimization by improving some metrics
        agent = self.agents[self.selected_agent]
        if agent['vitals']['response_time'] > 0.3:
            agent['vitals']['response_time'] *= 0.9  # 10% improvement
        if agent['vitals']['memory_usage'] > 30:
            agent['vitals']['memory_usage'] *= 0.95  # 5% improvement

    def run(self):
        """Main TUI loop"""
        try:
            while self.running:
                # Clear screen
                self.stdscr.clear()

                # Draw UI components
                self._draw_header()
                self._draw_agent_list()
                self._draw_agent_details()
                self._draw_alerts()
                self._draw_footer()

                # Refresh screen
                self.stdscr.refresh()

                # Handle input
                if not self._handle_input():
                    break

                # Small delay to prevent CPU overload
                time.sleep(0.05)

        except KeyboardInterrupt:
            self.running = False
        finally:
            # Cleanup
            curses.endwin()
            print(f"\nAI Agent Monitor TUI closed. Logs saved to: {self.monitor_log}")

def main():
    """Main entry point"""
    # Initialize curses
    stdscr = curses.initscr()

    try:
        # Create and run the TUI
        tui = AIAgentMonitorTUI(stdscr)
        tui.run()
    except Exception as e:
        curses.endwin()
        print(f"Error running AI Agent Monitor TUI: {e}")
        return 1

    return 0

if __name__ == "__main__":
    main()
