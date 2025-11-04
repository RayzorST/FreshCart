from pydantic import BaseModel
from typing import List, Dict

class Base64ImageRequest(BaseModel):
    image_data: str

class Base64ImageResponse(BaseModel):
    success: bool
    detected_ingredients: List[str]
    alternatives: List[Dict]
    message: str