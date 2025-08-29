FROM python:3.11-slim@sha256:1d6131b5d479888b43200645e03a78443c7157efbdb730e6b48129740727c312

# Устанавливаем переменные окружения
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Установка только необходимых системных зависимостей
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Рабочая директория
WORKDIR /app

# Копирование зависимостей
COPY requirements.txt .

# Обновленный requirements.txt с webdriver-manager
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    pytest==7.4.3 \
    selenium==4.15.2 \
    requests==2.31.0 \
    webdriver-manager==4.0.1 \
    pytest-html==4.1.1 \
    pytest-xdist==3.3.1 \
    allure-pytest==2.13.2

# Копирование исходного кода
COPY . .

# Создание директории для отчетов
RUN mkdir -p /app/reports

# Копируем и делаем исполняемым entrypoint скрипт
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Устанавливаем entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Команда по умолчанию (можно переопределить при запуске)
CMD ["all"]

# Добавляем метки
LABEL workshop=qa-devops \
      component=tests \
      version=simple