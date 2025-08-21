import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import requests


@pytest.fixture(scope="session")
def chrome_options():
    """Настройки для Chrome в контейнере"""
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--remote-debugging-port=9222")
    options.add_argument("--window-size=1920,1080")
    return options


@pytest.fixture(scope="function")
def driver(chrome_options):
    """WebDriver для UI тестов"""
    driver = webdriver.Chrome(options=chrome_options)
    driver.implicitly_wait(10)
    yield driver
    driver.quit()


@pytest.fixture(scope="session")
def api_client():
    """HTTP клиент для API тестов"""
    session = requests.Session()
    session.headers.update({'User-Agent': 'QA-Tests/1.0'})
    yield session
    session.close()


@pytest.fixture(scope="session")
def base_url():
    """Базовый URL для тестов"""
    return "https://jsonplaceholder.typicode.com"