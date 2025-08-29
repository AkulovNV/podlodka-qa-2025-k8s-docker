from models import SessionLocal, create_tables
from sqlalchemy import text
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def init_database():
    """Инициализация базы данных"""
    max_retries = 30
    retry_interval = 2
    
    for attempt in range(max_retries):
        try:
            logger.info(f"Попытка подключения к БД: {attempt + 1}/{max_retries}")
            
            # Пробуем создать сессию
            db = SessionLocal()
            db.execute(text("SELECT 1"))
            db.close()
            
            # Создаем таблицы
            create_tables()
            logger.info("База данных инициализирована успешно!")
            return True
            
        except Exception as e:
            logger.error(f"Ошибка подключения к БД: {e}")
            if attempt < max_retries - 1:
                logger.info(f"Повтор через {retry_interval} секунд...")
                time.sleep(retry_interval)
            else:
                logger.error("Не удалось подключиться к базе данных!")
                return False
    
    return False


if __name__ == "__main__":
    init_database()
