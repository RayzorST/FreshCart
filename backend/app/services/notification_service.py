import logging
import json
import asyncio
from typing import List, Optional, Dict, Any
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.models.notification import Notification, NotificationType, NotificationStatus
from app.models.user import User, UserSettings
from app.services.websocket_manager import websocket_manager

logger = logging.getLogger(__name__)

class NotificationService:
    def __init__(self, db: Session):
        self.db = db

    def _send_websocket_message(self, user_id: int, message: str):
        """Send WebSocket message in a separate thread"""
        try:
            # Создаем новый event loop в отдельном потоке
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            async def send():
                await websocket_manager.send_personal_message(message, user_id)
            
            loop.run_until_complete(send())
            loop.close()
            logger.debug(f"WebSocket message sent to user {user_id}")
        except Exception as e:
            logger.error(f"Failed to send WebSocket message: {e}")

    def create_notification(
        self,
        user_id: int,
        notification_type: NotificationType,
        title: str,
        message: str,
        data: Optional[Dict[str, Any]] = None
    ) -> Notification:
        """Create notification for user"""
        try:
            notification = Notification(
                user_id=user_id,
                type=notification_type,
                title=title,
                message=message,
                data=json.dumps(data) if data else None
            )
            
            self.db.add(notification)
            self.db.commit()
            self.db.refresh(notification)
            
            # Отправляем через WebSocket
            ws_message = json.dumps({
                "id": notification.id,
                "user_id": notification.user_id,
                "type": notification.type.value,
                "title": notification.title,
                "message": notification.message,
                "data": data,
                "status": notification.status.value,
                "created_at": notification.created_at.isoformat()
            })
            
            # Запускаем отправку в отдельном потоке
            import threading
            thread = threading.Thread(
                target=self._send_websocket_message,
                args=(user_id, ws_message),
                daemon=True
            )
            thread.start()
            
            logger.info(f"Notification created for user {user_id}: {title}")
            return notification
            
        except Exception as e:
            logger.error(f"Error creating notification: {e}")
            self.db.rollback()
            raise

    def create_order_status_notification(
        self,
        user_id: int,
        order_id: int,
        old_status: str,
        new_status: str
    ) -> Notification:
        """Create order status change notification"""
        # Проверяем настройки пользователя
        user_settings = self.db.query(UserSettings).filter(
            UserSettings.user_id == user_id
        ).first()
        
        # Если настройки есть и пользователь отключил уведомления о заказах - не отправляем
        if user_settings and not user_settings.order_notifications:
            logger.info(f"User {user_id} disabled order notifications")
            return None
        
        status_messages = {
            "pending": "Заказ создан и ожидает обработки",
            "confirmed": "Заказ подтвержден",
            "shipped": "Заказ отправлен",
            "delivered": "Заказ доставлен",
            "cancelled": "Заказ отменен"
        }
        
        message = status_messages.get(new_status, f"Статус заказа изменен на {new_status}")
        
        return self.create_notification(
            user_id=user_id,
            notification_type=NotificationType.ORDER_STATUS,
            title=f"Изменение статуса заказа #{order_id}",
            message=message,
            data={
                "order_id": order_id,
                "old_status": old_status,
                "new_status": new_status
            }
        )

    def create_promotion_notification(
        self,
        user_id: int,
        promotion_id: int,
        promotion_name: str,
        promotion_description: str
    ) -> Notification:
        """Create new promotion notification"""
        # Проверяем настройки пользователя
        user_settings = self.db.query(UserSettings).filter(
            UserSettings.user_id == user_id
        ).first()
        
        # Если настройки есть и пользователь отключил уведомления об акциях - не отправляем
        if user_settings and not user_settings.promo_notifications:
            logger.info(f"User {user_id} disabled promo notifications")
            return None
        
        return self.create_notification(
            user_id=user_id,
            notification_type=NotificationType.NEW_PROMOTION,
            title=f"Новая акция: {promotion_name}",
            message=promotion_description[:200] if promotion_description else "Действует ограниченное время!",
            data={
                "promotion_id": promotion_id,
                "promotion_name": promotion_name
            }
        )

    def get_user_notifications(
        self,
        user_id: int,
        skip: int = 0,
        limit: int = 50,
        unread_only: bool = False
    ) -> List[Notification]:
        """Получить уведомления пользователя"""
        query = self.db.query(Notification).filter(Notification.user_id == user_id)
        
        if unread_only:
            query = query.filter(Notification.status == NotificationStatus.UNREAD)
        
        return query.order_by(Notification.created_at.desc()).offset(skip).limit(limit).all()
    
    def mark_as_read(self, notification_id: int, user_id: int) -> Optional[Notification]:
        """Отметить уведомление как прочитанное"""
        notification = self.db.query(Notification).filter(
            and_(
                Notification.id == notification_id,
                Notification.user_id == user_id
            )
        ).first()
        
        if notification and notification.status == NotificationStatus.UNREAD:
            notification.status = NotificationStatus.READ
            notification.read_at = datetime.utcnow()
            self.db.commit()
            self.db.refresh(notification)
        
        return notification
    
    def mark_all_as_read(self, user_id: int) -> int:
        """Отметить все уведомления пользователя как прочитанные"""
        count = self.db.query(Notification).filter(
            and_(
                Notification.user_id == user_id,
                Notification.status == NotificationStatus.UNREAD
            )
        ).update({"status": NotificationStatus.READ, "read_at": datetime.utcnow()})
        
        self.db.commit()
        return count
    
    def get_unread_count(self, user_id: int) -> int:
        """Получить количество непрочитанных уведомлений"""
        return self.db.query(Notification).filter(
            and_(
                Notification.user_id == user_id,
                Notification.status == NotificationStatus.UNREAD
            )
        ).count()