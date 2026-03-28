from pydantic import BaseModel
from datetime import datetime
from typing import Optional, Dict, Any
from app.models.notification import NotificationType

class NotificationBase(BaseModel):
    type: NotificationType
    title: str
    message: str
    data: Optional[Dict[str, Any]] = None

class NotificationCreate(NotificationBase):
    user_id: int

class NotificationResponse(NotificationBase):
    id: int
    user_id: int
    status: str
    created_at: datetime
    read_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class MarkReadRequest(BaseModel):
    notification_id: int