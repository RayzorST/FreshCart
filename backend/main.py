from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import logging
import threading

from app.core.config import settings
from app.models.database import engine, Base, SessionLocal
from app.models.user import Role
from app.services.rabbitmq_consumer import message_consumer
from app.api.endpoints import auth, products, orders, cart, addresses, images, favorites, promotions, analysis

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

Base.metadata.create_all(bind=engine)

def create_initial_role():
    db = SessionLocal()
    try:
        if not db.query(Role).filter(Role.id == 1).first():
            role = Role(id=1, name='user', description='Regular User')
            db.add(role)
            db.commit()
            print("✅ Initial role created")
    except Exception as e:
        print(f"⚠️ Role creation warning: {e}")
    finally:
        db.close()

create_initial_role()

app = FastAPI(
    title="Food Marketplace API",
    description="API для маркетплейса продуктов питания с ИИ распознаванием блюд",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "*",
        "http://127.0.0.1:8000",
        "http://10.0.2.2:8000",
        "http://192.168.1.100:8000",
        "https://freshcart.cloudpub.ru",
        "https://freshcart-api.cloudpub.ru",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="uploads"), name="static")

app.include_router(auth.router, prefix="/auth", tags=["authentication"])
app.include_router(products.router, prefix="/products", tags=["products"])
app.include_router(orders.router, prefix="/orders", tags=["orders"])
app.include_router(cart.router, prefix="/cart", tags=["cart"])
app.include_router(addresses.router, prefix="/addresses", tags=["addresses"])
app.include_router(images.router, prefix="/images", tags=["images"])
app.include_router(favorites.router, prefix="/favorites", tags=["favorites"])
app.include_router(promotions.router, prefix="/promotions", tags=["promotions"])
app.include_router(analysis.router, prefix="/ai", tags=["ai"])



@app.on_event("startup")
async def startup_event():
    """Запуск приложения"""
    logger = logging.getLogger(__name__)
    logger.info("🚀 Starting Food Marketplace API...")
    
    consumer_thread = threading.Thread(
        target=message_consumer.start_consumers,
        daemon=True,
        name="RabbitMQ-Consumers"
    )
    consumer_thread.start()
    logger.info("✅ RabbitMQ consumers started")

@app.on_event("shutdown")
async def shutdown_event():
    """Остановка приложения"""
    logger = logging.getLogger(__name__)
    logger.info("🛑 Shutting down Food Marketplace API...")
    message_consumer.stop_consumers()

@app.get("/")
async def root():
    return {"message": "Food Marketplace API"}

@app.get("/health")
async def health_check():
    from app.models.database import SessionLocal
    from sqlalchemy import text
    
    db_status = "connected"
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
    except Exception:
        db_status = "disconnected"
    
    rabbitmq_status = "connected"
    try:
        from app.services.rabbitmq import rabbitmq_client
        rabbitmq_client._ensure_connected()
    except Exception:
        rabbitmq_status = "disconnected"
    
    return {
        "status": "healthy",
        "database": db_status,
        "rabbitmq": rabbitmq_status
    }

