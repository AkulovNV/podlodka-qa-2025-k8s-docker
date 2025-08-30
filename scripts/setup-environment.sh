#!/bin/bash
# ===========================================
# Файл: scripts/setup-environment.sh
# ===========================================

set -e

echo "🚀 Настройка окружения QA DevOps Workshop..."
echo "============================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функция логирования
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверка, что мы в правильной директории
if [[ ! -f "scripts/setup-environment.sh" ]]; then
    log_error "Скрипт должен запускаться из корня репозитория"
    exit 1
fi

log_info "Шаг 1: Проверка prerequisites..."
if ! ./scripts/check-prerequisites.sh; then
    log_error "Prerequisites не прошли проверку"
    exit 1
fi

log_info "Шаг 2: Создание виртуального окружения Python..."
if [[ ! -d "venv" ]]; then
    python3 -m venv venv
    log_success "Виртуальное окружение создано"
else
    log_warning "Виртуальное окружение уже существует"
fi

# Активация виртуального окружения
source venv/bin/activate || {
    log_warning "Не удалось активировать venv, используем системный Python"
}

log_info "Шаг 3: Установка Python зависимостей..."
if [[ -f "01-tests-in-container/requirements.txt" ]]; then
    pip install -r 01-tests-in-container/requirements.txt
    log_success "Зависимости для контейнерных тестов установлены"
fi

# Установка дополнительных пакетов для разработки
# pip install docker-compose requests pyyaml
# log_success "Дополнительные пакеты установлены"

log_info "Шаг 4: Настройка Docker образов..."
# Скачиваем базовые образы
docker pull python:3.11-slim
docker pull postgres:15
docker pull nginx:alpine
log_success "Базовые Docker образы загружены"

log_info "Шаг 5: Создание рабочих директорий..."
mkdir -p {reports,logs,artifacts,tmp}
mkdir -p {01-tests-in-container/reports,02-microservice-testing/logs,02-microservice-testing/reports}
mkdir -p {03-qa-environment-k8s/logs,04-cicd-integration/artifacts}
log_success "Рабочие директории созданы"

log_info "Шаг 6: Настройка разрешений..."
chmod +x scripts/*.sh
chmod +x 01-tests-in-container/scripts/*.sh
chmod +x 02-microservice-testing/scripts/*.sh  
chmod +x 03-qa-environment-k8s/scripts/*.sh
log_success "Разрешения на выполнение установлены"

log_info "Шаг 7: Проверка конфигураций..."
# Проверяем docker-compose файлы
if [[ -f "02-microservice-testing/docker-compose.yml" ]]; then
    docker-compose -f 02-microservice-testing/docker-compose.yml config > /dev/null
    log_success "docker-compose конфигурация корректна"
fi

# Проверяем Kubernetes манифесты (если kubectl доступен)
if command -v kubectl &> /dev/null && [[ -d "03-qa-environment-k8s/manifests" ]]; then
    kubectl apply --dry-run=client -f 03-qa-environment-k8s/manifests/ > /dev/null 2>&1 && {
        log_success "Kubernetes манифесты корректны"
    } || {
        log_warning "Проблемы с Kubernetes манифестами или нет доступа к кластеру"
    }
fi

log_info "Шаг 8: Создание файла окружения..."
cat > .env << EOF
# QA DevOps Workshop Environment
WORKSHOP_ENV=local
APP_HOST=localhost
APP_PORT=8000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=qaworkshop
DB_USER=qauser
DB_PASSWORD=qapass

# Docker настройки
COMPOSE_PROJECT_NAME=qaworkshop
DOCKER_BUILDKIT=1

# Paths
REPORTS_DIR=./reports
LOGS_DIR=./logs
ARTIFACTS_DIR=./artifacts
EOF
log_success ".env файл создан"

log_info "Шаг 9: Настройка Git hooks (опционально)..."
if [[ -d ".git" ]]; then
    mkdir -p .git/hooks
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Простая проверка перед коммитом
echo "🔍 Проверка перед коммитом..."

# Проверка yaml файлов
find . -name "*.yml" -o -name "*.yaml" | while read file; do
    if command -v yamllint &> /dev/null; then
        yamllint "$file" || exit 1
    fi
done

# Проверка shell скриптов
find . -name "*.sh" | while read file; do
    if command -v shellcheck &> /dev/null; then
        shellcheck "$file" || echo "Warning: shellcheck issues in $file"
    fi
done

echo "✅ Pre-commit проверки завершены"
EOF
    chmod +x .git/hooks/pre-commit
    log_success "Git pre-commit hook установлен"
fi

log_info "Шаг 10: Создание демо-данных..."
# Создаем тестовые файлы если их нет
if [[ ! -f "sample-app/app.py" ]]; then
    mkdir -p sample-app
    cat > sample-app/app.py << 'EOF'
from flask import Flask, jsonify, request
import os

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "demo-app"})

@app.route('/api/users')
def get_users():
    return jsonify([
        {"id": 1, "name": "Test User 1", "email": "user1@example.com"},
        {"id": 2, "name": "Test User 2", "email": "user2@example.com"}
    ])

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    return jsonify({
        "id": 123,
        "name": data.get("name"),
        "email": data.get("email"),
        "created": True
    }), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
EOF
    log_success "Демо-приложение создано"
fi

echo ""
echo "🎉 Настройка окружения завершена!"
echo "=================================="
echo -e "${GREEN}Готово к использованию:${NC}"
echo "• Python виртуальное окружение: venv/"
echo "• Рабочие директории созданы"  
echo "• Docker образы загружены"
echo "• Скрипты готовы к выполнению"
echo ""
echo -e "${BLUE}Следующие шаги:${NC}"
echo "1. source venv/bin/activate  # активировать Python окружение"
echo "2. cd 01-tests-in-container && ./scripts/run_in_docker.sh  # автотесты в docker"
echo "3. cd ../02-microservice-testing && ./scripts/start_environment.sh  # микросервисные тесты в docker-compose"
echo "4. cd ../03-microservice-testing && ./deploy.sh  # k8s тесты"
echo ""
echo -e "${YELLOW}Полезные команды:${NC}"
echo "• ./scripts/demo-reset.sh     # сброс к исходному состоянию"
echo "• ./scripts/cleanup-all.sh    # полная очистка"
