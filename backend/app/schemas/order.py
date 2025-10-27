from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.schemas.product import ProductResponse

class OrderItemBase(BaseModel):
    product_id: int
    quantity: int
    price: float

class OrderItemCreate(OrderItemBase):
    pass

class OrderItemResponse(OrderItemBase):
    id: int
    product: ProductResponse
    
    class Config:
        from_attributes = True

class OrderBase(BaseModel):
    shipping_address: str
    notes: Optional[str] = None

class OrderCreate(OrderBase):
    items: List[OrderItemCreate]

class OrderUpdate(BaseModel):
    status: Optional[str] = None
    shipping_address: Optional[str] = None
    notes: Optional[str] = None

class OrderResponse(OrderBase):
    id: int
    user_id: int
    status: str
    total_amount: float
    created_at: datetime
    updated_at: Optional[datetime] = None
    items: List[OrderItemResponse]
    
    class Config:
        from_attributes = True