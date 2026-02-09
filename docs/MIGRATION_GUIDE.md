# Migration Guide: Restructuring Your Project

## 🎯 Goal
Transform your current project structure into the best-practice structure for maintainability, scalability, and team collaboration.

## 📊 Current vs. Proposed Structure

### Current Structure (Based on your document)
```
xai-student-suicide-prediction/
├── src/
│   ├── data/
│   │   ├── data_loader.py
│   │   └── data_fusion.py
│   ├── models/
│   │   └── model_trainer.py
│   ├── features/
│   ├── dashboard/
│   │   └── app.py
│   └── evaluation/
│       ├── metrics.py
│       └── fairness_audit.py
├── data/
│   └── synthetic/
├── models/
├── scripts/
│   ├── generate_synthetic_data.py
│   └── train_model.py
└── notebooks/
```

### Issues with Current Structure
- ❌ Flat module hierarchy (hard to navigate as it grows)
- ❌ No clear separation between production and experimental code
- ❌ Configuration management unclear
- ❌ No testing structure
- ❌ Deployment code mixed with source
- ❌ No API layer for programmatic access

## 🔄 Step-by-Step Migration

### Phase 1: Reorganize Core Source Code (Week 1)

#### Step 1.1: Enhanced Data Module
```bash
# Current
src/data/
  ├── data_loader.py
  └── data_fusion.py

# Proposed
src/data/
  ├── __init__.py
  ├── data_loader.py       # Keep as is
  ├── data_fusion.py       # Keep as is
  ├── data_validator.py    # NEW - Add data quality checks
  ├── preprocessor.py      # NEW - Extract preprocessing logic
  └── schemas.py           # NEW - Define data schemas
```

**Action Items:**
```python
# Create src/data/data_validator.py
class DataValidator:
    """Validate data quality and schema"""
    
    def validate_schema(self, df, expected_columns):
        """Check if dataframe has expected columns"""
        missing = set(expected_columns) - set(df.columns)
        if missing:
            raise ValueError(f"Missing columns: {missing}")
    
    def check_data_quality(self, df):
        """Check for nulls, duplicates, outliers"""
        issues = {}
        issues['null_counts'] = df.isnull().sum()
        issues['duplicates'] = df.duplicated().sum()
        return issues

# Create src/data/schemas.py
BEHAVIORAL_SCHEMA = {
    'student_id': 'object',
    'lms_logins_per_week': 'float64',
    'attendance_rate': 'float64',
    'absences_count': 'int64'
}

ACADEMIC_SCHEMA = {
    'student_id': 'object',
    'gpa': 'float64',
    'failed_courses': 'int64',
    'grade_average': 'float64'
}
```

#### Step 1.2: Enhanced Models Module
```bash
# Current
src/models/
  └── model_trainer.py

# Proposed
src/models/
  ├── __init__.py
  ├── base_model.py           # NEW - Abstract base class
  ├── random_forest.py        # EXTRACT from model_trainer.py
  ├── xgboost_model.py        # EXTRACT from model_trainer.py
  ├── ensemble.py             # NEW - Ensemble methods
  ├── model_trainer.py        # REFACTOR - Orchestration only
  ├── model_registry.py       # NEW - Model versioning
  └── hyperparameter_tuner.py # NEW - Separate tuning logic
```

**Action Items:**
```python
# Create src/models/base_model.py
from abc import ABC, abstractmethod
import joblib

class BaseModel(ABC):
    """Abstract base class for all models"""
    
    def __init__(self, config: dict):
        self.config = config
        self.model = None
        self.is_trained = False
    
    @abstractmethod
    def build(self):
        """Build the model"""
        pass
    
    @abstractmethod
    def train(self, X, y):
        """Train the model"""
        pass
    
    def predict(self, X):
        """Make predictions"""
        if not self.is_trained:
            raise RuntimeError("Model not trained")
        return self.model.predict(X)
    
    def save(self, path: str):
        """Save model to disk"""
        joblib.dump(self.model, path)
    
    @classmethod
    def load(cls, path: str):
        """Load model from disk"""
        instance = cls({})
        instance.model = joblib.load(path)
        instance.is_trained = True
        return instance

# Create src/models/random_forest.py
from sklearn.ensemble import RandomForestClassifier
from .base_model import BaseModel

class RandomForestModel(BaseModel):
    """Random Forest implementation"""
    
    def build(self):
        self.model = RandomForestClassifier(**self.config)
        return self
    
    def train(self, X, y):
        self.model.fit(X, y)
        self.is_trained = True
        return self

# Create src/models/model_registry.py
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
```

