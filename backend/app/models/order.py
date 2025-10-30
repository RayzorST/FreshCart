from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.database import Base

class Order(Base):
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    status = Column(String(50), default='pending')
    total_amount = Column(Float, default=0.0)           # Общая сумма
    discount_amount = Column(Float, default=0.0)        # Сумма скидки
    final_amount = Column(Float, default=0.0)           # Итоговая сумма (total_amount - discount_amount)
    shipping_address = Column(Text)
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    items = relationship("OrderItem", back_populates="order")
    applied_promotions = relationship("OrderPromotion", back_populates="order")

class OrderItem(Base):
    __tablename__ = "order_items"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    quantity = Column(Integer, nullable=False)
    price = Column(Float, nullable=False)               # Исходная цена
    discount_price = Column(Float, default=0.0)         # Цена со скидкой
    applied_promotions = Column(Text)                   # JSON с примененными акциями к этому товару
    
    order = relationship("Order", back_populates="items")
    product = relationship("Product")

class OrderPromotion(Base):
    __tablename__ = "order_promotions"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    promotion_id = Column(Integer, ForeignKey("promotions.id"))
    discount_amount = Column(Float, default=0.0)        # Сумма скидки от этой акции
    description = Column(String(500))                   # Описание примененной акции
    
    order = relationship("Order", back_populates="applied_promotions")
    promotion = relationship("Promotion")

class Address(Base):
    __tablename__ = "addresses"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))  # Оставить только FK
    title = Column(String(100), nullable=False)
    address_line = Column(String(500), nullable=False)
    city = Column(String(100), nullable=False)
    postal_code = Column(String(20))
    is_default = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # УБРАТЬ: user = relationship("User", back_populates="addresses")