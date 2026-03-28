from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text, Enum as SQLEnum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.database import Base
import enum

class NotificationType(str, enum.Enum):
    ORDER_STATUS = "order_status"
    NEW_PROMOTION = "new_promotion"
    PROMOTION_UPDATE = "promotion_update"
    ORDER_CREATED = "order_created"
    ORDER_CANCELLED = "order_cancelled"
    SYSTEM = "system"

class NotificationStatus(str, enum.Enum):
    UNREAD = "unread"
    READ = "read"
    ARCHIVED = "archived"

class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(SQLEnum(NotificationType), nullable=False)
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    data = Column(Text)  # JSON с дополнительными данными
    status = Column(SQLEnum(NotificationStatus), default=NotificationStatus.UNREAD)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    read_at = Column(DateTime(timezone=True), nullable=True)
    
    user = relationship("User", back_populates="notifications")