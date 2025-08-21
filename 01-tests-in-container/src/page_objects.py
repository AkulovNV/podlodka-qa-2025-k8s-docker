from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from typing import List


class BasePage:
    """Базовый класс для всех страниц"""
    
    def __init__(self, driver):
        self.driver = driver
        self.wait = WebDriverWait(driver, 10)
    
    def find_element(self, locator):
        """Найти элемент с ожиданием"""
        return self.wait.until(EC.presence_of_element_located(locator))
    
    def find_elements(self, locator):
        """Найти элементы"""
        return self.driver.find_elements(*locator)
    
    def click_element(self, locator):
        """Кликнуть по элементу с ожиданием кликабельности"""
        element = self.wait.until(EC.element_to_be_clickable(locator))
        element.click()
        return element


class GooglePage(BasePage):
    """Page Object для Google Search"""
    
    # Локаторы
    SEARCH_BOX = (By.NAME, "q")
    SEARCH_BUTTON = (By.NAME, "btnK")
    RESULTS_CONTAINER = (By.ID, "search")
    RESULT_TITLES = (By.CSS_SELECTOR, "h3")
    CONSENT_BUTTON = (By.ID, "L2AGLb")
    
    def __init__(self, driver):
        super().__init__(driver)
        self.url = "https://www.google.com"
    
    def open(self):
        """Открыть страницу Google"""
        self.driver.get(self.url)
        return self
    
    def accept_cookies_if_present(self):
        """Принять cookies если диалог появился"""
        try:
            self.wait = WebDriverWait(self.driver, 3)  # Короткое ожидание
            self.click_element(self.CONSENT_BUTTON)
        except TimeoutException:
            pass  # Диалог может не появиться
        finally:
            self.wait = WebDriverWait(self.driver, 10)  # Восстанавливаем обычное ожидание
    
    def search(self, query: str):
        """Выполнить поиск"""
        search_box = self.find_element(self.SEARCH_BOX)
        search_box.clear()
        search_box.send_keys(query)
        search_box.submit()
        return self
    
    def has_search_results(self) -> bool:
        """Проверить наличие результатов поиска"""
        try:
            self.find_element(self.RESULTS_CONTAINER)
            return True
        except TimeoutException:
            return False
    
    def get_results_text(self) -> List[str]:
        """Получить текст заголовков результатов"""
        if not self.has_search_results():
            return []
        
        title_elements = self.find_elements(self.RESULT_TITLES)
        return [element.text for element in title_elements if element.text]


class DemoAppPage(BasePage):
    """Page Object для демо-приложения"""
    
    # Локаторы
    HEADER = (By.TAG_NAME, "h1")
    NAVIGATION = (By.CSS_SELECTOR, "nav ul")
    CONTENT = (By.ID, "content")
    
    def __init__(self, driver, base_url: str = "http://localhost:8000"):
        super().__init__(driver)
        self.base_url = base_url
    
    def open(self):
        """Открыть главную страницу"""
        self.driver.get(self.base_url)
        return self
    
    def get_header_text(self) -> str:
        """Получить текст заголовка"""
        header = self.find_element(self.HEADER)
        return header.text
    
    def has_navigation(self) -> bool:
        """Проверить наличие навигации"""
        try:
            self.find_element(self.NAVIGATION)
            return True
        except TimeoutException:
            return False
