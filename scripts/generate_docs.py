#!/usr/bin/env python3
"""
Documentation Generator for bash.d

Automatically generates documentation from:
- Python docstrings
- Bash function comments
- Configuration files
- Module metadata
"""

import os
import re
import ast
import json
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime


class DocGenerator:
    """Generate documentation from source code"""
    
    def __init__(self, root_path: Optional[str] = None):
        self.root = Path(root_path) if root_path else Path.cwd()
        self.docs_dir = self.root / 'docs'
        self.generated_dir = self.docs_dir / 'generated'
        
    def generate_all(self):
        """Generate all documentation"""
        self.generated_dir.mkdir(parents=True, exist_ok=True)
        
        print("📚 Generating documentation...")
        
        # Generate agent documentation
        self._generate_agents_docs()
        
        # Generate tools documentation
        self._generate_tools_docs()
        
        # Generate function reference
        self._generate_functions_docs()
        
        # Generate configuration reference
        self._generate_config_docs()
        
        # Generate main index
        self._generate_index()
        
        print(f"✓ Documentation generated in {self.generated_dir}")
    
    def _generate_agents_docs(self):
        """Generate documentation for all agents"""
        agents_dir = self.root / 'agents'
        if not agents_dir.exists():
            return
        
        output = ["# Agent Reference\n"]
        output.append(f"Generated: {datetime.now().isoformat()}\n\n")
        output.append("## Overview\n\n")
        output.append("bash.d includes a comprehensive multi-agent system for AI-assisted development.\n\n")
        
        # Group agents by category
        categories: Dict[str, List[Dict]] = {}
        
        for agent_file in agents_dir.glob('**/*_agent.py'):
            category = agent_file.parent.name
            if category == 'agents':
                category = 'core'
            
            if category not in categories:
                categories[category] = []
            
            agent_info = self._parse_python_file(agent_file)
            agent_info['file'] = str(agent_file.relative_to(self.root))
            categories[category].append(agent_info)
        
        # Generate documentation for each category
        for category, agents in sorted(categories.items()):
            output.append(f"## {category.title()} Agents\n\n")
            
            for agent in sorted(agents, key=lambda x: x['name']):
                output.append(f"### {agent['name']}\n\n")
                output.append(f"**File:** `{agent['file']}`\n\n")
                
                if agent['docstring']:
                    output.append(f"{agent['docstring']}\n\n")
                
                if agent['classes']:
                    for cls in agent['classes']:
                        output.append(f"**Class:** `{cls['name']}`\n\n")
                        if cls['docstring']:
                            output.append(f"{cls['docstring']}\n\n")
                        
                        if cls['methods']:
                            output.append("**Methods:**\n\n")
                            for method in cls['methods']:
                                output.append(f"- `{method['name']}`: {method['docstring'][:100] if method['docstring'] else 'No description'}\n")
                            output.append("\n")
                
                output.append("---\n\n")
        
        # Write output
        with open(self.generated_dir / 'AGENTS.md', 'w') as f:
            f.write(''.join(output))
    
    def _generate_tools_docs(self):
        """Generate documentation for all tools"""
        tools_dir = self.root / 'tools'
        if not tools_dir.exists():
            return
        
        output = ["# Tools Reference\n"]
        output.append(f"Generated: {datetime.now().isoformat()}\n\n")
        output.append("## Overview\n\n")
        output.append("bash.d provides a comprehensive set of tools for various operations.\n\n")
        
        for tool_file in sorted(tools_dir.glob('*_tools.py')):
            tool_info = self._parse_python_file(tool_file)
            tool_name = tool_file.stem.replace('_tools', '')
            
            output.append(f"## {tool_name.title()} Tools\n\n")
            output.append(f"**File:** `{tool_file.relative_to(self.root)}`\n\n")
            
            if tool_info['docstring']:
                output.append(f"{tool_info['docstring']}\n\n")
            
            # Document functions
            if tool_info['functions']:
                output.append("### Functions\n\n")
                for func in tool_info['functions']:
                    output.append(f"#### `{func['name']}`\n\n")
                    if func['docstring']:
                        output.append(f"{func['docstring']}\n\n")
                    if func['signature']:
                        output.append(f"```python\n{func['signature']}\n```\n\n")
            
            output.append("---\n\n")
        
        with open(self.generated_dir / 'TOOLS.md', 'w') as f:
            f.write(''.join(output))
    
    def _generate_functions_docs(self):
        """Generate documentation for bash functions"""
        func_dir = self.root / 'bash_functions.d'
        if not func_dir.exists():
            return
        
        output = ["# Bash Functions Reference\n"]
        output.append(f"Generated: {datetime.now().isoformat()}\n\n")
        
        # Group by category
        categories: Dict[str, List[Dict]] = {}
        
        for func_file in func_dir.glob('**/*.sh'):
            category = func_file.parent.name
            if category == 'bash_functions.d':
                category = 'core'
            
            if category not in categories:
                categories[category] = []
            
            functions = self._parse_bash_file(func_file)
            for func in functions:
                func['file'] = str(func_file.relative_to(self.root))
                categories[category].append(func)
        
        for category, functions in sorted(categories.items()):
            output.append(f"## {category.title()}\n\n")
            
            for func in sorted(functions, key=lambda x: x['name']):
                output.append(f"### `{func['name']}`\n\n")
                output.append(f"**File:** `{func['file']}`\n\n")
                if func['description']:
                    output.append(f"{func['description']}\n\n")
            
            output.append("---\n\n")
        
        with open(self.generated_dir / 'FUNCTIONS.md', 'w') as f:
            f.write(''.join(output))
    
    def _generate_config_docs(self):
        """Generate documentation for configurations"""
        configs_dir = self.root / 'configs'
        if not configs_dir.exists():
            return
        
        output = ["# Configuration Reference\n"]
        output.append(f"Generated: {datetime.now().isoformat()}\n\n")
        
        for config_file in sorted(configs_dir.glob('**/*.*')):
            if config_file.suffix not in ['.yaml', '.yml', '.json']:
                continue
            
            output.append(f"## {config_file.stem}\n\n")
            output.append(f"**File:** `{config_file.relative_to(self.root)}`\n\n")
            
            # Try to extract schema or structure
            try:
                with open(config_file, 'r') as f:
                    content = f.read()
                
                if config_file.suffix == '.json':
                    data = json.loads(content)
                    output.append("**Structure:**\n\n```json\n")
                    output.append(json.dumps(self._get_structure(data), indent=2))
                    output.append("\n```\n\n")
                else:
                    output.append("```yaml\n")
                    output.append(content[:500])
                    if len(content) > 500:
                        output.append("\n# ... truncated")
                    output.append("\n```\n\n")
            except:
                pass
        
        with open(self.generated_dir / 'CONFIGURATION.md', 'w') as f:
            f.write(''.join(output))
    
    def _generate_index(self):
        """Generate main documentation index"""
        output = ["# bash.d Documentation\n\n"]
        output.append(f"Generated: {datetime.now().isoformat()}\n\n")
        
        output.append("## Quick Links\n\n")
        output.append("- [README](../README.md) - Getting started\n")
        output.append("- [QUICKSTART](../QUICKSTART.md) - Quick start guide\n")
        output.append("- [CONTRIBUTING](../CONTRIBUTING.md) - How to contribute\n\n")
        
        output.append("## Generated Reference\n\n")
        output.append("- [Agent Reference](generated/AGENTS.md)\n")
        output.append("- [Tools Reference](generated/TOOLS.md)\n")
        output.append("- [Functions Reference](generated/FUNCTIONS.md)\n")
        output.append("- [Configuration Reference](generated/CONFIGURATION.md)\n\n")
        
        output.append("## Guides\n\n")
        
        # List existing documentation
        for doc_file in sorted(self.docs_dir.glob('*.md')):
            if doc_file.name != 'INDEX.md':
                output.append(f"- [{doc_file.stem}]({doc_file.name})\n")
        
        with open(self.docs_dir / 'INDEX.md', 'w') as f:
            f.write(''.join(output))
    
    def _parse_python_file(self, path: Path) -> Dict[str, Any]:
        """Parse Python file and extract documentation"""
        result = {
            'name': path.stem,
            'docstring': '',
            'classes': [],
            'functions': []
        }
        
        try:
            with open(path, 'r') as f:
                content = f.read()
            
            tree = ast.parse(content)
            
            # Get module docstring
            result['docstring'] = ast.get_docstring(tree) or ''
            
            # Get classes and functions
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    cls_info = {
                        'name': node.name,
                        'docstring': ast.get_docstring(node) or '',
                        'methods': []
                    }
                    
                    for item in node.body:
                        if isinstance(item, ast.FunctionDef):
                            cls_info['methods'].append({
                                'name': item.name,
                                'docstring': ast.get_docstring(item) or ''
                            })
                    
                    result['classes'].append(cls_info)
                
                elif isinstance(node, ast.FunctionDef) and node.col_offset == 0:
                    result['functions'].append({
                        'name': node.name,
                        'docstring': ast.get_docstring(node) or '',
                        'signature': self._get_function_signature(node)
                    })
        except:
            pass
        
        return result
    
    def _get_function_signature(self, node: ast.FunctionDef) -> str:
        """Get function signature as string"""
        args = []
        for arg in node.args.args:
            args.append(arg.arg)
        return f"def {node.name}({', '.join(args)})"
    
    def _parse_bash_file(self, path: Path) -> List[Dict[str, Any]]:
        """Parse bash file and extract functions"""
        functions = []
        
        try:
            with open(path, 'r') as f:
                content = f.read()
            
            # Match function definitions
            pattern = r'(?:^|\n)(?:#\s*(.*?)\n)?(?:function\s+)?(\w+)\s*\(\s*\)'
            matches = re.findall(pattern, content)
            
            for comment, name in matches:
                if name and not name.startswith('_'):
                    functions.append({
                        'name': name,
                        'description': comment.strip() if comment else ''
                    })
        except:
            pass
        
        return functions
    
    def _get_structure(self, data: Any, depth: int = 0) -> Any:
        """Get structure of JSON data (types only)"""
        if depth > 3:
            return "..."
        
        if isinstance(data, dict):
            return {k: self._get_structure(v, depth + 1) for k, v in list(data.items())[:5]}
        elif isinstance(data, list):
            if data:
                return [self._get_structure(data[0], depth + 1)]
            return []
        elif isinstance(data, str):
            return "string"
        elif isinstance(data, bool):
            return "boolean"
        elif isinstance(data, int):
            return "integer"
        elif isinstance(data, float):
            return "number"
        elif data is None:
            return "null"
        return str(type(data).__name__)


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate bash.d documentation')
    parser.add_argument('--path', help='Project root path')
    parser.add_argument('--output', help='Output directory')
    args = parser.parse_args()
    
    generator = DocGenerator(args.path)
    if args.output:
        generator.generated_dir = Path(args.output)
    
    generator.generate_all()


if __name__ == '__main__':
    main()
