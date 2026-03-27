# app/schemas/choice.py

from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class SelectedProductBase(BaseModel):
    product_id: int
    original_ingredient: str
    ingredient_type: str  # 'basic' или 'additional'
    quantity: int = 1

class SelectedProductCreate(SelectedProductBase):
    pass

class SelectedProductResponse(SelectedProductBase):
    id: int
    user_choice_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Расширенный ответ с данными продукта
class SelectedProductWithProductResponse(SelectedProductResponse):
    product: dict  # Можно использовать ProductResponse


class UserChoiceBase(BaseModel):
    analysis_id: int

class UserChoiceCreate(UserChoiceBase):
    selected_products: List[SelectedProductCreate]

class UserChoiceResponse(UserChoiceBase):
    id: int
    user_id: int
    created_at: datetime
    selected_items: List[SelectedProductResponse]
    
    class Config:
        from_attributes = True

# Расширенный ответ с деталями продуктов
class UserChoiceWithProductsResponse(UserChoiceResponse):
    selected_items: List[SelectedProductWithProductResponse]