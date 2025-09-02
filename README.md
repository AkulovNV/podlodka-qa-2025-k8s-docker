# QA DevOps Workshop: Containerization and Testing

> **QA workshop on containerization, microservice testing, and deployment strategies**
> 
> This repository contains practical examples for testing containerized applications using Docker and Kubernetes.

![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)
![Pytest](https://img.shields.io/badge/Pytest-0A9EDC?style=flat&logo=pytest&logoColor=white)

## 📋 Содержание

- [Обзор](#обзор)
- [Структура репозитория](#структура-репозитория)
- [Быстрый старт](#быстрый-старт)
- [Модули](#модули)
- [Требования](#требования)
- [Установка](#установка)
- [Использование](#использование)
- [Примеры](#примеры)
- [Troubleshooting](#troubleshooting)
- [Участие в разработке](#участие-в-разработке)

## 🎯 Обзор

Этот репозиторий демонстрирует современные подходы к тестированию контейнеризованных приложений:

- **Контейнеризация тестов** с Docker
- **Тестирование микросервисной архитектуры** с Docker Compose
- **Деплой и тестирование в Kubernetes**
- **Лучшие практики** DevOps для QA

### Что вы изучите

✅ Создание тестовых контейнеров  
✅ Интеграционное тестирование микросервисов  
✅ Управление тестовыми средами  
✅ CI/CD для контейнеризованных приложений  
✅ Мониторинг и отладка в контейнерах  

## 📁 Структура репозитория

```
podlodka-qa-2025-k8s-docker/
│
├── 01-tests-in-container/          # Контейнеризация тестов
│   ├── tests/                      # Набор тестов
│   ├── src/                        # Тестовые утилиты
│   ├── scripts/                    # Скрипты управления
│   └── Dockerfile                  # Образ для тестов
│
├── 02-microservice-testing/        # Тестирование микросервисов
│   ├── app/                        # FastAPI приложение
│   ├── tests/                      # Интеграционные тесты
│   ├── mocks/                      # Mock-сервисы
│   ├── db/                         # Настройки БД
│   └── docker-compose.yml          # Оркестрация сервисов
│
├── 03-qa-environment-k8s/          # Kubernetes окружение
│   ├── k8s/                        # Kubernetes манифесты
│   ├── deploy.sh                   # Деплой скрипт
│   └── validate.sh                 # Валидация окружения
│
├── sample-app/                     # Демонстрационное приложение
├── scripts/                       # Глобальные скрипты
└── README.md                       # Этот файл
```

## 🚀 Быстрый старт

### Предварительные требования

Убедитесь, что у вас установлены:

```bash
# Проверить Docker
docker --version

# Проверить Docker Compose
docker-compose --version

# Проверить Kubernetes (опционально)
kubectl version --client
```

### Запуск

1. **Клонируйте репозиторий**
   ```bash
   git clone <repository-url>
   cd podlodka-qa-2025-k8s-docker
   ```

2. **Запустите быструю демонстрацию**
   ```bash
   # Настройка окружения
   ./scripts/setup-environment.sh
   
   # Запуск простых тестов
   cd 01-tests-in-container
   ./scripts/run_in_docker.sh
   ```

3. **Тестирование микросервисов**
   ```bash
   cd 02-microservice-testing
   ./scripts/start_environment.sh
   ./scripts/run_tests.sh
   ```

## 📚 Модули

### 🐳 Модуль 1: Тесты в контейнерах

**Цель:** Изучить контейнеризацию тестов для обеспечения консистентности и переносимости.

**Что изучается:**
- Создание Dockerfile для тестов
- Управление зависимостями
- Объемы и сети для тестов
- Отладка в контейнерах

**Запуск:**
```bash
cd 01-tests-in-container
./scripts/run_in_docker.sh
```

[📖 Подробная документация](01-tests-in-container/README.md)

---

### 🏗 Модуль 2: Тестирование микросервисов

**Цель:** Освоить тестирование сложных микросервисных архитектур с использованием Docker Compose.

**Что изучается:**
- Оркестрация с Docker Compose
- Интеграционное тестирование
- Mock-сервисы и тестовые данные
- Health checks и зависимости

**Компоненты:**
- **FastAPI приложение** - основной микросервис
- **PostgreSQL** - база данных
- **Mock-сервер** - имитация внешних API
- **Pytest контейнер** - автоматизированные тесты

**Запуск:**
```bash
cd 02-microservice-testing
docker-compose up -d
docker-compose run --rm tests
```

[📖 Подробная документация](02-microservice-testing/README.md)

---

### ☸️ Модуль 3: QA окружение в Kubernetes

**Цель:** Развертывание и тестирование приложений в Kubernetes кластере.

**Что изучается:**
- Kubernetes манифесты для тестирования
- Управление конфигурацией и секретами
- Стратегии деплоя
- Мониторинг и логирование

**Запуск:**
```bash
cd 03-qa-environment-k8s
./deploy.sh
./validate.sh
```

[📖 Подробная документация](03-qa-environment-k8s/k8s/README.md)

---

### 📱 Демонстрационное приложение

**Простое Flask приложение** для демонстрации базовых концепций.

```bash
cd sample-app
./run_docker.sh
```

## ⚙️ Требования

### Обязательные

| Инструмент | Версия | Описание |
|------------|--------|----------|
| **Docker** | 20.10+ | Контейнеризация приложений |
| **Docker Compose** | 2.0+ | Оркестрация контейнеров |
| **Python** | 3.11+ | Язык программирования |
| **Git** | 2.0+ | Система контроля версий |

### Опциональные

| Инструмент | Версия | Для модуля |
|------------|--------|------------|
| **kubectl** | 1.25+ | Kubernetes (модуль 3) |
| **minikube** | 1.28+ | Локальный K8s кластер |
| **curl** | любая | Тестирование API |

## 🛠 Установка

### Автоматическая установка

```bash
# Проверка предварительных требований
./scripts/check-prerequisites.sh

# Автоматическая настройка окружения
./scripts/setup-environment.sh
```

### Ручная установка

<details>
<summary>Развернуть инструкции</summary>

1. **Установите Docker**
   ```bash
   # macOS
   brew install docker docker-compose
   
   # Ubuntu
   sudo apt update
   sudo apt install docker.io docker-compose
   
   # Добавьте пользователя в группу docker
   sudo usermod -aG docker $USER
   ```

2. **Создайте виртуальное окружение Python**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/macOS
   # или
   venv\Scripts\activate     # Windows
   ```

3. **Установите зависимости**
   ```bash
   pip install -r requirements.txt
   ```

</details>

## 🎮 Использование

### Основные команды

```bash
# Проверка состояния всех модулей
./scripts/check-all-modules.sh

# Сброс всех окружений
./scripts/cleanup-all.sh

# Демо с нуля
./scripts/demo-reset.sh
```

### Работа с модулями

```bash
# Модуль 1: Простые тесты
cd 01-tests-in-container && ./scripts/run_tests.sh

# Модуль 2: Микросервисы  
cd 02-microservice-testing && ./scripts/start_environment.sh

# Модуль 3: Kubernetes
cd 03-qa-environment-k8s && ./deploy.sh
```

## 📝 Примеры

### Пример 1: Запуск интеграционных тестов

```bash
cd 02-microservice-testing

# Запуск всей инфраструктуры
docker-compose up -d

# Ожидание готовности сервисов
docker-compose ps

# Запуск тестов
docker-compose run --rm tests

# Просмотр результатов
open reports/integration-report.html
```

### Пример 2: Отладка неудачных тестов

```bash
# Просмотр логов приложения
docker-compose logs app

# Подключение к контейнеру для отладки
docker-compose exec app /bin/bash

# Запуск отдельного теста
docker-compose run --rm tests pytest tests/test_specific.py -v
```

### Пример 3: Deployment в Kubernetes

```bash
cd 03-qa-environment-k8s

# Деплой всех компонентов
./deploy.sh

# Проверка состояния подов
kubectl get pods -n qa-microservice-testing

# Просмотр логов тестов
kubectl logs job/tests -n qa-microservice-testing
```

## 🔍 Troubleshooting

### Частые проблемы

<details>
<summary><b>Docker контейнеры не запускаются</b></summary>

```bash
# Проверьте статус Docker
docker info

# Очистите неиспользуемые ресурсы
docker system prune -a

# Перезапустите Docker Desktop
```
</details>

<details>
<summary><b>Тесты падают с сетевыми ошибками</b></summary>

```bash
# Проверьте доступность сервисов
docker-compose ps

# Проверьте логи сервисов
docker-compose logs

# Перезапустите окружение
docker-compose down && docker-compose up -d
```
</details>

<details>
<summary><b>Kubernetes поды в статусе Pending</b></summary>

```bash
# Проверьте события кластера
kubectl get events --sort-by=.metadata.creationTimestamp

# Проверьте ресурсы узлов
kubectl top nodes

# Описание проблемного пода
kubectl describe pod <pod-name> -n qa-microservice-testing
```
</details>

### Получение помощи

- 🐛 **Issues:** [GitHub Issues](link-to-issues)
- 💬 **Обсуждения:** [GitHub Discussions](link-to-discussions)  
- 📖 **Документация:** Проверьте README в каждом модуле
- 🔍 **Логи:** Всегда начинайте с анализа логов контейнеров

## 🤝 Участие в разработке

Мы приветствуем вклады в развитие проекта!

### Как внести вклад

1. **Fork** репозитория
2. Создайте **feature branch** (`git checkout -b feature/amazing-feature`)  
3. **Commit** ваши изменения (`git commit -m 'Add some amazing feature'`)
4. **Push** в branch (`git push origin feature/amazing-feature`)
5. Откройте **Pull Request**

### Стандарты кода

- Следуйте **PEP 8** для Python кода
- Добавляйте **тесты** для нового функционала
- Обновляйте **документацию**
- Используйте **осмысленные commit messages**

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл `LICENSE` для подробностей.

---

## 🌟 Дополнительные ресурсы

### Полезные ссылки

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Testing Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [FastAPI Testing](https://fastapi.tiangolo.com/tutorial/testing/)
- [Pytest Documentation](https://docs.pytest.org/)

### Похожие проекты

- [Testcontainers](https://www.testcontainers.org/)
- [KIND (Kubernetes in Docker)](https://kind.sigs.k8s.io/)
- [Tilt - Microservice Development](https://tilt.dev/)

---

<p align="center">
  <b>⭐ Если этот репозиторий был полезен, поставьте звездочку! ⭐</b>
</p>

<p align="center">
  Создано с ❤️ для QA DevOps Workshop 2025
</p>
