# app/api/endpoints/analysis.py
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
import logging
import base64
from typing import Dict, List

from app.models.database import get_db
from app.models.user import User
from app.api.endpoints.auth import get_current_user
from app.schemas.analysis import Base64ImageRequest, AnalysisResponse
from app.services.tag_service import TagService

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/image")
async def analyze_food_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Анализ изображения еды через загрузку файла"""
    try:
        logger.info(f"Image analysis started for user {current_user.id}")

        if not file.content_type.startswith('image/'):
            raise HTTPException(400, "File must be an image")

        # Читаем файл и конвертируем в base64
        image_data = await file.read()
        base64_image = base64.b64encode(image_data).decode('utf-8')
        
        # Используем base64 endpoint
        return await analyze_base64_image_internal(
            base64_image, current_user, db
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Image analysis error: {e}", exc_info=True)
        raise HTTPException(500, f"Analysis failed: {str(e)}")

@router.post("/base64", response_model=AnalysisResponse)
async def analyze_base64_image(
    request: Base64ImageRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Анализ изображения в формате base64"""
    try:
        return await analyze_base64_image_internal(
            request.image_data, current_user, db
        )
        
    except Exception as e:
        logger.error(f"Food analysis error: {e}")
        raise HTTPException(500, f"Analysis failed: {str(e)}")

async def analyze_base64_image_internal(
    base64_image: str, 
    current_user: User,
    db: Session
) -> Dict:
    """Внутренняя функция анализа base64 изображения"""
    try:
        # Декодируем base64
        if ',' in base64_image:
            image_bytes = base64.b64decode(base64_image.split(',')[1])
        else:
            image_bytes = base64.b64decode(base64_image)
        
        logger.info(f"Analyzing image for user {current_user.id}, size: {len(image_bytes)} bytes")
        
        # Используем модель для распознавания блюда
        from app.services.food_classification_model import FoodClassificationModel
        food_model = FoodClassificationModel()
        
        # Получаем блюдо с ингредиентами
        dish_result = food_model.detect_dish_with_ingredients(image_bytes)
        
        logger.info(f"Detected dish: {dish_result['dish_name']} with confidence: {dish_result['confidence']}")
        
        # Ищем продукты в базе через TagService
        tag_service = TagService(db)
        
        # Для основных ингредиентов
        basic_alternatives = []
        for ingredient in dish_result["basic_ingredients"]:
            products = tag_service.get_products_by_tag(ingredient, current_user.id, limit=5)
            if products:
                basic_alternatives.append({
                    "ingredient": ingredient,
                    "products": products
                })
        
        # Для дополнительных ингредиентов  
        additional_alternatives = []
        for ingredient in dish_result["additional_ingredients"]:
            products = tag_service.get_products_by_tag(ingredient, current_user.id, limit=3)
            if products:
                additional_alternatives.append({
                    "ingredient": ingredient,
                    "products": products
                })
        
        # Формируем ответ
        response = {
            "success": True,
            "user_id": current_user.id,
            "detected_dish": dish_result["dish_name"],
            "confidence": dish_result["confidence"],
            "message": dish_result["message"],
            "basic_ingredients": dish_result["basic_ingredients"],
            "additional_ingredients": dish_result["additional_ingredients"],
            "basic_alternatives": basic_alternatives,
            "additional_alternatives": additional_alternatives,
            "recommendations": _generate_recommendations(dish_result, basic_alternatives, additional_alternatives)
        }
        
        logger.info(f"Analysis completed. Found {len(basic_alternatives)} basic and {len(additional_alternatives)} additional alternatives")
        
        return response
        
    except Exception as e:
        logger.error(f"Analysis internal error: {e}", exc_info=True)
        raise HTTPException(500, f"Analysis failed: {str(e)}")

def _generate_recommendations(dish_result: Dict, basic_alts: List, additional_alts: List) -> List[str]:
    """Генерация рекомендаций на основе результатов анализа"""
    recommendations = []
    
    if dish_result["confidence"] > 0.7:
        recommendations.append(f"Высокая уверенность в определении блюда: {dish_result['dish_name']}")
    elif dish_result["confidence"] > 0.3:
        recommendations.append(f"Средняя уверенность в определении блюда. Проверьте предложенные ингредиенты")
    else:
        recommendations.append("Низкая уверенность в определении. Попробуйте другое изображение")
    
    # Рекомендации по основным ингредиентам
    basic_found = len(basic_alts)
    basic_total = len(dish_result["basic_ingredients"])
    
    if basic_found == basic_total:
        recommendations.append("✅ Найдены все основные ингредиенты!")
    elif basic_found > 0:
        recommendations.append(f"🔍 Найдено {basic_found} из {basic_total} основных ингредиентов")
    else:
        recommendations.append("❌ Основные ингредиенты не найдены в магазине")
    
    # Рекомендации по дополнительным ингредиентам
    additional_found = len(additional_alts)
    if additional_found > 0:
        recommendations.append(f"✨ Найдено {additional_found} дополнительных ингредиентов для улучшения блюда")
    
    return recommendations