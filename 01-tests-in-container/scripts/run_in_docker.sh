#!/bin/bash

set -e

echo "🐳 Запуск тестов в Docker контейнере..."
echo "======================================="

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

# Проверяем наличие Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker не найден. Установите Docker Desktop."
    exit 1
fi

# Проверяем, что Docker демон запущен
if ! docker info &> /dev/null; then
    log_error "Docker демон не запущен. Запустите Docker Desktop."
    exit 1
fi

# Проверяем, что мы в правильной директории
if [[ ! -f "Dockerfile" ]]; then
    log_error "Dockerfile не найден. Запускайте из директории 01-tests-in-container/"
    exit 1
fi

# Создаем директорию для отчетов
mkdir -p reports
log_info "Создана директория reports/"

# Имя образа
IMAGE_NAME="qa-tests"
CONTAINER_NAME="qa-tests-run"

log_info "Сборка Docker образа..."
docker build -t $IMAGE_NAME . \
    --label "workshop=qa-devops" \
    --label "component=tests" || {
    log_error "Не удалось собрать Docker образ"
    exit 1
}

log_success "Docker образ собран: $IMAGE_NAME"

log_info "Запуск тестов в контейнере..."

# Удаляем старый контейнер если существует
docker rm $CONTAINER_NAME 2>/dev/null || true

# Запуск контейнера с монтированием volume для отчетов
docker run --name $CONTAINER_NAME \
    -v "$(pwd)/reports:/app/reports" \
    -e "TEST_ENV=docker" \
    -e "CI=true" \
    $IMAGE_NAME || {

    log_error "Тесты завершились с ошибками"
    log_info "Проверьте отчеты в reports/"
    
    # Показываем логи контейнера для отладки
    echo ""
    echo "📋 Последние логи контейнера:"
    docker logs $CONTAINER_NAME --tail 20 || true
    
    exit 1
}

log_success "Тесты в Docker выполнены успешно!"

# Проверяем созданные отчеты
echo ""
echo "📊 Созданные отчеты:"
if [[ -f "reports/report.html" ]]; then
    log_success "HTML отчет: $(pwd)/reports/report.html"
    echo "   Откройте в браузере: open reports/report.html"
fi

if [[ -f "reports/junit.xml" ]]; then
    log_success "JUnit XML: $(pwd)/reports/junit.xml"
fi

if [[ -d "reports/allure" ]]; then
    log_success "Allure данные: $(pwd)/reports/allure/"
    if command -v allure &> /dev/null; then
        echo "   Для просмотра Allure отчета: allure serve reports/allure"
    else
        log_info "Установите Allure для просмотра отчетов: npm install -g allure-commandline"
    fi
fi

# Показываем размер образа
echo ""
echo "📏 Информация об образе:"
docker images $IMAGE_NAME --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo ""
echo "🎉 Готово!"
echo "============"
echo "Преимущества запуска в контейнере:"
echo "✅ Изолированное окружение"
echo "✅ Воспроизводимость результатов"
echo "✅ Нет конфликтов зависимостей"
echo "✅ Готово к CI/CD"