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
