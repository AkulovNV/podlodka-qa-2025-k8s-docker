#!/bin/bash

echo "🔍 Отладка Docker контейнера для тестов..."
echo "=========================================="

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

IMAGE_NAME="qa-tests"

# Проверяем наличие образа
if ! docker images $IMAGE_NAME --format '{{.Repository}}' | grep -q "$IMAGE_NAME"; then
    echo -e "${YELLOW}⚠️  Образ $IMAGE_NAME не найден, собираем...${NC}"
    docker build -t $IMAGE_NAME .
fi

echo "🐳 Доступные опции отладки:"
echo "1. Интерактивный bash в контейнере"
echo "2. Проверка установленных пакетов"
echo "3. Запуск одного теста"
echo "4. Просмотр структуры файлов"
echo "5. Проверка переменных окружения"

read -p "Выберите опцию (1-5): " choice

case $choice in
    1)
        log_info "Запуск интерактивного bash..."
        docker run -it --rm \
            -v "$(pwd):/workspace" \
            -w /app \
            $IMAGE_NAME bash
        ;;
    2)
        log_info "Проверка установленных Python пакетов..."
        docker run --rm $IMAGE_NAME pip list
        ;;
    3)
        echo "Доступные тесты:"
        find tests -name "*.py" -type f | grep -E "test_.*\.py$"
        read -p "Введите имя файла теста (например: tests/test_api.py): " test_file
        
        log_info "Запуск теста: $test_file"
        docker run --rm \
            -v "$(pwd)/reports:/app/reports" \
            $IMAGE_NAME \
            python -m pytest "$test_file" -v -s
        ;;
    4)
        log_info "Структура файлов в контейнере..."
        docker run --rm $IMAGE_NAME find /app -type f -name "*.py" | head -20
        ;;
    5)
        log_info "Переменные окружения в контейнере..."
        docker run --rm $IMAGE_NAME env | sort
        ;;
    *)
        echo "Неверная опция"
        exit 1
        ;;
esac

log_success "Отладка завершена"
