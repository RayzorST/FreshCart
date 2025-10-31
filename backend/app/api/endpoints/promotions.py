from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.models.database import get_db
from app.models.product import Product
from app.models.promotions import Promotion, PromotionType, PromotionCategory, PromotionProduct
from app.schemas.promotions import PromotionCreate, PromotionUpdate, PromotionResponse
from app.api.endpoints.auth import get_current_user
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/", response_model=List[PromotionResponse])
async def get_promotions(
    skip: int = 0,
    limit: int = 100,
    is_active: Optional[bool] = None,
    promotion_type: Optional[PromotionType] = None,
    db: Session = Depends(get_db)
):
    """Получить список акций"""
    query = db.query(Promotion)
    
    if is_active is not None:
        query = query.filter(Promotion.is_active == is_active)
    
    if promotion_type is not None:
        query = query.filter(Promotion.promotion_type == promotion_type)
    
    # Фильтр по датам - показываем только активные по времени
    now = datetime.now()
    query = query.filter(Promotion.start_date <= now, Promotion.end_date >= now)
    
    promotions = query.order_by(Promotion.priority.desc(), Promotion.created_at.desc()).offset(skip).limit(limit).all()
    return promotions

@router.get("/{promotion_id}", response_model=PromotionResponse)
async def get_promotion(
    promotion_id: int,
    db: Session = Depends(get_db)
):
    """Получить акцию по ID"""
    promotion = db.query(Promotion).filter(Promotion.id == promotion_id).first()
    if not promotion:
        raise HTTPException(status_code=404, detail="Promotion not found")
    return promotion

@router.post("/", response_model=PromotionResponse)
async def create_promotion(
    promotion_data: PromotionCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Создать новую акцию (только для админов)"""
    try:
        logger.info(f"Creating promotion with data: {promotion_data.dict()}")
        
        # Проверяем существование товара-подарка если указан
        if promotion_data.promotion_type == PromotionType.GIFT and promotion_data.gift_product_id:
            gift_product = db.query(Product).filter(Product.id == promotion_data.gift_product_id).first()
            if not gift_product:
                raise HTTPException(status_code=400, detail="Gift product not found")
        
        # Создаем акцию
        promotion_dict = promotion_data.dict(exclude={'category_ids', 'product_ids'})
        logger.info(f"Promotion dict: {promotion_dict}")
        
        promotion = Promotion(**promotion_dict)
        db.add(promotion)
        db.commit()
        db.refresh(promotion)
        logger.info(f"Promotion created with ID: {promotion.id}")
        
        # Добавляем категории если указаны
        if promotion_data.category_ids:
            logger.info(f"Adding categories: {promotion_data.category_ids}")
            for category_id in promotion_data.category_ids:
                promotion_category = PromotionCategory(
                    promotion_id=promotion.id,
                    category_id=category_id
                )
                db.add(promotion_category)
        
        # Добавляем товары если указаны
        if promotion_data.product_ids:
            logger.info(f"Adding products: {promotion_data.product_ids}")
            for product_id in promotion_data.product_ids:
                promotion_product = PromotionProduct(
                    promotion_id=promotion.id,
                    product_id=product_id
                )
                db.add(promotion_product)
        
        db.commit()
        logger.info("Promotion successfully created")
        return promotion
        
    except Exception as e:
        logger.error(f"Error creating promotion: {str(e)}", exc_info=True)
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.put("/{promotion_id}", response_model=PromotionResponse)
async def update_promotion(
    promotion_id: int,
    promotion_data: PromotionUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Обновить акцию (только для админов)"""
    promotion = db.query(Promotion).filter(Promotion.id == promotion_id).first()
    if not promotion:
        raise HTTPException(status_code=404, detail="Promotion not found")
    
    for field, value in promotion_data.dict(exclude_unset=True).items():
        setattr(promotion, field, value)
    
    db.commit()
    db.refresh(promotion)
    return promotion

@router.delete("/{promotion_id}")
async def delete_promotion(
    promotion_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Удалить акцию (только для админов)"""
    promotion = db.query(Promotion).filter(Promotion.id == promotion_id).first()
    if not promotion:
        raise HTTPException(status_code=404, detail="Promotion not found")
    
    # Удаляем связи с категориями и товарами
    db.query(PromotionCategory).filter(PromotionCategory.promotion_id == promotion_id).delete()
    db.query(PromotionProduct).filter(PromotionProduct.promotion_id == promotion_id).delete()
    
    db.delete(promotion)
    db.commit()
    return {"message": "Promotion deleted successfully"}

@router.get("/active/for-cart", response_model=List[PromotionResponse])
async def get_active_promotions_for_cart(
    db: Session = Depends(get_db)
):
    """Получить активные акции для применения в корзине"""
    now = datetime.now()
    promotions = db.query(Promotion).filter(
        Promotion.is_active == True,
        Promotion.start_date <= now,
        Promotion.end_date >= now
    ).order_by(Promotion.priority.desc()).all()
    
    return promotions