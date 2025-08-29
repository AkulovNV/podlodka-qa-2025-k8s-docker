# ===========================================
# Файл: scripts/demo-reset.sh
# ===========================================

#!/bin/bash

echo "🔄 Сброс демо к исходному состоянию..."
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

log_info "Шаг 1: Остановка всех запущенных сервисов..."

# Остановка микросервисов
if [[ -f "02-microservice-testing/docker-compose.yml" ]]; then
    cd 02-microservice-testing
    docker-compose down 2>/dev/null || true
    cd ..
fi

# Остановка отдельных контейнеров
docker stop $(docker ps -q --filter "label=workshop=qa-devops" 2>/dev/null) 2>/dev/null || true

log_info "Шаг 2: Очистка временных файлов..."
rm -rf {reports,logs,artifacts}/*
mkdir -p {reports,logs,artifacts}
mkdir -p 01-tests-in-container/reports
mkdir -p 02-microservice-testing/{logs,reports}
mkdir -p 03-qa-environment-k8s/logs
mkdir -p 04-cicd-integration/artifacts

log_info "Шаг 3: Создание свежих .gitkeep файлов..."
find . -name "reports" -o -name "logs" -o -name "artifacts" | while read dir; do
    if [[ -d "$dir" ]]; then
        touch "$dir/.gitkeep"
    fi
done

log_info "Шаг 4: Проверка образов Docker..."
# Пересобираем образы если нужно
if [[ ! "$(docker images -q qa-tests 2>/dev/null)" ]]; then
    log_info "Пересборка образа для тестов..."
    if [[ -f "01-tests-in-container/Dockerfile" ]]; then
        docker build -t qa-tests 01-tests-in-container/
    fi
fi

log_info "Шаг 5: Сброс базы данных..."
# Удаляем старые volumes базы данных
docker volume rm 02-microservice-testing_postgres_data 2>/dev/null || true

log_info "Шаг 6: Проверка настроек Kubernetes..."
if command -v kubectl &> /dev/null; then
    # Удаляем namespace если существует
    kubectl delete namespace qa-environment 2>/dev/null || true
    log_success "Kubernetes namespace сброшен"
fi

log_info "Шаг 7: Восстановление демо-данных..."
# Восстанавливаем исходное состояние mock данных
if [[ -f "02-microservice-testing/mocks/responses/orders.json.backup" ]]; then
    cp 02-microservice-testing/mocks/responses/orders.json.backup \
       02-microservice-testing/mocks/responses/orders.json
fi

log_info "Шаг 8: Финальная проверка..."
./scripts/check-prerequisites.sh > /dev/null && {
    log_success "Prerequisites в порядке"
} || {
    log_info "Возможны проблемы с prerequisites, запустите check-prerequisites.sh"
}

echo ""
echo "🎉 Демо сброшено к исходному состоянию!"
echo "======================================"
echo -e "${GREEN}Готово к новой демонстрации:${NC}"
echo "• Все сервисы остановлены"
echo "• Временные файлы очищены"
echo "• База данных сброшена"
echo "• Образы готовы к использованию"
echo ""
echo -e "${BLUE}Рекомендуемый порядок демо:${NC}"
echo "1. cd 01-tests-in-container && ./scripts/run_in_docker.sh"
echo "2. cd ../02-microservice-testing && ./scripts/start_environment.sh"  
echo "3. cd ../03-qa-environment-k8s && ./scripts/deploy-qa.sh"
echo ""
