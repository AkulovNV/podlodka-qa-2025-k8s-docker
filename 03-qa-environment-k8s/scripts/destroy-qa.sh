# ===========================================
# Файл: 03-qa-environment-k8s/scripts/destroy-qa.sh
# ===========================================

#!/bin/bash

echo "🗑️  Удаление QA окружения из Kubernetes..."
echo "========================================="

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

# Проверяем существование namespace
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    log_warning "Namespace $NAMESPACE не существует"
    exit 0
fi

# Подтверждение удаления
echo -e "${YELLOW}⚠️  Это удалит все ресурсы в namespace $NAMESPACE${NC}"
kubectl get all -n "$NAMESPACE"

echo ""
read -p "Продолжить удаление? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Отменено пользователем"
    exit 0
fi

# Сбор логов перед удалением
log_info "Сбор логов перед удалением..."
mkdir -p logs/final-logs
kubectl logs --all-containers --namespace="$NAMESPACE" \
    --ignore-errors > logs/final-logs/all-pods-$(date +%Y%m%d-%H%M%S).log 2>/dev/null || true

# Проверяем способ развертывания и удаляем соответственно
if command -v helm &> /dev/null && helm list -n "$NAMESPACE" | grep -q qa-app; then
    log_info "Найден Helm релиз, удаляем через Helm..."
    helm uninstall qa-app -n "$NAMESPACE"
    log_success "Helm релиз удален"
fi

log_info "Удаление всех ресурсов в namespace..."

# Удаляем все ресурсы в namespace
kubectl delete all --all -n "$NAMESPACE" --grace-period=30 --timeout=60s

# Удаляем дополнительные ресурсы
resource_types=(
    "configmaps"
    "secrets"
    "persistentvolumeclaims" 
    "ingresses"
    "networkpolicies"
)

for resource in "${resource_types[@]}"; do
    if kubectl get "$resource" -n "$NAMESPACE" --no-headers 2>/dev/null | grep -q .; then
        log_info "Удаление $resource..."
        kubectl delete "$resource" --all -n "$NAMESPACE" --timeout=30s
    fi
done

log_info "Удаление namespace..."
kubectl delete namespace "$NAMESPACE" --timeout=60s

# Проверяем успешность удаления
log_info "Проверка удаления..."
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    log_warning "Namespace все еще существует, принудительное удаление..."
    kubectl delete namespace "$NAMESPACE" --force --grace-period=0 || true
fi

# Очистка локальных файлов
log_info "Очистка локальных файлов..."
rm -rf logs/port-forward.pid logs/deployment-info.txt 2>/dev/null || true

log_success "QA окружение удалено!"

# Показываем оставшиеся ресурсы (если есть)
echo ""
log_info "Проверка оставшихся ресурсов..."
remaining_pods=$(kubectl get pods --all-namespaces --field-selector=metadata.namespace=="$NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [[ $remaining_pods -gt 0 ]]; then
    log_warning "Остались поды в namespace $NAMESPACE:"
    kubectl get pods --all-namespaces --field-selector=metadata.namespace=="$NAMESPACE"
else
    log_success "Все ресурсы успешно удалены"
fi

echo ""
echo "🎉 Удаление завершено!"
echo "====================="
echo "• Namespace $NAMESPACE удален"
echo "• Логи сохранены в logs/final-logs/"
echo "• Для повторного развертывания: ./scripts/deploy-qa.sh"
