from pydantic import BaseModel, ConfigDict
from typing import Optional, List
from datetime import datetime

# Категории остаются без изменений
class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None

class CategoryCreate(CategoryBase):
    pass

class CategoryResponse(CategoryBase):
    id: int
    
    model_config = ConfigDict(from_attributes=True)

# Схемы для тегов
class TagBase(BaseModel):
    name: str
    description: Optional[str] = None

class TagCreate(TagBase):
    pass

class TagResponse(TagBase):
    id: int
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

class ProductTagLinkBase(BaseModel):
    product_id: int
    tag_id: int

class ProductTagLinkCreate(ProductTagLinkBase):
    pass

class ProductTagLinkResponse(ProductTagLinkBase):
    id: int
    created_at: datetime
    tag: TagResponse  # Включаем информацию о теге
    
    model_config = ConfigDict(from_attributes=True)

# Обновленные схемы продуктов
class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    category_id: Optional[int] = None
    stock_quantity: int = 0
    image_url: Optional[str] = None

class ProductCreate(ProductBase):
    tag_ids: Optional[List[int]] = None

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    category_id: Optional[int] = None
    stock_quantity: Optional[int] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None
    tag_ids: Optional[List[int]] = None

class ProductResponse(ProductBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    category: Optional[CategoryResponse] = None
    tags: List[TagResponse] = []
    
    model_config = ConfigDict(from_attributes=True)

# Схемы для работы с тегами независимо от продуктов
class TagWithProductsResponse(TagResponse):
    products_count: int = 0

# Схемы для массовых операций с тегами
class ProductTagsUpdate(BaseModel):
    tag_names: List[str]  # Список названий тегов для привязки к продукту

class BulkTagAssign(BaseModel):
    product_ids: List[int]
    tag_names: List[str]