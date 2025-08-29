# Развертывание Kubernetes для среды тестирования микросервисов

Данная директория содержит манифесты Kubernetes, которые дублируют те же сервисы из конфигурации Docker Compose.

## Обзор архитектуры

Развертывание Kubernetes включает те же сервисы, что и docker-compose:

- **База данных PostgreSQL** - Постоянная база данных с инициализационными скриптами
- **Mock Server** - API-сервер на Flask с JSON-файлами ответов
- **Основное приложение** - Микросервис на FastAPI
- **Тесты** - Задание Kubernetes для запуска автоматических тестов

## Предварительные требования

1. **Docker-образы**: Сначала создайте образы с помощью docker-compose
   ```bash
   cd ../  # Перейти в корень проекта
   docker-compose build
   ```

2. **Кластер Kubernetes**: Убедитесь, что у вас есть доступ к кластеру Kubernetes
   - Локальная разработка: Docker Desktop, Minikube или Kind
   - Облако: EKS, GKE, AKS и т.д.

3. **kubectl**: Инструмент командной строки Kubernetes, настроенный с доступом к кластеру

## Быстрое развертывание

### Вариант 1: Автоматический скрипт
```bash
./deploy.sh
```

### Вариант 2: Ручное развертывание
```bash
# Развернуть ресурсы по порядку
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-configmaps-secrets.yaml
kubectl apply -f 02-postgres.yaml
kubectl apply -f 03-mock-server.yaml
kubectl apply -f 04-app.yaml

# Дождаться готовности всех сервисов, затем развернуть тесты
kubectl apply -f 05-tests.yaml
```

## Структура файлов

```
k8s/
├── 00-namespace.yaml           # Пространство имен для изоляции
├── 01-configmaps-secrets.yaml  # Конфигурация и чувствительные данные
├── 02-postgres.yaml            # База данных с постоянным хранилищем
├── 03-mock-server.yaml         # Mock API-сервер
├── 04-app.yaml                 # Основное FastAPI-приложение
├── 05-tests.yaml               # Задание для тестов
├── deploy.sh                   # Скрипт автоматического развертывания
└── README.md                   # Этот файл
```

## Сервисы и ресурсы

### Пространство имен
- **Имя**: `qa-microservice-testing`
- **Назначение**: Изоляция всех ресурсов

### База данных PostgreSQL
- **Развертывание**: `postgres`
- **Сервис**: `postgres:5432`
- **Хранилище**: Постоянный том 1Gi
- **Учетные данные**: Хранятся в `postgres-secret`
- **Инициализация**: SQL-скрипт из ConfigMap

### Mock Server
- **Развертывание**: `mock-server`
- **Сервис**: `mock-server:8001`
- **Данные**: JSON-ответы из ConfigMap
- **Проверка здоровья**: `/health`

### Основное приложение
- **Развертывание**: `app`
- **Сервис**: `app:8000` (внутренний), `app-external:30080` (внешний)
- **База данных**: Автоматически подключается к PostgreSQL
- **Внешний API**: Указывает на mock-server
- **Проверки здоровья**: `/health` (живучесть), `/ready` (готовность)

### Тесты
- **Тип**: Задание Kubernetes
- **Назначение**: Запуск автоматических тестов против развернутых сервисов
- **Зависимости**: Ожидает готовности app и mock-server

## Конфигурация

### Переменные окружения
Вся конфигурация управляется через ConfigMaps и Secrets:

- **Конфигурация БД**: ConfigMap `postgres-config`
- **Учетные данные БД**: Secret `postgres-secret`
- **Конфигурация приложения**: ConfigMap `app-config`
- **Конфигурация Mock Server**: ConfigMap `mock-server-config`
- **Конфигурация тестов**: ConfigMap `tests-config`

### Секреты
Учетные данные базы данных хранятся безопасно:
```yaml
postgres-secret:
  username: user
  password: password
  database: testdb
```

## Доступ и тестирование

### Доступ к сервисам
- **Внешний**: http://localhost:30080 (NodePort)
- **Внутренний**: http://app:8000 (ClusterIP)

