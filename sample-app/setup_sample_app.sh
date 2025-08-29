#!/bin/bash
# Файл: sample-app/setup_sample_app.sh
# Настройка демонстрационного приложения

set -e

echo "🚀 Настройка Sample App для QA DevOps Workshop"
echo "=============================================="

# Цвета
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверяем, что мы в правильной директории
if [[ $(basename "$(pwd)") != "sample-app" ]]; then
    log_error "Запускайте из директории sample-app/"
    exit 1
fi

log_info "Шаг 1: Создание структуры директорий..."
mkdir -p {static,templates}

log_info "Шаг 2: Создание Dockerfile..."
cat > Dockerfile <<'EOF'
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN adduser --disabled-password --gecos '' appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 5050

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5050/health || exit 1

CMD ["python", "app.py"]
EOF

log_success "Dockerfile создан"

log_info "Шаг 3: Создание requirements.txt..."
cat > requirements.txt <<'EOF'
flask==3.0.0
requests==2.31.0
gunicorn==21.2.0
EOF

log_success "Requirements.txt создан"

log_info "Шаг 4: Проверка основных файлов..."

# Проверяем наличие основных файлов
required_files=("app.py" "config.py" "templates/index.html" "static/style.css" "static/app.js")
missing_files=0

for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        log_error "Отсутствует файл: $file"
        ((missing_files++))
    else
        log_success "Найден: $file"
    fi
done

if [[ $missing_files -gt 0 ]]; then
    log_error "Отсутствует $missing_files файлов. Создаем минимальную версию..."
    
    # Создаем минимальную версию app.py если её нет
    if [[ ! -f "app.py" ]]; then
        cat > app.py <<'EOF'
from flask import Flask, jsonify
import os
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def home():
    return '<h1>🚀 QA Demo App</h1><p>Демонстрационное приложение запущено!</p><p><a href="/health">Health Check</a></p>'

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "service": "qa-demo-app",
        "timestamp": datetime.utcnow().isoformat()
    })

@app.route('/api/users')
def api_users():
    return jsonify({
        "users": [
            {"id": 1, "name": "Test User", "email": "test@example.com"}
        ]
    })

if __name__ == '__main__':
    PORT = int(os.environ.get('PORT', 5050))
    app.run(host='0.0.0.0', port=PORT, debug=True)
EOF
        log_success "Создана минимальная версия app.py"
    fi
fi

log_info "Шаг 5: Тестирование сборки Docker образа..."
if command -v docker &> /dev/null; then
    if docker build -t sample-app-test . > /dev/null 2>&1; then
        log_success "Docker образ собирается корректно"
        docker rmi sample-app-test > /dev/null 2>&1 || true
    else
        log_warning "Проблемы со сборкой Docker образа"
    fi
else
    log_warning "Docker не найден, пропускаем тест сборки"
fi

log_info "Шаг 6: Создание скриптов запуска..."

# Скрипт локального запуска
cat > run_local.sh <<'EOF'
#!/bin/bash
echo "🏃 Локальный запуск Sample App"
echo "============================="

# Проверяем Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 не найден"
    exit 1
fi

# Устанавливаем зависимости
echo "📦 Установка зависимостей..."
pip3 install -r requirements.txt

# Запускаем приложение
echo "🚀 Запуск приложения..."
export FLASK_ENV=development
python3 app.py
EOF

chmod +x run_local.sh

# Скрипт Docker запуска
cat > run_docker.sh <<'EOF'
#!/bin/bash
echo "🐳 Docker запуск Sample App"
echo "=========================="

# Проверяем Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не найден"
    exit 1
fi

echo "🔨 Сборка Docker образа..."
docker build -t sample-app .

echo "🚀 Запуск контейнера..."
docker run --rm \
    -p 5050:5050 \
    --name sample-app-container \
    sample-app

echo "✅ Приложение доступно на http://localhost:5050"
EOF

chmod +x run_docker.sh

# Скрипт тестирования
cat > test_app.sh <<'EOF'
#!/bin/bash
echo "🧪 Тестирование Sample App"
echo "========================="

BASE_URL="http://localhost:5050"

test_endpoint() {
    local endpoint=$1
    local description=$2
    
    echo -n "Тестируем $description... "
    if curl -s -f "$BASE_URL$endpoint" > /dev/null; then
        echo "✅ OK"
    else
        echo "❌ FAIL"
    fi
}

echo "Ждем готовности приложения..."
sleep 3

test_endpoint "/" "Главная страница"
test_endpoint "/health" "Health check" 
test_endpoint "/api/users" "Users API"

echo ""
echo "🎉 Тестирование завершено!"
EOF

chmod +x test_app.sh

log_success "Скрипты запуска созданы"

log_info "Шаг 7: Создание README..."
cat > README.md <<'EOF'
# 🚀 Sample App - QA DevOps Workshop

Демонстрационное Flask приложение для обучения контейнеризации и тестирования.

## 🏃‍♂️ Быстрый старт

### Локальный запуск
```bash
./run_local.sh
```

### Docker запуск
```bash
./run_docker.sh
```

### Тестирование
```bash
./test_app.sh
```

## 🔌 API Эндпоинты

- `GET /` - Главная страница
- `GET /health` - Health check
- `GET /ready` - Readiness check
- `GET /api/users` - Список пользователей
- `POST /api/users` - Создание пользователя
- `GET /api/stats` - Статистика приложения

## 🧪 Для тестирования

Приложение включает эндпоинты для демонстрации:
- HTTP статус коды
- JSON API ответы
- Health checks
- Симуляция ошибок

## 🐳 Docker

```bash
# Сборка
docker build -t sample-app .

# Запуск
docker run -p 5050:5050 sample-app

# С переменными окружения
docker run -p 5050:5050 -e FLASK_ENV=production sample-app
```
EOF

log_success "README.md создан"

# Финальная проверка
echo ""
echo "📋 Проверка созданной структуры:"
echo "================================"

files_to_check=("Dockerfile" "requirements.txt" "app.py" "run_local.sh" "run_docker.sh" "test_app.sh" "README.md")

for file in "${files_to_check[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file${NC}"
    fi
done

echo ""
echo "🎉 Настройка Sample App завершена!"
echo "=================================="
echo ""
echo -e "${GREEN}📁 Структура проекта:${NC}"
echo "sample-app/"
echo "├── 🐳 Dockerfile              # Docker контейнер"  
echo "├── 📦 requirements.txt        # Python зависимости"
echo "├── 🐍 app.py                  # Flask приложение"
echo "├── ⚙️  config.py               # Конфигурация"
echo "├── 📄 templates/              # HTML шаблоны"
echo "├── 🎨 static/                 # CSS и JavaScript"
echo "├── 🏃 run_local.sh            # Локальный запуск"
echo "├── 🐳 run_docker.sh           # Docker запуск"  
echo "├── 🧪 test_app.sh             # Тестирование"
echo "└── 📋 README.md               # Документация"
echo ""
echo -e "${BLUE}🚀 Следующие шаги:${NC}"
echo "1. ./run_docker.sh             # Запуск в Docker"
echo "2. Откройте http://localhost:5050"
echo "3. ./test_app.sh              # Тестирование API"
echo ""
echo -e "${YELLOW}💡 Использование в тестах:${NC}"
echo "• Приложение готово для UI и API тестирования"
echo "• Health checks настроены для мониторинга"
echo "• JSON API для автоматизированных тестов"
