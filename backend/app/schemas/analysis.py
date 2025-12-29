from pydantic import BaseModel
from datetime import datetime
from typing import List, Dict, Optional

class Base64ImageRequest(BaseModel):
    image_data: str

class Base64ImageResponse(BaseModel):
    success: bool
    detected_ingredients: List[str]
    alternatives: List[Dict]
    message: str

class AnalysisResponse(BaseModel):
    success: bool
    user_id: int
    detected_dish: str
    confidence: float
    message: str
    basic_ingredients: List[str]
    additional_ingredients: List[str]
    basic_alternatives: List[Dict]
    additional_alternatives: List[Dict]
    recommendations: List[str]

class AnalysisHistoryBase(BaseModel):
    detected_dish: str
    confidence: float
    ingredients: Dict
    alternatives_found: Dict

class AnalysisHistoryResponse(AnalysisHistoryBase):
    id: int
    user_id: int
    created_at: datetime
    image_url: Optional[str] = None

class AnalysisStatsResponse(BaseModel):
    total_analyses: int
    high_confidence_analyses: int
    recent_week_analyses: int
    success_rate: float