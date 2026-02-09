import json
from pathlib import Path
from datetime import datetime

class ModelRegistry:
    """Track and version models"""

    def __init__(self, registry_path: str = "models/registry.json"):
        self.registry_path = Path(registry_path)
        self.registry = self._load_registry()

    def _load_registry(self):
        if self.registry_path.exists():
            with open(self.registry_path) as f:
                return json.load(f)
        return {"models": []}

    def register_model(self, name: str, version: str,
                      metrics: dict, path: str):
        """Register a new model version"""
        model_info = {
            "name": name,
            "version": version,
            "timestamp": datetime.now().isoformat(),
            "metrics": metrics,
            "path": path,
            "status": "experimental"
        }
        self.registry["models"].append(model_info)
        self._save_registry()

    def promote_to_production(self, name: str, version: str):
        """Promote model to production"""
        for model in self.registry["models"]:
            if model["name"] == name and model["version"] == version:
                model["status"] = "production"
        self._save_registry()

    def get_production_model(self, name: str):
        """Get latest production model"""
        prod_models = [
            m for m in self.registry["models"]
            if m["name"] == name and m["status"] == "production"
        ]
        if not prod_models:
            raise ValueError(f"No production model for {name}")
        return max(prod_models, key=lambda x: x["timestamp"])