#### Step 1.3: Enhanced Dashboard Module
```bash
# Current
src/dashboard/
  └── app.py

# Proposed
src/dashboard/
  ├── __init__.py
  ├── app.py                # REFACTOR - Main entry point only
  ├── pages/                # NEW - Multi-page structure
  │   ├── __init__.py
  │   ├── home.py
  │   ├── predictions.py
  │   ├── analytics.py
  │   └── explanations.py
  ├── components/           # NEW - Reusable components
  │   ├── __init__.py
  │   ├── charts.py
  │   ├── tables.py
  │   └── sidebar.py
  └── utils/
      ├── __init__.py
      ├── session_state.py
      └── cache.py
```

**Action Items:**
```python
# Refactor src/dashboard/app.py
import streamlit as st
from .pages import home, predictions, analytics, explanations
from .components import sidebar

def main():
    st.set_page_config(
        page_title="XAI Student Risk Dashboard",
        layout="wide"
    )
    
    # Sidebar navigation
    page = sidebar.render()
    
    # Route to pages
    pages = {
        "Home": home.render,
        "Predictions": predictions.render,
        "Analytics": analytics.render,
        "Explanations": explanations.render
    }
    
    pages[page]()

if __name__ == "__main__":
    main()

# Create src/dashboard/pages/predictions.py
import streamlit as st
import pandas as pd
from src.models.model_registry import ModelRegistry
from src.explainability import SHAPExplainer

def render():
    st.title("Risk Predictions")
    
    # Load production model
    registry = ModelRegistry()
    model_info = registry.get_production_model("random_forest")
    model = load_model(model_info["path"])
    
    # File upload
    uploaded_file = st.file_uploader("Upload student data (CSV)")
    
    if uploaded_file:
        df = pd.read_csv(uploaded_file)
        
        # Make predictions
        predictions = model.predict(df)
        probabilities = model.predict_proba(df)
        
        # Display results
        results_df = df.copy()
        results_df['risk_prediction'] = predictions
        results_df['risk_probability'] = probabilities[:, 1]
        
        st.dataframe(results_df)
        
        # Show explanations
        if st.button("Explain Predictions"):
            explainer = SHAPExplainer(model)
            st.pyplot(explainer.plot_force_plot(df.iloc[0]))

# Create src/dashboard/components/charts.py
import plotly.graph_objects as go
import plotly.express as px

class Charts:
    """Reusable chart components"""
    
    @staticmethod
    def risk_distribution(predictions):
        fig = px.histogram(
            predictions, 
            x='risk_probability',
            title='Risk Probability Distribution'
        )
        return fig
    
    @staticmethod
    def feature_importance(feature_names, importances):
        fig = go.Figure([go.Bar(
            x=importances,
            y=feature_names,
            orientation='h'
        )])
        fig.update_layout(title='Feature Importance')
        return fig
```

### Phase 2: Add Configuration Management (Week 2)

#### Step 2.1: Create Configuration System
```bash
mkdir -p config
```

**Create config/config.yaml:**
```yaml
# Environment
environment: ${ENV:dev}

# Paths
paths:
  data_dir: data
  models_dir: models
  logs_dir: logs

# Data processing
data:
  raw_path: ${paths.data_dir}/raw
  processed_path: ${paths.data_dir}/processed
  test_size: 0.2
  val_size: 0.1
  random_state: 42
  
  # Feature columns
  behavioral_features:
    - lms_logins_per_week
    - attendance_rate
    - absences_count
  
  academic_features:
    - gpa
    - failed_courses
    - grade_average
  
  engagement_features:
    - facility_visits
    - wifi_usage_hours
    - club_participation

# Models
models:
  random_forest:
    n_estimators: 100
    max_depth: 10
    min_samples_split: 2
    min_samples_leaf: 1
    class_weight: balanced
  
  xgboost:
    n_estimators: 100
    learning_rate: 0.1
    max_depth: 6
    subsample: 0.8
    colsample_bytree: 0.8
    scale_pos_weight: 5

# Training
training:
  use_smote: true
  smote_sampling_strategy: 0.5
  cross_validation_folds: 5
  hyperparameter_tuning: true
  
  grid_search:
    cv: 5
    scoring: roc_auc
    n_jobs: -1

# Dashboard
dashboard:
  title: "XAI Student Risk Dashboard"
  port: 8501
  theme: light
  max_upload_size: 200  # MB

# AWS
aws:
  region: ${AWS_REGION:us-east-1}
  s3_bucket: ${S3_BUCKET}
  use_s3: false

# Monitoring
monitoring:
  enable_mlflow: false
  log_level: INFO
  track_custom_metrics: true
```

**Create src/utils/config.py:**
```python
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
```

**Usage in code:**
```python
# In any module
from src.utils.config import config

# Get values
n_estimators = config.get('models.random_forest.n_estimators')
data_path = config.get('paths.data_dir')
features = config.get('data.behavioral_features')
```

