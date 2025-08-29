# ===========================================
# Файл: 02-microservice-testing/scripts/load_test_data.sh
# ===========================================

#!/bin/bash

echo "📊 Загрузка тестовых данных..."
echo "============================"

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

# Ждем готовности приложения
log_info "Ожидание готовности сервисов..."
for i in {1..30}; do
    if curl -s http://localhost:8000/health > /dev/null; then
        break
    fi
    sleep 1
done

log_info "Создание тестовых пользователей..."

# Массив тестовых пользователей
users=(
    '{"name": "Alice Johnson", "email": "alice@example.com"}'
    '{"name": "Bob Smith", "email": "bob@example.com"}'
    '{"name": "Carol Davis", "email": "carol@example.com"}'
    '{"name": "David Wilson", "email": "david@example.com"}'
    '{"name": "Eva Brown", "email": "eva@example.com"}'
)

created_users=()

for user_data in "${users[@]}"; do
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$user_data" \
        http://localhost:8000/users)
    
    if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
        user_id=$(echo "$response" | jq -r '.id')
        user_name=$(echo "$response" | jq -r '.name')
        created_users+=("$user_id")
        log_success "Создан пользователь: $user_name (ID: $user_id)"
    else
        log_error "Ошибка создания пользователя: $user_data"
    fi
done

log_info "Создание тестовых заказов..."

# Создаем заказы для первых трех пользователей
orders=(
    '{"user_id": 1, "items": [{"product": "Laptop", "quantity": 1, "price": 999.99}], "total": 999.99}'
    '{"user_id": 1, "items": [{"product": "Mouse", "quantity": 2, "price": 29.99}], "total": 59.98}'
    '{"user_id": 2, "items": [{"product": "Keyboard", "quantity": 1, "price": 79.99}], "total": 79.99}'
    '{"user_id": 3, "items": [{"product": "Monitor", "quantity": 1, "price": 299.99}], "total": 299.99}'
)

for order_data in "${orders[@]}"; do
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$order_data" \
        http://localhost:8000/orders)
    
    if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
        order_id=$(echo "$response" | jq -r '.id')
        user_id=$(echo "$response" | jq -r '.user_id')
        total=$(echo "$response" | jq -r '.total')
        log_success "Создан заказ: ID $order_id для пользователя $user_id на сумму $total"
    else
        log_error "Ошибка создания заказа: $order_data"
        echo "Ответ сервера: $response"
    fi
done

# Проверяем созданные данные
echo ""
log_info "Проверка созданных данных..."

echo "👥 Пользователи:"
curl -s http://localhost:8000/users | jq -r '.[] | "ID: \(.id), Name: \(.name), Email: \(.email)"'

echo ""
echo "📦 Заказы пользователей:"
for user_id in "${created_users[@]:0:3}"; do
    echo "Пользователь $user_id:"
    curl -s "http://localhost:8000/users/$user_id/orders" | jq -r '.orders[]? | "  Order ID: \(.id), Total: \(.total), Status: \(.status)"'
done

echo ""
log_success "Тестовые данные загружены!"
echo "=============================="
echo "📊 Статистика:"
echo "• Пользователей: ${#created_users[@]}"
echo "• Заказов: ${#orders[@]}"
echo ""
echo "🔍 Для проверки данных:"
echo "• GET http://localhost:8000/users"
echo "• GET http://localhost:8000/users/{id}/orders"