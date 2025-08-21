import pytest
import requests
import time
from typing import Dict


class TestMicroserviceAPI:
    """Тесты основного функционала микросервиса"""
    
    @pytest.fixture(scope="class")
    def app_url(self):
        return "http://app:8000"  # URL из docker-compose
    
    @pytest.fixture(scope="class") 
    def test_user(self, app_url):
        """Создать тестового пользователя"""
        user_data = {
            "name": "Test User",
            "email": "test@example.com"
        }
        
        response = requests.post(f"{app_url}/users", json=user_data)
        assert response.status_code == 200
        
        return response.json()
    
    def test_health_check(self, app_url):
        """Тест health check эндпоинта"""
        response = requests.get(f"{app_url}/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "qa-demo-microservice"
    
    def test_readiness_check(self, app_url):
        """Тест readiness check эндпоинта"""
        # Ждем, пока сервис будет готов
        for _ in range(30):  # 30 секунд максимум
            try:
                response = requests.get(f"{app_url}/ready")
                if response.status_code == 200:
                    break
            except requests.RequestException:
                pass
            time.sleep(1)
        
        response = requests.get(f"{app_url}/ready")
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "ready"
        assert data["database"] == "connected"
    
    def test_create_user(self, app_url):
        """Тест создания пользователя"""
        user_data = {
            "name": "John Doe",
            "email": "john@example.com"
        }
        
        response = requests.post(f"{app_url}/users", json=user_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == user_data["name"]
        assert data["email"] == user_data["email"]
        assert "id" in data
    
    def test_get_users(self, app_url, test_user):
        """Тест получения списка пользователей"""
        response = requests.get(f"{app_url}/users")
        
        assert response.status_code == 200
        users = response.json()
        assert len(users) > 0
        
        # Проверяем, что наш тестовый пользователь в списке
        user_ids = [user["id"] for user in users]
        assert test_user["id"] in user_ids
    
    def test_get_user_orders_empty(self, app_url, test_user):
        """Тест получения заказов пользователя (пустой список)"""
        user_id = test_user["id"]
        response = requests.get(f"{app_url}/users/{user_id}/orders")
        
        assert response.status_code == 200
        data = response.json()
        assert "orders" in data
        # Для нового пользователя заказов быть не должно
        assert data["orders"] == []
    
    def test_get_user_orders_not_found(self, app_url):
        """Тест получения заказов несуществующего пользователя"""
        response = requests.get(f"{app_url}/users/99999/orders")
        assert response.status_code == 404


class TestOrdersIntegration:
    """Интеграционные тесты с внешними сервисами"""
    
    @pytest.fixture(scope="class")
    def app_url(self):
        return "http://app:8000"
    
    @pytest.fixture(scope="class")
    def mock_url(self):
        return "http://mock-server:8001"
    
    def test_mock_server_health(self, mock_url):
        """Проверить работу mock-сервера"""
        response = requests.get(f"{mock_url}/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"
    
    def test_create_order_integration(self, app_url, mock_url):
        """Интеграционный тест создания заказа"""
        # Сначала создаем пользователя
        user_data = {"name": "Order User", "email": "order@example.com"}
        user_response = requests.post(f"{app_url}/users", json=user_data)
        user = user_response.json()
        
        # Создаем заказ
        order_data = {
            "user_id": user["id"],
            "items": [{"product": "Test Product", "quantity": 1, "price": 10.99}],
            "total": 10.99
        }
        
        response = requests.post(f"{app_url}/orders", json=order_data)
        
        assert response.status_code == 201
        order = response.json()
        assert order["user_id"] == user["id"]
        assert order["total"] == 10.99
        assert order["status"] == "created"


class TestErrorHandling:
    """Тесты обработки ошибок"""
    
    @pytest.fixture(scope="class")
    def app_url(self):
        return "http://app:8000"
    
    def test_create_user_missing_fields(self, app_url):
        """Тест создания пользователя с отсутствующими полями"""
        incomplete_data = {"name": "Only Name"}
        
        response = requests.post(f"{app_url}/users", json=incomplete_data)
        # В зависимости от валидации, может быть 400 или 422
        assert response.status_code in [400, 422]
    
    def test_orders_for_nonexistent_user(self, app_url):
        """Тест заказов для несуществующего пользователя"""
        response = requests.get(f"{app_url}/users/999999/orders")
        assert response.status_code == 404
    
    def test_create_order_invalid_user(self, app_url):
        """Тест создания заказа для несуществующего пользователя"""
        order_data = {
            "user_id": 999999,
            "items": [{"product": "Test", "quantity": 1, "price": 10}],
            "total": 10
        }
        
        response = requests.post(f"{app_url}/orders", json=order_data)
        assert response.status_code == 404