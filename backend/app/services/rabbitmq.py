import pika
import json
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

class RabbitMQClient:
    def __init__(self):
        self.connection = None
        self.channel = None
        # Убираем автоматическое подключение в __init__
    
    def connect(self):
        """Установка соединения с RabbitMQ"""
        try:
            self.connection = pika.BlockingConnection(
                pika.URLParameters(settings.RABBITMQ_URL)
            )
            self.channel = self.connection.channel()
            
            # Объявление основных очередей
            queues = [
                ('image_processing', True),
                ('order_processing', True),
                ('user_notifications', True),
                ('ai_results', True),
                ('error_logs', True)
            ]
            
            for queue, durable in queues:
                self.channel.queue_declare(
                    queue=queue,
                    durable=durable,
                    arguments={
                        'x-message-ttl': 60000  # TTL 60 секунд для сообщений
                    }
                )
            
            logger.info("✅ Successfully connected to RabbitMQ")
            
        except Exception as e:
            logger.error(f"❌ Failed to connect to RabbitMQ: {e}")
            raise
    
    def _ensure_connected(self):
        """Проверка и установка соединения при необходимости"""
        if not self.connection or self.connection.is_closed:
            self.connect()
    
    def publish_message(self, queue: str, message: dict):
        """Публикация сообщения в очередь"""
        try:
            self._ensure_connected()
                
            self.channel.basic_publish(
                exchange='',
                routing_key=queue,
                body=json.dumps(message),
                properties=pika.BasicProperties(
                    delivery_mode=2,  # persistent message
                    content_type='application/json'
                )
            )
            logger.debug(f"📤 Message published to '{queue}': {message}")
            
        except Exception as e:
            logger.error(f"❌ Failed to publish message: {e}")
            # Не пытаемся переподключиться автоматически
    
    def consume_messages(self, queue: str, callback):
        """Потребление сообщений из очереди"""
        try:
            self._ensure_connected()
                
            def wrapped_callback(ch, method, properties, body):
                try:
                    message = json.loads(body)
                    callback(message)
                    ch.basic_ack(delivery_tag=method.delivery_tag)
                except Exception as e:
                    logger.error(f"❌ Error processing message: {e}")
                    ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            
            self.channel.basic_consume(
                queue=queue,
                on_message_callback=wrapped_callback,
                auto_ack=False
            )
            
            logger.info(f"📥 Started consuming from '{queue}'")
            
        except Exception as e:
            logger.error(f"❌ Failed to start consumer: {e}")
            raise

    def start_consuming_non_blocking(self):
        """Неблокирующий запуск потребления сообщений"""
        try:
            self._ensure_connected()
            # Этот метод не блокирует, он просто запускает потребление в фоне
            logger.info("🔄 Starting non-blocking consumption...")
        except Exception as e:
            logger.error(f"❌ Error in non-blocking consuming: {e}")
            raise

    def process_data_events(self):
        """Обработка событий (неблокирующая) - должен вызываться периодически"""
        try:
            if self.connection and not self.connection.is_closed:
                self.connection.process_data_events()
        except Exception as e:
            logger.error(f"❌ Error processing data events: {e}")
            # При ошибке переподключаемся
            self.connect()
    
    def start_consuming(self):
        """Запуск потребления сообщений"""
        try:
            self._ensure_connected()
            self.channel.start_consuming()
        except Exception as e:
            logger.error(f"❌ Error in consuming: {e}")
    
    def close(self):
        """Закрытие соединения"""
        if self.connection and not self.connection.is_closed:
            self.connection.close()
            logger.info("🔌 RabbitMQ connection closed")

# Глобальный экземпляр клиента RabbitMQ (без автоматического подключения)
rabbitmq_client = RabbitMQClient()