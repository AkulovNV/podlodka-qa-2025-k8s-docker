import pytest
import requests
import os
from unittest.mock import Mock, patch
from src.api_client import JSONPlaceholderClient


class TestAPIBasic:
    """Базовые API тесты"""
    
    @pytest.fixture(autouse=True)
    def check_offline_mode(self):
        """Auto-fixture to handle offline mode"""
        if os.environ.get('OFFLINE_MODE', 'false').lower() == 'true':
            pytest.skip("Пропущено: OFFLINE_MODE включен")
    
    def test_get_posts(self, api_client, base_url):
        """Тест получения списка постов"""
        try:
            response = api_client.get(f"{base_url}/posts")
            
            assert response.status_code == 200
            data = response.json()
            assert len(data) > 0
            assert "id" in data[0]
            assert "title" in data[0]
            
        except (requests.exceptions.Timeout, requests.exceptions.ConnectionError):
            pytest.skip(f"API {base_url} недоступен")
    
    def test_get_single_post(self, api_client, base_url):
        """Тест получения одного поста"""
        try:
            post_id = 1
            response = api_client.get(f"{base_url}/posts/{post_id}")
            
            assert response.status_code == 200
            post = response.json()
            assert post["id"] == post_id
            assert "title" in post
            assert "body" in post
            
        except (requests.exceptions.Timeout, requests.exceptions.ConnectionError):
            pytest.skip(f"API {base_url} недоступен")
    
    def test_create_post(self, api_client, base_url):
        """Тест создания поста"""
        try:
            new_post = {
                "title": "QA Test Post",
                "body": "This is a test post from QA automation",
                "userId": 1
            }
            
            response = api_client.post(f"{base_url}/posts", json=new_post)
            
            assert response.status_code == 201
            created_post = response.json()
            assert created_post["title"] == new_post["title"]
            assert created_post["body"] == new_post["body"]
            assert "id" in created_post
            
        except (requests.exceptions.Timeout, requests.exceptions.ConnectionError):
            pytest.skip(f"API {base_url} недоступен")


class TestAPIClientWrapper:
    """Тесты с использованием клиент-обертки"""
    
    @pytest.fixture
    def client(self, base_url):
        return JSONPlaceholderClient(base_url)
    
    def test_client_get_all_posts(self, client):
        """Тест получения всех постов через клиент"""
        try:
            posts = client.get_all_posts()
            assert len(posts) > 0
            assert all("id" in post for post in posts)
        except (requests.exceptions.Timeout, requests.exceptions.ConnectionError):
            pytest.skip("API недоступен")
    
    def test_client_get_user_posts(self, client):
        """Тест получения постов пользователя"""
        try:
            user_id = 1
            posts = client.get_user_posts(user_id)
            assert len(posts) > 0
            assert all(post["userId"] == user_id for post in posts)
        except (requests.exceptions.Timeout, requests.exceptions.ConnectionError):
            pytest.skip("API недоступен")
