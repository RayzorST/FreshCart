from sqlalchemy import Column, Integer, String, DateTime, Boolean, Enum, ForeignKey, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.models.database import Base

class PromotionType(enum.Enum):
    PERCENTAGE = "percentage"    # Процентная скидка
    FIXED = "fixed"              # Фиксированная сумма
    GIFT = "gift"                # Подарок (1+1=3)

class Promotion(Base):
    __tablename__ = "promotions"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)                    # Название акции
    description = Column(Text)                                    # Описание
    promotion_type = Column(Enum(PromotionType), nullable=False) # Тип акции
    value = Column(Integer)                                      # Значение: для percentage - %, для fixed - сумма в копейках
    gift_product_id = Column(Integer, ForeignKey("products.id")) # Для gift - ID товара-подарка
    min_quantity = Column(Integer, default=1)                    # Минимальное количество для активации (для gift)
    min_order_amount = Column(Integer, default=0)               # Минимальная сумма заказа (в копейках)
    start_date = Column(DateTime, nullable=False)               # Начало акции
    end_date = Column(DateTime, nullable=False)                 # Конец акции
    is_active = Column(Boolean, default=True)                   # Активна ли акция
    priority = Column(Integer, default=0)                       # Приоритет (чем выше число, тем выше приоритет)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Связи
    gift_product = relationship("Product", foreign_keys=[gift_product_id])
    categories = relationship("PromotionCategory", back_populates="promotion")
    products = relationship("PromotionProduct", back_populates="promotion")

class PromotionCategory(Base):
    __tablename__ = "promotion_categories"
    
    id = Column(Integer, primary_key=True, index=True)
    promotion_id = Column(Integer, ForeignKey("promotions.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    
    # Связи
    promotion = relationship("Promotion", back_populates="categories")
    category = relationship("Category")

class PromotionProduct(Base):
    __tablename__ = "promotion_products"
    
    id = Column(Integer, primary_key=True, index=True)
    promotion_id = Column(Integer, ForeignKey("promotions.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    
    # Связи
    promotion = relationship("Promotion", back_populates="products")
    product = relationship("Product")