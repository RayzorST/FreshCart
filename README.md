# FreshCart

🛒 FreshCart - Маркетплейс продуктов питания с ИИ
Многофункциональное приложение для покупки продуктов с возможностью распознавания блюд по фото и автоматическим подбором ингредиентов.

🚀 Возможности
Для пользователей:
📱 Умные покупки - распознавание блюд по фото и автоматический подбор ингредиентов

🛒 Удобный каталог - фильтрация по категориям, поиск товаров

❤️ Избранное - сохранение любимых товаров

📦 История заказов - отслеживание предыдущих покупок

👤 Персонализация - личный кабинет с настройками

Технические особенности:
🎯 Modern Stack - Flutter + FastAPI + PostgreSQL + RabbitMQ

🤖 AI Integration - интеграция с Clarifai для распознавания еды

🔔 Real-time - WebSocket уведомления и брокер сообщений

🐳 Containerized - полная Docker-ориентированная архитектура

📱 Cross-platform - iOS & Android из одного кода

🏗️ Архитектура
text
Frontend (Flutter) ↔ Backend (FastAPI) ↔ RabbitMQ ↔ AI Service ↔ PostgreSQL
Компоненты:
Frontend: Flutter с Riverpod для state management

Backend: FastAPI с JWT аутентификацией

Database: PostgreSQL с SQLAlchemy ORM

Message Broker: RabbitMQ для асинхронных задач

AI Service: Clarifai для распознавания изображений

Storage: MinIO (S3-совместимое) для файлов

🛠️ Установка и запуск
Предварительные требования:
Docker & Docker Compose

Clarifai API ключ (бесплатный тариф)

Быстрый старт:
Клонируй репозиторий:

bash
git clone <repository-url>
cd FreshCart
Настрой окружение:

bash
# Скопируй и настрой .env файл
cp backend/.env.example backend/.env
# Добавь свой CLARIFAI_API_KEY в backend/.env
Запусти приложение:

bash
docker-compose up -d
Примени миграции БД:

bash
docker-compose exec backend alembic upgrade head
Открой приложение:

Frontend: http://localhost:3000

Backend API: http://localhost:8000

API Docs: http://localhost:8000/docs

RabbitMQ Management: http://localhost:15672 (guest/guest)

MinIO Console: http://localhost:9001 (minioadmin/minioadmin)

📁 Структура проекта
text
FreshCart/
├── frontend/                 # Flutter приложение
│   ├── lib/
│   │   ├── features/        # Фичи приложения
│   │   ├── core/           # Общие виджеты и утилиты
│   │   └── main.dart       # Точка входа
│   └── pubspec.yaml
├── backend/                 # FastAPI сервер
│   ├── app/
│   │   ├── api/           # Эндпоинты
│   │   ├── core/          # Конфиги и утилиты
│   │   ├── models/        # SQLAlchemy модели
│   │   ├── schemas/       # Pydantic схемы
│   │   └── services/      # Бизнес-логика
│   ├── alembic/           # Миграции БД
│   └── main.py            # Точка входа
└── docker-compose.yml     # Оркестрация контейнеров
🔧 Разработка
Локальная разработка бэкенда:
bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Запуск в режиме разработки
uvicorn main:app --reload --host 0.0.0.0 --port 8000
Локальная разработка фронтенда:
bash
cd frontend
flutter pub get
flutter run
Полезные команды:
bash
# Просмотр логов
docker-compose logs -f backend

# Создание миграции БД
docker-compose exec backend alembic revision --autogenerate -m "description"

# Запуск тестов
docker-compose exec backend pytest

# Доступ к БД
docker-compose exec postgres psql -U user -d marketplace
🎯 Основные эндпоинты API
Аутентификация:
POST /auth/register - Регистрация

POST /auth/login - Вход

GET /auth/me - Профиль пользователя

Продукты:
GET /products/ - Список продуктов

GET /products/{id} - Детали продукта

GET /products/category/{category} - Фильтр по категории

ИИ функционал:
POST /ai/recognize-dish - Распознавание блюда по фото

GET /ai/ingredients/{dish_name} - Ингредиенты для блюда

Заказы:
POST /orders/ - Создание заказа

GET /orders/ - История заказов

GET /orders/{id} - Детали заказа