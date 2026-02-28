#!/usr/bin/env python3
"""
Test Framework for bash.d
Reusable classes for testing scripts, utilities, and AI agents.
"""

import subprocess
import os
import sys
import json
import time
from dataclasses import dataclass, field
from typing import List, Dict, Callable, Optional
from enum import Enum

# Colors for output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

class TestStatus(Enum):
    PASSED = "PASSED"
    FAILED = "FAILED"
    SKIPPED = "SKIPPED"
    RUNNING = "RUNNING"

@dataclass
class TestResult:
    """Result of a single test."""
    name: str
    status: TestStatus
    message: str = ""
    duration: float = 0.0
    output: str = ""
    error: str = ""

class BaseTest:
    """Base class for all tests."""
    
    def __init__(self, name: str):
        self.name = name
        self.result: Optional[TestResult] = None
    
    def run(self) -> TestResult:
        """Run the test."""
        start = time.time()
        try:
            self.result = self._execute()
            self.result.duration = time.time() - start
        except Exception as e:
            self.result = TestResult(
                name=self.name,
                status=TestStatus.FAILED,
                message=str(e),
                duration=time.time() - start
            )
        return self.result
    
    def _execute(self) -> TestResult:
        """Override this in subclasses."""
        raise NotImplementedError
    
    def print_result(self):
        """Print test result."""
        if not self.result:
            return
        
        status_str = f"{Colors.GREEN}{self.result.status.value}{Colors.END}"
        if self.result.status == TestStatus.FAILED:
            status_str = f"{Colors.RED}{self.result.status.value}{Colors.END}"
        elif self.result.status == TestStatus.SKIPPED:
            status_str = f"{Colors.YELLOW}{self.result.status.value}{Colors.END}"
        
        print(f"  [{status_str}] {self.name}")
        if self.result.message:
            print(f"        {self.result.message}")

