#!/bin/bash

set -e

echo "🚀 Сборка и публикация Docker образа с тестами..."
echo "================================================"

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

# Конфигурация
REGISTRY=${DOCKER_REGISTRY:-"localhost:5000"}
IMAGE_NAME="qa-tests"
VERSION=${VERSION:-"latest"}
FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME:$VERSION"

log_info "Конфигурация сборки:"
echo "Registry: $REGISTRY"
echo "Image: $IMAGE_NAME"
echo "Version: $VERSION"
echo "Full name: $FULL_IMAGE_NAME"

log_info "Сборка образа..."
docker build \
    -t $IMAGE_NAME:$VERSION \
    -t $IMAGE_NAME:latest \
    -t $FULL_IMAGE_NAME \
    --label "workshop=qa-devops" \
    --label "component=tests" \
    --label "version=$VERSION" \
    --label "build-date=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    . || {
    log_error "Ошибка при сборке образа"
    exit 1
}

log_success "Образ собран: $FULL_IMAGE_NAME"

# Проверяем размер образа
echo ""
echo "📏 Информация об образе:"
docker images $IMAGE_NAME --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Тестовый запуск
log_info "Тестовый запуск образа..."
docker run --rm $IMAGE_NAME:$VERSION python --version
docker run --rm $IMAGE_NAME:$VERSION python -c "import pytest, selenium, requests; print('✅ Основные пакеты импортированы')"

# Предложение пуша в registry
if [[ "$REGISTRY" != "localhost:5000" ]]; then
    read -p "Загрузить образ в registry $REGISTRY? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Загрузка в registry..."
        docker push $FULL_IMAGE_NAME
        log_success "Образ загружен в registry"
        
        echo ""
        echo "📋 Для использования в CI/CD:"
        echo "docker pull $FULL_IMAGE_NAME"
        echo "docker run --rm -v \$PWD/reports:/app/reports $FULL_IMAGE_NAME"
    fi
fi

log_success "Готово!"