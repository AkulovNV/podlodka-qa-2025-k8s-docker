#!/bin/bash

set -e

echo "🧪 Запуск тестов локально (без Docker)..."
echo "========================================="

# Цвета для вывода
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

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверяем, что мы в правильной директории
if [[ ! -f "Dockerfile" ]] || [[ ! -d "tests" ]]; then
    log_error "Скрипт должен запускаться из директории 01-tests-in-container/"
    exit 1
fi

log_info "Проверка Python окружения..."

# Проверяем Python
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 не найден"
    exit 1
fi

# Проверяем зависимости
log_info "Проверка зависимостей..."
if [[ -f "requirements.txt" ]]; then
    pip install -r requirements.txt
    log_success "Зависимости установлены"
fi

# Создаем директорию для отчетов
mkdir -p reports
log_info "Создана директория reports/"

# Настройка переменных окружения
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
export TEST_ENV="local"

log_info "Запуск тестов..."

# Базовый запуск pytest
python3 -m pytest tests/ \
    -v \
    --tb=short \
    --html=reports/report.html \
    --self-contained-html \
    --junit-xml=reports/junit.xml \
    || {
        log_error "Тесты завершились с ошибками"
        echo "📊 Отчеты сохранены в reports/"
        exit 1
    }

log_success "Тесты завершены успешно!"

# Проверяем наличие отчетов
if [[ -f "reports/report.html" ]]; then
    log_success "HTML отчет: $(pwd)/reports/report.html"
fi

if [[ -f "reports/junit.xml" ]]; then
    log_success "JUnit отчет: $(pwd)/reports/junit.xml"
fi

echo ""
echo "🎉 Готово!"
echo "============"
echo "📊 Откройте отчет: open reports/report.html"