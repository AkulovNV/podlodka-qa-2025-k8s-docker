# ===========================================
# Файл: 02-microservice-testing/scripts/debug.sh
# ===========================================

#!/bin/bash

echo "🔍 Отладка микросервисного окружения..."
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

if [[ ! -f "docker-compose.yml" ]]; then
    echo "Запускайте из директории 02-microservice-testing/"
    exit 1
fi

echo "🛠 Доступные опции отладки:"
echo "1. Статус всех сервисов"
echo "2. Логи сервиса"  
echo "3. Подключение к базе данных"
echo "4. Проверка API эндпоинтов"
echo "5. Просмотр переменных окружения"
echo "6. Интерактивный shell в контейнере"
echo "7. Тест подключения между сервисами"

read -p "Выберите опцию (1-7): " choice

case $choice in
    1)
        log_info "Статус сервисов:"
        docker-compose ps
        
        echo ""
        log_info "Использование ресурсов:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
        ;;
    2)
        echo "Доступные сервисы:"
        docker-compose ps --services
        read -p "Введите имя сервиса: " service
        
        echo "Опции просмотра логов:"
        echo "1. Последние 50 строк"
        echo "2. Следить за логами в реальном времени"
        echo "3. Логи с конкретного времени"
        read -p "Выберите (1-3): " log_option
        
        case $log_option in
            1) docker-compose logs --tail 50 "$service" ;;
            2) docker-compose logs -f "$service" ;;
            3) 
                read -p "Введите время (например: 2023-12-01T10:00:00): " timestamp
                docker-compose logs --since "$timestamp" "$service"
                ;;
        esac
        ;;
    3)
        log_info "Подключение к PostgreSQL..."
        docker-compose exec db psql -U user -d testdb -c "\dt"
        
        echo ""
        echo "Полезные SQL команды:"
        echo "• \dt                 - список таблиц"
        echo "• \d table_name       - структура таблицы"
        echo "• SELECT * FROM users LIMIT 5;"
        echo ""
        read -p "Открыть интерактивный psql? (y/N): " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose exec db psql -U user -d testdb
        fi
        ;;
    4)
        log_info "Проверка API эндпоинтов..."
        
        endpoints=(
            "http://localhost:8000/health|GET|App Health"
            "http://localhost:8001/health|GET|Mock Health"
            "http://localhost:8000/ready|GET|App Readiness"
            "http://localhost:8000/users|GET|Users List"
            "http://localhost:8001/orders/1|GET|Mock Orders"
        )
        
        for endpoint in "${endpoints[@]}"; do
            IFS='|' read -r url method description <<< "$endpoint"
            echo -n "Testing $description... "
            if curl -s -f "$url" > /dev/null; then
                echo -e "${GREEN}OK${NC}"
            else
                echo -e "${RED}FAIL${NC}"
            fi
        done
        
        echo ""
        read -p "Протестировать кастомный URL? (y/N): " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo
            read -p "Введите URL: " custom_url
            echo "Ответ:"
            curl -s "$custom_url" | jq . 2>/dev/null || curl -s "$custom_url"
        fi
        ;;
    5)
        echo "Доступные сервисы:"
        docker-compose ps --services
        read -p "Введите имя сервиса: " service
        
        log_info "Переменные окружения в $service:"
        docker-compose exec "$service" env | sort
        ;;
    6)
        echo "Доступные сервисы:"
        docker-compose ps --services
        read -p "Введите имя сервиса: " service
        
        log_info "Открытие shell в $service..."
        docker-compose exec "$service" /bin/bash || docker-compose exec "$service" /bin/sh
        ;;
    7)
        log_info "Тестирование связи между сервисами..."
        
        echo "Проверка связи app -> db:"
        docker-compose exec app ping -c 1 db && echo -e "${GREEN}OK${NC}" || echo -e "${RED}FAIL${NC}"
        
        echo "Проверка связи app -> mock-server:"
        docker-compose exec app ping -c 1 mock-server && echo -e "${GREEN}OK${NC}" || echo -e "${RED}FAIL${NC}"
        
        echo "Проверка HTTP связи app -> mock-server:"
        docker-compose exec app curl -s http://mock-server:8001/health | jq . 2>/dev/null && echo -e "${GREEN}OK${NC}" || echo -e "${RED}FAIL${NC}"
        ;;
    *)
        echo "Неверная опция"
        exit 1
        ;;
esac

log_success "Отладка завершена"