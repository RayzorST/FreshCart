from pydantic import BaseModel, EmailStr
from typing import Optional, Dict
from datetime import datetime, date

class RoleResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    
    class Config:
        from_attributes = True

class UserBase(BaseModel):
    email: EmailStr
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    date_of_birth: Optional[date] = None

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(UserBase):
    id: int
    is_active: bool
    role: RoleResponse
    created_at: datetime
    settings: Optional[Dict[str, bool]] = None
    
    class Config:
        from_attributes = True

class UserWithSettingsResponse(UserResponse):
    settings: dict
    
    class Config:
        from_attributes = True

class UserUpdate(BaseModel): 
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None

class ChangePassword(BaseModel):
    current_password: str
    new_password: str

class NotificationSettings(BaseModel):
    order_notifications: bool = True
    promo_notifications: bool = True

class NotificationSettingsResponse(NotificationSettings):
    user_id: int
    
    class Config:
        from_attributes = True

class NotificationSettingsUpdate(BaseModel):
    order_notifications: Optional[bool] = None
    promo_notifications: Optional[bool] = None

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    user_id: Optional[int] = None