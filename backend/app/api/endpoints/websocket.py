from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.orm import Session
from app.models.database import get_db
from app.services.websocket_manager import websocket_manager
from app.services.notification_service import NotificationService
from app.models.user import User
from app.api.endpoints.auth import get_current_user_ws
import json
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

# app/api/endpoints/websocket.py - добавим больше логов
@router.websocket("/notifications")
async def websocket_endpoint(
    websocket: WebSocket,
    db: Session = Depends(get_db)
):
    """WebSocket эндпоинт для получения уведомлений в реальном времени"""
    user = None
    try:
        token = websocket.query_params.get("token")
        logger.info(f"🔌 WebSocket connection attempt")
        logger.info(f"🔌 Token: {token[:30] if token else 'None'}...")
        
        if not token:
            logger.warning("❌ No token provided")
            await websocket.close(code=1008, reason="No token provided")
            return
        
        user = await get_current_user_ws(token, db)
        if not user:
            logger.warning("❌ Invalid token")
            await websocket.close(code=1008, reason="Invalid token")
            return
        
        logger.info(f"✅ User {user.id} authenticated")
        
        # Подключаем WebSocket
        await websocket_manager.connect(websocket, user.id)
        logger.info(f"✅ WebSocket connected for user {user.id}")
        
        # Отправляем количество непрочитанных уведомлений
        notification_service = NotificationService(db)
        unread_count = notification_service.get_unread_count(user.id)
        await websocket.send_text(json.dumps({
            "type": "initial",
            "unread_count": unread_count
        }))
        logger.info(f"📊 Sent unread count: {unread_count}")
        
        # Ждем сообщения от клиента
        while True:
            try:
                data = await websocket.receive_text()
                logger.debug(f"📨 Received from client: {data}")
                
                if data == "ping":
                    await websocket.send_text("pong")
                else:
                    message = json.loads(data)
                    if message.get("type") == "mark_read":
                        notification_id = message.get("notification_id")
                        if notification_id:
                            notification_service.mark_as_read(notification_id, user.id)
                            await websocket.send_text(json.dumps({
                                "type": "marked_read",
                                "notification_id": notification_id
                            }))
                            logger.info(f"📖 Marked notification {notification_id} as read")
                    elif message.get("type") == "mark_all_read":
                        count = notification_service.mark_all_as_read(user.id)
                        await websocket.send_text(json.dumps({
                            "type": "marked_all_read",
                            "count": count
                        }))
                        logger.info(f"📖 Marked all ({count}) notifications as read")
            except WebSocketDisconnect:
                logger.info(f"🔌 WebSocket disconnected for user {user.id}")
                break
            except json.JSONDecodeError:
                logger.warning(f"Invalid JSON from user {user.id}")
            except Exception as e:
                logger.error(f"Error processing message: {e}")
    
    except WebSocketDisconnect:
        if user:
            await websocket_manager.disconnect(websocket, user.id)
        logger.info(f"WebSocket disconnected")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        try:
            await websocket.close(code=1011, reason="Internal server error")
        except:
            pass
