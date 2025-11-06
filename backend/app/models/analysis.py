# app/models/analysis.py
from sqlalchemy.orm import relationship
from sqlalchemy import Column, Integer, String, DateTime, Float, JSON
from sqlalchemy.sql import func
from sqlalchemy import ForeignKey
from app.models.database import Base

class AnalysisHistory(Base):
    __tablename__ = "analysis_history"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    image_hash = Column(String(64), index=True)  # Для избежания дубликатов
    detected_dish = Column(String(255), nullable=False)
    confidence = Column(Float, nullable=False)
    ingredients = Column(JSON)  # {basic: [], additional: []}
    alternatives_found = Column(JSON)  # Результаты поиска товаров
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="analysis_history")