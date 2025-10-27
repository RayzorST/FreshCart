from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None

class CategoryCreate(CategoryBase):
    pass

class CategoryResponse(CategoryBase):
    id: int
    
    class Config:
        from_attributes = True

class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    category_id: Optional[int] = None
    stock_quantity: int = 0
    image_url: Optional[str] = None

class ProductCreate(ProductBase):
    pass

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    category_id: Optional[int] = None
    stock_quantity: Optional[int] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None

class ProductResponse(ProductBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    category: Optional[CategoryResponse] = None
    
    class Config:
        from_attributes = True