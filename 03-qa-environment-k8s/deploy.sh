#!/bin/bash

# Скрипт деплоя приложений на которых будут запускаться тесты
set -e

echo "🚀 Deploying Microservice Testing Environment to Kubernetes"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we have a current context
if ! kubectl config current-context &> /dev/null; then
    echo "❌ No Kubernetes context is set"
    exit 1
fi

# Function to wait for deployment to be ready
wait_for_deployment() {
    local deployment=$1
    local namespace=$2
    echo "⏳ Waiting for deployment $deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$deployment -n $namespace
}

# Function to wait for job completion
wait_for_job() {
    local job=$1
    local namespace=$2
    echo "⏳ Waiting for job $job to complete..."
    kubectl wait --for=condition=complete --timeout=300s job/$job -n $namespace
}

echo "📦 Deploying Kubernetes resources..."

# Deploy in order
echo "1️⃣ Creating namespace..."
kubectl apply -f k8s/00-namespace.yaml

echo "2️⃣ Creating ConfigMaps and Secrets..."
kubectl apply -f k8s/01-configmaps-secrets.yaml

echo "3️⃣ Deploying PostgreSQL database..."
kubectl apply -f k8s/02-postgres.yaml
wait_for_deployment "postgres" "qa-microservice-testing"

echo "4️⃣ Deploying Mock Server..."
kubectl apply -f k8s/03-mock-server.yaml
wait_for_deployment "mock-server" "qa-microservice-testing"

echo "5️⃣ Deploying Main Application..."
kubectl apply -f k8s/04-app.yaml
wait_for_deployment "app" "qa-microservice-testing"

echo "✅ All services deployed successfully!"

# Show service status
echo "📊 Service Status:"
kubectl get pods -n qa-microservice-testing

echo ""
echo "🌐 Services available at:"
echo "   Main App: http://localhost:30080"
echo "   Health Check: http://localhost:30080/health"
echo "   Ready Check: http://localhost:30080/ready"
echo ""
echo "📝 To deploy tests, run:"
echo "   kubectl apply -f k8s/05-tests.yaml"
echo ""
echo "🔍 To view logs:"
echo "   kubectl logs -n qa-microservice-testing deployment/app"
echo "   kubectl logs -n qa-microservice-testing deployment/mock-server"
echo "   kubectl logs -n qa-microservice-testing deployment/postgres"
echo ""
echo "🗑️ To cleanup:"
echo "   kubectl delete namespace qa-microservice-testing"
