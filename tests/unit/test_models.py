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
