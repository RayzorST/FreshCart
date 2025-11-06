from sqlalchemy import Column, Integer, String, Date, DateTime, Boolean, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.database import Base
from app.core.security import verify_password, get_password_hash

class Role(Base):
    __tablename__ = "roles"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False)
    description = Column(String(255))
    
    users = relationship("User", back_populates="role")
    
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    first_name = Column(String(100))
    last_name = Column(String(100))
    password_hash = Column(String(255), nullable=False)
    date_of_birth = Column(Date)
    role_id = Column(Integer, ForeignKey("roles.id"), default=1)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    role = relationship("Role", back_populates="users")
    analysis_history = relationship("AnalysisHistory", back_populates="user")
    #settings = relationship("UserSettings", back_populates="user", uselist=False)

    def verify_password(self, password: str) -> bool:
        return verify_password(password, self.password_hash)
    
    def set_password(self, password: str):
        self.password_hash = get_password_hash(password)

class UserSettings(Base):
    __tablename__ = "user_settings"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    order_notifications = Column(Boolean, default=True)
    promo_notifications = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())