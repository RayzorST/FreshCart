# app/services/analysis_history_service.py
from sqlalchemy.orm import Session
from typing import List, Dict, Optional
from app.models.analysis import AnalysisHistory
from sqlalchemy import func, and_
from datetime import datetime, timedelta
import hashlib

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
        """Создание записи анализа"""
        
        # Создаем хэш изображения для избежания дубликатов
        image_hash = hashlib.sha256(image_bytes).hexdigest()
        
        # Проверяем нет ли недавнего такого же анализа (за последний час)
        one_hour_ago = datetime.now() - timedelta(hours=1)
        
        recent_duplicate = self.db.query(AnalysisHistory).filter(
            AnalysisHistory.user_id == user_id,
            AnalysisHistory.image_hash == image_hash,
            AnalysisHistory.created_at >= one_hour_ago
        ).first()
        
        if recent_duplicate:
            return recent_duplicate
        
        record = AnalysisHistory(
            user_id=user_id,
            image_hash=image_hash,
            detected_dish=detected_dish,
            confidence=confidence,
            ingredients=ingredients,
            alternatives_found=alternatives_found
        )
        
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return record
    
    def get_user_analysis_history(
        self, 
        user_id: int, 
        limit: int = 50,
        offset: int = 0
    ) -> List[AnalysisHistory]:
        """Получение истории анализов пользователя"""
        return self.db.query(AnalysisHistory).filter(
            AnalysisHistory.user_id == user_id
        ).order_by(
            AnalysisHistory.created_at.desc()
        ).offset(offset).limit(limit).all()
    
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
        
        success_rate = (high_confidence / total * 100) if total > 0 else 0
        
        return {
            "total_analyses": total,
            "high_confidence_analyses": high_confidence,
            "recent_week_analyses": recent_analyses,
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