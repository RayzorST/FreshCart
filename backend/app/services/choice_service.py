# app/services/choice_service.py

from sqlalchemy.orm import Session, joinedload
from typing import List, Dict, Optional
from app.models.analysis import UserChoice, SelectedProduct, AnalysisHistory
from app.schemas.choice import UserChoiceCreate
import logging

logger = logging.getLogger(__name__)

class ChoiceService:
    def __init__(self, db: Session):
        self.db = db
    
    def create_user_choice(self, user_id: int, choice_data: UserChoiceCreate) -> UserChoice:
        """Создает запись выбора пользователя"""
        
        # Проверяем, что анализ существует и принадлежит пользователю
        analysis = self.db.query(AnalysisHistory).filter(
            AnalysisHistory.id == choice_data.analysis_id,
            AnalysisHistory.user_id == user_id
        ).first()
        
        if not analysis:
            raise ValueError(f"Analysis {choice_data.analysis_id} not found or not owned by user {user_id}")
        
        # Создаем основную запись выбора
        user_choice = UserChoice(
            analysis_id=choice_data.analysis_id,
            user_id=user_id
        )
        
        self.db.add(user_choice)
        self.db.flush()  # Получаем ID без коммита
        
        # Создаем выбранные продукты
        selected_items = []
        for product_data in choice_data.selected_products:
            selected_item = SelectedProduct(
                user_choice_id=user_choice.id,
                product_id=product_data.product_id,
                original_ingredient=product_data.original_ingredient,
                ingredient_type=product_data.ingredient_type,
                quantity=product_data.quantity
            )
            self.db.add(selected_item)
            selected_items.append(selected_item)
        
        self.db.commit()
        self.db.refresh(user_choice)
        
        logger.info(f"Created user choice {user_choice.id} for user {user_id} with {len(selected_items)} products")
        
        return user_choice
    
    def get_user_choices(self, user_id: int, skip: int = 0, limit: int = 50) -> List[UserChoice]:
        """Получает историю выборов пользователя"""
        return self.db.query(UserChoice).filter(
            UserChoice.user_id == user_id
        ).order_by(UserChoice.created_at.desc()).offset(skip).limit(limit).all()
    
    def get_user_choice_with_products(self, choice_id: int, user_id: int) -> Optional[UserChoice]:
        """Получает выбор пользователя с деталями продуктов"""
        return self.db.query(UserChoice).filter(
            UserChoice.id == choice_id,
            UserChoice.user_id == user_id
        ).options(
            joinedload(UserChoice.selected_items).joinedload(SelectedProduct.product)
        ).first()
    
    def get_choices_by_analysis(self, analysis_id: int, user_id: int) -> List[UserChoice]:
        """Получает все выборы для конкретного анализа"""
        return self.db.query(UserChoice).filter(
            UserChoice.analysis_id == analysis_id,
            UserChoice.user_id == user_id
        ).order_by(UserChoice.created_at.desc()).all()
    
    def get_choice_statistics(self, user_id: int) -> Dict:
        """Статистика по выборам пользователя"""
        total_choices = self.db.query(UserChoice).filter(
            UserChoice.user_id == user_id
        ).count()
        
        # Самые часто выбираемые ингредиенты
        popular_ingredients = self.db.query(
            SelectedProduct.original_ingredient,
            func.count(SelectedProduct.id).label('count')
        ).join(UserChoice).filter(
            UserChoice.user_id == user_id
        ).group_by(SelectedProduct.original_ingredient).order_by(
            func.count(SelectedProduct.id).desc()
        ).limit(5).all()
        
        # Самые часто выбираемые продукты
        popular_products = self.db.query(
            SelectedProduct.product_id,
            func.count(SelectedProduct.id).label('count')
        ).join(UserChoice).filter(
            UserChoice.user_id == user_id
        ).group_by(SelectedProduct.product_id).order_by(
            func.count(SelectedProduct.id).desc()
        ).limit(5).all()
        
        return {
            "total_choices": total_choices,
            "popular_ingredients": [
                {"ingredient": ing, "count": cnt} 
                for ing, cnt in popular_ingredients
            ],
            "popular_products": [
                {"product_id": pid, "count": cnt} 
                for pid, cnt in popular_products
            ]
        }