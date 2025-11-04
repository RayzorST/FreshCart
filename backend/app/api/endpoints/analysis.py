# app/api/endpoints/analysis.py
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
import logging
import base64

from app.models.database import get_db
from app.models.user import User
from app.api.endpoints.auth import get_current_user
from app.schemas.analysis import Base64ImageRequest, Base64ImageResponse
from app.services.tag_service import TagService

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/image")
async def analyze_food_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Анализ изображения еды"""
    try:
        logger.info(f"Image analysis started for user {current_user.id}")

        if not file.content_type.startswith('image/'):
            raise HTTPException(400, "File must be an image")

        image_data = await file.read()
        logger.info(f"Image size: {len(image_data)} bytes")
        
        ingredients = ["салат", "курица", "сыр", "помидор"]
        
        return {
            "success": True,
            "user_id": current_user.id,
            "detected_ingredients": ingredients,
            "alternatives": [
                {
                    "ingredient": "салат",
                    "products": [
                        {"id": 1, "name": "Айсберг", "price": 120, "in_favorites": True},
                        {"id": 2, "name": "Романо", "price": 140, "in_favorites": False}
                    ]
                },
                {
                    "ingredient": "курица", 
                    "products": [
                        {"id": 3, "name": "Куриная грудка", "price": 300, "in_favorites": True}
                    ]
                }
            ]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Image analysis error: {e}", exc_info=True)
        raise HTTPException(500, f"Analysis failed: {str(e)}")
    
@router.post("/base64")
async def analyze_base64_image(
    request: Base64ImageRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        image_bytes = base64.b64decode(request.image_data.split(',')[1] if ',' in request.image_data else request.image_data)
        
        from app.services.food_classification_model import FoodClassificationModel
        food_model = FoodClassificationModel()
        
        # Получаем блюдо с ингредиентами
        dish_result = food_model.detect_dish_with_ingredients(image_bytes)
        
        # Ищем альтернативные продукты в базе через теги
        tag_service = TagService(db)
        
        # Для основных ингредиентов
        basic_alternatives = []
        for ingredient in dish_result["basic_ingredients"]:
            products = tag_service.get_products_by_tag(ingredient, current_user.id)
            if products:
                basic_alternatives.append({
                    "ingredient": ingredient,
                    "products": products
                })
        
        # Для дополнительных ингредиентов  
        additional_alternatives = []
        for ingredient in dish_result["additional_ingredients"]:
            products = tag_service.get_products_by_tag(ingredient, current_user.id)
            if products:
                additional_alternatives.append({
                    "ingredient": ingredient,
                    "products": products
                })
        
        return {
            "success": True,
            "detected_dish": dish_result["dish_name"],
            "confidence": dish_result["confidence"],
            "message": dish_result["message"],
            "basic_ingredients": dish_result["basic_ingredients"],
            "additional_ingredients": dish_result["additional_ingredients"],
            "basic_alternatives": basic_alternatives,
            "additional_alternatives": additional_alternatives
        }
        
    except Exception as e:
        logger.error(f"Food analysis error: {e}")
        raise HTTPException(500, f"Analysis failed: {str(e)}")