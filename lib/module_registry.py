#!/usr/bin/env python3
"""
Module Registry for bash.d

Provides a centralized registry for discovering, loading, and managing
all bash.d modules including:
- Agents
- Tools  
- Bash functions
- Aliases
- Plugins
- Completions
"""

import os
import sys
import json
import importlib
import inspect
from pathlib import Path
from typing import Any, Dict, List, Optional, Type, Callable
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum


class ModuleType(str, Enum):
    """Types of modules in bash.d"""
    AGENT = "agent"
    TOOL = "tool"
    FUNCTION = "function"
    ALIAS = "alias"
    PLUGIN = "plugin"
    COMPLETION = "completion"
    CONFIG = "config"


@dataclass
class ModuleInfo:
    """Information about a registered module"""
    name: str
    type: ModuleType
    path: Path
    description: str = ""
    version: str = "1.0.0"
    enabled: bool = True
    dependencies: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    loaded_at: Optional[datetime] = None
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            'type': self.type.value,
            'path': str(self.path),
            'description': self.description,
            'version': self.version,
            'enabled': self.enabled,
            'dependencies': self.dependencies,
            'tags': self.tags,
        }


class ModuleRegistry:
    """
    Central registry for all bash.d modules
    
    Features:
    - Automatic module discovery
    - Lazy loading
    - Dependency tracking
    - Module validation
    - Search and filtering
    """
    
    def __init__(self, root_path: Optional[str] = None):
        self.root = Path(root_path) if root_path else self._find_root()
        self._modules: Dict[str, ModuleInfo] = {}
        self._loaded: Dict[str, Any] = {}
        self._discovered = False
        
    def _find_root(self) -> Path:
        """Find bash.d root directory"""
        if 'BASHD_HOME' in os.environ:
            return Path(os.environ['BASHD_HOME'])
        
        candidates = [Path.cwd(), Path.home() / '.bash.d']
        for candidate in candidates:
            if (candidate / 'bashrc').exists():
                return candidate
        return Path.cwd()
    
    def discover(self, force: bool = False) -> int:
        """
        Discover all modules in the project
        
        Returns number of modules discovered.
        """
        if self._discovered and not force:
            return len(self._modules)
        
        self._modules.clear()
        count = 0
        
        # Discover Python agents
        count += self._discover_agents()
        
        # Discover Python tools
        count += self._discover_tools()
        
        # Discover bash functions
        count += self._discover_bash_functions()
        
        # Discover aliases
        count += self._discover_aliases()
        
        # Discover plugins
        count += self._discover_plugins()
        
        # Discover completions
        count += self._discover_completions()
        
        self._discovered = True
        return count
    
    def _discover_agents(self) -> int:
        """Discover agent modules"""
        agents_dir = self.root / 'agents'
        count = 0
        
        if not agents_dir.exists():
            return count
        
        for agent_file in agents_dir.glob('**/*_agent.py'):
            name = agent_file.stem.replace('_agent', '')
            description = self._extract_docstring(agent_file)
            
            self._modules[f"agent:{name}"] = ModuleInfo(
                name=name,
                type=ModuleType.AGENT,
                path=agent_file,
                description=description,
                tags=self._extract_tags(agent_file.parent.name)
            )
            count += 1
        
        # Also discover core agent files
        for agent_file in agents_dir.glob('*.py'):
            if agent_file.stem.startswith('_'):
                continue
            name = agent_file.stem
            description = self._extract_docstring(agent_file)
            
            self._modules[f"agent:{name}"] = ModuleInfo(
                name=name,
                type=ModuleType.AGENT,
                path=agent_file,
                description=description,
                tags=['core']
            )
            count += 1
        
        return count
    
    def _discover_tools(self) -> int:
        """Discover tool modules"""
        tools_dir = self.root / 'tools'
        count = 0
        
        if not tools_dir.exists():
            return count
        
        for tool_file in tools_dir.glob('*_tools.py'):
            name = tool_file.stem.replace('_tools', '')
            description = self._extract_docstring(tool_file)
            
            self._modules[f"tool:{name}"] = ModuleInfo(
                name=name,
                type=ModuleType.TOOL,
                path=tool_file,
                description=description
            )
            count += 1
        
        return count
    
    def _discover_bash_functions(self) -> int:
        """Discover bash function modules"""
        func_dir = self.root / 'bash_functions.d'
        count = 0
        
        if not func_dir.exists():
            return count
        
        for func_file in func_dir.glob('**/*.sh'):
            name = func_file.stem
            description = self._extract_bash_description(func_file)
            
            self._modules[f"function:{name}"] = ModuleInfo(
                name=name,
                type=ModuleType.FUNCTION,
                path=func_file,
                description=description,
                tags=self._extract_tags(func_file.parent.name)
            )
            count += 1
        
        return count
    
    def _discover_aliases(self) -> int:
        """Discover alias modules"""
        aliases_dir = self.root / 'aliases'
        count = 0
        
        if not aliases_dir.exists():
            return count
        
        for alias_file in aliases_dir.glob('*.bash'):
            name = alias_file.stem.replace('.aliases', '')
            description = self._extract_bash_description(alias_file)
            
            self._modules[f"alias:{name}"] = ModuleInfo(
                name=name,
                type=ModuleType.ALIAS,
                path=alias_file,
                description=description
            )
            count += 1
        
        return count
    
    def _discover_plugins(self) -> int:
        """Discover plugin modules"""
        plugins_dir = self.root / 'plugins'
        count = 0
        
        if not plugins_dir.exists():
            return count
        
        for plugin_file in plugins_dir.glob('*.bash'):
            name = plugin_file.stem.replace('.plugin', '')
            description = self._extract_bash_description(plugin_file)
            
            self._modules[f"plugin:{name}"] = ModuleInfo(
                name=name,
                type=ModuleType.PLUGIN,
                path=plugin_file,
                description=description
            )
            count += 1
        
        return count
    
    def _discover_completions(self) -> int:
        """Discover completion modules"""
        completions_dir = self.root / 'completions'
        count = 0
        
        if not completions_dir.exists():
            return count
        
        for comp_file in completions_dir.glob('*.bash'):
            name = comp_file.stem.replace('.completion', '')
            description = self._extract_bash_description(comp_file)
            
            self._modules[f"completion:{name}"] = ModuleInfo(
                name=name,
                type=ModuleType.COMPLETION,
                path=comp_file,
                description=description
            )
            count += 1
        
        return count
    
    def _extract_docstring(self, path: Path) -> str:
        """Extract docstring from Python file"""
        try:
            with open(path, 'r') as f:
                content = f.read()
            
            if '"""' in content:
                start = content.find('"""') + 3
                end = content.find('"""', start)
                return content[start:end].strip().split('\n')[0]
        except:
            pass
        return ""
    
    def _extract_bash_description(self, path: Path) -> str:
        """Extract description from bash file comments"""
        try:
            with open(path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line.startswith('#') and not line.startswith('#!'):
                        return line[1:].strip()
                    elif line and not line.startswith('#'):
                        break
        except:
            pass
        return ""
    
    def _extract_tags(self, category: str) -> List[str]:
        """Extract tags from category name"""
        if category and category not in ['.', '..', 'bash_functions.d']:
            return [category]
        return []
    
    def get(self, key: str) -> Optional[ModuleInfo]:
        """Get module by key (type:name)"""
        if not self._discovered:
            self.discover()
        return self._modules.get(key)
    
    def get_by_name(self, name: str, type: Optional[ModuleType] = None) -> List[ModuleInfo]:
        """Get modules by name, optionally filtered by type"""
        if not self._discovered:
            self.discover()
        
        results = []
        for key, module in self._modules.items():
            if module.name == name:
                if type is None or module.type == type:
                    results.append(module)
        return results
    
    def list(
        self,
        type: Optional[ModuleType] = None,
        tags: Optional[List[str]] = None,
        enabled_only: bool = False
    ) -> List[ModuleInfo]:
        """List modules with optional filtering"""
        if not self._discovered:
            self.discover()
        
        results = []
        for module in self._modules.values():
            # Filter by type
            if type and module.type != type:
                continue
            
            # Filter by enabled
            if enabled_only and not module.enabled:
                continue
            
            # Filter by tags
            if tags and not any(t in module.tags for t in tags):
                continue
            
            results.append(module)
        
        return sorted(results, key=lambda m: (m.type.value, m.name))
    
    def search(self, query: str) -> List[ModuleInfo]:
        """Search modules by name or description"""
        if not self._discovered:
            self.discover()
        
        query = query.lower()
        results = []
        
        for module in self._modules.values():
            if (query in module.name.lower() or 
                query in module.description.lower() or
                any(query in tag.lower() for tag in module.tags)):
                results.append(module)
        
        return sorted(results, key=lambda m: m.name)
    
    def load(self, key: str) -> Any:
        """Load and return a Python module"""
        if key in self._loaded:
            return self._loaded[key]
        
        module_info = self.get(key)
        if not module_info:
            raise ModuleNotFoundError(f"Module not found: {key}")
        
        if module_info.type not in [ModuleType.AGENT, ModuleType.TOOL]:
            raise TypeError(f"Cannot load non-Python module: {key}")
        
        # Calculate module path
        rel_path = module_info.path.relative_to(self.root)
        module_path = str(rel_path.with_suffix('')).replace(os.sep, '.')
        
        # Add root to sys.path if needed
        if str(self.root) not in sys.path:
            sys.path.insert(0, str(self.root))
        
        # Import module
        loaded = importlib.import_module(module_path)
        module_info.loaded_at = datetime.now()
        
        self._loaded[key] = loaded
        return loaded
    
    def stats(self) -> Dict[str, int]:
        """Get module statistics"""
        if not self._discovered:
            self.discover()
        
        stats = {t.value: 0 for t in ModuleType}
        for module in self._modules.values():
            stats[module.type.value] += 1
        stats['total'] = len(self._modules)
        
        return stats
    
    def export(self, format: str = 'json') -> str:
        """Export registry as JSON or YAML"""
        if not self._discovered:
            self.discover()
        
        data = {
            'generated_at': datetime.now().isoformat(),
            'root': str(self.root),
            'stats': self.stats(),
            'modules': [m.to_dict() for m in self._modules.values()]
        }
        
        return json.dumps(data, indent=2)
    
    def save_index(self, path: Optional[Path] = None):
        """Save module index to file"""
        if path is None:
            path = self.root / '.bashd_modules.json'
        
        with open(path, 'w') as f:
            f.write(self.export())


# Global registry instance
_registry: Optional[ModuleRegistry] = None


def get_registry() -> ModuleRegistry:
    """Get global module registry instance"""
    global _registry
    if _registry is None:
        _registry = ModuleRegistry()
        _registry.discover()
    return _registry


def list_modules(type: Optional[str] = None) -> List[ModuleInfo]:
    """Convenience function to list modules"""
    mod_type = ModuleType(type) if type else None
    return get_registry().list(type=mod_type)


def search_modules(query: str) -> List[ModuleInfo]:
    """Convenience function to search modules"""
    return get_registry().search(query)


# CLI interface
if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Module Registry CLI')
    parser.add_argument('command', choices=['list', 'search', 'stats', 'export', 'info'])
    parser.add_argument('--type', '-t', help='Filter by module type')
    parser.add_argument('--query', '-q', help='Search query')
    parser.add_argument('--name', '-n', help='Module name')
    args = parser.parse_args()
    
    registry = ModuleRegistry()
    registry.discover()
    
    if args.command == 'list':
        mod_type = ModuleType(args.type) if args.type else None
        modules = registry.list(type=mod_type)
        
        print(f"\n{'Module':<40} {'Type':<12} {'Description'}")
        print("-" * 80)
        for m in modules:
            print(f"{m.name:<40} {m.type.value:<12} {m.description[:30]}")
        print(f"\nTotal: {len(modules)} modules")
    
    elif args.command == 'search':
        if not args.query:
            print("Error: --query required for search")
            sys.exit(1)
        
        modules = registry.search(args.query)
        print(f"\nSearch results for '{args.query}':")
        for m in modules:
            print(f"  [{m.type.value}] {m.name}: {m.description[:50]}")
    
    elif args.command == 'stats':
        stats = registry.stats()
        print("\nModule Statistics:")
        for type_name, count in stats.items():
            print(f"  {type_name}: {count}")
    
    elif args.command == 'export':
        print(registry.export())
    
    elif args.command == 'info':
        if not args.name:
            print("Error: --name required for info")
            sys.exit(1)
        
        modules = registry.get_by_name(args.name)
        if not modules:
            print(f"Module '{args.name}' not found")
            sys.exit(1)
        
        for m in modules:
            print(f"\nModule: {m.name}")
            print(f"  Type: {m.type.value}")
            print(f"  Path: {m.path}")
            print(f"  Description: {m.description}")
            print(f"  Tags: {', '.join(m.tags) or 'none'}")
