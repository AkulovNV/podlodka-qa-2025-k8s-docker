import requests
from typing import List, Dict, Optional


class JSONPlaceholderClient:
    """Клиент для работы с JSONPlaceholder API"""
    
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'User-Agent': 'QA-APIClient/1.0'
        })
    
    def get_all_posts(self) -> List[Dict]:
        """Получить все посты"""
        response = self.session.get(f"{self.base_url}/posts")
        response.raise_for_status()
        return response.json()
    
    def get_post(self, post_id: int) -> Dict:
        """Получить пост по ID"""
        response = self.session.get(f"{self.base_url}/posts/{post_id}")
        response.raise_for_status()
        return response.json()
    
    def get_user_posts(self, user_id: int) -> List[Dict]:
        """Получить посты пользователя"""
        response = self.session.get(
            f"{self.base_url}/posts",
            params={'userId': user_id}
        )
        response.raise_for_status()
        return response.json()
    
    def create_post(self, title: str, body: str, user_id: int) -> Dict:
        """Создать новый пост"""
        post_data = {
            'title': title,
            'body': body,
            'userId': user_id
        }
        response = self.session.post(f"{self.base_url}/posts", json=post_data)
        response.raise_for_status()
        return response.json()
    
    def update_post(self, post_id: int, title: str = None, body: str = None) -> Dict:
        """Обновить пост"""
        # Сначала получаем текущий пост
        current_post = self.get_post(post_id)
        
        # Обновляем только указанные поля
        if title:
            current_post['title'] = title
        if body:
            current_post['body'] = body
        
        response = self.session.put(f"{self.base_url}/posts/{post_id}", json=current_post)
        response.raise_for_status()
        return response.json()
    
    def delete_post(self, post_id: int) -> bool:
        """Удалить пост"""
        response = self.session.delete(f"{self.base_url}/posts/{post_id}")
        response.raise_for_status()
        return response.status_code == 200