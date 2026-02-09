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
