#!/bin/bash
# ===========================================
# Файл: 03-qa-environment-k8s/scripts/deploy-qa.sh
# ===========================================

set -e

echo "☸️  Развертывание QA окружения в Kubernetes..."
echo "=============================================="

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
    log_error "kubectl не найден. Установите kubectl."
    exit 1
fi

# Проверяем подключение к кластеру
if ! kubectl cluster-info &> /dev/null; then
    log_error "Нет подключения к Kubernetes кластеру"
    echo "💡 Возможные решения:"
    echo "   • Запустите minikube: minikube start"
    echo "   • Проверьте kubeconfig: kubectl config current-context"
    echo "   • Используйте Docker Desktop Kubernetes"
    exit 1
fi

# Проверяем, что мы в правильной директории
if [[ ! -d "manifests" ]]; then
    log_error "Директория manifests/ не найдена. Запускайте из 03-qa-environment-k8s/"
    exit 1
fi

# Создаем директорию для логов
mkdir -p logs
log_info "Создана директория logs/"

NAMESPACE="qa-environment"
DEPLOYMENT_METHOD="manifests"

# Выбор способа развертывания
echo "🛠 Способы развертывания:"
echo "1. Kubernetes манифесты (manifests/)"
echo "2. Helm чарт (helm/qa-app/)"
echo "3. Только namespace и базовые ресурсы"

read -p "Выберите способ (1-3, по умолчанию 1): " method_choice
case ${method_choice:-1} in
    2) DEPLOYMENT_METHOD="helm" ;;
    3) DEPLOYMENT_METHOD="basic" ;;
    *) DEPLOYMENT_METHOD="manifests" ;;
esac

log_info "Проверка текущего состояния namespace..."
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    log_warning "Namespace $NAMESPACE уже существует"
    read -p "Пересоздать namespace? Это удалит все ресурсы! (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete namespace "$NAMESPACE"
        log_info "Namespace удален, создаем новый..."
        sleep 5
    fi
fi

if [[ "$DEPLOYMENT_METHOD" == "helm" ]]; then
    # Развертывание с помощью Helm
    log_info "Развертывание с помощью Helm..."
    
    # Проверяем наличие Helm
    if ! command -v helm &> /dev/null; then
        log_error "Helm не найден. Установите Helm или выберите другой способ."
        exit 1
    fi
    
    # Создаем namespace
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Устанавливаем чарт
    helm upgrade --install qa-app ./helm/qa-app/ \
        --namespace "$NAMESPACE" \
        --values ./helm/qa-app/values.yaml \
        --wait \
        --timeout 300s || {
        log_error "Ошибка при установке Helm чарта"
        exit 1
    }
    
    log_success "Helm чарт установлен"

elif [[ "$DEPLOYMENT_METHOD" == "basic" ]]; then
    # Базовое развертывание
    log_info "Базовое развертывание..."
    
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
  labels:
    purpose: qa-testing
    environment: qa
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: qa-demo-app
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: qa-demo-app
  template:
    metadata:
      labels:
        app: qa-demo-app
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: qa-demo-app-service
  namespace: $NAMESPACE
spec:
  selector:
    app: qa-demo-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

    log_success "Базовые ресурсы созданы"

else
    # Развертывание через манифесты
    log_info "Развертывание через Kubernetes манифесты..."
    
    # Проверяем корректность манифестов
    log_info "Валидация манифестов..."
    if kubectl apply --dry-run=client -f manifests/ > /dev/null 2>&1; then
        log_success "Манифесты валидны"
    else
        log_error "Ошибки в манифестах"
        exit 1
    fi
    
    # Применяем манифесты
    kubectl apply -f manifests/
    log_success "Манифесты применены"
fi

# Ожидание готовности подов
log_info "Ожидание готовности подов..."
kubectl wait --for=condition=ready pod \
    --selector=app=qa-app \
    --namespace="$NAMESPACE" \
    --timeout=300s || {
    log_warning "Поды не стали готовыми за 5 минут"
    log_info "Проверка состояния подов:"
    kubectl get pods -n "$NAMESPACE"
}

# Показываем состояние развертывания
echo ""
log_info "Состояние развертывания:"
echo "========================"

echo "📦 Поды:"
kubectl get pods -n "$NAMESPACE" -o wide

echo ""
echo "🔌 Сервисы:"
kubectl get services -n "$NAMESPACE" -o wide

echo ""
echo "🚀 Deployments:"
kubectl get deployments -n "$NAMESPACE" -o wide

# Показываем полезную информацию
echo ""
echo "🎉 QA окружение развернуто!"
echo "=========================="

# Получаем информацию о доступе
SERVICE_NAME=$(kubectl get services -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')
SERVICE_PORT=$(kubectl get services -n "$NAMESPACE" -o jsonpath='{.items[0].spec.ports[0].port}')

echo -e "${GREEN}Способы доступа к приложению:${NC}"
echo "• Port forward: kubectl port-forward -n $NAMESPACE svc/$SERVICE_NAME 8080:$SERVICE_PORT"
echo "• Внутри кластера: http://$SERVICE_NAME.$NAMESPACE.svc.cluster.local:$SERVICE_PORT"

# Проверяем ingress если есть
if kubectl get ingress -n "$NAMESPACE" &> /dev/null; then
    echo "• Ingress: $(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[0].spec.rules[0].host}')"
fi

echo ""
echo -e "${BLUE}Полезные команды:${NC}"
echo "• kubectl get all -n $NAMESPACE                    # все ресурсы"
echo "• kubectl logs -f deployment/qa-app -n $NAMESPACE  # логи приложения"
echo "• kubectl describe pod <pod-name> -n $NAMESPACE    # детали пода"
echo "• ./scripts/port-forward.sh                        # настройка port-forward"
echo "• ./scripts/get-logs.sh                           # сбор всех логов"
echo "• ./scripts/destroy-qa.sh                         # удаление окружения"

# Сохраняем информацию о развертывании
cat > logs/deployment-info.txt <<EOF
QA Environment Deployment Info
==============================
Date: $(date)
Namespace: $NAMESPACE
Method: $DEPLOYMENT_METHOD
Cluster: $(kubectl config current-context)

Resources:
$(kubectl get all -n "$NAMESPACE")

Port Forward Command:
kubectl port-forward -n $NAMESPACE svc/$SERVICE_NAME 8080:$SERVICE_PORT
EOF

log_success "Информация о развертывании сохранена в logs/deployment-info.txt"