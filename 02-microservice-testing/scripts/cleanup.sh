# ===========================================
# Файл: 02-microservice-testing/scripts/cleanup.sh
# ===========================================

#!/bin/bash

echo "🧹 Очистка микросервисного окружения..."
echo "====================================="

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

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Проверяем наличие docker-compose.yml
if [[ ! -f "docker-compose.yml" ]]; then
    echo "docker-compose.yml не найден. Запускайте из директории 02-microservice-testing/"
    exit 1
fi

log_info "Остановка и удаление сервисов..."
docker-compose down --volumes --remove-orphans

log_info "Удаление образов проекта..."
# Удаляем образы, созданные для этого проекта
PROJECT_NAME=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
docker images --filter "label=com.docker.compose.project=$PROJECT_NAME" -q | xargs -r docker rmi -f

# Альтернативный способ через имена образов
docker rmi -f "${PROJECT_NAME}_app" "${PROJECT_NAME}_mock-server" "${PROJECT_NAME}_tests" 2>/dev/null || true

log_info "Очистка volumes..."
docker volume ls --filter "name=$PROJECT_NAME" -q | xargs -r docker volume rm

log_info "Очистка сетей..."
docker network ls --filter "name=$PROJECT_NAME" -q | xargs -r docker network rm 2>/dev/null || true

log_info "Очистка локальных файлов..."
rm -rf logs/* reports/* 2>/dev/null || true
# Сохраняем .gitkeep файлы
touch logs/.gitkeep reports/.gitkeep

log_success "Очистка завершена!"

# Показываем статистику
echo ""
echo "📊 Статистика после очистки:"
echo "Docker containers: $(docker ps -a -q | wc -l)"
echo "Docker images: $(docker images -q | wc -l)"
echo "Docker volumes: $(docker volume ls -q | wc -l)"

echo ""
echo "🎉 Микросервисное окружение очищено!"
echo "Для повторного запуска используйте: ./scripts/start_environment.sh"