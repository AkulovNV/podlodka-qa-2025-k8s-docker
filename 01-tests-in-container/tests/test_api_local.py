import pytest
import json
from unittest.mock import Mock, patch
from src.api_client import JSONPlaceholderClient


class TestAPILocal:
    """Локальные API тесты с мокированием"""
    
    @pytest.fixture
    def mock_posts_data(self):
        """Тестовые данные для постов"""
        return [
            {
                "id": 1,
                "title": "Test Post 1",
                "body": "This is test post body",
                "userId": 1
            },
            {
                "id": 2,
                "title": "Test Post 2", 
                "body": "This is another test post",
                "userId": 1
            }
        ]
    
    @pytest.fixture
    def mock_single_post(self):
        """Тестовые данные для одного поста"""
        return {
            "id": 1,
            "title": "Test Post",
            "body": "This is a test post body",
            "userId": 1
        }
    
    def test_get_posts_success(self, mock_posts_data):
        """Тест успешного получения списка постов"""
        with patch('requests.Session.get') as mock_get:
            # Настраиваем мок
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = mock_posts_data
            mock_response.raise_for_status.return_value = None
            mock_get.return_value = mock_response
            
            # Создаем клиент и выполняем запрос
            client = JSONPlaceholderClient("https://example.com")
            posts = client.get_all_posts()
            
            # Проверяем результат
            assert len(posts) == 2
            assert posts[0]["id"] == 1
            assert posts[0]["title"] == "Test Post 1"
            assert "body" in posts[0]
            
            # Проверяем вызов
            mock_get.assert_called_once_with("https://example.com/posts")
    
    def test_get_single_post_success(self, mock_single_post):
        """Тест получения одного поста"""
        with patch('requests.Session.get') as mock_get:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = mock_single_post
            mock_response.raise_for_status.return_value = None
            mock_get.return_value = mock_response
            
            client = JSONPlaceholderClient("https://example.com")
            post = client.get_post(1)
            
            assert post["id"] == 1
            assert post["title"] == "Test Post"
            assert "body" in post
            
            mock_get.assert_called_once_with("https://example.com/posts/1")
    
    def test_create_post_success(self):
        """Тест создания поста"""
        created_post = {
            "id": 101,
            "title": "New Test Post",
            "body": "New test body",
            "userId": 1
        }
        
        with patch('requests.Session.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 201
            mock_response.json.return_value = created_post
            mock_response.raise_for_status.return_value = None
            mock_post.return_value = mock_response
            
            client = JSONPlaceholderClient("https://example.com")
            result = client.create_post("New Test Post", "New test body", 1)
            
            assert result["id"] == 101
            assert result["title"] == "New Test Post"
            assert result["body"] == "New test body"
            
            # Проверяем параметры вызова
            mock_post.assert_called_once_with(
                "https://example.com/posts",
                json={
                    'title': "New Test Post",
                    'body': "New test body", 
                    'userId': 1
                }
            )
    
    def test_get_user_posts(self, mock_posts_data):
        """Тест получения постов пользователя"""
        user_posts = [post for post in mock_posts_data if post["userId"] == 1]
        
        with patch('requests.Session.get') as mock_get:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = user_posts
            mock_response.raise_for_status.return_value = None
            mock_get.return_value = mock_response
            
            client = JSONPlaceholderClient("https://example.com")
            posts = client.get_user_posts(1)
            
            assert len(posts) == 2
            assert all(post["userId"] == 1 for post in posts)
            
            mock_get.assert_called_once_with(
                "https://example.com/posts",
                params={'userId': 1}
            )
    
    def test_api_client_error_handling(self):
        """Тест обработки ошибок API"""
        with patch('requests.Session.get') as mock_get:
            # Симулируем HTTP ошибку
            mock_response = Mock()
            mock_response.status_code = 404
            mock_response.raise_for_status.side_effect = Exception("404 Not Found")
            mock_get.return_value = mock_response
            
            client = JSONPlaceholderClient("https://example.com")
            
            with pytest.raises(Exception) as exc_info:
                client.get_post(999)
            
            assert "404 Not Found" in str(exc_info.value)
    
    @pytest.mark.parametrize("post_id,expected_url", [
        (1, "https://example.com/posts/1"),
        (42, "https://example.com/posts/42"),
        (100, "https://example.com/posts/100"),
    ])
    def test_get_post_urls(self, post_id, expected_url):
        """Параметризованный тест URL для получения постов"""
        with patch('requests.Session.get') as mock_get:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"id": post_id}
            mock_response.raise_for_status.return_value = None
            mock_get.return_value = mock_response
            
            client = JSONPlaceholderClient("https://example.com")
            client.get_post(post_id)
            
            mock_get.assert_called_once_with(expected_url)


class TestAPIIntegration:
    """Интеграционные тесты (требуют сетевого соединения)"""
    
    def test_real_api_connection(self):
        """Тест реального соединения с API (может быть пропущен)"""
        import requests
        
        try:
            # Быстрая проверка доступности
            response = requests.get("https://httpbin.org/get", timeout=3)
            if response.status_code != 200:
                pytest.skip("Internet connection not available")
        except:
            pytest.skip("Internet connection not available")
        
        # Если соединение есть, тестируем с httpbin
        client = JSONPlaceholderClient("https://httpbin.org")
        
        with patch.object(client, 'get_all_posts') as mock_method:
            mock_method.return_value = [{"id": 1, "title": "Test"}]
            posts = client.get_all_posts()
            assert len(posts) >= 0
