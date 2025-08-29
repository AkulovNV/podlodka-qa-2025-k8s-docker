# ===========================================
# Файл: scripts/cleanup-all.sh  
# ===========================================

#!/bin/bash

echo "🧹 Очистка всех ресурсов QA DevOps Workshop..."
echo "==============================================="

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

# Подтверждение пользователя
echo -e "${YELLOW}⚠️  Это удалит все Docker контейнеры, сети, volumes и локальные файлы воркшопа${NC}"
read -p "Продолжить? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Отменено пользователем"
    exit 1
fi

log_info "Шаг 1: Остановка всех контейнеров воркшопа..."

# Остановка docker-compose сервисов
if [[ -f "02-microservice-testing/docker-compose.yml" ]]; then
    cd 02-microservice-testing
    docker-compose down -v --remove-orphans 2>/dev/null || true
    cd ..
    log_success "Микросервисы остановлены"
fi

# Остановка контейнеров по меткам
docker stop $(docker ps -q --filter "label=workshop=qa-devops" 2>/dev/null) 2>/dev/null || true
docker rm $(docker ps -aq --filter "label=workshop=qa-devops" 2>/dev/null) 2>/dev/null || true

log_info "Шаг 2: Удаление Docker образов воркшопа..."
docker rmi $(docker images -q --filter "label=workshop=qa-devops" 2>/dev/null) 2>/dev/null || true
docker rmi qa-tests 2>/dev/null || true
docker rmi qaworkshop_app 2>/dev/null || true
docker rmi qaworkshop_mock-server 2>/dev/null || true
docker rmi qaworkshop_tests 2>/dev/null || true
log_success "Образы воркшопа удалены"

log_info "Шаг 3: Очистка Docker volumes..."
docker volume rm $(docker volume ls -q --filter "name=qaworkshop" 2>/dev/null) 2>/dev/null || true
docker volume rm $(docker volume ls -q --filter "name=02-microservice-testing" 2>/dev/null) 2>/dev/null || true
log_success "Volumes очищены"

log_info "Шаг 4: Удаление Docker сетей..."
docker network rm $(docker network ls -q --filter "name=qaworkshop" 2>/dev/null) 2>/dev/null || true
docker network rm $(docker network ls -q --filter "name=02-microservice-testing" 2>/dev/null) 2>/dev/null || true
log_success "Сети удалены"

log_info "Шаг 5: Очистка Kubernetes ресурсов..."
if command -v kubectl &> /dev/null; then
    kubectl delete namespace qa-environment 2>/dev/null || true
    kubectl delete -f 03-qa-environment-k8s/manifests/ 2>/dev/null || true
    log_success "Kubernetes ресурсы удалены"
else
    log_warning "kubectl недоступен, пропускаем очистку Kubernetes"
fi

log_info "Шаг 6: Очистка локальных файлов..."
rm -rf {reports,logs,artifacts,tmp}/ 2>/dev/null || true
rm -rf 01-tests-in-container/reports/ 2>/dev/null || true
rm -rf 02-microservice-testing/{logs,reports}/ 2>/dev/null || true
rm -rf 03-qa-environment-k8s/logs/ 2>/dev/null || true
rm -rf 04-cicd-integration/artifacts/ 2>/dev/null || true
rm -f .env 2>/dev/null || true
log_success "Локальные файлы очищены"

log_info "Шаг 7: Очистка Python окружения..."
if [[ -d "venv" ]]; then
    read -p "Удалить Python venv? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf venv/
        log_success "Python venv удален"
    else
        log_warning "Python venv сохранен"
    fi
fi

log_info "Шаг 8: Общая очистка Docker..."
echo "Освобождаем место, удаляя неиспользуемые ресурсы..."
docker system prune -f
log_success "Docker система очищена"

# Показываем статистику
echo ""
echo "📊 Статистика после очистки:"
echo "Docker containers: $(docker ps -a -q | wc -l)"
echo "Docker images: $(docker images -q | wc -l)"  
echo "Docker volumes: $(docker volume ls -q | wc -l)"
echo "Docker networks: $(docker network ls -q | wc -l)"

if command -v kubectl &> /dev/null; then
    echo "K8s pods: $(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l || echo 0)"
fi

echo ""
echo "🎉 Очистка завершена!"
echo "Система возвращена к исходному состоянию."