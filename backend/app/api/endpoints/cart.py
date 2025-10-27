from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.models.database import get_db
from app.models.cart import CartItem
from app.models.product import Product
from app.models.user import User
from app.schemas.cart import CartItemResponse, CartItemCreate, CartItemUpdate, CartResponse
from app.api.endpoints.auth import get_current_user

router = APIRouter()

@router.get("/cart", response_model=CartResponse)
async def get_cart(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Получение корзины пользователя"""
    cart_items = db.query(CartItem).filter(
        CartItem.user_id == current_user.id
    ).all()
    
    # Рассчитываем общую стоимость и количество
    total_price = 0
    total_items = 0
    
    for item in cart_items:
        product = db.query(Product).filter(Product.id == item.product_id).first()
        if product:
            total_price += product.price * item.quantity
            total_items += item.quantity
    
    return CartResponse(
        items=cart_items,
        total_items=total_items,
        total_price=total_price
    )

@router.post("/cart/items", response_model=CartItemResponse)
async def add_to_cart(
    cart_item_data: CartItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Добавление товара в корзину"""
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
    
    # Проверяем есть ли уже товар в корзине
    existing_item = db.query(CartItem).filter(
        CartItem.user_id == current_user.id,
        CartItem.product_id == cart_item_data.product_id
    ).first()
    
    if existing_item:
        # Обновляем количество если товар уже в корзине
        existing_item.quantity += cart_item_data.quantity
        db.commit()
        db.refresh(existing_item)
        return existing_item
    else:
        # Добавляем новый товар в корзину
        cart_item = CartItem(
            user_id=current_user.id,
            product_id=cart_item_data.product_id,
            quantity=cart_item_data.quantity
        )
        db.add(cart_item)
        db.commit()
        db.refresh(cart_item)
        return cart_item

@router.put("/cart/items/{product_id}", response_model=CartItemResponse)
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
        # Удаляем если количество 0 или меньше
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

@router.delete("/cart/items/{product_id}")
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

@router.delete("/cart")
async def clear_cart(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Очистка корзины"""
    db.query(CartItem).filter(CartItem.user_id == current_user.id).delete()
    db.commit()
    
    return {"message": "Cart cleared successfully"}