# ===========================================
# Файл: 03-qa-environment-k8s/scripts/port-forward.sh
# ===========================================

#!/bin/bash

echo "🔌 Настройка Port Forward для QA окружения..."
echo "============================================"

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

# Проверяем наличие kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl не найден"
    exit 1
fi

NAMESPACE="qa-environment"
LOGS_DIR="logs"

# Проверяем существование namespace
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    log_error "Namespace $NAMESPACE не существует"
    log_info "Запустите сначала: ./scripts/deploy-qa.sh"
    exit 1
fi

mkdir -p "$LOGS_DIR"

# Функция остановки существующих port-forward
stop_existing_forwards() {
    if [[ -f "$LOGS_DIR/port-forward.pid" ]]; then
        local pid=$(cat "$LOGS_DIR/port-forward.pid")
        if kill -0 "$pid" 2>/dev/null; then
            log_info "Остановка существующего port-forward (PID: $pid)"
            kill "$pid" 2>/dev/null || true
            sleep 2
        fi
        rm -f "$LOGS_DIR/port-forward.pid"
    fi
    
    # Дополнительная очистка
    pkill -f "kubectl port-forward.*$NAMESPACE" 2>/dev/null || true
}

# Получаем список доступных сервисов
log_info "Поиск доступных сервисов..."
services=$(kubectl get services -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name,:spec.ports[0].port")

if [[ -z "$services" ]]; then
    log_error "Не найдено сервисов в namespace $NAMESPACE"
    exit 1
fi

echo ""
echo "📋 Доступные сервисы:"
echo "===================="
counter=1
declare -a service_array
declare -a port_array

while IFS=$'\t' read -r service_name service_port; do
    [[ -z "$service_name" ]] && continue
    echo "$counter. $service_name (порт: $service_port)"
    service_array[$counter]=$service_name
    port_array[$counter]=$service_port
    ((counter++))
done <<< "$services"

# Автоматический выбор если один сервис
if [[ $counter -eq 2 ]]; then
    SELECTED_SERVICE=${service_array[1]}
    SELECTED_PORT=${port_array[1]}
    log_info "Автоматически выбран единственный сервис: $SELECTED_SERVICE"
else
    # Выбор пользователя
    echo ""
    read -p "Выберите сервис (1-$((counter-1))): " choice
    
    if [[ -z "${service_array[$choice]}" ]]; then
        log_error "Неверный выбор"
        exit 1
    fi
    
    SELECTED_SERVICE=${service_array[$choice]}
    SELECTED_PORT=${port_array[$choice]}
fi

# Выбор локального порта
echo ""
echo "🔌 Настройка локального порта:"
read -p "Локальный порт (по умолчанию 8080): " local_port
LOCAL_PORT=${local_port:-8080}

# Проверяем, не занят ли порт
if lsof -i :$LOCAL_PORT &> /dev/null || netstat -tuln 2>/dev/null | grep :$LOCAL_PORT &> /dev/null; then
    log_warning "Порт $LOCAL_PORT занят"
    read -p "Попробовать другой порт? Введите номер или Enter для автоматического выбора: " alt_port
    if [[ -n "$alt_port" ]]; then
        LOCAL_PORT=$alt_port
    else
        LOCAL_PORT=$((8080 + RANDOM % 1000))
        log_info "Выбран случайный порт: $LOCAL_PORT"
    fi
fi

# Остановка существующих forwards
stop_existing_forwards

log_info "Настройка port-forward..."
echo "Сервис: $SELECTED_SERVICE"
echo "Удаленный порт: $SELECTED_PORT"
echo "Локальный порт: $LOCAL_PORT"

# Запуск port-forward в фоне
kubectl port-forward -n "$NAMESPACE" "svc/$SELECTED_SERVICE" "$LOCAL_PORT:$SELECTED_PORT" > "$LOGS_DIR/port-forward.log" 2>&1 &
PID=$!

# Сохраняем PID
echo $PID > "$LOGS_DIR/port-forward.pid"

# Ждем, пока port-forward запустится
sleep 3

# Проверяем, что процесс запустился
if kill -0 $PID 2>/dev/null; then
    log_success "Port-forward запущен (PID: $PID)"
    
    # Тестируем соединение
    if curl -s -f "http://localhost:$LOCAL_PORT" > /dev/null 2>&1; then
        log_success "Соединение работает!"
    else
        log_warning "Port-forward запущен, но соединение недоступно"
        log_info "Возможно, приложение еще загружается"
    fi
else
    log_error "Не удалось запустить port-forward"
    cat "$LOGS_DIR/port-forward.log"
    exit 1
fi

# Создаем удобные команды
cat > "$LOGS_DIR/port-forward-commands.sh" <<EOF
#!/bin/bash
# Полезные команды для работы с port-forward

# Проверка статуса
curl http://localhost:$LOCAL_PORT/health 2>/dev/null | jq . || curl -s http://localhost:$LOCAL_PORT/health

# Остановка port-forward
kill $(cat logs/port-forward.pid) 2>/dev/null || echo "Port-forward не запущен"

# Просмотр логов port-forward
tail -f logs/port-forward.log

# Перезапуск port-forward
./scripts/port-forward.sh
EOF

chmod +x "$LOGS_DIR/port-forward-commands.sh"

echo ""
echo "🎉 Port-forward настроен!"
echo "========================"
echo -e "${GREEN}Доступ к приложению:${NC}"
echo "• URL: http://localhost:$LOCAL_PORT"
echo "• Сервис: $SELECTED_SERVICE"
echo "• PID: $PID"

echo ""
echo -e "${BLUE}Полезные команды:${NC}"
echo "• curl http://localhost:$LOCAL_PORT/health  # проверка приложения"
echo "• kill $PID                                 # остановка port-forward"
echo "• tail -f logs/port-forward.log            # просмотр логов"
echo "• ./logs/port-forward-commands.sh          # готовые команды"

echo ""
echo -e "${YELLOW}Примечания:${NC}"
echo "• Port-forward работает в фоне"
echo "• Логи сохраняются в logs/port-forward.log"
echo "• PID сохранен в logs/port-forward.pid"
echo "• При закрытии терминала port-forward остается активным"

# Мониторинг в фоне (опционально)
read -p "Запустить мониторинг соединения? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    log_info "Запуск мониторинга... (Ctrl+C для остановки)"
    
    while kill -0 $PID 2>/dev/null; do
        if curl -s -f "http://localhost:$LOCAL_PORT" > /dev/null; then
            echo "$(date '+%H:%M:%S') - ✅ Соединение активно"
        else
            echo "$(date '+%H:%M:%S') - ❌ Соединение недоступно"
        fi
        sleep 10
    done
    
    log_warning "Port-forward процесс завершился"
fi