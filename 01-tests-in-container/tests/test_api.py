import pytest
import requests
from src.api_client import JSONPlaceholderClient


class TestAPIBasic:
    """Базовые API тесты"""
    
    def test_get_posts(self, api_client, base_url):
        """Тест получения списка постов"""
        response = api_client.get(f"{base_url}/posts")
        
        assert response.status_code == 200
        assert len(response.json()) > 0
        assert "id" in response.json()[0]
        assert "title" in response.json()[0]
    
    def test_get_single_post(self, api_client, base_url):
        """Тест получения одного поста"""
        post_id = 1
        response = api_client.get(f"{base_url}/posts/{post_id}")
        
        assert response.status_code == 200
        post = response.json()
        assert post["id"] == post_id
        assert "title" in post
        assert "body" in post
    
    def test_create_post(self, api_client, base_url):
        """Тест создания поста"""
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


class TestAPIClientWrapper:
    """Тесты с использованием клиент-обертки"""
    
    @pytest.fixture
    def client(self, base_url):
        return JSONPlaceholderClient(base_url)
    
    def test_client_get_all_posts(self, client):
        """Тест получения всех постов через клиент"""
        posts = client.get_all_posts()
        assert len(posts) > 0
        assert all("id" in post for post in posts)
    
    def test_client_get_user_posts(self, client):
        """Тест получения постов пользователя"""
        user_id = 1
        posts = client.get_user_posts(user_id)
        assert len(posts) > 0
        assert all(post["userId"] == user_id for post in posts)
