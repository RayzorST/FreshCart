import logging
import threading
import time
from app.services.rabbitmq import RabbitMQClient

logger = logging.getLogger(__name__)

class MessageConsumer:
    def __init__(self):
        self.is_running = False
        self.consumer_threads = {}
    
    def handle_image_processing(self, message):
        """Обработчик сообщений обработки изображений"""
        try:
            logger.info(f"🖼️ Processing image: {message}")
            # Здесь будет логика обработки изображений
            # Например: анализ фото блюда, определение ингредиентов и т.д.
            
        except Exception as e:
            logger.error(f"❌ Error processing image: {e}")
    
    def handle_order_processing(self, message):
        """Обработчик сообщений обработки заказов"""
        try:
            logger.info(f"📦 Processing order: {message}")
            # Здесь будет логика обработки заказов
            # Например: создание заказа, списание товаров, уведомления и т.д.
            
        except Exception as e:
            logger.error(f"❌ Error processing order: {e}")
    
    def handle_user_notifications(self, message):
        """Обработчик уведомлений пользователей"""
        try:
            logger.info(f"🔔 Sending notification: {message}")
            # Здесь будет логика уведомлений
            # Например: отправка push-уведомлений, email, SMS и т.д.
            
        except Exception as e:
            logger.error(f"❌ Error sending notification: {e}")
    
    def _wait_for_rabbitmq(self):
        """Ожидание готовности RabbitMQ"""
        max_retries = 30
        retry_delay = 2
        
        for attempt in range(max_retries):
            try:
                test_client = RabbitMQClient()
                test_client.connect()
                test_client.close()
                logger.info("✅ RabbitMQ is ready!")
                return True
            except Exception as e:
                if attempt < max_retries - 1:
                    logger.warning(f"🔄 RabbitMQ not ready, retrying in {retry_delay}s... ({attempt + 1}/{max_retries})")
                    time.sleep(retry_delay)
                else:
                    logger.error(f"❌ RabbitMQ not available after {max_retries} attempts")
                    return False
        
        return False
    
    def _create_consumer_for_queue(self, queue: str, handler):
        """Создает и запускает потребителя для конкретной очереди"""
        def consumer_worker():
            logger.info(f"🚀 Starting consumer worker for queue: {queue}")
            
            while self.is_running:
                client = None
                try:
                    # Создаем новое соединение для этого потока
                    client = RabbitMQClient()
                    client.connect()
                    
                    logger.info(f"📥 Consumer for '{queue}' is ready and consuming...")
                    client.consume_messages(queue, handler)
                    client.start_consuming()  # Блокирующий вызов
                    
                except Exception as e:
                    logger.error(f"❌ Consumer for '{queue}' failed: {e}")
                    
                    # Закрываем соединение при ошибке
                    if client:
                        try:
                            client.close()
                        except:
                            pass
                    
                    # Пауза перед переподключением, если еще работаем
                    if self.is_running:
                        logger.info(f"🔄 Reconnecting to '{queue}' in 5 seconds...")
                        time.sleep(5)
                    else:
                        break
                finally:
                    # Всегда закрываем соединение при выходе
                    if client:
                        try:
                            client.close()
                        except:
                            pass
            
            logger.info(f"🛑 Consumer worker for '{queue}' stopped")
        
        return consumer_worker
    
    def start_consumers(self):
        """Запуск всех consumers в отдельных потоках"""
        if not self._wait_for_rabbitmq():
            logger.error("❌ Cannot start consumers - RabbitMQ unavailable")
            return
            
        self.is_running = True
        
        # Запускаем consumers для разных очередей
        queues_handlers = [
            ('image_processing', self.handle_image_processing),
            ('order_processing', self.handle_order_processing),
            ('user_notifications', self.handle_user_notifications),
        ]
        
        for queue, handler in queues_handlers:
            thread = threading.Thread(
                target=self._create_consumer_for_queue(queue, handler),
                daemon=True,
                name=f"Consumer-{queue}"
            )
            thread.start()
            self.consumer_threads[queue] = thread
            logger.info(f"✅ Started consumer thread for queue: {queue}")
        
        logger.info(f"🎯 All consumers started. Total threads: {len(self.consumer_threads)}")
    
    def stop_consumers(self):
        """Остановка всех consumers"""
        logger.info("🛑 Stopping all consumers...")
        self.is_running = False
        
        # Даем время потокам завершиться
        time.sleep(2)
        
        # Логируем статус потоков
        for queue, thread in self.consumer_threads.items():
            if thread.is_alive():
                logger.warning(f"⚠️ Consumer thread for '{queue}' is still alive")
            else:
                logger.info(f"✅ Consumer thread for '{queue}' stopped")
        
        logger.info("🛑 All consumers stopped")

# Глобальный экземпляр consumer
message_consumer = MessageConsumer()