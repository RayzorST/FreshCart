from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Response
from sqlalchemy.orm import Session
import base64
import io
from minio.error import S3Error

from app.models.database import get_db
from app.models.product import Product, Category
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
            
            # Используем Response вместо StreamingResponse
            return Response(
                content=image_data,
                media_type="image/jpeg",
                headers={
                    "Content-Disposition": f"inline; filename={filename}",
                    "Cache-Control": "public, max-age=3600",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, OPTIONS",
                    "Access-Control-Allow-Headers": "*"
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
    
@router.options("/products/{product_id}/image")
async def options_product_image():
    """Обработчик CORS preflight запросов"""
    return Response(
        status_code=200,
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Access-Control-Allow-Headers": "*"
        }
    )

@router.post("/categories/{category_id}/image")
async def upload_category_image_base64(
    category_id: int,
    image_data: ImageBase64,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Загрузка изображения для категории в формате base64""" 
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found"
        )
    
    try:
        # Удаляем старое изображение, если оно есть
        if category.image_url:
            delete_image(category.image_url)
        
        # Сохраняем новое изображение
        image_url = await save_image_base64(image_data.image_data)
        
        # Обновляем URL изображения в категории
        category.image_url = image_url
        db.commit()
        
        return {
            "message": "Category image uploaded successfully to MinIO",
            "image_url": image_url
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading category image: {str(e)}"
        )


@router.post("/categories/{category_id}/image-file")
async def upload_category_image_file(
    category_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Загрузка изображения для категории через файл"""
    print(f"DEBUG: Uploading file image for category {category_id} to MinIO")
    
    # Проверяем тип файла
    allowed_content_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    if file.content_type not in allowed_content_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Only JPEG, PNG, GIF and WebP are allowed."
        )
    
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found"
        )
    
    try:
        # Удаляем старое изображение, если оно есть
        if category.image_url:
            delete_image(category.image_url)
        
        # Сохраняем новое изображение
        image_url = await save_image(file)
        
        # Обновляем URL изображения в категории
        category.image_url = image_url
        db.commit()
        
        return {
            "message": "Category image file uploaded successfully to MinIO",
            "image_url": image_url
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading category image file: {str(e)}"
        )


@router.get("/categories/{category_id}/image")
async def get_category_image(
    category_id: int,
    db: Session = Depends(get_db)
):
    """Получение изображения категории по ID категории"""
    try:
        category = db.query(Category).filter(Category.id == category_id).first()
        if not category or not category.image_url:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category or image not found"
            )
        
        # Извлекаем имя файла из URL
        filename = category.image_url.split('/')[-1]
        if not filename:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Image filename not found"
            )

        try:
            # Получаем изображение из MinIO
            response = minio_client.client.get_object(
                minio_client.bucket_name,
                filename
            )
            
            image_data = response.read()
            
            # Определяем Content-Type на основе расширения файла
            content_type = "image/jpeg"  # значение по умолчанию
            if filename.lower().endswith('.png'):
                content_type = "image/png"
            elif filename.lower().endswith('.gif'):
                content_type = "image/gif"
            elif filename.lower().endswith('.webp'):
                content_type = "image/webp"
            
            return Response(
                content=image_data,
                media_type=content_type,
                headers={
                    "Content-Disposition": f"inline; filename={filename}",
                    "Cache-Control": "public, max-age=3600",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, OPTIONS",
                    "Access-Control-Allow-Headers": "*"
                }
            )
            
        except S3Error as e:
            print(f"MinIO error: {e}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Image not found in storage"
            )
        except Exception as e:
            print(f"Error reading image: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Error retrieving image"
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


@router.delete("/categories/{category_id}/image")
async def delete_category_image(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Удаление изображения категории"""
    category = db.query(Category).filter(Category.id == category_id).first()
    
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found"
        )
    
    if not category.image_url:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category has no image"
        )
    
    try:
        # Удаляем изображение из хранилища
        delete_image(category.image_url)
        
        # Очищаем поле image_url в категории
        category.image_url = None
        db.commit()
        
        return {
            "message": "Category image deleted successfully",
            "category_id": category_id
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting category image: {str(e)}"
        )


@router.options("/categories/{category_id}/image")
async def options_category_image():
    """Обработчик CORS preflight запросов для изображений категорий"""
    return Response(
        status_code=200,
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "*"
        }
    )