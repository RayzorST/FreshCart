from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.models.database import get_db
from app.models.order import Address
from app.models.user import User
from app.schemas.address import AddressResponse, AddressCreate, AddressUpdate
from app.api.endpoints.auth import get_current_user

router = APIRouter()

@router.get("/", response_model=List[AddressResponse])
async def get_my_addresses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Получение списка адресов пользователя"""
    addresses = db.query(Address).filter(
        Address.user_id == current_user.id
    ).order_by(Address.is_default.desc(), Address.created_at.desc()).all()
    
    return addresses

@router.post("/", response_model=AddressResponse)
async def create_address(
    address_data: AddressCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Создание нового адреса"""
    
    if address_data.is_default:
        db.query(Address).filter(
            Address.user_id == current_user.id,
            Address.is_default == True
        ).update({"is_default": False})
    
    address = Address(
        user_id=current_user.id,
        **address_data.dict()
    )
    
    db.add(address)
    db.commit()
    db.refresh(address)
    
    return address

@router.get("/{address_id}", response_model=AddressResponse)
async def get_address(
    address_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Получение адреса по ID"""
    address = db.query(Address).filter(
        Address.id == address_id,
        Address.user_id == current_user.id
    ).first()
    
    if not address:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Address not found"
        )
    
    return address

@router.put("/{address_id}", response_model=AddressResponse)
async def update_address(
    address_id: int,
    address_data: AddressUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Обновление адреса"""
    address = db.query(Address).filter(
        Address.id == address_id,
        Address.user_id == current_user.id
    ).first()
    
    if not address:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Address not found"
        )
    
    if address_data.is_default:
        db.query(Address).filter(
            Address.user_id == current_user.id,
            Address.is_default == True
        ).update({"is_default": False})
    
    update_data = address_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(address, field, value)
    
    db.commit()
    db.refresh(address)
    
    return address

@router.delete("/{address_id}")
async def delete_address(
    address_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Удаление адреса"""
    address = db.query(Address).filter(
        Address.id == address_id,
        Address.user_id == current_user.id
    ).first()
    
    if not address:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Address not found"
        )
    
    db.delete(address)
    db.commit()
    
    return {"message": "Address deleted successfully"}

@router.put("/{address_id}/set-default")
async def set_default_address(
    address_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Установка адреса как адреса по умолчанию"""
    address = db.query(Address).filter(
        Address.id == address_id,
        Address.user_id == current_user.id
    ).first()
    
    if not address:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Address not found"
        )

    db.query(Address).filter(
        Address.user_id == current_user.id
    ).update({"is_default": False})

    address.is_default = True
    db.commit()
    
    return {"message": "Address set as default"}