"""Простые тесты для проверки микросервисной среды"""

import pytest
import requests
import time


def test_mock_server_health():
    """Проверка health check mock сервера"""
    response = requests.get("http://mock-server:8001/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"


def test_app_health():
    """Проверка health check основного приложения"""
    response = requests.get("http://app:8000/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"


def test_app_ready():
    """Проверка готовности приложения"""
    # Ждем, пока приложение будет готово
    max_attempts = 30
    for attempt in range(max_attempts):
        try:
            response = requests.get("http://app:8000/ready")
            if response.status_code == 200:
                break
        except requests.RequestException:
            pass
        time.sleep(1)
    else:
        pytest.fail("App не готов после 30 секунд ожидания")
    
    data = response.json()
    assert data["status"] == "ready"


def test_create_and_get_user():
    """Тест создания и получения пользователя"""
    # Создаем пользователя
    user_data = {
        "name": "Simple Test User",
        "email": "simple-test@example.com"
    }
    
    response = requests.post("http://app:8000/users", json=user_data)
    assert response.status_code == 200
    
    created_user = response.json()
    assert created_user["name"] == "Simple Test User"
    assert created_user["email"] == "simple-test@example.com"
    assert "id" in created_user
    
    # Получаем всех пользователей
    response = requests.get("http://app:8000/users")
    assert response.status_code == 200
    
    users = response.json()
    assert len(users) >= 1
    assert any(user["email"] == "simple-test@example.com" for user in users)


def test_mock_orders():
    """Тест получения заказов из mock сервиса"""
    response = requests.get("http://mock-server:8001/orders/1")
    assert response.status_code == 200
    
    data = response.json()
    assert "orders" in data
    assert len(data["orders"]) > 0
