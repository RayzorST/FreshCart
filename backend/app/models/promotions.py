from sqlalchemy import Column, Integer, String, DateTime, Boolean, Enum, ForeignKey, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.enum.promotions import PromotionType
from app.models.database import Base

class Promotion(Base):
    __tablename__ = "promotions"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text)  
    promotion_type = Column(Enum(PromotionType), nullable=False)
    value = Column(Integer)    
    gift_product_id = Column(Integer, ForeignKey("products.id")) 
    min_quantity = Column(Integer, default=1)  
    min_order_amount = Column(Integer, default=0)  
    start_date = Column(DateTime, nullable=False)    
    end_date = Column(DateTime, nullable=False) 
    is_active = Column(Boolean, default=True) 
    priority = Column(Integer, default=0)  
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    gift_product = relationship("Product", foreign_keys=[gift_product_id])
    categories = relationship("PromotionCategory", back_populates="promotion")
    products = relationship("PromotionProduct", back_populates="promotion")

class PromotionCategory(Base):
    __tablename__ = "promotion_categories"
    
    id = Column(Integer, primary_key=True, index=True)
    promotion_id = Column(Integer, ForeignKey("promotions.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    
    promotion = relationship("Promotion", back_populates="categories")
    category = relationship("Category")

class PromotionProduct(Base):
    __tablename__ = "promotion_products"
    
    id = Column(Integer, primary_key=True, index=True)
    promotion_id = Column(Integer, ForeignKey("promotions.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    
    promotion = relationship("Promotion", back_populates="products")
    product = relationship("Product")