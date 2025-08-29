#!/bin/bash
echo "🏃 Локальный запуск Sample App"
echo "============================="

# Проверяем Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 не найден"
    exit 1
fi

# Устанавливаем зависимости
echo "📦 Установка зависимостей..."
pip3 install -r requirements.txt

# Запускаем приложение
echo "🚀 Запуск приложения..."
export FLASK_ENV=development
python3 app.py
