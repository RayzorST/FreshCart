from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Response
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
import base64
import io
from minio.error import S3Error

from app.models.database import get_db
from app.models.product import Product
from app.models.user import User
from app.core.file_storage import save_image_base64, delete_image, save_image
from app.core.minio_client import minio_client
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
    print(f"DEBUG: Uploading base64 image for product {product_id} to MinIO")
    
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    try:
        if product.image_url:
            delete_image(product.image_url)
        
        image_url = await save_image_base64(image_data.image_data)
        
        product.image_url = image_url
        db.commit()
        
        return {
            "message": "Image uploaded successfully to MinIO",
            "image_url": image_url
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading image: {str(e)}"
        )

@router.post("/products/{product_id}/image-file")
async def upload_product_image_file(
    product_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Загрузка изображения для товара через файл"""
    print(f"DEBUG: Uploading file image for product {product_id} to MinIO")
    
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    try:
        if product.image_url:
            delete_image(product.image_url)
        
        image_url = await save_image(file)
        
        product.image_url = image_url
        db.commit()
        
        return {
            "message": "Image file uploaded successfully to MinIO",
            "image_url": image_url
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading image file: {str(e)}"
        )
    
@router.get("/products/{product_id}/image")
async def get_product_image(
    product_id: int,
    db: Session = Depends(get_db)
):
    """Получение изображения товара по ID товара"""
    try:
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product or not product.image_url:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product or image not found"
            )
        
        filename = product.image_url.split('/')[-1]
        if not filename:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Image filename not found"
            )

        try:
            response = minio_client.client.get_object(
                minio_client.bucket_name,
                filename
            )
            
            image_data = response.read()
            
            return StreamingResponse(
                io.BytesIO(image_data),
                media_type="image/jpeg",
                headers={
                    "Content-Disposition": f"inline; filename={filename}",
                    "Cache-Control": "public, max-age=3600" 
                }
            )
            
        except Exception as e:
            print(f"MinIO error: {e}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Image not found in storage"
            )
        finally:
            if 'response' in locals():
                response.close()
                response.release_conn()
                
    except HTTPException:
        raise
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )