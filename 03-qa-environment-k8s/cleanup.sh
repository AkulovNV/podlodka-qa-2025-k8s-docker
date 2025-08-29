#!/bin/bash

# Cleanup script for microservice testing environment
set -e

NAMESPACE="qa-microservice-testing"

echo "🗑️ Cleaning up Microservice Testing Environment"
echo "=============================================="

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "ℹ️ Namespace $NAMESPACE does not exist. Nothing to clean up."
    exit 0
fi

echo "📋 Current resources in $NAMESPACE:"
kubectl get all -n $NAMESPACE

echo ""
read -p "🤔 Are you sure you want to delete all resources in namespace $NAMESPACE? (y/N): " confirm

if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    echo "❌ Cleanup cancelled."
    exit 0
fi

echo ""
echo "🧹 Deleting namespace $NAMESPACE (this will remove all resources)..."

kubectl delete namespace $NAMESPACE

echo "⏳ Waiting for namespace to be fully deleted..."
while kubectl get namespace $NAMESPACE &> /dev/null; do
    echo -n "."
    sleep 2
done

echo ""
echo "✅ Cleanup completed! All resources have been removed."
echo ""
echo "💡 To redeploy, run: ./deploy.sh"
