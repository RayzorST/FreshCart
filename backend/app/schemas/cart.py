from pydantic import BaseModel
from typing import List
from datetime import datetime
from app.schemas.product import ProductResponse

class CartItemBase(BaseModel):
    product_id: int
    quantity: int

class CartItemCreate(CartItemBase):
    pass

class CartItemUpdate(BaseModel):
    quantity: int

class CartItemResponse(CartItemBase):
    id: int
    user_id: int
    #product: ProductResponse
    created_at: datetime
    updated_at: datetime = None
    
    class Config:
        from_attributes = True

class CartResponse(BaseModel):
    items: List[CartItemResponse]
    total_items: int
    total_price: float