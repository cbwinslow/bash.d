#!/usr/bin/env python3
"""
Project Health Checker

Analyzes the bash.d project for health metrics, issues, and recommendations.
"""

import os
import sys
import json
import glob
import subprocess
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class HealthReport:
    """Health report data structure"""
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())
    score: int = 100
    status: str = "healthy"
    statistics: dict = field(default_factory=dict)
    issues: list = field(default_factory=list)
    warnings: list = field(default_factory=list)
    recommendations: list = field(default_factory=list)


class ProjectHealthChecker:
    """Checks project health and generates reports"""
    
    def __init__(self, root_path: Optional[str] = None):
        self.root = Path(root_path or os.getcwd())
        self.report = HealthReport()
        
    def check_all(self) -> HealthReport:
        """Run all health checks"""
        self._check_structure()
        self._check_python_files()
        self._check_shell_scripts()
        self._check_tests()
        self._check_documentation()
        self._check_dependencies()
        self._check_git_status()
        self._calculate_score()
        return self.report
    
    def _check_structure(self):
        """Check project structure"""
        required_dirs = [
            'agents', 'tools', 'tests', 'docs', 'scripts',
            'bash_functions.d', 'configs', 'lib'
        ]
        required_files = [
            'README.md', 'requirements.txt', 'install.sh', 'bashrc'
        ]
        
        missing_dirs = [d for d in required_dirs if not (self.root / d).exists()]
        missing_files = [f for f in required_files if not (self.root / f).exists()]
        
        if missing_dirs:
            self.report.warnings.append(f"Missing directories: {', '.join(missing_dirs)}")
        if missing_files:
            self.report.issues.append(f"Missing required files: {', '.join(missing_files)}")
            
        self.report.statistics['directories'] = len(list(self.root.glob('*/')))
        
    def _check_python_files(self):
        """Check Python files for issues"""
        py_files = list(self.root.glob('**/*.py'))
        py_files = [f for f in py_files if '.git' not in str(f)]
        
        self.report.statistics['python_files'] = len(py_files)
        
        # Check for syntax errors
        syntax_errors = []
        for py_file in py_files[:50]:  # Limit to avoid slowness
            try:
                with open(py_file, 'r') as f:
                    compile(f.read(), py_file, 'exec')
            except SyntaxError as e:
                syntax_errors.append(f"{py_file}: {e.msg}")
                
        if syntax_errors:
            self.report.issues.extend(syntax_errors[:5])
            if len(syntax_errors) > 5:
                self.report.issues.append(f"... and {len(syntax_errors) - 5} more syntax errors")
                
        # Count lines of code
        total_lines = 0
        for py_file in py_files[:100]:
            try:
                with open(py_file, 'r') as f:
                    total_lines += len(f.readlines())
            except:
                pass
        self.report.statistics['python_loc'] = total_lines
        
    def _check_shell_scripts(self):
        """Check shell scripts"""
        sh_files = list(self.root.glob('**/*.sh'))
        sh_files += list(self.root.glob('**/*.bash'))
        sh_files = [f for f in sh_files if '.git' not in str(f)]
        
        self.report.statistics['shell_scripts'] = len(sh_files)
        
        # Check for basic syntax with bash -n
        syntax_errors = []
        for sh_file in sh_files[:20]:
            try:
                result = subprocess.run(
                    ['bash', '-n', str(sh_file)],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                if result.returncode != 0:
                    syntax_errors.append(f"{sh_file.name}: syntax error")
            except:
                pass
                
        if syntax_errors:
            self.report.warnings.extend(syntax_errors[:3])
            
    def _check_tests(self):
        """Check test coverage"""
        test_files = list((self.root / 'tests').glob('test_*.py'))
        self.report.statistics['test_files'] = len(test_files)
        
        # Count test functions
        test_count = 0
        for test_file in test_files:
            try:
                with open(test_file, 'r') as f:
                    content = f.read()
                    test_count += content.count('def test_')
            except:
                pass
        self.report.statistics['test_count'] = test_count
        
        if test_count < 10:
            self.report.recommendations.append(
                "Consider adding more tests. Current count: " + str(test_count)
            )
        elif test_count >= 40:
            self.report.statistics['test_coverage'] = 'good'
            
    def _check_documentation(self):
        """Check documentation status"""
        md_files = list(self.root.glob('**/*.md'))
        md_files = [f for f in md_files if '.git' not in str(f)]
        
        self.report.statistics['documentation_files'] = len(md_files)
        
        # Check README
        readme = self.root / 'README.md'
        if readme.exists():
            with open(readme, 'r') as f:
                content = f.read()
                if len(content) < 1000:
                    self.report.warnings.append("README.md seems too short")
                elif len(content) > 5000:
                    self.report.statistics['readme_status'] = 'comprehensive'
                    
    def _check_dependencies(self):
        """Check dependencies"""
        req_file = self.root / 'requirements.txt'
        if req_file.exists():
            with open(req_file, 'r') as f:
                lines = [l.strip() for l in f if l.strip() and not l.startswith('#')]
                self.report.statistics['dependencies'] = len(lines)
        else:
            self.report.issues.append("requirements.txt not found")
            
    def _check_git_status(self):
        """Check git repository status"""
        try:
            # Check for uncommitted changes
            result = subprocess.run(
                ['git', 'status', '--porcelain'],
                capture_output=True,
                text=True,
                cwd=self.root
            )
            if result.stdout.strip():
                changes = len(result.stdout.strip().split('\n'))
                self.report.warnings.append(f"{changes} uncommitted changes")
                
            # Get current branch
            result = subprocess.run(
                ['git', 'branch', '--show-current'],
                capture_output=True,
                text=True,
                cwd=self.root
            )
            self.report.statistics['git_branch'] = result.stdout.strip()
            
        except Exception as e:
            self.report.warnings.append(f"Git check failed: {e}")
            
    def _calculate_score(self):
        """Calculate overall health score"""
        score = 100
        
        # Deduct for issues
        score -= len(self.report.issues) * 10
        
        # Deduct for warnings
        score -= len(self.report.warnings) * 3
        
        # Bonus for good practices
        if self.report.statistics.get('test_count', 0) >= 40:
            score += 5
        if self.report.statistics.get('documentation_files', 0) >= 10:
            score += 5
            
        self.report.score = max(0, min(100, score))
        
        if self.report.score >= 80:
            self.report.status = "healthy"
        elif self.report.score >= 60:
            self.report.status = "needs attention"
        else:
            self.report.status = "unhealthy"
            
    def print_report(self):
        """Print formatted health report"""
        # Status emoji
        status_emoji = {
            "healthy": "✅",
            "needs attention": "⚠️",
            "unhealthy": "❌"
        }
        
        print("\n" + "=" * 60)
        print("📊 BASH.D PROJECT HEALTH REPORT")
        print("=" * 60)
        
        # Overall status
        emoji = status_emoji.get(self.report.status, "❓")
        print(f"\n{emoji} Status: {self.report.status.upper()}")
        print(f"📈 Health Score: {self.report.score}/100")
        print(f"🕐 Generated: {self.report.timestamp}")
        
        # Statistics
        print("\n📁 Statistics:")
        for key, value in self.report.statistics.items():
            print(f"   • {key.replace('_', ' ').title()}: {value}")
            
        # Issues
        if self.report.issues:
            print("\n❌ Issues:")
            for issue in self.report.issues:
                print(f"   • {issue}")
                
        # Warnings
        if self.report.warnings:
            print("\n⚠️  Warnings:")
            for warning in self.report.warnings:
                print(f"   • {warning}")
                
        # Recommendations
        if self.report.recommendations:
            print("\n💡 Recommendations:")
            for rec in self.report.recommendations:
                print(f"   • {rec}")
                
        print("\n" + "=" * 60)
        
    def to_json(self) -> str:
        """Export report as JSON"""
        return json.dumps({
            'timestamp': self.report.timestamp,
            'score': self.report.score,
            'status': self.report.status,
            'statistics': self.report.statistics,
            'issues': self.report.issues,
            'warnings': self.report.warnings,
            'recommendations': self.report.recommendations
        }, indent=2)


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Check bash.d project health')
    parser.add_argument('--json', action='store_true', help='Output as JSON')
    parser.add_argument('--path', type=str, help='Project root path')
    args = parser.parse_args()
    
    checker = ProjectHealthChecker(args.path)
    checker.check_all()
    
    if args.json:
        print(checker.to_json())
    else:
        checker.print_report()
        
    # Exit with error code if unhealthy
    sys.exit(0 if checker.report.score >= 60 else 1)


if __name__ == '__main__':
    main()
