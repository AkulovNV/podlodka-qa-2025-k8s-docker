#!/bin/bash
echo "🐳 Docker запуск Sample App"
echo "=========================="

# Проверяем Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не найден"
    exit 1
fi

echo "🔨 Сборка Docker образа..."
docker build -t sample-app .

echo "🚀 Запуск контейнера..."
docker run --rm \
    -p 5050:5050 \
    --name sample-app-container \
    sample-app

echo "✅ Приложение доступно на http://localhost:5050"
