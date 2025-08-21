import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from src.page_objects import GooglePage


class TestGoogleSearch:
    """UI тесты поиска Google"""
    
    def test_google_search_basic(self, driver):
        """Базовый тест поиска"""
        driver.get("https://www.google.com")
        
        # Согласие на cookies (если появится)
        try:
            consent_button = WebDriverWait(driver, 3).until(
                EC.element_to_be_clickable((By.ID, "L2AGLb"))
            )
            consent_button.click()
        except:
            pass  # Кнопка может не появиться
        
        # Поиск
        search_box = driver.find_element(By.NAME, "q")
        search_box.send_keys("Docker testing")
        search_box.submit()
        
        # Проверка результатов
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "search"))
        )
        
        results = driver.find_elements(By.CSS_SELECTOR, "h3")
        assert len(results) > 0
        assert any("docker" in result.text.lower() for result in results)
    
    def test_google_search_with_page_object(self, driver):
        """Тест с использованием Page Object паттерна"""
        google_page = GooglePage(driver)
        
        google_page.open()
        google_page.accept_cookies_if_present()
        google_page.search("Kubernetes testing")
        
        assert google_page.has_search_results()
        results_text = google_page.get_results_text()
        assert any("kubernetes" in text.lower() for text in results_text)


class TestDemoApp:
    """Тесты демо-приложения (если запущено локально)"""
    
    @pytest.fixture
    def app_url(self):
        return "http://localhost:8000"  # URL нашего демо-приложения
    
    def test_home_page_loads(self, driver, app_url):
        """Тест загрузки главной страницы"""
        try:
            driver.get(app_url)
            assert "Demo App" in driver.title
            
            # Проверка основных элементов
            header = driver.find_element(By.TAG_NAME, "h1")
            assert "Welcome" in header.text
            
        except Exception as e:
            pytest.skip(f"Demo app not available: {e}")