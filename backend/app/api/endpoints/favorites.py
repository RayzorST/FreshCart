from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.models.database import get_db
from app.models.favorite import Favorite
from app.models.product import Product
from app.models.user import User
from app.schemas.favorite import FavoriteResponse, FavoriteWithProductResponse, FavoriteCreate
from app.api.endpoints.auth import get_current_user

router = APIRouter()

@router.get("/", response_model=List[FavoriteWithProductResponse])
async def get_favorites(
    search: Optional[str] = Query(None, description="Поиск по названию товара"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Получить список избранных товаров пользователя с возможностью поиска"""
    query = db.query(Favorite).filter(Favorite.user_id == current_user.id)
    
    if search:
        query = query.join(Product).filter(Product.name.ilike(f"%{search}%"))
    
    favorites = query.all()
    
    result = []
    for favorite in favorites:
        favorite_data = {
            "id": favorite.id,
            "user_id": favorite.user_id,
            "product_id": favorite.product_id,
            "created_at": favorite.created_at,
            "product": {
                "id": favorite.product.id,
                "name": favorite.product.name,
                "description": favorite.product.description,
                "price": favorite.product.price,
                "image_url": favorite.product.image_url,
                "category": {
                    "id": favorite.product.category.id,
                    "name": favorite.product.category.name
                },
                "stock_quantity": favorite.product.stock_quantity,
            }
        }
        result.append(favorite_data)
    
    return result

@router.post("/", response_model=FavoriteResponse)
async def add_to_favorites(
    favorite_data: FavoriteCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Добавить товар в избранное"""
    product = db.query(Product).filter(Product.id == favorite_data.product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    existing_favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.product_id == favorite_data.product_id
    ).first()
    
    if existing_favorite:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Product already in favorites"
        )
    
    favorite = Favorite(
        user_id=current_user.id,
        product_id=favorite_data.product_id
    )
    
    db.add(favorite)
    db.commit()
    db.refresh(favorite)
    
    return favorite

@router.delete("/items/{product_id}")
async def remove_from_favorites(
    product_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Удалить товар из избранного"""
    favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.product_id == product_id
    ).first()
    
    if not favorite:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Favorite not found"
        )
    
    db.delete(favorite)
    db.commit()
    
    return {"message": "Product removed from favorites"}

@router.get("/check/{product_id}")
async def check_favorite(
    product_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Проверить, есть ли товар в избранном"""
    favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.product_id == product_id
    ).first()
    
    return {"is_favorite": favorite is not None}