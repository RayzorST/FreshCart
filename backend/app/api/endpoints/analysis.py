# analysis.py - исправленная версия
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.orm import Session, joinedload
import logging
import base64
import os
from typing import Dict, List, Optional

from app.models.database import get_db
from app.models.user import User
from app.models.analysis import AnalysisHistory, UserChoice, SelectedProduct
from app.api.endpoints.auth import get_current_user
from app.schemas.analysis import Base64ImageRequest, AnalysisResponse, AnalysisHistoryResponse
from app.services.analysis_history_service import AnalysisHistoryService
from app.services.tag_service import TagService
from app.core.file_storage import save_image_base64

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/base64", response_model=AnalysisResponse)
async def analyze_base64_image(
    request: Base64ImageRequest,
    background_tasks: BackgroundTasks,
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
        
        # Анализируем изображение с помощью модели
        from app.services.food_classification_model import food_model

        dish_result = food_model.detect_dish_with_ingredients(image_bytes)
        
        logger.info(f"Detected dish: {dish_result['dish_name']} with confidence: {dish_result['confidence']}")

        # Ищем альтернативы продуктов
        tag_service = TagService(db)

        basic_alternatives = []
        for ingredient in dish_result["basic_ingredients"]:
            products = tag_service.get_products_by_tag(ingredient, current_user.id, limit=5)
            if products:
                basic_alternatives.append({
                    "ingredient": ingredient,
                    "products": products
                })

        additional_alternatives = []
        for ingredient in dish_result["additional_ingredients"]:
            products = tag_service.get_products_by_tag(ingredient, current_user.id, limit=3)
            if products:
                additional_alternatives.append({
                    "ingredient": ingredient,
                    "products": products
                })

        # Создаем запись в истории с новым методом
        history_service = AnalysisHistoryService(db)
        
        try:
            # Используем новый метод без image_bytes
            history_record = history_service.create_analysis_record_simple(
                user_id=current_user.id,
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
            logger.info(f"Analysis record created with ID: {history_record.id}")
            
            # Добавляем задачу на сохранение изображения в фоне
            background_tasks.add_task(
                save_analysis_image_background,
                db=db,
                history_service=history_service,
                image_bytes=image_bytes,
                analysis_id=history_record.id,
                user_id=current_user.id
            )
            
            analysis_id = history_record.id
            
        except Exception as history_error:
            logger.error(f"Could not create analysis record: {history_error}")
            analysis_id = 0

        # Генерируем рекомендации
        recommendations = _generate_recommendations(dish_result, basic_alternatives, additional_alternatives)

        # Формируем ответ
        response = {
            "success": True,
            "user_id": current_user.id,
            "analysis_id": analysis_id,
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
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


async def save_analysis_image_background(
    db: Session,
    history_service: AnalysisHistoryService,
    image_bytes: bytes,
    analysis_id: int,
    user_id: int
):
    """Фоновая задача для сохранения изображения анализа"""
    try:
        # Преобразуем в base64
        base64_image = base64.b64encode(image_bytes).decode('utf-8')
        full_base64 = f"data:image/jpeg;base64,{base64_image}"
        
        # Сохраняем изображение через file_storage
        from app.core.file_storage import save_image_base64
        image_url = await save_image_base64(full_base64)
        
        if image_url:
            # Обновляем запись с URL изображения
            success = history_service.update_analysis_image(
                analysis_id=analysis_id,
                user_id=user_id,
                image_url=image_url
            )
            
            if success:
                logger.info(f"Image saved for analysis {analysis_id}: {image_url}")
            else:
                logger.warning(f"Failed to update image URL for analysis {analysis_id}")
        else:
            logger.warning(f"Failed to save image for analysis {analysis_id}")
            
    except Exception as e:
        logger.error(f"Failed to save analysis image: {e}")

@router.get("/my-history", response_model=List[AnalysisHistoryResponse])
async def get_my_analysis_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    min_confidence: Optional[float] = Query(None, ge=0.0, le=1.0),
    include_choices: bool = Query(True, description="Включить выборы пользователя"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Получение истории анализов текущего пользователя.
    Если include_choices=True, включает выборы пользователя для каждого анализа.
    """
    try:
        history_service = AnalysisHistoryService(db)
        
        # Выбираем нужный метод в зависимости от необходимости выборов
        if include_choices:
            history = history_service.get_user_analysis_history_with_choices(
                user_id=current_user.id,
                offset=skip,
                limit=limit,
                min_confidence=min_confidence
            )
        else:
            if min_confidence is not None:
                history = history_service.get_user_analysis_history(
                    user_id=current_user.id,
                    offset=skip,
                    limit=limit,
                    min_confidence=min_confidence
                )
            else:
                history = history_service.get_analysis_history(
                    user_id=current_user.id,
                    offset=skip,
                    limit=limit
                )
        
        # Формируем ответ
        result = []
        for record in history:
            analysis_dict = {
                "id": record.id,
                "user_id": record.user_id,
                "detected_dish": record.detected_dish,
                "confidence": record.confidence,
                "ingredients": record.ingredients or {},
                "alternatives_found": record.alternatives_found or {},
                "image_url": record.image_url,
                "created_at": record.created_at
            }
            
            # Добавляем выборы, если они есть и запрошены
            if include_choices and record.user_choices:
                analysis_dict["user_choices"] = []
                for user_choice in record.user_choices:
                    choice_dict = {
                        "id": user_choice.id,
                        "created_at": user_choice.created_at,
                        "selected_products": []
                    }
                    
                    # Добавляем выбранные продукты
                    for selected in user_choice.selected_items:
                        product_data = {
                            "id": selected.id,
                            "product_id": selected.product_id,
                            "ingredient_type": selected.ingredient_type,
                            "created_at": selected.created_at,
                            "product": {
                                "id": selected.product.id,
                                "name": selected.product.name,
                                "price": selected.product.price,
                                "image_url": selected.product.image_url
                            }
                        }
                        choice_dict["selected_products"].append(product_data)
                    
                    analysis_dict["user_choices"].append(choice_dict)
            
            result.append(analysis_dict)
        
        return result
        
    except Exception as e:
        logger.error(f"Error getting analysis history: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get history: {str(e)}")

@router.get("/all-history", response_model=List[AnalysisHistoryResponse])
async def get_all_analysis_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    user_id: Optional[int] = Query(None, description="ID конкретного пользователя"),
    min_confidence: Optional[float] = Query(None, ge=0.0, le=1.0),
    include_choices: bool = Query(True, description="Включить выборы пользователя"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Получение истории анализов всех или конкретного пользователя (админ).
    Если include_choices=True, включает выборы пользователя для каждого анализа.
    """
    try:
        # Проверяем права администратора
        if user_id is not None and user_id != current_user.id:
            if current_user.role.name != "admin":
                raise HTTPException(status_code=403, detail="Not authorized to view other users' history")
        
        history_service = AnalysisHistoryService(db)
        
        # Выбираем нужный метод
        if include_choices:
            history = history_service.get_analysis_history_with_choices(
                user_id=user_id,
                offset=skip,
                limit=limit,
                min_confidence=min_confidence
            )
        else:
            history = history_service.get_analysis_history(
                user_id=user_id,
                offset=skip,
                limit=limit,
                min_confidence=min_confidence
            )
        
        # Формируем ответ (аналогично my-history)
        result = []
        for record in history:
            analysis_dict = {
                "id": record.id,
                "user_id": record.user_id,
                "detected_dish": record.detected_dish,
                "confidence": record.confidence,
                "ingredients": record.ingredients or {},
                "alternatives_found": record.alternatives_found or {},
                "image_url": record.image_url,
                "created_at": record.created_at
            }
            
            # Добавляем выборы, если они есть и запрошены
            if include_choices and record.user_choices:
                analysis_dict["user_choices"] = []
                for user_choice in record.user_choices:
                    choice_dict = {
                        "id": user_choice.id,
                        "created_at": user_choice.created_at,
                        "selected_products": []
                    }
                    
                    for selected in user_choice.selected_items:
                        product_data = {
                            "id": selected.id,
                            "product_id": selected.product_id,
                            "ingredient_type": selected.ingredient_type,
                            "created_at": selected.created_at,
                            "product": {
                                "id": selected.product.id,
                                "name": selected.product.name,
                                "price": selected.product.price,
                                "image_url": selected.product.image_url
                            }
                        }
                        choice_dict["selected_products"].append(product_data)
                    
                    analysis_dict["user_choices"].append(choice_dict)
            
            result.append(analysis_dict)
        
        return result
        
    except Exception as e:
        logger.error(f"Error getting all analysis history: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get history: {str(e)}")
    
@router.get("/history/{analysis_id}/choices")
async def get_analysis_choices(
    analysis_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Получение всех выборов пользователя для конкретного анализа
    """
    try:
        # Проверяем существование анализа и права доступа
        analysis = db.query(AnalysisHistory).filter(
            AnalysisHistory.id == analysis_id
        ).first()
        
        if not analysis:
            raise HTTPException(status_code=404, detail="Analysis not found")
        
        if analysis.user_id != current_user.id and current_user.role.name != "admin":
            raise HTTPException(status_code=403, detail="Not authorized")
        
        # Получаем выборы
        choices = db.query(UserChoice).filter(
            UserChoice.analysis_id == analysis_id,
            UserChoice.user_id == current_user.id if current_user.role.name != "admin" else UserChoice.user_id == analysis.user_id
        ).options(
            joinedload(UserChoice.selected_items).joinedload(SelectedProduct.product)
        ).order_by(UserChoice.created_at.desc()).all()
        
        # Форматируем результат
        result = []
        for choice in choices:
            choice_dict = {
                "id": choice.id,
                "created_at": choice.created_at,
                "selected_products": []
            }
            
            for selected in choice.selected_items:
                choice_dict["selected_products"].append({
                    "id": selected.id,
                    "product_id": selected.product_id,
                    "ingredient_type": selected.ingredient_type,
                    "created_at": selected.created_at,
                    "product": {
                        "id": selected.product.id,
                        "name": selected.product.name,
                        "price": selected.product.price,
                        "image_url": selected.product.image_url
                    }
                })
            
            result.append(choice_dict)
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting analysis choices: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get choices: {str(e)}")

@router.get("/history/stats")
async def get_analysis_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Статистика по анализам"""
    try:
        history_service = AnalysisHistoryService(db)
        stats = history_service.get_analysis_stats(current_user.id)
        return stats
    except Exception as e:
        logger.error(f"Error getting analysis stats: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get stats: {str(e)}")


@router.delete("/history/{analysis_id}")
async def delete_analysis_record(
    analysis_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Удаление записи анализа"""
    try:
        record = db.query(AnalysisHistory).filter(
            AnalysisHistory.id == analysis_id,
            AnalysisHistory.user_id == current_user.id
        ).first()
        
        if not record:
            raise HTTPException(status_code=404, detail="Record not found")
        
        # Удаляем связанное изображение если оно есть
        if record.image_url:
            try:
                from app.core.file_storage import delete_image
                delete_image(record.image_url)
            except Exception as img_error:
                logger.warning(f"Could not delete analysis image: {img_error}")
        
        # Удаляем запись из БД
        db.delete(record)
        db.commit()
        
        return {"success": True, "message": "Analysis record deleted"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting analysis record: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to delete record: {str(e)}")


def _generate_recommendations(dish_result: Dict, basic_alts: List, additional_alts: List) -> List[str]:
    """Генерация рекомендаций на основе результатов анализа"""
    recommendations = []
    
    if dish_result["confidence"] > 0.7:
        recommendations.append(f"Высокая уверенность в определении блюда: {dish_result['dish_name']}")
    elif dish_result["confidence"] > 0.3:
        recommendations.append(f"Средняя уверенность в определении блюда. Проверьте предложенные ингредиенты")
    else:
        recommendations.append("Низкая уверенность в определении. Попробуйте другое изображение")
    
    basic_found = len(basic_alts)
    basic_total = len(dish_result["basic_ingredients"])
    
    if basic_found == basic_total:
        recommendations.append("✅ Найдены все основные ингредиенты!")
    elif basic_found > 0:
        recommendations.append(f"🔍 Найдено {basic_found} из {basic_total} основных ингредиентов")
    else:
        recommendations.append("❌ Основные ингредиенты не найдены в магазине")
    
    additional_found = len(additional_alts)
    if additional_found > 0:
        recommendations.append(f"✨ Найдено {additional_found} дополнительных ингредиентов для улучшения блюда")
    
    # Добавляем рекомендации на основе ингредиентов
    if "соль" in [ing.lower() for ing in dish_result["basic_ingredients"]]:
        recommendations.append("🧂 Для этого блюда понадобится соль")
    
    if "перец" in [ing.lower() for ing in dish_result["basic_ingredients"]]:
        recommendations.append("🌶️ Не забудьте про перец для вкуса")
    
    if len(recommendations) < 3:
        recommendations.append("🍽️ Приятного аппетита!")
    
    return recommendations


# Упрощенная версия без BackgroundTasks
@router.post("/base64-simple", response_model=AnalysisResponse)
async def analyze_base64_image_simple(
    request: Base64ImageRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Упрощенная версия анализа"""
    try:
        # Декодируем base64 изображение
        if ',' in request.image_data:
            image_bytes = base64.b64decode(request.image_data.split(',')[1])
        else:
            image_bytes = base64.b64decode(request.image_data)
        
        logger.info(f"Analyzing image for user {current_user.id}, size: {len(image_bytes)} bytes")
        
        # Анализируем изображение
        from app.services.food_classification_model import FoodClassificationModel
        food_model = FoodClassificationModel()
        
        dish_result = food_model.detect_dish_with_ingredients(image_bytes)
        
        # Ищем альтернативы продуктов
        tag_service = TagService(db)
        
        basic_alternatives = []
        for ingredient in dish_result["basic_ingredients"]:
            products = tag_service.get_products_by_tag(ingredient, current_user.id, limit=5)
            if products:
                basic_alternatives.append({
                    "ingredient": ingredient,
                    "products": products
                })
        
        additional_alternatives = []
        for ingredient in dish_result["additional_ingredients"]:
            products = tag_service.get_products_by_tag(ingredient, current_user.id, limit=3)
            if products:
                additional_alternatives.append({
                    "ingredient": ingredient,
                    "products": products
                })
        
        # Сохраняем изображение
        image_url = None
        try:
            base64_image = base64.b64encode(image_bytes).decode('utf-8')
            full_base64 = f"data:image/jpeg;base64,{base64_image}"
            image_url = await save_image_base64(full_base64)
        except Exception as img_error:
            logger.warning(f"Could not save image: {img_error}")
        
        # Создаем запись в истории
        history_service = AnalysisHistoryService(db)
        analysis_id = 0
        
        try:
            history_record = history_service.create_analysis_record(
                user_id=current_user.id,
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
            analysis_id = history_record.id
            
            # Если изображение было сохранено, обновляем запись
            if image_url and history_record:
                history_record.image_url = image_url
                db.commit()
                logger.info(f"Image saved for analysis {analysis_id}")
            
        except Exception as history_error:
            logger.error(f"History creation error: {history_error}")
        
        # Генерируем рекомендации
        recommendations = _generate_recommendations(dish_result, basic_alternatives, additional_alternatives)
        
        # Формируем ответ
        response = {
            "success": True,
            "user_id": current_user.id,
            "analysis_id": analysis_id,
            "detected_dish": dish_result["dish_name"],
            "confidence": dish_result["confidence"],
            "message": dish_result["message"],
            "basic_ingredients": dish_result["basic_ingredients"],
            "additional_ingredients": dish_result["additional_ingredients"],
            "basic_alternatives": basic_alternatives,
            "additional_alternatives": additional_alternatives,
            "recommendations": recommendations
        }
        
        return response
        
    except Exception as e:
        logger.error(f"Food analysis error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")