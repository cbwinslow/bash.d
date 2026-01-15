#!/usr/bin/env python3
"""
Configuration Manager for bash.d

Provides centralized configuration management with:
- YAML and JSON configuration loading
- Environment variable interpolation
- Configuration validation
- Schema validation
- Hierarchical configuration merging
"""

import os
import re
import json
from pathlib import Path
from typing import Any, Dict, List, Optional, Union
from dataclasses import dataclass, field
from datetime import datetime


try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


@dataclass
class ConfigSource:
    """Represents a configuration source"""
    path: Path
    format: str  # 'yaml', 'json', 'env'
    priority: int = 0
    loaded_at: Optional[datetime] = None
    data: Dict[str, Any] = field(default_factory=dict)


class ConfigurationError(Exception):
    """Configuration related errors"""
    pass


class ConfigManager:
    """
    Centralized configuration management for bash.d
    
    Features:
    - Load configurations from multiple sources
    - Support for YAML, JSON, and environment variables
    - Environment variable interpolation (${VAR} syntax)
    - Configuration validation
    - Hierarchical merging with priority support
    """
    
    def __init__(self, root_path: Optional[str] = None):
        self.root = Path(root_path) if root_path else self._find_root()
        self.configs_dir = self.root / 'configs'
        self.sources: List[ConfigSource] = []
        self._cache: Dict[str, Any] = {}
        self._env_pattern = re.compile(r'\$\{([^}]+)\}')
        
    def _find_root(self) -> Path:
        """Find bash.d root directory"""
        # Check environment
        if 'BASHD_HOME' in os.environ:
            return Path(os.environ['BASHD_HOME'])
        
        # Check common locations
        candidates = [
            Path.cwd(),
            Path.home() / '.bash.d',
            Path.home() / 'bash.d',
        ]
        
        for candidate in candidates:
            if (candidate / 'bashrc').exists():
                return candidate
        
        return Path.cwd()
    
    def load(self, name: str, required: bool = True) -> Dict[str, Any]:
        """
        Load a configuration by name
        
        Args:
            name: Configuration name (without extension)
            required: Raise error if not found
            
        Returns:
            Configuration dictionary
        """
        # Check cache
        if name in self._cache:
            return self._cache[name]
        
        # Try different extensions
        extensions = ['.yaml', '.yml', '.json']
        config_file = None
        
        for ext in extensions:
            candidate = self.configs_dir / f'{name}{ext}'
            if candidate.exists():
                config_file = candidate
                break
        
        # Also check subdirectories
        if not config_file:
            for ext in extensions:
                matches = list(self.configs_dir.glob(f'**/{name}{ext}'))
                if matches:
                    config_file = matches[0]
                    break
        
        if not config_file:
            if required:
                raise ConfigurationError(f"Configuration '{name}' not found")
            return {}
        
        # Load and parse
        data = self._load_file(config_file)
        
        # Interpolate environment variables
        data = self._interpolate_env(data)
        
        # Cache and return
        self._cache[name] = data
        return data
    
    def load_all(self, pattern: str = '*') -> Dict[str, Dict[str, Any]]:
        """Load all configurations matching pattern"""
        configs = {}
        
        for ext in ['.yaml', '.yml', '.json']:
            for config_file in self.configs_dir.glob(f'{pattern}{ext}'):
                name = config_file.stem
                if name not in configs:
                    configs[name] = self.load(name, required=False)
        
        return configs
    
    def _load_file(self, path: Path) -> Dict[str, Any]:
        """Load configuration from file"""
        with open(path, 'r') as f:
            content = f.read()
        
        if path.suffix in ['.yaml', '.yml']:
            if not HAS_YAML:
                raise ConfigurationError("PyYAML not installed. Run: pip install pyyaml")
            return yaml.safe_load(content) or {}
        elif path.suffix == '.json':
            return json.loads(content) or {}
        else:
            raise ConfigurationError(f"Unsupported format: {path.suffix}")
    
    def _interpolate_env(self, data: Any) -> Any:
        """Recursively interpolate environment variables"""
        if isinstance(data, str):
            # Replace ${VAR} with environment value
            def replace(match):
                var_name = match.group(1)
                # Support default values: ${VAR:-default}
                if ':-' in var_name:
                    var_name, default = var_name.split(':-', 1)
                    return os.environ.get(var_name, default)
                return os.environ.get(var_name, match.group(0))
            
            return self._env_pattern.sub(replace, data)
        elif isinstance(data, dict):
            return {k: self._interpolate_env(v) for k, v in data.items()}
        elif isinstance(data, list):
            return [self._interpolate_env(item) for item in data]
        return data
    
    def get(self, key: str, default: Any = None) -> Any:
        """
        Get a configuration value using dot notation
        
        Example:
            config.get('agents.default.model')
            config.get('database.host', 'localhost')
        """
        parts = key.split('.')
        
        if not parts:
            return default
        
        # First part is the config name
        config_name = parts[0]
        
        try:
            data = self.load(config_name, required=False)
        except ConfigurationError:
            return default
        
        # Navigate nested keys
        for part in parts[1:]:
            if isinstance(data, dict) and part in data:
                data = data[part]
            else:
                return default
        
        return data
    
    def set(self, name: str, data: Dict[str, Any], format: str = 'yaml'):
        """
        Save a configuration
        
        Args:
            name: Configuration name
            data: Configuration data
            format: Output format ('yaml' or 'json')
        """
        self.configs_dir.mkdir(parents=True, exist_ok=True)
        
        if format == 'yaml':
            if not HAS_YAML:
                format = 'json'
            else:
                config_file = self.configs_dir / f'{name}.yaml'
                with open(config_file, 'w') as f:
                    yaml.dump(data, f, default_flow_style=False)
                self._cache[name] = data
                return
        
        config_file = self.configs_dir / f'{name}.json'
        with open(config_file, 'w') as f:
            json.dump(data, f, indent=2)
        self._cache[name] = data
    
    def merge(self, *configs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Deep merge multiple configurations
        
        Later configs override earlier ones.
        """
        result = {}
        
        for config in configs:
            result = self._deep_merge(result, config)
        
        return result
    
    def _deep_merge(self, base: Dict, override: Dict) -> Dict:
        """Deep merge two dictionaries"""
        result = base.copy()
        
        for key, value in override.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._deep_merge(result[key], value)
            else:
                result[key] = value
        
        return result
    
    def validate(self, name: str, schema: Optional[Dict] = None) -> List[str]:
        """
        Validate a configuration against a schema
        
        Returns list of validation errors (empty if valid).
        """
        errors = []
        
        try:
            data = self.load(name)
        except ConfigurationError as e:
            return [str(e)]
        
        if schema:
            errors.extend(self._validate_schema(data, schema, ''))
        
        return errors
    
    def _validate_schema(self, data: Any, schema: Dict, path: str) -> List[str]:
        """Validate data against schema"""
        errors = []
        
        # Check type
        expected_type = schema.get('type')
        if expected_type:
            type_map = {
                'string': str,
                'integer': int,
                'number': (int, float),
                'boolean': bool,
                'array': list,
                'object': dict,
            }
            expected = type_map.get(expected_type)
            if expected and not isinstance(data, expected):
                errors.append(f"{path}: expected {expected_type}, got {type(data).__name__}")
        
        # Check required properties
        if schema.get('type') == 'object' and 'properties' in schema:
            required = schema.get('required', [])
            for prop in required:
                if prop not in data:
                    errors.append(f"{path}.{prop}: required property missing")
            
            # Validate nested properties
            for prop, prop_schema in schema.get('properties', {}).items():
                if prop in data:
                    errors.extend(self._validate_schema(
                        data[prop], prop_schema, f"{path}.{prop}"
                    ))
        
        return errors
    
    def clear_cache(self):
        """Clear configuration cache"""
        self._cache.clear()
    
    def list_configs(self) -> List[str]:
        """List all available configurations"""
        configs = set()
        
        if self.configs_dir.exists():
            for ext in ['.yaml', '.yml', '.json']:
                for config_file in self.configs_dir.glob(f'**/*{ext}'):
                    configs.add(config_file.stem)
        
        return sorted(configs)
    
    def export(self, name: str, format: str = 'json') -> str:
        """Export configuration as string"""
        data = self.load(name)
        
        if format == 'yaml' and HAS_YAML:
            return yaml.dump(data, default_flow_style=False)
        return json.dumps(data, indent=2)


# Global configuration manager instance
_config_manager: Optional[ConfigManager] = None


def get_config_manager() -> ConfigManager:
    """Get global configuration manager instance"""
    global _config_manager
    if _config_manager is None:
        _config_manager = ConfigManager()
    return _config_manager


def get_config(key: str, default: Any = None) -> Any:
    """Convenience function to get configuration value"""
    return get_config_manager().get(key, default)


def load_config(name: str, required: bool = True) -> Dict[str, Any]:
    """Convenience function to load configuration"""
    return get_config_manager().load(name, required)


# CLI interface
if __name__ == '__main__':
    import sys
    
    manager = ConfigManager()
    
    if len(sys.argv) < 2:
        print("Usage: config_manager.py [list|load|get|validate] [args...]")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == 'list':
        for config in manager.list_configs():
            print(f"  • {config}")
    
    elif command == 'load' and len(sys.argv) > 2:
        name = sys.argv[2]
        try:
            data = manager.load(name)
            print(json.dumps(data, indent=2))
        except ConfigurationError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    
    elif command == 'get' and len(sys.argv) > 2:
        key = sys.argv[2]
        value = manager.get(key)
        print(value if value is not None else "null")
    
    elif command == 'validate' and len(sys.argv) > 2:
        name = sys.argv[2]
        errors = manager.validate(name)
        if errors:
            print("Validation errors:")
            for error in errors:
                print(f"  • {error}")
            sys.exit(1)
        else:
            print("✓ Configuration valid")
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
