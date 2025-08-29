#!/bin/bash

# Kubernetes manifest validation script
set -e

echo "🔍 Validating Kubernetes Manifests"

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

echo "📋 Current Kubernetes context: $(kubectl config current-context)"
echo ""

# Function to validate manifest
validate_manifest() {
    local file=$1
    echo "📄 Validating $file..."
    
    if kubectl apply --dry-run=client -f "$file" > /dev/null 2>&1; then
        echo "✅ $file is valid"
    else
        echo "❌ $file has validation errors:"
        kubectl apply --dry-run=client -f "$file"
        return 1
    fi
}

# Validate all manifests
echo "🔍 Validating all manifest files..."
echo ""

cd "$(dirname "$0")"

for file in *.yaml; do
    validate_manifest "$file"
done

echo ""
echo "🎯 Checking Docker images availability..."

# Check if docker images exist
images=(
    "02-microservice-testing-app:latest"
    "02-microservice-testing-mock-server:latest" 
    "02-microservice-testing-tests:latest"
)

for image in "${images[@]}"; do
    if docker images | grep -q "${image%:*}"; then
        echo "✅ $image is available"
    else
        echo "⚠️  $image is not built yet"
        echo "   Run 'docker-compose build' to build required images"
    fi
done

echo ""
echo "📊 Cluster resource check..."
echo "Nodes:"
kubectl get nodes --no-headers 2>/dev/null | wc -l | xargs echo "  Available nodes:"

echo ""
echo "Storage Classes:"
kubectl get storageclass --no-headers 2>/dev/null | head -3

echo ""
echo "✅ All manifests are valid and ready for deployment!"
echo ""
echo "🚀 To deploy, run: ./deploy.sh"
echo "📋 To see what will be deployed: kubectl apply --dry-run=server -f ."
