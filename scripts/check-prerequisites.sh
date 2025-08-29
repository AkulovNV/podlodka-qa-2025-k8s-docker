#!/bin/bash
# ===========================================
# Файл: scripts/check-prerequisites.sh
# ===========================================

set -e  # Остановить при первой ошибке

echo "🔍 Проверка необходимых инструментов для QA DevOps Workshop..."
echo "=================================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для проверки команды
check_command() {
    local cmd=$1
    local name=$2
    local required=$3
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✅ $name установлен${NC}"
        if [[ "$cmd" == "docker" ]]; then
            echo "   Версия: $(docker --version)"
            # Проверяем, что Docker daemon запущен
            if docker info &> /dev/null; then
                echo -e "${GREEN}   ✅ Docker daemon запущен${NC}"
            else
                echo -e "${RED}   ❌ Docker daemon не запущен${NC}"
                echo "   💡 Запустите Docker Desktop или systemctl start docker"
                if [[ "$required" == "true" ]]; then
                    exit 1
                fi
            fi
        elif [[ "$cmd" == "python3" ]]; then
            echo "   Версия: $(python3 --version)"
        elif [[ "$cmd" == "kubectl" ]]; then
            echo "   Версия: $(kubectl version --client --short 2>/dev/null || echo 'kubectl version error')"
            # Проверяем доступ к кластеру
            if kubectl cluster-info &> /dev/null; then
                echo -e "${GREEN}   ✅ Есть доступ к Kubernetes кластеру${NC}"
            else
                echo -e "${YELLOW}   ⚠️  Нет доступа к Kubernetes кластеру${NC}"
            fi
        elif [[ "$cmd" == "helm" ]]; then
            echo "   Версия: $(helm version --short 2>/dev/null || echo 'helm version error')"
        elif [[ "$cmd" == "git" ]]; then
            echo "   Версия: $(git --version)"
        fi
    else
        if [[ "$required" == "true" ]]; then
            echo -e "${RED}❌ $name не установлен (обязательно)${NC}"
            exit 1
        else
            echo -e "${YELLOW}⚠️  $name не установлен (опционально)${NC}"
        fi
    fi
}

# Функция проверки Python пакетов
check_python_packages() {
    echo -e "\n${BLUE}📦 Проверка Python пакетов...${NC}"
    
    local packages=("requests" "pytest" "selenium")
    for pkg in "${packages[@]}"; do
        if python3 -c "import $pkg" &> /dev/null; then
            echo -e "${GREEN}✅ Python пакет '$pkg' доступен${NC}"
        else
            echo -e "${YELLOW}⚠️  Python пакет '$pkg' не установлен${NC}"
            echo "   💡 Установите: pip3 install $pkg"
        fi
    done
}

# Функция проверки портов
check_ports() {
    echo -e "\n${BLUE}🔌 Проверка доступности портов...${NC}"
    
    local ports=(8000 8001 5432)
    for port in "${ports[@]}"; do
        if lsof -i :$port &> /dev/null || netstat -tuln 2>/dev/null | grep :$port &> /dev/null; then
            echo -e "${YELLOW}⚠️  Порт $port занят${NC}"
        else
            echo -e "${GREEN}✅ Порт $port свободен${NC}"
        fi
    done
}

# Основные проверки
echo -e "${BLUE}🔧 Основные инструменты:${NC}"
check_command "docker" "Docker" "true"
check_command "python3" "Python 3" "true"  
check_command "git" "Git" "true"

echo -e "\n${BLUE}☸️  Kubernetes инструменты:${NC}"
check_command "kubectl" "kubectl" "false"
check_command "helm" "Helm" "false"

# Дополнительные проверки
check_python_packages
check_ports

# Проверка места на диске
echo -e "\n${BLUE}💾 Проверка места на диске...${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    available_space=$(df -h . | tail -1 | awk '{print $4}')
    echo -e "${GREEN}✅ Доступно места: $available_space${NC}"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    available_space=$(df -h . | tail -1 | awk '{print $4}')
    echo -e "${GREEN}✅ Доступно места: $available_space${NC}"
else
    # Windows (Git Bash)
    echo -e "${YELLOW}⚠️  Проверьте наличие свободного места (рекомендуется 5+ GB)${NC}"
fi

# Создание тестовых директорий
echo -e "\n${BLUE}📁 Создание рабочих директорий...${NC}"
mkdir -p {reports,logs,artifacts}
echo -e "${GREEN}✅ Рабочие директории созданы${NC}"

echo -e "\n${GREEN}🎉 Проверка завершена!${NC}"
echo "=================================================="
echo -e "${BLUE}💡 Для полного функционала рекомендуется:${NC}"
echo "   • Docker Desktop запущен"
echo "   • Python 3.8+"
echo "   • kubectl (для Kubernetes примеров)"
echo "   • 5+ GB свободного места"