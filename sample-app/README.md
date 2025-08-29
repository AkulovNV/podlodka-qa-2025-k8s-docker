# 🚀 Sample App - QA DevOps Workshop

Демонстрационное Flask приложение для обучения контейнеризации и тестирования.

## 🏃‍♂️ Быстрый старт

### Локальный запуск
```bash
./run_local.sh
```

### Docker запуск
```bash
./run_docker.sh
```

### Тестирование
```bash
./test_app.sh
```

## 🔌 API Эндпоинты

- `GET /` - Главная страница
- `GET /health` - Health check
- `GET /ready` - Readiness check
- `GET /api/users` - Список пользователей
- `POST /api/users` - Создание пользователя
- `GET /api/stats` - Статистика приложения

## 🧪 Для тестирования

Приложение включает эндпоинты для демонстрации:
- HTTP статус коды
- JSON API ответы
- Health checks
- Симуляция ошибок

## 🐳 Docker

```bash
# Сборка
docker build -t sample-app .

# Запуск
docker run -p 5050:5050 sample-app

# С переменными окружения
docker run -p 5050:5050 -e FLASK_ENV=production sample-app
```
