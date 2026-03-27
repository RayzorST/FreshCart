from pydantic import BaseModel
from typing import List
from datetime import datetime
from typing import List, Optional, Dict, Any
from app.schemas.product import ProductResponse

class CartItemBase(BaseModel):
    product_id: int
    quantity: int

class CartItemCreate(CartItemBase):
    choice_metadata: Optional[dict] = None

class CartItemUpdate(BaseModel):
    quantity: int

class CartItemResponse(CartItemBase):
    id: int
    user_id: int
    product: ProductResponse
    created_at: datetime
    updated_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    discount_price: Optional[float] = None 
    applied_promotions: Optional[List[Dict]] = []
    user_choice_id: Optional[int] = None
    selected_product_id: Optional[int] = None
    
    class Config:
        from_attributes = True

class CartResponse(BaseModel):
    items: List[CartItemResponse]
    total_items: int
    total_price: float
    discount_amount: float = 0  # ДОБАВИТЬ
    final_price: float = 0  # ДОБАВИТЬ
    applied_promotions: List[Dict] = []  # ДОБАВИТЬ