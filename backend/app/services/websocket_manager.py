# app/services/websocket_manager.py
import asyncio
import json
import logging
from typing import Dict, Set
from fastapi import WebSocket, WebSocketDisconnect

logger = logging.getLogger(__name__)

class WebSocketManager:
    def __init__(self):
        self.active_connections: Dict[int, Set[WebSocket]] = {}
        self._lock = asyncio.Lock()
    
    async def connect(self, websocket: WebSocket, user_id: int):
        """Connect WebSocket for user"""
        await websocket.accept()
        
        async with self._lock:
            if user_id not in self.active_connections:
                self.active_connections[user_id] = set()
            self.active_connections[user_id].add(websocket)
        
        logger.info(f"WebSocket connected for user {user_id}. Total connections: {len(self.active_connections[user_id])}")
    
    async def disconnect(self, websocket: WebSocket, user_id: int):
        """Disconnect WebSocket for user"""
        async with self._lock:
            if user_id in self.active_connections:
                self.active_connections[user_id].discard(websocket)
                if not self.active_connections[user_id]:
                    del self.active_connections[user_id]
        
        logger.info(f"WebSocket disconnected for user {user_id}")
    
    async def send_personal_message(self, message: str, user_id: int):
        """Send message to specific user"""
        if user_id in self.active_connections:
            disconnected = []
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_text(message)
                    logger.debug(f"Message sent to user {user_id}: {message[:100]}")
                except WebSocketDisconnect:
                    disconnected.append(connection)
                except Exception as e:
                    logger.error(f"Error sending message to user {user_id}: {e}")
                    disconnected.append(connection)
            
            # Remove disconnected connections
            if disconnected:
                async with self._lock:
                    for conn in disconnected:
                        self.active_connections[user_id].discard(conn)
                    if not self.active_connections[user_id]:
                        del self.active_connections[user_id]
        else:
            logger.debug(f"User {user_id} not connected to WebSocket")
    
    async def broadcast_to_users(self, message: str, user_ids: list[int]):
        """Broadcast message to multiple users"""
        tasks = [self.send_personal_message(message, user_id) for user_id in user_ids]
        await asyncio.gather(*tasks)

# Global instance
websocket_manager = WebSocketManager()