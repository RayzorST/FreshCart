from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import logging

from app.models.database import get_db
from app.models.cart import CartItem
from app.models.product import Product
from app.models.analysis import UserChoice, SelectedProduct
from app.models.user import User
from app.schemas.cart import CartItemResponse, CartItemCreate, CartItemUpdate, CartResponse
from app.api.endpoints.auth import get_current_user
from app.services.promotion_service import PromotionService

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/", response_model=CartResponse)
async def get_cart(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Получение корзины пользователя с учетом скидок"""
    cart_items = db.query(CartItem).filter(
        CartItem.user_id == current_user.id
    ).order_by(CartItem.created_at.desc()).all()
    
    cart_items_data = []
    for item in cart_items:
        cart_items_data.append({
            'product_id': item.product_id,
            'quantity': item.quantity
        })
    
    promotion_service = PromotionService(db)
    discount_result = promotion_service.calculate_cart_discounts(cart_items_data, current_user.id)
    
    items_with_discounts = []
    for db_item in cart_items:
        discounted_item = next(
            (item for item in discount_result['items'] 
             if item['product_id'] == db_item.product_id), 
            None
        )
        
        if discounted_item:
            items_with_discounts.append(CartItemResponse(
                id=db_item.id,
                user_id=db_item.user_id,
                product_id=db_item.product_id,
                quantity=db_item.quantity,
                product=db_item.product, 
                created_at=db_item.created_at,
                updated_at=db_item.updated_at,
                discount_price=discounted_item['discount_price'],
                applied_promotions=discounted_item['applied_promotions']
            ))
    
    return CartResponse(
        items=items_with_discounts,
        total_items=sum(item.quantity for item in cart_items),
        total_price=discount_result['total_amount'],
        discount_amount=discount_result['discount_amount'],
        final_price=discount_result['final_amount'],
        applied_promotions=discount_result['applied_promotions']
    )

@router.post("/", response_model=CartItemResponse)
async def add_to_cart(
    cart_item_data: CartItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Добавление товара в корзину.
    Если передан choice_metadata, автоматически создается запись выбора пользователя.
    """
    # Проверяем существование товара
    product = db.query(Product).filter(
        Product.id == cart_item_data.product_id,
        Product.is_active == True
    ).first()
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Product not found"
        )
    
    # Проверяем наличие товара на складе
    if product.stock_quantity < cart_item_data.quantity:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Not enough stock. Available: {product.stock_quantity}"
        )
    
    # Добавляем/обновляем товар в корзине
    existing_item = db.query(CartItem).filter(
        CartItem.user_id == current_user.id,
        CartItem.product_id == cart_item_data.product_id
    ).first()
    
    if existing_item:
        existing_item.quantity += cart_item_data.quantity
        db.commit()
        db.refresh(existing_item)
        cart_item = existing_item
    else:
        cart_item = CartItem(
            user_id=current_user.id,
            product_id=cart_item_data.product_id,
            quantity=cart_item_data.quantity
        )
        db.add(cart_item)
        db.commit()
        db.refresh(cart_item)
    
    logger.info(cart_item_data.choice_metadata)
    if cart_item_data.choice_metadata:
        try:
            logger.info(f"🔄 SAVING: analysis_id={cart_item_data.choice_metadata.get('analysis_id')}")
            await create_user_choice_from_cart_item(
                db=db,
                user_id=current_user.id,
                cart_item=cart_item,
                metadata=cart_item_data.choice_metadata
            )
            logger.info("✅ SAVE SUCCESS")
        except Exception as e:
            logger.error(f"❌ SAVE ERROR: {e}", exc_info=True)
    
    return cart_item

async def create_user_choice_from_cart_item(
    db: Session,
    user_id: int,
    cart_item: CartItem,
    metadata: dict
):
    """
    Создает запись выбора пользователя на основе метаданных из корзины
    """
    # Извлекаем данные из метаданных
    analysis_id = metadata.get('analysis_id')
    ingredient_type = metadata.get('ingredient_type', 'basic')
    
    if not analysis_id:
        logger.warning(f"Missing analysis_id in metadata")
        return
    
    # Проверяем, существует ли анализ и принадлежит ли пользователю
    from app.models.analysis import AnalysisHistory
    analysis = db.query(AnalysisHistory).filter(
        AnalysisHistory.id == analysis_id,
        AnalysisHistory.user_id == user_id
    ).first()
    
    if not analysis:
        logger.warning(f"Analysis {analysis_id} not found or not owned by user {user_id}")
        return
    
    # Ищем существующий выбор для этого анализа
    existing_choice = db.query(UserChoice).filter(
        UserChoice.analysis_id == analysis_id,
        UserChoice.user_id == user_id
    ).first()
    
    # Если выбора нет - создаем новый
    if not existing_choice:
        user_choice = UserChoice(
            analysis_id=analysis_id,
            user_id=user_id
        )
        db.add(user_choice)
        db.flush()
        logger.info(f"Created new UserChoice id: {user_choice.id}")
    else:
        user_choice = existing_choice
        logger.info(f"Using existing UserChoice id: {user_choice.id}")
    
    # Проверяем, не добавляли ли уже этот продукт
    existing_selected = db.query(SelectedProduct).filter(
        SelectedProduct.user_choice_id == user_choice.id,
        SelectedProduct.product_id == cart_item.product_id
    ).first()
    
    if not existing_selected:
        # Создаем новую запись выбранного продукта
        selected_product = SelectedProduct(
            user_choice_id=user_choice.id,
            product_id=cart_item.product_id,
            ingredient_type=ingredient_type,
        )
        db.add(selected_product)
        logger.info(f"Created SelectedProduct for product {cart_item.product_id}")
    else:
        logger.info(f"Product {cart_item.product_id} already selected, skipping")
    
    db.commit()
    logger.info(f"Saved user choice for analysis {analysis_id}")

@router.put("/{product_id}", response_model=CartItemResponse)
async def update_cart_item(
    product_id: int,
    cart_item_data: CartItemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Обновление количества товара в корзине"""
    cart_item = db.query(CartItem).filter(
        CartItem.user_id == current_user.id,
        CartItem.product_id == product_id
    ).first()
    
    if not cart_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found in cart"
        )
    
    if cart_item_data.quantity <= 0:
        db.delete(cart_item)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_200_OK,
            detail="Item removed from cart"
        )
    
    cart_item.quantity = cart_item_data.quantity
    db.commit()
    db.refresh(cart_item)
    
    return cart_item

@router.delete("/{product_id}")
async def remove_from_cart(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Удаление товара из корзины"""
    cart_item = db.query(CartItem).filter(
        CartItem.user_id == current_user.id,
        CartItem.product_id == product_id
    ).first()
    
    if not cart_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found in cart"
        )
    
    db.delete(cart_item)
    db.commit()
    
    return {"message": "Item removed from cart"}

@router.delete("/")
async def clear_cart(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Очистка корзины"""
    db.query(CartItem).filter(CartItem.user_id == current_user.id).delete()
    db.commit()
    
    return {"message": "Cart cleared successfully"}