from pydantic import BaseModel
from datetime import datetime
from typing import List

class FavoriteBase(BaseModel):
    product_id: int

class FavoriteCreate(FavoriteBase):
    pass

class FavoriteResponse(FavoriteBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class FavoriteWithProductResponse(FavoriteResponse):
    product: dict  # Будем включать информацию о продукте