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
