from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List
from datetime import datetime

from app.models.database import get_db
from app.models.order import Order, OrderItem
from app.models.product import Product
from app.models.user import User
from app.schemas.order import OrderResponse, OrderCreate, OrderUpdate
from app.api.endpoints.auth import get_current_user

router = APIRouter()

@router.post("/", response_model=OrderResponse)
async def create_order(
    order_data: OrderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Создание нового заказа"""

    total_amount = 0
    order_items = []
    
    for item in order_data.items:
        product = db.query(Product).filter(
            Product.id == item.product_id,
            Product.is_active == True
        ).first()
        
        if not product:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Product with id {item.product_id} not found"
            )
        
        if product.stock_quantity < item.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Not enough stock for product {product.name}. Available: {product.stock_quantity}"
            )
        
        total_amount += item.price * item.quantity
        
        order_item = OrderItem(
            product_id=item.product_id,
            quantity=item.quantity,
            price=item.price
        )
        order_items.append(order_item)
    
    order = Order(
        user_id=current_user.id,
        shipping_address=order_data.shipping_address,
        notes=order_data.notes,
        total_amount=total_amount,
        status='pending'
    )
    
    db.add(order)
    db.flush() 
    
    for order_item in order_items:
        order_item.order_id = order.id
    
    db.add_all(order_items)

    for item in order_data.items:
        product = db.query(Product).filter(Product.id == item.product_id).first()
        product.stock_quantity -= item.quantity
    
    db.commit()
    db.refresh(order)
    
    return order

@router.get("/", response_model=List[OrderResponse])
async def get_my_orders(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Получение списка заказов текущего пользователя"""
    orders = db.query(Order).filter(
        Order.user_id == current_user.id
    ).options(
        joinedload(Order.items).joinedload(OrderItem.product) 
    ).order_by(Order.created_at.desc()).offset(skip).limit(limit).all()
    
    return orders

@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Получение деталей заказа"""
    order = db.query(Order).filter(
        Order.id == order_id,
        Order.user_id == current_user.id
    ).options(
        joinedload(Order.items).joinedload(OrderItem.product) 
    ).first()
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    
    return order

@router.put("/{order_id}", response_model=OrderResponse)
async def update_order(
    order_id: int,
    order_data: OrderUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Обновление заказа (только статус и заметки)"""
    order = db.query(Order).filter(
        Order.id == order_id,
        Order.user_id == current_user.id
    ).first()
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )

    update_data = order_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(order, field, value)
    
    order.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(order)
    
    return order

@router.delete("/{order_id}")
async def cancel_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Отмена заказа"""
    order = db.query(Order).filter(
        Order.id == order_id,
        Order.user_id == current_user.id,
        Order.status == 'pending'
    ).first()
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found or cannot be cancelled"
        )

    for item in order.items:
        product = db.query(Product).filter(Product.id == item.product_id).first()
        if product:
            product.stock_quantity += item.quantity
    
    # Меняем статус заказа
    order.status = 'cancelled'
    order.updated_at = datetime.utcnow()
    
    db.commit()
    
    return {"message": "Order cancelled successfully"}