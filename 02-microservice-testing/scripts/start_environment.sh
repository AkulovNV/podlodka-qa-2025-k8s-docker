#!/bin/bash
# ===========================================
# Файл: 02-microservice-testing/scripts/start_environment.sh
# ===========================================

set -e

echo "🚀 Запуск микросервисного окружения..."
echo "===================================="

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

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Проверяем наличие docker-compose
if ! command -v docker-compose &> /dev/null; then
    log_error "docker-compose не найден. Установите docker-compose."
    exit 1
fi

# Проверяем, что мы в правильной директории
if [[ ! -f "docker-compose.yml" ]]; then
    log_error "docker-compose.yml не найден. Запускайте из директории 02-microservice-testing/"
    exit 1
fi

# Создаем необходимые директории
mkdir -p {logs,reports}
log_info "Созданы директории logs/ и reports/"

log_info "Проверка конфигурации docker-compose..."
docker-compose config > /dev/null || {
    log_error "Ошибка в конфигурации docker-compose.yml"
    exit 1
}

log_info "Остановка существующих сервисов..."
docker-compose down --remove-orphans

log_info "Сборка и запуск сервисов..."
docker-compose up -d --build

# Ждем запуска сервисов
log_info "Ожидание запуска сервисов..."

# Функция проверки готовности сервиса
wait_for_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            log_success "$service_name готов"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    log_error "$service_name не запустился за $((max_attempts * 2)) секунд"
    return 1
}

# Проверяем готовность сервисов
echo -n "Проверка базы данных"
for i in {1..15}; do
    if docker-compose exec -T db pg_isready -U user -d testdb > /dev/null 2>&1; then
        echo
        log_success "База данных готова"
        break
    fi
    echo -n "."
    sleep 2
done

echo -n "Проверка mock-сервера"
wait_for_service "Mock-сервер" "http://localhost:8001/health"

echo -n "Проверка приложения" 
wait_for_service "Приложение" "http://localhost:8000/health"

# Показываем статус сервисов
echo ""
log_info "Статус сервисов:"
docker-compose ps

# Проверяем доступность эндпоинтов
echo ""
log_info "Проверка эндпоинтов:"

# Health checks
echo -n "App health: "
if curl -s http://localhost:8000/health | jq -r '.status' 2>/dev/null; then
    log_success "OK"
else
    log_error "FAIL"
fi

echo -n "Mock health: "
if curl -s http://localhost:8001/health | jq -r '.status' 2>/dev/null; then
    log_success "OK"  
else
    log_error "FAIL"
fi

echo -n "App readiness: "
if curl -s http://localhost:8000/ready > /dev/null 2>&1; then
    log_success "OK"
else
    log_warning "Not ready yet"
fi

# Показываем полезную информацию
echo ""
echo "🎉 Окружение запущено!"
echo "===================="
echo -e "${GREEN}Доступные сервисы:${NC}"
echo "• Приложение:  http://localhost:8000"
echo "• Mock-сервер: http://localhost:8001"
echo "• База данных: localhost:5432"
echo ""
echo -e "${BLUE}Полезные команды:${NC}"
echo "• docker-compose logs -f               # просмотр логов"
echo "• docker-compose ps                    # статус сервисов"
echo "• curl http://localhost:8000/health    # проверка приложения"
echo "• ./scripts/run_tests.sh               # запуск тестов"
echo "• ./scripts/cleanup.sh                 # остановка и очистка"
echo ""
echo -e "${BLUE}API эндпоинты:${NC}"
echo "• GET  /health                         # health check"
echo "• GET  /ready                          # readiness check"  
echo "• GET  /users                          # список пользователей"
echo "• POST /users                          # создание пользователя"
echo "• GET  /users/{id}/orders              # заказы пользователя"
echo "• POST /orders                         # создание заказа"
