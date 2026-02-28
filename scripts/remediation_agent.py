#!/usr/bin/env python3
"""
Automated Remediation Agent
Automatically detects and fixes common system issues.
"""

import os
import subprocess
import time
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
import threading
import signal

# Config
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "qwen3:4b")
BASHD_DIR = os.path.expanduser("~/bash.d")

# Issue thresholds
MEMORY_THRESHOLD = 85  # %
CPU_THRESHOLD = 90    # %
DISK_THRESHOLD = 90   # %

@dataclass
class Issue:
    """Represents a detected issue."""
    severity: str  # low, medium, high, critical
    category: str  # memory, cpu, disk, process, docker, security
    description: str
    pid: Optional[int] = None
    command: Optional[str] = None

@dataclass
class Remediation:
    """Represents a remediation action."""
    issue: Issue
    action: str
    command: str
    auto_execute: bool = False
    executed: bool = False
    result: str = ""

class RemediationAgent:
    """Automated remediation agent."""
    
    def __init__(self, dry_run: bool = True):
        self.dry_run = dry_run
        self.issues: List[Issue] = []
        self.remediations: List[Remediation] = []
        self.running = False
    
    # ====================
    # Detection Methods
    # ====================
    
    def check_memory(self) -> List[Issue]:
        """Check for memory issues."""
        issues = []
        
        try:
            result = subprocess.run(
                "free | grep Mem | awk '{printf \"%d\", ($3/$2)",
                shell=True * 100}',
                capture_output=True,
                text=True
            )
            
            mem_percent = int(result.stdout.strip())
            
            if mem_percent >= MEMORY_THRESHOLD:
                issues.append(Issue(
                    severity="high" if mem_percent >= 90 else "medium",
                    category="memory",
                    description=f"Memory usage at {mem_percent}%"
                ))
        
        except:
            pass
        
        return issues
    
    def check_processes(self) -> List[Issue]:
        """Check for problematic processes."""
        issues = []
        
        try:
            # Check for duplicate processes
            result = subprocess.run(
                "ps aux | grep -E 'kilo|cline|node' | grep -v grep | awk '{print $11,$2}' | sort | uniq -d",
                shell=True,
                capture_output=True,
                text=True
            )
            
            lines = result.stdout.strip().split('\n')
            kilo_count = 0
            cline_count = 0
            
            for line in lines:
                if 'kilo' in line.lower():
                    kilo_count += 1
                if 'cline' in line.lower():
                    cline_count += 1
            
            if kilo_count > 2:
                issues.append(Issue(
                    severity="medium",
                    category="process",
                    description=f"Multiple kilo processes: {kilo_count} instances",
                    command="pkill -f kilo"
                ))
            
            if cline_count > 2:
                issues.append(Issue(
                    severity="medium",
                    category="process",
                    description=f"Multiple cline processes: {cline_count} instances",
                    command="pkill -f cline"
                ))
        
        except:
            pass
        
        return issues
    
    def check_zombies(self) -> List[Issue]:
        """Check for zombie processes."""
        issues = []
        
        try:
            result = subprocess.run(
                "ps aux | grep -c ' Z ' | grep -v grep",
                shell=True,
                capture_output=True,
                text=True
            )
            
            zombie_count = int(result.stdout.strip()) if result.stdout.strip().isdigit() else 0
            
            if zombie_count > 0:
                issues.append(Issue(
                    severity="low",
                    category="process",
                    description=f"Zombie processes: {zombie_count}",
                    command="ps aux | grep Z"
                ))
        
        except:
            pass
        
        return issues
    
    def check_docker(self) -> List[Issue]:
        """Check Docker issues."""
        issues = []
        
        try:
            # Check for stopped containers
            result = subprocess.run(
                "docker ps -a --filter status=exited --format '{{.Names}}'",
                shell=True,
                capture_output=True,
                text=True
            )
            
            exited = result.stdout.strip().split('\n')
            if len(exited) > 0 and exited[0]:
                issues.append(Issue(
                    severity="low",
                    category="docker",
                    description=f"Stopped containers: {len([c for c in exited if c])}",
                    command="docker system prune -f"
                ))
            
            # Check for unused images
            result = subprocess.run(
                "docker images --filter dangling=true -q",
                shell=True,
                capture_output=True,
                text=True
            )
            
            if result.stdout.strip():
                issues.append(Issue(
                    severity="low",
                    category="docker",
                    description="Dangling Docker images",
                    command="docker image prune -f"
                ))
        
        except:
            pass
        
        return issues
    
    def check_disk(self) -> List[Issue]:
        """Check disk space."""
        issues = []
        
        try:
            result = subprocess.run(
                "df -h / | tail -1 | awk '{print $5}' | sed 's/%//'",
                shell=True,
                capture_output=True,
                text=True
            )
            
            disk_percent = int(result.stdout.strip())
            
            if disk_percent >= DISK_THRESHOLD:
                issues.append(Issue(
                    severity="high" if disk_percent >= 95 else "medium",
                    category="disk",
                    description=f"Disk usage at {disk_percent}%"
                ))
        
        except:
            pass
        
        return issues
    
    # ====================
    # Remediation Methods
    # ====================
    
    def get_remediations(self) -> List[Remediation]:
        """Get remediation recommendations."""
        remediations = []
        
        for issue in self.issues:
            if issue.category == "memory" and issue.command:
                remediations.append(Remediation(
                    issue=issue,
                    action="Kill memory-heavy process",
                    command=issue.command,
                    auto_execute=False
                ))
            
            elif issue.category == "process" and issue.command:
                remediations.append(Remediation(
                    issue=issue,
                    action="Kill duplicate processes",
                    command=issue.command,
                    auto_execute=False
                ))
            
            elif issue.category == "docker":
                remediations.append(Remediation(
                    issue=issue,
                    action="Clean Docker resources",
                    command=issue.command,
                    auto_execute=False
                ))
        
        return remediations
    
    # ====================
    # Main Methods
    # ====================
    
    def scan(self) -> List[Issue]:
        """Scan for all issues."""
        self.issues = []
        
        print("Scanning for issues...")
        
        # Run all checks
        self.issues.extend(self.check_memory())
        self.issues.extend(self.check_processes())
        self.issues.extend(self.check_zombies())
        self.issues.extend(self.check_docker())
        self.issues.extend(self.check_disk())
        
        return self.issues
    
    def execute_remediation(self, remediation: Remediation) -> bool:
        """Execute a remediation."""
        if self.dry_run:
            print(f"[DRY RUN] Would execute: {remediation.command}")
            remediation.result = "Would execute (dry run)"
            return True
        
        try:
            result = subprocess.run(
                remediation.command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                remediation.result = "Success"
                remediation.executed = True
                return True
            else:
                remediation.result = f"Failed: {result.stderr}"
                return False
        
        except Exception as e:
            remediation.result = f"Error: {e}"
            return False
    
    def auto_fix(self, max_severity: str = "low") -> Dict:
        """Automatically fix issues up to a certain severity."""
        severity_order = ["low", "medium", "high", "critical"]
        max_index = severity_order.index(max_severity)
        
        results = {
            "fixed": [],
            "failed": [],
            "skipped": []
        }
        
        # Scan first
        self.scan()
        
        # Get remediations
        remediations = self.get_remediations()
        
        for rem in remediations:
            if severity_order.index(rem.issue.severity) <= max_index:
                success = self.execute_remediation(rem)
                if success:
                    results["fixed"].append(rem.issue.description)
                else:
                    results["failed"].append(rem.issue.description)
            else:
                results["skipped"].append(rem.issue.description)
        
        return results
    
    def run(self):
        """Run the remediation agent."""
        self.running = True
        
        while self.running:
            self.scan()
            self.remediations = self.get_remediations()
            
            if self.issues:
                print(f"\n=== Found {len(self.issues)} issues ===")
                
                for i, issue in enumerate(self.issues, 1):
                    print(f"{i}. [{issue.severity.upper()}] {issue.category}: {issue.description}")
                
                if not self.dry_run:
                    print("\nApplying auto-fixes...")
                    results = self.auto_fix(max_severity="medium")
                    print(f"Fixed: {results['fixed']}")
                    print(f"Failed: {results['failed']}")
            
            time.sleep(60)  # Check every minute
    
    def stop(self):
        """Stop the agent."""
        self.running = False


# ====================
# CLI Interface
# ====================

def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Automated Remediation Agent")
    parser.add_argument("--scan", action="store_true", help="Scan for issues")
    parser.add_argument("--fix", action="store_true", help="Auto-fix issues")
    parser.add_argument("--dry-run", action="store_true", default=True, help="Dry run mode")
    parser.add_argument("--execute", action="store_true", help="Actually execute fixes")
    parser.add_argument("--daemon", action="store_true", help="Run as daemon")
    parser.add_argument("--max-severity", default="medium", help="Max severity to fix")
    
    args = parser.parse_args()
    
    agent = RemediationAgent(dry_run=not args.execute)
    
    if args.daemon:
        print("Starting remediation agent in daemon mode...")
        print("Press Ctrl+C to stop")
        
        def signal_handler(sig, frame):
            print("\nStopping...")
            agent.stop()
        
        signal.signal(signal.SIGINT, signal_handler)
        agent.run()
    
    elif args.scan:
        issues = agent.scan()
        
        if not issues:
            print("No issues found!")
        else:
            print(f"\n=== Found {len(issues)} issues ===\n")
            
            for i, issue in enumerate(issues, 1):
                print(f"{i}. [{issue.severity.upper()}] {issue.category}")
                print(f"   {issue.description}")
                if issue.command:
                    print(f"   Fix: {issue.command}")
                print()
            
            remediations = agent.get_remediations()
            if remediations:
                print(f"\n=== Recommended Actions ===\n")
                
                for i, rem in enumerate(remediations, 1):
                    print(f"{i}. {rem.action}")
                    print(f"   Command: {rem.command}")
                    print()
    
    elif args.fix:
        results = agent.auto_fix(max_severity=args.max_severity)
        
        print("\n=== Remediation Results ===")
        print(f"Fixed: {results['fixed']}")
        print(f"Failed: {results['failed']}")
        print(f"Skipped: {results['skipped']}")
    
    else:
        print("Usage: remediation_agent.py --scan")
        print("       remediation_agent.py --fix")
        print("       remediation_agent.py --daemon")


if __name__ == "__main__":
    main()
