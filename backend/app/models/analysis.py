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
    detected_dish = Column(String(255), nullable=False)
    confidence = Column(Float, nullable=False)
    ingredients = Column(JSON)
    alternatives_found = Column(JSON)
    image_url = Column(String(500))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="analysis_history")
    user_choices = relationship("UserChoice", back_populates="analysis", cascade="all, delete-orphan")

class UserChoice(Base):
    """Запись выбора пользователя"""
    __tablename__ = "user_choices"
    
    id = Column(Integer, primary_key=True, index=True)
    analysis_id = Column(Integer, ForeignKey("analysis_history.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    analysis = relationship("AnalysisHistory", back_populates="user_choices")
    user = relationship("User", back_populates="user_choices")
    selected_items = relationship("SelectedProduct", back_populates="user_choice", cascade="all, delete-orphan")


class SelectedProduct(Base):
    """Выбранные продукты в рамках одного выбора"""
    __tablename__ = "selected_products"
    
    id = Column(Integer, primary_key=True, index=True)
    user_choice_id = Column(Integer, ForeignKey("user_choices.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    ingredient_type = Column(String(50), nullable=False, default='basic')
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user_choice = relationship("UserChoice", back_populates="selected_items")
    product = relationship("Product")