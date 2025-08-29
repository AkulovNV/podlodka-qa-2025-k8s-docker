import pytest
import os
import sys
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
import requests


def get_chrome_options():
    """Настройки Chrome для контейнера и локального запуска"""
    options = Options()
    
    # Базовые опции для headless режима
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--disable-extensions")
    options.add_argument("--disable-plugins")
    options.add_argument("--disable-images")
    options.add_argument("--disable-javascript")  # для простых тестов
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--remote-debugging-port=9222")
    
    # Дополнительные опции для контейнеров
    if os.environ.get('CI') or os.environ.get('DOCKER'):
        options.add_argument("--disable-background-timer-throttling")
        options.add_argument("--disable-backgrounding-occluded-windows")
        options.add_argument("--disable-renderer-backgrounding")
        options.add_argument("--disable-features=TranslateUI")
        options.add_argument("--disable-ipc-flooding-protection")
    
    return options


def get_chrome_driver_service():
    """Получить сервис ChromeDriver с автоматическим определением пути"""
    service = None
    
    # Попробуем разные способы получения ChromeDriver
    driver_paths = [
        '/usr/local/bin/chromedriver',  # Установлен вручную
        '/usr/bin/chromedriver',        # Через пакетный менеджер
        'chromedriver'                   # В PATH
    ]
    
    for path in driver_paths:
        try:
            service = Service(executable_path=path)
            # Проверяем, что драйвер доступен
            if os.path.exists(path) or path == 'chromedriver':
                return service
        except Exception:
            continue
    
    # Если ничего не найдено, используем webdriver-manager
    try:
        from webdriver_manager.chrome import ChromeDriverManager
        from selenium.webdriver.chrome.service import Service
        
        driver_path = ChromeDriverManager().install()
        service = Service(executable_path=driver_path)
        return service
    except ImportError:
        print("webdriver-manager не установлен, попробуйте: pip install webdriver-manager")
        return None
    except Exception as e:
        print(f"Ошибка при получении ChromeDriver: {e}")
        return None


@pytest.fixture(scope="session")
def chrome_options():
    """Настройки для Chrome"""
    return get_chrome_options()


@pytest.fixture(scope="function")
def driver(chrome_options):
    """WebDriver для UI тестов с улучшенной обработкой ошибок"""
    driver = None
    
    try:
        # Сначала пробуем с сервисом
        service = get_chrome_driver_service()
        
        if service:
            driver = webdriver.Chrome(service=service, options=chrome_options)
        else:
            # Fallback - без явного сервиса
            driver = webdriver.Chrome(options=chrome_options)
        
        driver.implicitly_wait(10)
        
        # Проверяем, что драйвер работает
        driver.get("about:blank")
        
        yield driver
        
    except Exception as e:
        pytest.skip(f"Chrome WebDriver недоступен: {e}")
    
    finally:
        if driver:
            try:
                driver.quit()
            except Exception:
                pass


@pytest.fixture(scope="function")
def headless_driver(chrome_options):
    """Гарантированно headless драйвер (без UI)"""
    # Убеждаемся, что headless включен
    if "--headless" not in chrome_options.arguments:
        chrome_options.add_argument("--headless")
    
    driver = None
    try:
        service = get_chrome_driver_service()
        if service:
            driver = webdriver.Chrome(service=service, options=chrome_options)
        else:
            driver = webdriver.Chrome(options=chrome_options)
            
        driver.implicitly_wait(5)
        yield driver
    except Exception as e:
        pytest.skip(f"Headless Chrome недоступен: {e}")
    finally:
        if driver:
            try:
                driver.quit()
            except Exception:
                pass


@pytest.fixture(scope="session")
def api_client():
    """HTTP клиент для API тестов"""
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'QA-Tests/1.0',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
    })
    
    # Настройка коротких таймаутов для тестов
    session.timeout = (5, 10)  # (connect timeout, read timeout)
    
    yield session
    session.close()


@pytest.fixture(scope="session")
def base_url():
    """Базовый URL для тестов"""
    # Можно переопределить через переменную окружения
    default_url = 'https://jsonplaceholder.typicode.com'
    fallback_url = 'https://httpbin.org'  # Fallback for testing
    
    url = os.environ.get('BASE_URL', default_url)
    
    # Test if the URL is reachable
    try:
        response = requests.get(url + '/posts' if 'jsonplaceholder' in url else url + '/get', timeout=5)
        if response.status_code == 200:
            return url
    except:
        pass
    
    # If default fails, skip tests or use fallback
    pytest.skip(f"API endpoint {url} is not reachable")


@pytest.fixture(scope="session")
def test_environment():
    """Информация о тестовом окружении"""
    return {
        'ci': os.environ.get('CI', False),
        'docker': os.environ.get('DOCKER', False),
        'test_env': os.environ.get('TEST_ENV', 'local'),
        'headless': True if os.environ.get('CI') or os.environ.get('DOCKER') else False
    }


# Хуки pytest для улучшенного вывода
def pytest_configure(config):
    """Конфигурация pytest"""
    # Добавляем маркеры
    config.addinivalue_line("markers", "slow: marks tests as slow")
    config.addinivalue_line("markers", "ui: marks tests as UI tests")
    config.addinivalue_line("markers", "api: marks tests as API tests")
    config.addinivalue_line("markers", "smoke: marks tests as smoke tests")


def pytest_collection_modifyitems(config, items):
    """Модификация собранных тестов"""
    # Автоматически добавляем маркеры based на имени файла
    for item in items:
        if "test_ui" in item.nodeid:
            item.add_marker(pytest.mark.ui)
        elif "test_api" in item.nodeid:
            item.add_marker(pytest.mark.api)


def pytest_runtest_setup(item):
    """Настройка перед каждым тестом"""
    # Пропускаем UI тесты если нет поддержки Chrome
    if "ui" in item.keywords:
        try:
            options = get_chrome_options()
            service = get_chrome_driver_service()
            
            # Быстрая проверка доступности Chrome
            test_driver = webdriver.Chrome(service=service, options=options)
            test_driver.quit()
            
        except Exception as e:
            pytest.skip(f"UI тесты пропущены: Chrome недоступен ({e})")


# Фикстура для отладки
@pytest.fixture
def debug_info(test_environment):
    """Отладочная информация"""
    def _debug():
        print("\n=== Debug Info ===")
        print(f"Environment: {test_environment}")
        print(f"Python version: {sys.version}")
        print(f"Working directory: {os.getcwd()}")
        print(f"Environment variables:")
        for key in ['CI', 'DOCKER', 'TEST_ENV', 'SELENIUM_HUB']:
            print(f"  {key}: {os.environ.get(key, 'not set')}")
        print("==================")
    
    return _debug