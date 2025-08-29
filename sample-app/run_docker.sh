#!/bin/bash
set -e

echo "🚀 Запуск приложения локально..."
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
    
# Проверяем Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker не найден"
    exit 1
fi

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

log_info "Остановка существующих сервисов..."
docker-compose down --remove-orphans

echo "🚀 Запуск контейнера..."
docker compose up -d --build

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

echo -n "Проверка Nginx"
wait_for_service "Nginx" "http://localhost:8080/health"

echo -n "Проверка приложения" 
wait_for_service "Приложение" "http://localhost:5050/health"

# Показываем статус сервисов
echo ""
log_info "Статус сервисов:"
docker-compose ps