from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta

from app.core.security import (
    verify_password, 
    get_password_hash, 
    create_access_token,
    verify_token
)
from app.core.config import settings
from app.models.database import get_db
from app.models.user import User, UserSettings
from app.schemas.user import UserCreate, UserResponse, Token, UserLogin, UserUpdate, ChangePassword, NotificationSettings, NotificationSettingsResponse

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """Получение текущего пользователя из токена"""
    user_id = verify_token(token)
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    return user

@router.post("/register", response_model=UserResponse)
async def register(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """Регистрация нового пользователя"""
    # Проверка существования пользователя
    existing_user = db.query(User).filter(
        (User.email == user_data.email) | (User.username == user_data.username)
    ).first()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email or username already exists"
        )
    
    # Создание пользователя
    hashed_password = get_password_hash(user_data.password)
    db_user = User(
        username=user_data.username,
        email=user_data.email,
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        date_of_birth=user_data.date_of_birth,
        password_hash=hashed_password,
        role_id=1  # Обычный пользователь
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user

@router.post("/login", response_model=Token)
async def login(
    form_data: UserLogin,
    db: Session = Depends(get_db)
):
    """Аутентификация пользователя"""
    # Поиск пользователя по email
    user = db.query(User).filter(User.email == form_data.email).first()
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    # Создание токена
    access_token = create_access_token(
        data={"sub": str(user.id)}
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }

@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)):
    """Получить текущего пользователя с настройками"""
    settings = db.query(UserSettings).filter(UserSettings.user_id == current_user.id).first()
    if not settings:
        settings = UserSettings(user_id=current_user.id)
        db.add(settings)
        db.commit()
        db.refresh(settings)
    
    # Вместо ручного словаря, обновляем объект current_user
    current_user.settings = {
        "order_notifications": settings.order_notifications,
        "promo_notifications": settings.promo_notifications,
    }
    
    return current_user

# Было: UserProfileUpdate -> Стало: UserUpdate
@router.put("/profile", response_model=UserResponse)
async def update_profile(
    profile_data: UserUpdate,  # ← Используем UserUpdate
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # ... код ...
    """Обновить профиль пользователя"""
    update_data = profile_data.dict(exclude_unset=True)
    
    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    return current_user

@router.put("/change-password")
async def change_password(
    password_data: ChangePassword,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Сменить пароль"""
    # Проверяем текущий пароль
    if not current_user.verify_password(password_data.current_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Неверный текущий пароль"
        )
    
    # Устанавливаем новый пароль
    current_user.set_password(password_data.new_password)
    db.commit()
    
    return {"message": "Пароль успешно изменен"}

@router.get("/settings/notifications", response_model=NotificationSettingsResponse)
async def get_notification_settings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Получить настройки уведомлений"""
    settings = db.query(UserSettings).filter(UserSettings.user_id == current_user.id).first()
    
    if not settings:
        # Создаем настройки по умолчанию если их нет
        settings = UserSettings(user_id=current_user.id)
        db.add(settings)
        db.commit()
        db.refresh(settings)
    
    return settings

@router.put("/settings/notifications", response_model=NotificationSettingsResponse)
async def update_notification_settings(
    settings_data: NotificationSettings,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Обновить настройки уведомлений"""
    settings = db.query(UserSettings).filter(UserSettings.user_id == current_user.id).first()
    
    if not settings:
        settings = UserSettings(user_id=current_user.id, **settings_data.dict())
        db.add(settings)
    else:
        update_data = settings_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(settings, field, value)
    
    db.commit()
    db.refresh(settings)
    return settings