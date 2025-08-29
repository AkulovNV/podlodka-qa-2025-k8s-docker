# ===========================================
# Файл: 03-qa-environment-k8s/scripts/get-logs.sh  
# ===========================================

#!/bin/bash

echo "📋 Сбор логов из QA окружения..."
echo "==============================="

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

# Проверяем наличие kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl не найден"
    exit 1
fi

NAMESPACE="qa-environment"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOGS_DIR="logs/collected-$TIMESTAMP"

# Проверяем существование namespace
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    log_error "Namespace $NAMESPACE не существует"
    exit 1
fi

# Создаем директорию для логов
mkdir -p "$LOGS_DIR"
log_info "Создана директория $LOGS_DIR"

# Опции сбора логов
echo "📊 Опции сбора логов:"
echo "1. Быстрый сбор (последние 100 строк)"
echo "2. Полный сбор всех логов"
echo "3. Логи за последний час"
echo "4. Интерактивный выбор"

read -p "Выберите опцию (1-4, по умолчанию 1): " log_option
LOG_OPTION=${log_option:-1}

# Параметры для kubectl logs
case $LOG_OPTION in
    1) LOG_PARAMS="--tail=100" ;;
    2) LOG_PARAMS="--previous=false" ;;
    3) LOG_PARAMS="--since=1h" ;;
    4) 
        read -p "Количество строк (или 'all' для всех): " tail_lines
        read -p "За какое время (например: 1h, 30m): " since_time
        
        LOG_PARAMS=""
        [[ "$tail_lines" != "all" ]] && LOG_PARAMS="$LOG_PARAMS --tail=$tail_lines"
        [[ -n "$since_time" ]] && LOG_PARAMS="$LOG_PARAMS --since=$since_time"
        ;;
    *) LOG_PARAMS="--tail=100" ;;
esac

log_info "Сбор общей информации о кластере..."

# Информация о кластере
cat > "$LOGS_DIR/cluster-info.txt" <<EOF
Kubernetes Cluster Information
==============================
Date: $(date)
Context: $(kubectl config current-context)
Namespace: $NAMESPACE

Cluster Info:
$(kubectl cluster-info)

Node Info:
$(kubectl get nodes -o wide)

Namespace Resources:
$(kubectl get all -n "$NAMESPACE" -o wide)
EOF

log_info "Сбор информации о ресурсах..."

# События в namespace
kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' > "$LOGS_DIR/events.txt"

# Описание всех ресурсов
kubectl describe all -n "$NAMESPACE" > "$LOGS_DIR/describe-all.txt"

# Сбор логов подов
log_info "Сбор логов подов..."
POD_COUNT=0

while IFS= read -r line; do
    pod_name=$(echo "$line" | awk '{print $1}')
    [[ "$pod_name" == "NAME" ]] && continue  # Пропускаем заголовок
    
    ((POD_COUNT++))
    log_info "Сбор логов пода: $pod_name"
    
    # Создаем директорию для пода
    POD_DIR="$LOGS_DIR/pods/$pod_name"
    mkdir -p "$POD_DIR"
    
    # Логи текущего состояния
    kubectl logs "$pod_name" -n "$NAMESPACE" $LOG_PARAMS > "$POD_DIR/current.log" 2>/dev/null || {
        echo "Ошибка сбора текущих логов" > "$POD_DIR/current.log"
    }
    
    # Логи предыдущего состояния (если под перезапускался)
    kubectl logs "$pod_name" -n "$NAMESPACE" --previous > "$POD_DIR/previous.log" 2>/dev/null || {
        echo "Предыдущих логов нет" > "$POD_DIR/previous.log"
    }
    
    # Описание пода
    kubectl describe pod "$pod_name" -n "$NAMESPACE" > "$POD_DIR/describe.txt"
    
    # Логи всех контейнеров если их несколько
    containers=$(kubectl get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}')
    for container in $containers; do
        if [[ $(echo "$containers" | wc -w) -gt 1 ]]; then
            kubectl logs "$pod_name" -c "$container" -n "$NAMESPACE" $LOG_PARAMS > "$POD_DIR/$container.log" 2>/dev/null || true
        fi
    done
    
done < <(kubectl get pods -n "$NAMESPACE" --no-headers)

# Сбор конфигураций
log_info "Сбор конфигураций..."
CONFIG_DIR="$LOGS_DIR/configs"
mkdir -p "$CONFIG_DIR"

# ConfigMaps
kubectl get configmaps -n "$NAMESPACE" -o yaml > "$CONFIG_DIR/configmaps.yaml" 2>/dev/null || true

# Secrets (без данных)
kubectl get secrets -n "$NAMESPACE" -o yaml > "$CONFIG_DIR/secrets.yaml" 2>/dev/null || true

# Services
kubectl get services -n "$NAMESPACE" -o yaml > "$CONFIG_DIR/services.yaml" 2>/dev/null || true

# Ingress
kubectl get ingresses -n "$NAMESPACE" -o yaml > "$CONFIG_DIR/ingresses.yaml" 2>/dev/null || true

# Persistent Volume Claims
kubectl get pvc -n "$NAMESPACE" -o yaml > "$CONFIG_DIR/pvc.yaml" 2>/dev/null || true

# Мониторинг ресурсов (если доступен metrics-server)
log_info "Сбор метрик использования ресурсов..."
kubectl top pods -n "$NAMESPACE" > "$LOGS_DIR/resource-usage-pods.txt" 2>/dev/null || {
    echo "Metrics server недоступен" > "$LOGS_DIR/resource-usage-pods.txt"
}

kubectl top nodes > "$LOGS_DIR/resource-usage-nodes.txt" 2>/dev/null || {
    echo "Metrics server недоступен" > "$LOGS_DIR/resource-usage-nodes.txt"
}

# Создание архива
log_info "Создание архива..."
ARCHIVE_NAME="qa-logs-$TIMESTAMP.tar.gz"
tar -czf "$ARCHIVE_NAME" -C logs "collected-$TIMESTAMP"

# Создание отчета
REPORT_FILE="$LOGS_DIR/summary.txt"
cat > "$REPORT_FILE" <<EOF
QA Environment Logs Summary
===========================
Collection Date: $(date)
Namespace: $NAMESPACE
Pods Processed: $POD_COUNT
Archive: $ARCHIVE_NAME

Directory Structure:
$(find "$LOGS_DIR" -type f | sort)

Quick Stats:
- Events: $(wc -l < "$LOGS_DIR/events.txt") events
- Log files: $(find "$LOGS_DIR/pods" -name "*.log" | wc -l) files
- Total size: $(du -sh "$LOGS_DIR" | cut -f1)
EOF

log_success "Сбор логов завершен!"

echo ""
echo "📊 Результаты:"
echo "=============="
echo "• Директория: $LOGS_DIR"
echo "• Архив: $ARCHIVE_NAME"
echo "• Обработано подов: $POD_COUNT"
echo "• Общий размер: $(du -sh "$LOGS_DIR" | cut -f1)"

echo ""
echo -e "${BLUE}📁 Собранные данные:${NC}"
echo "• cluster-info.txt    - информация о кластере"
echo "• events.txt          - события namespace"
echo "• describe-all.txt    - описание всех ресурсов"
echo "• pods/               - логи и описания подов"
echo "• configs/            - конфигурации ресурсов"
echo "• summary.txt         - краткая сводка"

echo ""
echo -e "${GREEN}💡 Рекомендации:${NC}"
echo "• Проверьте events.txt на наличие ошибок"
echo "• Посмотрите логи подов в pods/"
echo "• Архив можно отправить для анализа"
