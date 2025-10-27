import os
import uuid
from fastapi import UploadFile, HTTPException
from PIL import Image
import io
import base64

UPLOAD_DIR = "uploads/images"
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB

def ensure_upload_dir():
    """Создание директории для загрузок если не существует"""
    os.makedirs(UPLOAD_DIR, exist_ok=True)

async def save_image(file: UploadFile) -> str:
    """Сохранение изображения и возврат URL"""
    ensure_upload_dir()
    
    # Генерируем уникальное имя файла
    file_extension = os.path.splitext(file.filename)[1].lower()
    if file_extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
        )
    
    filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    # Читаем и обрабатываем изображение
    contents = await file.read()
    
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Max size: {MAX_FILE_SIZE // 1024 // 1024}MB"
        )
    
    try:
        # Оптимизируем изображение
        image = Image.open(io.BytesIO(contents))
        
        # Конвертируем в RGB если нужно
        if image.mode in ('RGBA', 'LA', 'P'):
            image = image.convert('RGB')
        
        # Сохраняем с оптимизацией
        image.save(file_path, "JPEG", quality=85, optimize=True)
        
        return f"/static/images/{filename}"
        
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid image file: {str(e)}"
        )

def delete_image(image_url: str) -> None:
    """Удаление изображения"""
    if image_url and image_url.startswith("/static/images/"):
        filename = image_url.split("/")[-1]
        file_path = os.path.join(UPLOAD_DIR, filename)
        if os.path.exists(file_path):
            os.remove(file_path)

async def save_image_base64(base64_data: str) -> str:
    """Сохранение изображения из base64 строки"""
    ensure_upload_dir()
    
    try:
        # Убираем префикс data:image/...;base64, если есть
        if ',' in base64_data:
            base64_data = base64_data.split(',')[1]
        
        # Декодируем base64
        image_bytes = base64.b64decode(base64_data)
        
        if len(image_bytes) > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=400,
                detail=f"File too large. Max size: {MAX_FILE_SIZE // 1024 // 1024}MB"
            )
        
        # Определяем формат по содержимому
        image = Image.open(io.BytesIO(image_bytes))
        
        # Генерируем имя файла
        filename = f"{uuid.uuid4()}.jpg"
        file_path = os.path.join(UPLOAD_DIR, filename)
        
        # Конвертируем в RGB если нужно
        if image.mode in ('RGBA', 'LA', 'P'):
            image = image.convert('RGB')
        
        # Сохраняем как JPEG
        image.save(file_path, "JPEG", quality=85, optimize=True)
        
        return f"/static/images/{filename}"
        
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid base64 image: {str(e)}"
        )