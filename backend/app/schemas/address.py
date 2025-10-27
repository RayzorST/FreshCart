from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class AddressBase(BaseModel):
    title: str
    address_line: str
    city: str
    postal_code: Optional[str] = None
    is_default: bool = False

class AddressCreate(AddressBase):
    pass

class AddressUpdate(BaseModel):
    title: Optional[str] = None
    address_line: Optional[str] = None
    city: Optional[str] = None
    postal_code: Optional[str] = None
    is_default: Optional[bool] = None

class AddressResponse(AddressBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True