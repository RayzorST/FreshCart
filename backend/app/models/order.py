from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.database import Base

class Order(Base):
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    status = Column(String(50), default='pending')
    total_amount = Column(Float, default=0.0)
    discount_amount = Column(Float, default=0.0)  
    final_amount = Column(Float, default=0.0)
    shipping_address = Column(Text)
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    items = relationship("OrderItem", back_populates="order")
    promotions = relationship("OrderPromotion", back_populates="order")

class OrderItem(Base):
    __tablename__ = "order_items"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    quantity = Column(Integer, nullable=False)
    price = Column(Float, nullable=False)  
    discount_price = Column(Float, default=0.0)
    applied_promotions = Column(Text) 
    
    order = relationship("Order", back_populates="items")
    product = relationship("Product")

class OrderPromotion(Base):
    __tablename__ = "order_promotions"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    promotion_id = Column(Integer, ForeignKey("promotions.id"))
    discount_amount = Column(Float, default=0.0)
    description = Column(String(500))
    
    order = relationship("Order", back_populates="promotions")
    promotion = relationship("Promotion")

class Address(Base):
    __tablename__ = "addresses"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id")) 
    title = Column(String(100), nullable=False)
    address_line = Column(String(500), nullable=False)
    city = Column(String(100), nullable=False)
    postal_code = Column(String(20))
    is_default = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())