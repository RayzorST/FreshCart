from pydantic import BaseModel, validator
from datetime import datetime
from typing import Optional, List
from app.models.enum.promotions import PromotionType

class PromotionBase(BaseModel):
    name: str
    description: Optional[str] = None
    promotion_type: PromotionType
    value: Optional[int] = None
    gift_product_id: Optional[int] = None
    min_quantity: int = 1
    min_order_amount: int = 0
    start_date: datetime
    end_date: datetime
    priority: int = 0

class PromotionCreate(PromotionBase):
    category_ids: Optional[List[int]] = []
    product_ids: Optional[List[int]] = []

    @validator('end_date')
    def end_date_after_start_date(cls, v, values):
        if 'start_date' in values and v <= values['start_date']:
            raise ValueError('End date must be after start date')
        return v

    @validator('value')
    def validate_value(cls, v, values):
        if 'promotion_type' in values:
            if values['promotion_type'] in [PromotionType.PERCENTAGE, PromotionType.FIXED] and v is None:
                raise ValueError('Value is required for percentage and fixed promotions')
            if values['promotion_type'] == PromotionType.PERCENTAGE and (v <= 0 or v > 100):
                raise ValueError('Percentage must be between 1 and 100')
            if values['promotion_type'] == PromotionType.FIXED and v <= 0:
                raise ValueError('Fixed amount must be greater than 0')
        return v

class PromotionUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None
    priority: Optional[int] = None

class PromotionResponse(PromotionBase):
    id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True