### Phase 3: Add Testing Infrastructure (Week 2)

#### Step 3.1: Set Up Testing Structure
```bash
mkdir -p tests/{unit,integration,e2e}
```

**Create tests/conftest.py:**
```python
import pytest
import pandas as pd
import numpy as np
from pathlib import Path

@pytest.fixture
def sample_data():
    """Generate sample dataset for testing"""
    return pd.DataFrame({
        'student_id': [f'S{i:04d}' for i in range(100)],
        'lms_logins_per_week': np.random.randint(0, 20, 100),
        'attendance_rate': np.random.uniform(0.5, 1.0, 100),
        'gpa': np.random.uniform(2.0, 4.0, 100),
        'risk_level': np.random.choice([0, 1], 100, p=[0.9, 0.1])
    })

@pytest.fixture
def trained_model():
    """Provide a trained model for testing"""
    from src.models.random_forest import RandomForestModel
    from sklearn.datasets import make_classification
    
    X, y = make_classification(n_samples=100, n_features=10, random_state=42)
    model = RandomForestModel({'n_estimators': 10, 'random_state': 42})
    model.build().train(X, y)
    return model

@pytest.fixture
def config():
    """Provide test configuration"""
    from src.utils.config import Config
    return Config('config/config.yaml')
```

**Create tests/unit/test_data_loader.py:**
```python
import pytest
from src.data.data_loader import load_data

def test_load_data_success(tmp_path, sample_data):
    """Test successful data loading"""
    # Create temp CSV
    csv_path = tmp_path / "test.csv"
    sample_data.to_csv(csv_path, index=False)
    
    # Load and verify
    df = load_data(str(csv_path))
    assert len(df) == len(sample_data)
    assert list(df.columns) == list(sample_data.columns)

def test_load_data_file_not_found():
    """Test error handling for missing file"""
    with pytest.raises(FileNotFoundError):
        load_data("nonexistent.csv")
```

**Create tests/unit/test_models.py:**
```python
import pytest
import numpy as np
from src.models.random_forest import RandomForestModel

def test_model_training():
    """Test model can be trained"""
    X = np.random.rand(100, 10)
    y = np.random.randint(0, 2, 100)
    
    model = RandomForestModel({'n_estimators': 10})
    model.build().train(X, y)
    
    assert model.is_trained
    assert model.model is not None

def test_model_prediction(trained_model):
    """Test model can make predictions"""
    X_test = np.random.rand(10, 10)
    predictions = trained_model.predict(X_test)
    
    assert len(predictions) == 10
    assert all(p in [0, 1] for p in predictions)

def test_model_save_load(trained_model, tmp_path):
    """Test model persistence"""
    save_path = tmp_path / "model.pkl"
    
    # Save
    trained_model.save(str(save_path))
    assert save_path.exists()
    
    # Load
    loaded_model = RandomForestModel.load(str(save_path))
    assert loaded_model.is_trained
```

### Phase 4: Add Documentation (Week 3)

#### Create docs/README.md:
```markdown
# XAI Dashboard Documentation

## Table of Contents
1. [Architecture](architecture.md)
2. [API Reference](api.md)
3. [Deployment Guide](deployment.md)
4. [User Guide](user_guide.md)
5. [Development Guide](development.md)
6. [Ethics Guidelines](ethics_guidelines.md)

## Quick Links
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
```

### Phase 5: Migration Checklist

```
✅ Phase 1: Core Restructuring
  ✅ Enhanced data module
  ✅ Enhanced models module
  ✅ Multi-page dashboard
  ✅ Reusable components

✅ Phase 2: Configuration
  ✅ Create config.yaml
  ✅ Create Config class
  ✅ Update code to use config

✅ Phase 3: Testing
  ✅ Set up test structure
  ✅ Write unit tests
  ✅ Write integration tests
  ✅ Configure pytest

✅ Phase 4: Documentation
  ✅ Create docs directory
  ✅ Write architecture docs
  ✅ Write API docs
  ✅ Write user guide

✅ Phase 5: Deployment
  ✅ Already done with Terraform!

✅ Phase 6: CI/CD
  ✅ Already done with GitHub Actions!
```

## 🎯 Final Structure Preview

After migration, you'll have:
```
xai-student-suicide-prediction/
├── config/              ✅ NEW
├── docs/                ✅ NEW
├── tests/               ✅ NEW
├── src/
│   ├── data/           ✅ ENHANCED
│   ├── models/         ✅ ENHANCED
│   ├── dashboard/      ✅ ENHANCED
│   ├── utils/          ✅ NEW
│   └── explainability/ ✅ EXISTING
├── terraform/          ✅ EXISTING
├── .github/            ✅ EXISTING
└── Makefile            ✅ NEW
```

This migration transforms your project from a prototype to production-ready!
