# app/services/analysis_history_service.py
from sqlalchemy.orm import Session
from typing import List, Dict, Optional
from app.models.analysis import AnalysisHistory
from sqlalchemy import func, and_
from datetime import datetime, timedelta
import hashlib
import logging

logger = logging.getLogger(__name__)

class AnalysisHistoryService:
    def __init__(self, db: Session):
        self.db = db
    
    def create_analysis_record(
        self, 
        user_id: int,
        image_bytes: bytes, 
        detected_dish: str,
        confidence: float,
        ingredients: Dict,
        alternatives_found: Dict
    ) -> AnalysisHistory:
        """Создание записи анализа (старая версия с image_bytes)"""
        
        if image_bytes:
            image_hash = hashlib.sha256(image_bytes).hexdigest()
        else:
            hash_input = f"{user_id}_{detected_dish}_{datetime.now().timestamp()}"
            image_hash = hashlib.sha256(hash_input.encode()).hexdigest()
        
        one_hour_ago = datetime.now() - timedelta(hours=1)
        
        # ВАЖНО: если в модели нет image_hash, убираем эту проверку
        # recent_duplicate = self.db.query(AnalysisHistory).filter(
        #     AnalysisHistory.user_id == user_id,
        #     AnalysisHistory.image_hash == image_hash,  # Убрать если нет такого поля
        #     AnalysisHistory.created_at >= one_hour_ago
        # ).first()
        # 
        # if recent_duplicate:
        #     return recent_duplicate
        
        record = AnalysisHistory(
            user_id=user_id,
            # image_hash=image_hash,  # Убрать если нет такого поля в модели
            detected_dish=detected_dish,
            confidence=confidence,
            ingredients=ingredients,
            alternatives_found=alternatives_found
        )
        
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return record
    
    # НОВЫЙ МЕТОД без image_bytes
    def create_analysis_record_simple(
        self, 
        user_id: int,
        detected_dish: str,
        confidence: float,
        ingredients: Dict,
        alternatives_found: Dict
    ) -> AnalysisHistory:
        """Создание записи анализа (новая версия без image_bytes)"""
        
        record = AnalysisHistory(
            user_id=user_id,
            detected_dish=detected_dish,
            confidence=confidence,
            ingredients=ingredients,
            alternatives_found=alternatives_found,
            image_url=None  # Будет установлено позже
        )
        
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        logger.info(f"Created analysis record ID: {record.id} for user {user_id}")
        return record
    
    def update_analysis_image(
        self,
        analysis_id: int,
        user_id: int,
        image_url: str
    ) -> bool:
        """Обновление URL изображения для анализа"""
        try:
            record = self.db.query(AnalysisHistory).filter(
                AnalysisHistory.id == analysis_id,
                AnalysisHistory.user_id == user_id
            ).first()
            
            if record:
                record.image_url = image_url
                self.db.commit()
                logger.info(f"Updated image URL for analysis {analysis_id}: {image_url}")
                return True
            else:
                logger.warning(f"Analysis record {analysis_id} not found for user {user_id}")
                return False
        except Exception as e:
            logger.error(f"Error updating analysis image: {e}")
            return False
    
    def get_analysis_history(
        self, 
        user_id: Optional[int] = None,
        offset: int = 0, 
        limit: int = 20, 
        min_confidence: float = None
    ):
        """Получение истории анализов"""
        query = self.db.query(AnalysisHistory)
        
        if user_id is not None:
            query = query.filter(AnalysisHistory.user_id == user_id)
        
        if min_confidence is not None:
            query = query.filter(AnalysisHistory.confidence >= min_confidence)
        
        return query.order_by(AnalysisHistory.created_at.desc()).offset(offset).limit(limit).all()
    
    def get_user_analysis_history(
        self,
        user_id: int,
        offset: int = 0,
        limit: int = 20,
        min_confidence: float = None
    ):
        """Получение истории анализов конкретного пользователя"""
        query = self.db.query(AnalysisHistory).filter(
            AnalysisHistory.user_id == user_id
        )
        
        if min_confidence is not None:
            query = query.filter(AnalysisHistory.confidence >= min_confidence)
        
        return query.order_by(AnalysisHistory.created_at.desc()).offset(offset).limit(limit).all()
    
    def get_analysis_stats(self, user_id: int) -> Dict:
        """Статистика по анализам пользователя"""
        total = self.db.query(AnalysisHistory).filter(
            AnalysisHistory.user_id == user_id
        ).count()
        
        high_confidence = self.db.query(AnalysisHistory).filter(
            and_(
                AnalysisHistory.user_id == user_id,
                AnalysisHistory.confidence >= 0.7
            )
        ).count()
        
        # Анализы за последние 7 дней
        seven_days_ago = datetime.now() - timedelta(days=7)
        recent_analyses = self.db.query(AnalysisHistory).filter(
            and_(
                AnalysisHistory.user_id == user_id,
                AnalysisHistory.created_at >= seven_days_ago
            )
        ).count()
        
        # Анализы с изображениями
        analyses_with_images = self.db.query(AnalysisHistory).filter(
            and_(
                AnalysisHistory.user_id == user_id,
                AnalysisHistory.image_url.isnot(None)
            )
        ).count()
        
        success_rate = (high_confidence / total * 100) if total > 0 else 0
        
        return {
            "total_analyses": total,
            "high_confidence_analyses": high_confidence,
            "recent_week_analyses": recent_analyses,
            "analyses_with_images": analyses_with_images,
            "success_rate": round(success_rate, 2)
        }
    
    def get_popular_dishes(self, user_id: int, limit: int = 5) -> List[Dict]:
        """Самые популярные блюда пользователя"""
        from sqlalchemy import desc
        
        popular_dishes = self.db.query(
            AnalysisHistory.detected_dish,
            func.count(AnalysisHistory.id).label('count')
        ).filter(
            AnalysisHistory.user_id == user_id
        ).group_by(
            AnalysisHistory.detected_dish
        ).order_by(
            desc('count')
        ).limit(limit).all()
        
        return [
            {"dish_name": dish, "analysis_count": count}
            for dish, count in popular_dishes
        ]