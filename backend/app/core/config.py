from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/marketplace"
    
    # RabbitMQ
    RABBITMQ_URL: str = "amqp://guest:guest@localhost:5672/"
    
    # Redis (для кеша и Celery)
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # JWT
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 * 30
    
    # File Upload
    UPLOAD_DIR: str = "uploads/images"
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    
    # External APIs (пока заглушки)
    CLARIFAI_API_KEY: str = "your-clarifai-api-key"
    
    # MinIO (S3)
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "minioadmin"
    MINIO_SECRET_KEY: str = "minioadmin"
    
    class Config:
        env_file = ".env"

settings = Settings()