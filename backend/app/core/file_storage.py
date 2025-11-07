from fastapi import UploadFile, HTTPException
from .minio_client import minio_client

async def save_image(file: UploadFile) -> str:
    """Сохранение изображения через MinIO"""
    try:
        return await minio_client.upload_image_file(file)
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=500,
            detail=f"Error saving image: {str(e)}"
        )

async def save_image_base64(base64_data: str) -> str:
    """Сохранение изображения из base64 через MinIO"""
    try:
        return await minio_client.upload_image_base64(base64_data)
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=500,
            detail=f"Error saving base64 image: {str(e)}"
        )

def delete_image(image_url: str) -> None:
    """Удаление изображения через MinIO"""
    try:
        minio_client.delete_image(image_url)
    except Exception as e:
        print(f"Error deleting image: {e}")