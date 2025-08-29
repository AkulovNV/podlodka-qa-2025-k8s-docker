# ===========================================
# Файл: 02-microservice-testing/scripts/run_tests.sh
# ===========================================

#!/bin/bash
set -e

echo "🧪 Запуск интеграционных тестов..."
echo "================================="

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

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверяем, что сервисы запущены
if ! docker-compose ps | grep -q "Up"; then
    log_error "Сервисы не запущены. Запустите: ./scripts/start_environment.sh"
    exit 1
fi

# Проверяем готовность сервисов
log_info "Проверка готовности сервисов..."

check_service() {
    local url=$1
    local name=$2
    
    if curl -s -f "$url" > /dev/null; then
        log_success "$name готов"
        return 0
    else
        log_error "$name не готов"
        return 1
    fi
}

check_service "http://localhost:8000/health" "Приложение"
check_service "http://localhost:8001/health" "Mock-сервер"

# Создаем директорию для отчетов
mkdir -p reports
log_info "Создана директория reports/"

log_info "Запуск тестов через docker-compose..."

# Запускаем тесты в отдельном контейнере
docker-compose run --rm \
    -e PYTHONPATH=/app \
    tests \
    python -m pytest /app/tests \
        -v \
        --tb=short \
        --html=/app/reports/integration-report.html \
        --self-contained-html \
        --junit-xml=/app/reports/integration-junit.xml \
        --maxfail=5 \
        -p no:warnings || {
    
    log_error "Тесты завершились с ошибками"
    
    # Показываем логи сервисов для отладки
    echo ""
    echo "📋 Логи сервисов для анализа:"
    echo "=============================="
    
    echo "🔍 Логи приложения (последние 10 строк):"
    docker-compose logs --tail 10 app || true
    
    echo ""
    echo "🔍 Логи mock-сервера (последние 10 строк):"
    docker-compose logs --tail 10 mock-server || true
    
    echo ""
    echo "🔍 Логи базы данных (последние 5 строк):"
    docker-compose logs --tail 5 db || true
    
    exit 1
}

log_success "Все тесты прошли успешно!"

# Копируем отчеты
if docker-compose ps tests &>/dev/null; then
    docker-compose cp tests:/app/reports ./reports/ 2>/dev/null || true
fi

# Показываем созданные отчеты
echo ""
echo "📊 Созданные отчеты:"
if [[ -f "reports/integration-report.html" ]]; then
    log_success "HTML отчет: $(pwd)/reports/integration-report.html"
    echo "   Откройте в браузере: open reports/integration-report.html"
fi

if [[ -f "reports/integration-junit.xml" ]]; then
    log_success "JUnit XML: $(pwd)/reports/integration-junit.xml"
fi

echo ""
echo "🎉 Тестирование завершено!"
echo "========================="
echo -e "${GREEN}Что было протестировано:${NC}"
echo "✅ Health check эндпоинты"
echo "✅ Создание и получение пользователей" 
echo "✅ Интеграция с mock-сервисами"
echo "✅ Работа с базой данных"
echo "✅ Обработка ошибок"