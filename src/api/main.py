"""
FastAPI backend for XAI Student Suicide Prediction Dashboard
Provides REST endpoints for model predictions, analytics, and data processing
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
import logging
import json
from datetime import datetime

# Import backend modules
from src.models.model_registry import ModelRegistry
from src.data.data_validator import DataValidator
from src.data.preprocessor import DataPreprocessor
from src.utils.config import Config
from src.monitoring.logger import setup_logger

# Setup logging
logger = setup_logger()

# Initialize FastAPI app
app = FastAPI(
    title="XAI Student Risk Prediction API",
    description="Backend API for student suicide risk prediction dashboard",
    version="1.0.0"
)

# Add CORS middleware for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize components
config = Config()
model_registry = ModelRegistry()
data_validator = DataValidator()
data_preprocessor = DataPreprocessor()

# Pydantic models for request/response
class PredictionRequest(BaseModel):
    student_data: Dict[str, Any] = Field(..., description="Student features for prediction")
    model_name: Optional[str] = Field("default", description="Model to use for prediction")

class PredictionResponse(BaseModel):
    prediction: float
    risk_level: str
    confidence: float
    explanation: Dict[str, Any]
    timestamp: datetime

class AnalyticsRequest(BaseModel):
    time_range: Optional[str] = Field("30d", description="Time range for analytics")
    filters: Optional[Dict[str, Any]] = Field({}, description="Filters for analytics")

class AnalyticsResponse(BaseModel):
    total_predictions: int
    risk_distribution: Dict[str, int]
    trends: List[Dict[str, Any]]
    top_risk_factors: List[Dict[str, Any]]

class HealthResponse(BaseModel):
    status: str
    version: str
    models_loaded: List[str]
    last_updated: datetime

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    try:
        models = model_registry.list_available_models()
        return HealthResponse(
            status="healthy",
            version="1.0.0",
            models_loaded=models,
            last_updated=datetime.now()
        )
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=500, detail="Service unhealthy")

@app.post("/predict", response_model=PredictionResponse)
async def predict_risk(request: PredictionRequest, background_tasks: BackgroundTasks):
    """Predict student suicide risk"""
    try:
        # Validate input data
        is_valid, validation_errors = data_validator.validate_student_data(request.student_data)
        if not is_valid:
            raise HTTPException(status_code=400, detail=f"Invalid input data: {validation_errors}")

        # Preprocess data
        processed_data = data_preprocessor.preprocess(request.student_data)

        # Get model and make prediction
        model = model_registry.get_model(request.model_name)
        if not model:
            raise HTTPException(status_code=404, detail=f"Model '{request.model_name}' not found")

        prediction_result = model.predict(processed_data)

        # Generate explanation
        explanation = model.explain_prediction(processed_data) if hasattr(model, 'explain_prediction') else {}

        # Determine risk level
        risk_level = "low" if prediction_result['prediction'] < 0.3 else "medium" if prediction_result['prediction'] < 0.7 else "high"

        response = PredictionResponse(
            prediction=prediction_result['prediction'],
            risk_level=risk_level,
            confidence=prediction_result.get('confidence', 0.8),
            explanation=explanation,
            timestamp=datetime.now()
        )

        # Log prediction for monitoring
        background_tasks.add_task(log_prediction, request.student_data, response.dict())

        return response

    except Exception as e:
        logger.error(f"Prediction failed: {e}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@app.get("/analytics", response_model=AnalyticsResponse)
async def get_analytics(time_range: str = "30d", filters: str = "{}"):
    """Get analytics data"""
    try:
        # Parse filters
        try:
            filters_dict = json.loads(filters)
        except:
            filters_dict = {}

        # In a real implementation, this would query a database
        # For now, return mock data
        analytics_data = {
            "total_predictions": 1250,
            "risk_distribution": {
                "low": 750,
                "medium": 350,
                "high": 150
            },
            "trends": [
                {"date": "2024-01-01", "predictions": 45, "high_risk": 8},
                {"date": "2024-01-02", "predictions": 52, "high_risk": 12},
                # ... more trend data
            ],
            "top_risk_factors": [
                {"factor": "academic_pressure", "impact": 0.85},
                {"factor": "social_isolation", "impact": 0.72},
                {"factor": "family_issues", "impact": 0.68}
            ]
        }

        return AnalyticsResponse(**analytics_data)

    except Exception as e:
        logger.error(f"Analytics failed: {e}")
        raise HTTPException(status_code=500, detail=f"Analytics failed: {str(e)}")

@app.get("/models")
async def list_models():
    """List available models"""
    try:
        models = model_registry.list_available_models()
        model_details = []

        for model_name in models:
            model = model_registry.get_model(model_name)
            if model:
                model_details.append({
                    "name": model_name,
                    "type": type(model).__name__,
                    "version": getattr(model, 'version', '1.0'),
                    "accuracy": getattr(model, 'accuracy', None),
                    "last_trained": getattr(model, 'last_trained', None)
                })

        return {"models": model_details}

    except Exception as e:
        logger.error(f"List models failed: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to list models: {str(e)}")

async def log_prediction(input_data: Dict[str, Any], result: Dict[str, Any]):
    """Log prediction for monitoring purposes"""
    try:
        # In a real implementation, save to database or monitoring system
        logger.info(f"Prediction logged: {result['risk_level']} risk, confidence: {result['confidence']}")
    except Exception as e:
        logger.error(f"Failed to log prediction: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
