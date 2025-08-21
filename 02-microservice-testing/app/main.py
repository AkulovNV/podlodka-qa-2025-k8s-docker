from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.orm import Session
import requests
import os
from models import SessionLocal, User, Order
from typing import List


app = FastAPI(title="QA Demo Microservice", version="1.0.0")

# Конфигурация
EXTERNAL_API_URL = os.getenv("EXTERNAL_API_URL", "http://localhost:8001")


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
        db.execute("SELECT 1")
        
        # Проверяем внешний сервис
        response = requests.get(f"{EXTERNAL_API_URL}/health", timeout=5)
        external_healthy = response.status_code == 200
        
        return {
            "status": "ready",
            "database": "connected",
            "external_service": "connected" if external_healthy else "disconnected"
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service not ready: {str(e)}")


@app.get("/users", response_model=List[dict])
def get_users(db: Session = Depends(get_db)):
    """Получить список пользователей"""
    users = db.query(User).all()
    return [{"id": user.id, "name": user.name, "email": user.email} for user in users]


@app.post("/users", response_model=dict)
def create_user(user_data: dict, db: Session = Depends(get_db)):
    """Создать пользователя"""
    user = User(name=user_data["name"], email=user_data["email"])
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"id": user.id, "name": user.name, "email": user.email}


@app.get("/users/{user_id}/orders")
def get_user_orders(user_id: int, db: Session = Depends(get_db)):
    """Получить заказы пользователя"""
    # Проверяем существование пользователя
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Получаем заказы из внешнего сервиса
    try:
        response = requests.get(f"{EXTERNAL_API_URL}/orders/{user_id}", timeout=10)
        if response.status_code == 200:
            return response.json()
        else:
            raise HTTPException(status_code=response.status_code, detail="External service error")
    except requests.RequestException as e:
        raise HTTPException(status_code=503, detail=f"External service unavailable: {str(e)}")


@app.post("/orders")
def create_order(order_data: dict, db: Session = Depends(get_db)):
    """Создать заказ"""
    # Проверяем пользователя
    user = db.query(User).filter(User.id == order_data["user_id"]).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Создаем заказ через внешний сервис
    try:
        response = requests.post(f"{EXTERNAL_API_URL}/orders", json=order_data, timeout=10)
        if response.status_code == 201:
            return response.json()
        else:
            raise HTTPException(status_code=response.status_code, detail="Failed to create order")
    except requests.RequestException as e:
        raise HTTPException(status_code=503, detail=f"External service unavailable: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