### Проверки здоровья
```bash
# Проверка здоровья
curl http://localhost:30080/health

# Проверка готовности (включает статус базы данных и внешнего сервиса)
curl http://localhost:30080/ready
```

### Запуск тестов
```bash
# Развернуть задание с тестами
kubectl apply -f 05-tests.yaml

# Проверить результаты тестов
kubectl logs -n qa-microservice-testing job/tests
```

## Мониторинг и устранение неисправностей

### Просмотр ресурсов
```bash
# Все ресурсы в пространстве имен
kubectl get all -n qa-microservice-testing

# Поды с метками
kubectl get pods -n qa-microservice-testing --show-labels

# Сервисы и эндпоинты
kubectl get svc,endpoints -n qa-microservice-testing
```

### Просмотр логов
```bash
# Логи приложения
kubectl logs -n qa-microservice-testing deployment/app -f

# Логи базы данных
kubectl logs -n qa-microservice-testing deployment/postgres -f

# Логи mock-сервера
kubectl logs -n qa-microservice-testing deployment/mock-server -f

# Логи тестов
kubectl logs -n qa-microservice-testing job/tests
```

### Отладка
```bash
# Описание ресурсов для устранения неисправностей
kubectl describe pod -n qa-microservice-testing

# Выполнение команд в контейнерах
kubectl exec -n qa-microservice-testing deployment/app -it -- /bin/bash
kubectl exec -n qa-microservice-testing deployment/postgres -it -- psql -U user -d testdb
```

### Перенаправление портов
```bash
# Перенаправление порта приложения для локального доступа (альтернатива NodePort)
kubectl port-forward -n qa-microservice-testing svc/app 8000:8000

# Перенаправление порта базы данных для прямого доступа
kubectl port-forward -n qa-microservice-testing svc/postgres 5432:5432

# Перенаправление порта mock-сервера
kubectl port-forward -n qa-microservice-testing svc/mock-server 8001:8001
```

## Отличия от Docker Compose

### Преимущества
- **Масштабируемость**: Легко масштабировать развертывания
- **Проверки здоровья**: Нативные для Kubernetes пробы живучести и готовности
- **Управление ресурсами**: Лимиты и запросы CPU и памяти
- **Обнаружение сервисов**: Автоматическое разрешение DNS
- **Хранилище**: Постоянные тома для базы данных
- **Безопасность**: Управление секретами
- **Наблюдаемость**: Богатые возможности мониторинга и логирования

### Изменения конфигурации
- **Переменные окружения**: Перенесены в ConfigMaps и Secrets
- **Монтирование томов**: JSON-файлы монтируются из ConfigMaps
- **Сеть**: Связь на основе сервисов вместо docker-сетей
- **Зависимости**: Init-контейнеры и пробы готовности вместо `depends_on`

## Очистка

### Удалить все
```bash
kubectl delete namespace qa-microservice-testing
```

### Удалить конкретные ресурсы
```bash
kubectl delete -f 05-tests.yaml
kubectl delete -f 04-app.yaml
kubectl delete -f 03-mock-server.yaml
kubectl delete -f 02-postgres.yaml
kubectl delete -f 01-configmaps-secrets.yaml
kubectl delete -f 00-namespace.yaml
```

## Соображения для продуктивного развертывания

Для продуктивных развертываний рассмотрите:

1. **Реестр образов**: Загрузите образы в контейнерный реестр вместо использования локальных образов
2. **Ingress**: Используйте Ingress-контроллеры вместо NodePort для внешнего доступа
3. **TLS**: Добавьте TLS-сертификаты и HTTPS
4. **Лимиты ресурсов**: Настройте лимиты CPU и памяти на основе нагрузочного тестирования
5. **Горизонтальное автомасштабирование подов**: Автомасштабирование на основе метрик
6. **Постоянное хранилище**: Используйте подходящий StorageClass для вашей среды
7. **Мониторинг**: Добавьте метрики и мониторинг Prometheus
8. **Логирование**: Централизованное логирование с ELK или аналогичным стеком
9. **Безопасность**: Стандарты безопасности подов, сетевые политики, RBAC
10. **Резервное копирование**: Процедуры резервного копирования базы данных и аварийного восстановления
