# app/api/endpoints/analysis.py
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from sqlalchemy.orm import Session
import logging
import base64
from typing import Dict, List

from app.models.database import get_db
from app.models.user import User
from app.models.analysis import AnalysisHistory
from app.api.endpoints.auth import get_current_user
from app.schemas.analysis import Base64ImageRequest, AnalysisResponse, AnalysisHistoryResponse
from app.services.analysis_history_service import AnalysisHistoryService
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
        # Декодируем base64 изображение
        if ',' in request.image_data:
            image_bytes = base64.b64decode(request.image_data.split(',')[1])
        else:
            image_bytes = base64.b64decode(request.image_data)
        
        logger.info(f"Analyzing image for user {current_user.id}, size: {len(image_bytes)} bytes")
        
        # Используем модель для распознавания блюда
        from app.services.food_classification_model import FoodClassificationModel
        food_model = FoodClassificationModel()
        
        # Получаем блюдо с ингредиентами
        dish_result = food_model.detect_dish_with_ingredients(image_bytes)
        
        logger.info(f"Detected dish: {dish_result['dish_name']} with confidence: {dish_result['confidence']}")
        
        # Ищем продукты в базе через TagService
        from app.services.tag_service import TagService
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
        
        # Сохраняем в историю анализов (если есть сервис истории)
        try:
            from app.services.analysis_history_service import AnalysisHistoryService
            history_service = AnalysisHistoryService(db)
            
            history_record = history_service.create_analysis_record(
                user_id=current_user.id,
                image_bytes=image_bytes,
                detected_dish=dish_result["dish_name"],
                confidence=dish_result["confidence"],
                ingredients={
                    "basic": dish_result["basic_ingredients"],
                    "additional": dish_result["additional_ingredients"]
                },
                alternatives_found={
                    "basic": basic_alternatives,
                    "additional": additional_alternatives
                }
            )
            logger.info(f"Analysis saved to history with ID: {history_record.id}")
        except Exception as history_error:
            logger.warning(f"Could not save to analysis history: {history_error}")
            # Продолжаем работу даже если история не сохранилась
        
        # Генерируем рекомендации
        recommendations = _generate_recommendations(dish_result, basic_alternatives, additional_alternatives)
        
        # Формируем финальный ответ
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
            "recommendations": recommendations
        }
        
        logger.info(f"Analysis completed. Found {len(basic_alternatives)} basic and {len(additional_alternatives)} additional alternatives")
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Food analysis error: {e}", exc_info=True)
        raise HTTPException(500, f"Analysis failed: {str(e)}")

def _generate_recommendations(dish_result: Dict, basic_alts: List, additional_alts: List) -> List[str]:
    """Генерация рекомендаций на основе результатов анализа"""
    recommendations = []
    
    dish_name = dish_result["dish_name"]
    confidence = dish_result["confidence"]
    
    # Рекомендации по уверенности
    if confidence > 0.7:
        recommendations.append(f"✅ Высокая уверенность в определении блюда: {dish_name}")
    elif confidence > 0.4:
        recommendations.append(f"⚠️ Средняя уверенность в определении блюда: {dish_name}")
    else:
        recommendations.append("❌ Низкая уверенность в определении. Попробуйте другое изображение")
    
    # Рекомендации по основным ингредиентам
    basic_found = len(basic_alts)
    basic_total = len(dish_result["basic_ingredients"])
    
    if basic_found == basic_total:
        recommendations.append("🎉 Найдены все основные ингредиенты!")
    elif basic_found > 0:
        recommendations.append(f"🔍 Найдено {basic_found} из {basic_total} основных ингредиентов")
        
        # Показываем какие ингредиенты не найдены
        found_ingredients = {alt["ingredient"] for alt in basic_alts}
        missing_ingredients = [ing for ing in dish_result["basic_ingredients"] if ing not in found_ingredients]
        if missing_ingredients:
            recommendations.append(f"❌ Не найдены: {', '.join(missing_ingredients)}")
    else:
        recommendations.append("❌ Основные ингредиенты не найдены в магазине")
    
    # Рекомендации по дополнительным ингредиентам
    additional_found = len(additional_alts)
    additional_total = len(dish_result["additional_ingredients"])
    
    if additional_found > 0:
        recommendations.append(f"✨ Найдено {additional_found} дополнительных ингредиентов для улучшения блюда")
    
    # Общие рекомендации
    if basic_found >= basic_total * 0.7:  # Найдено более 70% ингредиентов
        recommendations.append("💡 Вы можете приготовить это блюдо с найденными ингредиентами!")
    elif basic_found >= basic_total * 0.5:  # Найдено более 50%
        recommendations.append("💡 Вы можете адаптировать рецепт с доступными ингредиентами")
    else:
        recommendations.append("💡 Попробуйте найти альтернативные ингредиенты или выбрать другое блюдо")
    
    return recommendations

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

@router.get("/history", response_model=List[AnalysisHistoryResponse])
async def get_analysis_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Получение истории анализов пользователя"""
    history_service = AnalysisHistoryService(db)
    history = history_service.get_user_analysis_history(
        user_id=current_user.id,
        offset=skip,
        limit=limit
    )
    return history

@router.get("/history/stats")
async def get_analysis_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Статистика по анализам"""
    history_service = AnalysisHistoryService(db)
    stats = history_service.get_analysis_stats(current_user.id)
    return stats

@router.delete("/history/{analysis_id}")
async def delete_analysis_record(
    analysis_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Удаление записи анализа"""
    history_service = AnalysisHistoryService(db)
    
    record = db.query(AnalysisHistory).filter(
        AnalysisHistory.id == analysis_id,
        AnalysisHistory.user_id == current_user.id
    ).first()
    
    if not record:
        raise HTTPException(404, "Record not found")
    
    db.delete(record)
    db.commit()
    
    return {"message": "Analysis record deleted"}