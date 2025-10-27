from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import base64
import io

from app.models.database import get_db
from app.models.product import Product
from app.models.user import User
from app.core.file_storage import save_image_base64, delete_image
from app.api.endpoints.auth import get_current_user
from app.schemas.image import ImageBase64

router = APIRouter()

@router.post("/products/{product_id}/image")
async def upload_product_image(
    product_id: int,
    image_data: ImageBase64,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Загрузка изображения для товара в формате base64"""
    print(f"DEBUG: Uploading base64 image for product {product_id}")
    
    # Находим товар
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    try:
        # Удаляем старое изображение если есть
        if product.image_url:
            delete_image(product.image_url)
        
        # Сохраняем новое изображение из base64
        image_url = await save_image_base64(image_data.image_data)
        
        # Обновляем товар
        product.image_url = image_url
        db.commit()
        
        return {
            "message": "Image uploaded successfully",
            "image_url": image_url
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading image: {str(e)}"
        )