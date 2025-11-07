import os
from minio import Minio
from minio.error import S3Error
from fastapi import HTTPException
import uuid
from PIL import Image
import io
import base64

# Конфигурация MinIO
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "localhost:9000")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minioadmin")
MINIO_SECURE = os.getenv("MINIO_SECURE", "False").lower() == "true"
MINIO_BUCKET_NAME = os.getenv("MINIO_BUCKET_NAME", "images")

class MinIOClient:
    def __init__(self):
        self.client = Minio(
            MINIO_ENDPOINT,
            access_key=MINIO_ACCESS_KEY,
            secret_key=MINIO_SECRET_KEY,
            secure=MINIO_SECURE
        )
        self.bucket_name = MINIO_BUCKET_NAME
        self._ensure_bucket_exists()

    def _ensure_bucket_exists(self):
        """Создает bucket если не существует"""
        try:
            if not self.client.bucket_exists(self.bucket_name):
                self.client.make_bucket(self.bucket_name)
                print(f"Bucket '{self.bucket_name}' created successfully")
        except S3Error as e:
            print(f"Error creating bucket: {e}")
            raise HTTPException(
                status_code=500,
                detail=f"MinIO bucket error: {str(e)}"
            )

    async def upload_image_base64(self, base64_data: str) -> str:
        """Загружает изображение из base64 в MinIO"""
        try:
            if ',' in base64_data:
                base64_data = base64_data.split(',')[1]
            
            image_bytes = base64.b64decode(base64_data)
            
            image = Image.open(io.BytesIO(image_bytes))

            if image.mode in ('RGBA', 'LA', 'P'):
                image = image.convert('RGB')

            output_buffer = io.BytesIO()
            image.save(output_buffer, "JPEG", quality=85, optimize=True)
            output_buffer.seek(0)

            filename = f"{uuid.uuid4()}.jpg"

            self.client.put_object(
                bucket_name=self.bucket_name,
                object_name=filename,
                data=output_buffer,
                length=len(output_buffer.getvalue()),
                content_type='image/jpeg'
            )

            return f"/minio/{self.bucket_name}/{filename}"
            
        except Exception as e:
            print(f"MinIO upload error: {e}")
            raise HTTPException(
                status_code=500,
                detail=f"Error uploading image to MinIO: {str(e)}"
            )

    async def upload_image_file(self, file) -> str:
        """Загружает файл изображения в MinIO"""
        try:
            contents = await file.read()
            
            MAX_FILE_SIZE = 10 * 1024 * 1024
            if len(contents) > MAX_FILE_SIZE:
                raise HTTPException(
                    status_code=400,
                    detail=f"File too large. Max size: {MAX_FILE_SIZE // 1024 // 1024}MB"
                )
            
            image = Image.open(io.BytesIO(contents))
            
            if image.mode in ('RGBA', 'LA', 'P'):
                image = image.convert('RGB')
            
            output_buffer = io.BytesIO()
            image.save(output_buffer, "JPEG", quality=85, optimize=True)
            output_buffer.seek(0)
            
            file_extension = ".jpg" 
            filename = f"{uuid.uuid4()}{file_extension}"
            
            self.client.put_object(
                bucket_name=self.bucket_name,
                object_name=filename,
                data=output_buffer,
                length=len(output_buffer.getvalue()),
                content_type='image/jpeg'
            )
            
            return f"/minio/{self.bucket_name}/{filename}"
            
        except Exception as e:
            print(f"MinIO upload error: {e}")
            raise HTTPException(
                status_code=500,
                detail=f"Error uploading image to MinIO: {str(e)}"
            )

    def delete_image(self, image_url: str) -> bool:
        """Удаляет изображение из MinIO"""
        try:
            if not image_url:
                return False
                
            filename = image_url.split('/')[-1]
            
            if not filename:
                return False
                
            self.client.remove_object(self.bucket_name, filename)
            return True
            
        except S3Error as e:
            print(f"MinIO delete error: {e}")
            return False
        except Exception as e:
            print(f"Error deleting image from MinIO: {e}")
            return False

    def get_image_url(self, image_url: str) -> str:
        """Генерирует URL для доступа к изображению"""
        if not image_url:
            return ""
            
        if image_url.startswith(('http://', 'https://')):
            return image_url
            
        filename = image_url.split('/')[-1]
        try:
            return self.client.presigned_get_object(
                self.bucket_name,
                filename,
                expires=604800 
            )
        except S3Error:

            return image_url

minio_client = MinIOClient()