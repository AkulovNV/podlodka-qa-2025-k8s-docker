from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
import requests
import os
from models import SessionLocal, User, Order
from database import init_database
from typing import List
import logging

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="QA Demo Microservice", version="1.0.0")

# Конфигурация
EXTERNAL_API_URL = os.getenv("EXTERNAL_API_URL", "http://localhost:8001")

# Инициализация базы данных при старте
@app.on_event("startup")
async def startup_event():
    logger.info("Инициализация приложения...")
    if not init_database():
        logger.error("Не удалось инициализировать базу данных!")
        raise RuntimeError("Database initialization failed")
    logger.info("Приложение инициализировано успешно!")


def get_db():
    """Получить сессию базы данных"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/health")
def health_check():
    """Health check эндпоинт"""
    return {"status": "healthy", "service": "qa-demo-microservice"}


@app.get("/ready")
def readiness_check(db: Session = Depends(get_db)):
    """Readiness check эндпоинт"""
    try:
        # Проверяем подключение к базе
        db.execute(text("SELECT 1"))
        
        # Проверяем внешний сервис
        response = requests.get(f"{EXTERNAL_API_URL}/health", timeout=5)
        external_healthy = response.status_code == 200
        
        return {
            "status": "ready",
            "database": "connected",
            "external_service": "connected" if external_healthy else "disconnected"
        }
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        raise HTTPException(status_code=503, detail=f"Service not ready: {str(e)}")


@app.get("/users", response_model=List[dict])
def get_users(db: Session = Depends(get_db)):
    """Получить список пользователей"""
    try:
        users = db.query(User).all()
        return [{"id": user.id, "name": user.name, "email": user.email} for user in users]
    except Exception as e:
        logger.error(f"Error getting users: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post("/users", response_model=dict)
def create_user(user_data: dict, db: Session = Depends(get_db)):
    """Создать пользователя"""
    try:
        # Проверяем обязательные поля
        if "name" not in user_data or "email" not in user_data:
            raise HTTPException(status_code=400, detail="Name and email are required")
        
        # Проверяем уникальность email
        existing_user = db.query(User).filter(User.email == user_data["email"]).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already exists")
        
        user = User(name=user_data["name"], email=user_data["email"])
        db.add(user)
        db.commit()
        db.refresh(user)
        
        logger.info(f"User created: {user.id}")
        return {"id": user.id, "name": user.name, "email": user.email}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/users/{user_id}/orders")
def get_user_orders(user_id: int, db: Session = Depends(get_db)):
    """Получить заказы пользователя"""
    try:
        # Проверяем существование пользователя
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Получаем заказы из внешнего сервиса
        response = requests.get(f"{EXTERNAL_API_URL}/orders/{user_id}", timeout=10)
        if response.status_code == 200:
            return response.json()
        elif response.status_code == 404:
            return {"orders": []}
        else:
            raise HTTPException(status_code=response.status_code, detail="External service error")
            
    except requests.RequestException as e:
        logger.error(f"External service error: {e}")
        raise HTTPException(status_code=503, detail="External service unavailable")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user orders: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post("/orders")
def create_order(order_data: dict, db: Session = Depends(get_db)):
    """Создать заказ"""
    try:
        # Проверяем обязательные поля
        required_fields = ["user_id", "items", "total"]
        for field in required_fields:
            if field not in order_data:
                raise HTTPException(status_code=400, detail=f"Missing field: {field}")
        
        # Проверяем пользователя
        user = db.query(User).filter(User.id == order_data["user_id"]).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Создаем заказ через внешний сервис
        response = requests.post(f"{EXTERNAL_API_URL}/orders", json=order_data, timeout=10)
        if response.status_code == 201:
            # Сохраняем информацию о заказе в локальной БД
            order = Order(
                user_id=order_data["user_id"],
                total=order_data["total"],
                status="created"
            )
            db.add(order)
            db.commit()
            db.refresh(order)
            
            result = response.json()
            result["local_order_id"] = order.id
            return result
        else:
            raise HTTPException(status_code=response.status_code, detail="Failed to create order")
            
    except requests.RequestException as e:
        logger.error(f"External service error: {e}")
        raise HTTPException(status_code=503, detail="External service unavailable")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating order: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail="Internal server error")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)