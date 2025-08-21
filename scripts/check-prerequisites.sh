#!/bin/bash

echo "🔍 Проверка необходимых инструментов..."

# Проверка Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker установлен: $(docker --version)"
    if docker info &> /dev/null; then
        echo "✅ Docker демон запущен"
    else
        echo "❌ Docker демон не запущен"
        exit 1
    fi
else
    echo "❌ Docker не установлен"
    exit 1
fi

# Проверка Python
if command -v python3 &> /dev/null; then
    echo "✅ Python установлен: $(python3 --version)"
else
    echo "❌ Python 3 не установлен"
    exit 1
fi

# Проверка kubectl (опционально)
if command -v kubectl &> /dev/null; then
    echo "✅ kubectl установлен: $(kubectl version --client)"
else
    echo "⚠️  kubectl не установлен (нужен для Kubernetes части)"
fi

# Проверка Helm (опционально)
if command -v helm &> /dev/null; then
    echo "✅ Helm установлен: $(helm version --short)"
else
    echo "⚠️  Helm не установлен (нужен для части с Helm чартами)"
fi

echo ""
echo "🎉 Проверка завершена!"