class ShellTest(BaseTest):
    """Test that runs a shell command."""
    
    def __init__(self, name: str, command: str, expected_exit_code: int = 0):
        super().__init__(name)
        self.command = command
        self.expected_exit_code = expected_exit_code
    
    def _execute(self) -> TestResult:
        result = subprocess.run(
            self.command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode == self.expected_exit_code:
            return TestResult(
                name=self.name,
                status=TestStatus.PASSED,
                output=result.stdout
            )
        else:
            return TestResult(
                name=self.name,
                status=TestStatus.FAILED,
                message=f"Exit code: {result.returncode}, expected: {self.expected_exit_code}",
                output=result.stdout,
                error=result.stderr
            )

class ScriptTest(BaseTest):
    """Test a bash.d script."""
    
    def __init__(self, name: str, script_path: str, args: str = "", expected_exit_code: int = 0):
        super().__init__(name)
        self.script_path = script_path
        self.args = args
        self.expected_exit_code = expected_exit_code
    
    def _execute(self) -> TestResult:
        if not os.path.exists(self.script_path):
            return TestResult(
                name=self.name,
                status=TestStatus.FAILED,
                message=f"Script not found: {self.script_path}"
            )
        
        cmd = f"bash {self.script_path} {self.args}"
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode == self.expected_exit_code:
            return TestResult(
                name=self.name,
                status=TestStatus.PASSED,
                output=result.stdout
            )
        else:
            return TestResult(
                name=self.name,
                status=TestStatus.FAILED,
                message=f"Exit code: {result.returncode}",
                output=result.stdout,
                error=result.stderr
            )

class DockerTest(BaseTest):
    """Test Docker containers."""
    
    def __init__(self, name: str, container_name: str):
        super().__init__(name)
        self.container_name = container_name
    
    def _execute(self) -> TestResult:
        # Check if container is running
        result = subprocess.run(
            f"docker ps --filter name={self.container_name} --format '{{{{.Names}}}}'",
            shell=True,
            capture_output=True,
            text=True
        )
        
        if self.container_name in result.stdout:
            return TestResult(
                name=self.name,
                status=TestStatus.PASSED,
                message=f"Container {self.container_name} is running"
            )
        else:
            return TestResult(
                name=self.name,
                status=TestStatus.FAILED,
                message=f"Container {self.container_name} is not running"
            )

class DatabaseTest(BaseTest):
    """Test database connectivity."""
    
    def __init__(self, name: str, connection_string: str, query: str = "SELECT 1"):
        super().__init__(name)
        self.connection_string = connection_string
        self.query = query
    
    def _execute(self) -> TestResult:
        cmd = f"psql '{self.connection_string}' -c '{self.query}' -t"
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0:
            return TestResult(
                name=self.name,
                status=TestStatus.PASSED,
                output=result.stdout.strip()
            )
        else:
            return TestResult(
                name=self.name,
                status=TestStatus.FAILED,
                message=result.stderr,
                error=result.stderr
            )

class TestSuite:
    """Collection of tests."""
    
    def __init__(self, name: str):
        self.name = name
        self.tests: List[BaseTest] = []
        self.results: List[TestResult] = []
    
    def add(self, test: BaseTest):
        """Add a test to the suite."""
        self.tests.append(test)
    
    def run_all(self) -> List[TestResult]:
        """Run all tests."""
        self.results = []
        
        print(f"\n{Colors.BOLD}━━━ {self.name} ━━━{Colors.END}\n")
        
        for test in self.tests:
            test.run()
            test.print_result()
            self.results.append(test.result)
        
        return self.results
    
    def summary(self):
        """Print test summary."""
        passed = sum(1 for r in self.results if r.status == TestStatus.PASSED)
        failed = sum(1 for r in self.results if r.status == TestStatus.FAILED)
        skipped = sum(1 for r in self.results if r.status == TestStatus.SKIPPED)
        total = len(self.results)
        
        print(f"\n{Colors.BOLD}━━━ Summary ━━━{Colors.END}")
        print(f"  Total:   {total}")
        print(f"  {Colors.GREEN}Passed:   {passed}{Colors.END}")
        print(f"  {Colors.RED}Failed:   {failed}{Colors.END}")
        print(f"  {Colors.YELLOW}Skipped:  {skipped}{Colors.END}")
        
        return failed == 0

# Example: Create smoke tests for bash.d
def create_smoke_tests() -> TestSuite:
    """Create smoke tests for bash.d."""
    suite = TestSuite("bash.d Smoke Tests")
    
    # Script tests
    suite.add(ShellTest(
        "System Analyzer Script Exists",
        "test -f ~/bash.d/scripts/system_analyzer.sh"
    ))
    
    suite.add(ShellTest(
        "Monitor Script Exists",
        "test -f ~/bash.d/scripts/monitor.sh"
    ))
    
    suite.add(ShellTest(
        "Menu Script Exists", 
        "test -f ~/bash.d/scripts/menu.sh"
    ))
    
    suite.add(ShellTest(
        "AI Sys Agent Exists",
        "test -f ~/bash.d/scripts/ai_sys_agent.sh"
    ))
    
    # Docker tests
    suite.add(DockerTest(
        "PostgreSQL Container Running",
        "telemetry-postgres"
    ))
    
    suite.add(DockerTest(
        "ChromaDB Container Running",
        "epstein-chroma"
    ))
    
    suite.add(DockerTest(
        "Neo4j Container Running",
        "epstein-neo4j"
    ))
    
    # Database tests
    suite.add(DockerTest(
        "Redis Container Running",
        "epstein-redis"
    ))
    
    # System tests
    suite.add(ShellTest(
        "Memory Check",
        "free -h | grep Mem"
    ))
    
    suite.add(ShellTest(
        "Disk Check",
        "df -h /"
    ))
    
    return suite

if __name__ == "__main__":
    suite = create_smoke_tests()
    suite.run_all()
    suite.summary()
