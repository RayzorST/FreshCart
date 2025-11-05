from pydantic import BaseModel
from typing import List, Dict

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