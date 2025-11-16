from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.database import get_db
from app.models.user import User
from app.models.product import Product
from app.models.order import Order
from app.models.promotions import Promotion
from app.api.endpoints.auth import get_current_admin

router = APIRouter()

@router.get("/stats")
async def get_admin_stats(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Общая статистика для админ-панели"""
    total_users = db.query(User).count()
    total_products = db.query(Product).filter(Product.is_active == True).count()
    total_orders = db.query(Order).count()
    total_promotions = db.query(Promotion).filter(Promotion.is_active == True).count()
    
    return {
        "total_users": total_users,
        "total_products": total_products,
        "total_orders": total_orders,
        "total_promotions": total_promotions
    }