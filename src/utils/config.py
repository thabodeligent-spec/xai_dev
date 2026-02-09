import yaml
import os
from pathlib import Path
from typing import Any, Dict
import re

class Config:
    """Configuration manager with environment variable support"""

    def __init__(self, config_path: str = "config/config.yaml"):
        self.config_path = Path(config_path)
        self._config = self._load_config()
        self._resolve_env_vars(self._config)

    def _load_config(self) -> Dict:
        """Load YAML configuration"""
        with open(self.config_path, 'r') as f:
            return yaml.safe_load(f)

    def _resolve_env_vars(self, config: Dict) -> None:
        """Recursively resolve ${ENV:var} patterns"""
        env_pattern = re.compile(r'\$\{([^:}]+):([^}]+)\}')

        for key, value in config.items():
            if isinstance(value, dict):
                self._resolve_env_vars(value)
            elif isinstance(value, str):
                match = env_pattern.match(value)
                if match:
                    env_var, default = match.groups()
                    config[key] = os.getenv(env_var, default)

    def get(self, key: str, default: Any = None) -> Any:
        """Get config value using dot notation"""
        keys = key.split('.')
        value = self._config

        for k in keys:
            if isinstance(value, dict):
                value = value.get(k)
            else:
                return default

            if value is None:
                return default

        return value

    def __getitem__(self, key: str) -> Any:
        """Allow dict-like access"""
        return self.get(key)

# Global config instance
config = Config()
