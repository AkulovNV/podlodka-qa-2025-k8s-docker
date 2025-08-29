from flask import Flask, jsonify, request, make_response
from flask_cors import CORS
import json
import os
import logging
import time
import random
from datetime import datetime

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Разрешаем CORS для всех доменов

# Путь к файлам с заготовленными ответами
RESPONSES_PATH = os.getenv("RESPONSES_PATH", "/app/responses")

# Глобальные переменные для симуляции состояния
request_count = 0
start_time = time.time()


def load_response(filename: str):
    """Загрузить заготовленный ответ из файла"""
    filepath = os.path.join(RESPONSES_PATH, filename)
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
            logger.info(f"Loaded response from {filename}")
            return data
    except FileNotFoundError:
        logger.error(f"Response file {filename} not found")
        return {"error": f"Response file {filename} not found"}
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in {filename}: {e}")
        return {"error": f"Invalid JSON in {filename}"}


@app.before_request
def log_request():
    """Логирование каждого запроса"""
    global request_count
    request_count += 1
    logger.info(f"Request #{request_count}: {request.method} {request.url}")


@app.after_request
def log_response(response):
    """Логирование ответов"""
    logger.info(f"Response: {response.status_code}")
    return response


@app.route('/health')
def health():
    """Health check для mock-сервера"""
    uptime = int(time.time() - start_time)
    return jsonify({
        "status": "healthy", 
        "service": "mock-server",
        "uptime_seconds": uptime,
        "requests_served": request_count,
        "timestamp": datetime.utcnow().isoformat()
    })


@app.route('/status')
def status():
    """Подробная информация о статусе mock-сервера"""
    return jsonify({
        "service": "QA Mock Server",
        "version": "1.0.0",
        "uptime_seconds": int(time.time() - start_time),
        "requests_served": request_count,
        "endpoints": [
            "/health",
            "/status", 
            "/orders/<user_id>",
            "/orders (POST)",
            "/payments/<order_id>",
            "/users/<user_id>/profile",
            "/simulate-error/<status_code>",
            "/slow-response/<delay>"
        ],
        "timestamp": datetime.utcnow().isoformat()
    })


@app.route('/orders/<int:user_id>')
def get_user_orders(user_id: int):
    """Получить заказы пользователя (mock)"""
    logger.info(f"Getting orders for user {user_id}")
    
    orders_data = load_response("orders.json")
    
    if "error" in orders_data:
        return jsonify(orders_data), 500
    
    # Фильтруем заказы по user_id
    user_orders = [
        order for order in orders_data.get("orders", []) 
        if order.get("user_id") == user_id
    ]
    
    response = {"orders": user_orders}
    logger.info(f"Found {len(user_orders)} orders for user {user_id}")
    
    return jsonify(response), 200


@app.route('/orders', methods=['POST'])
def create_order():
    """Создать заказ (mock)"""
    logger.info("Creating new order")
    
    try:
        order_data = request.get_json()
        
        if not order_data:
            return jsonify({"error": "No JSON data provided"}), 400
        
        # Валидация
        required_fields = ["user_id", "items", "total"]
        for field in required_fields:
            if field not in order_data:
                logger.error(f"Missing required field: {field}")
                return jsonify({"error": f"Missing field: {field}"}), 400
        
        # Генерируем уникальный ID заказа
        order_id = random.randint(10000, 99999)
        
        # Создаем mock ответ
        mock_order = {
            "id": order_id,
            "user_id": order_data["user_id"],
            "items": order_data["items"],
            "total": order_data["total"],
            "status": "created",
            "created_at": datetime.utcnow().isoformat() + "Z",
            "mock": True  # Помечаем как mock данные
        }
        
        logger.info(f"Created mock order with ID: {order_id}")
        return jsonify(mock_order), 201
        
    except Exception as e:
        logger.error(f"Error creating order: {e}")
        return jsonify({"error": "Internal server error"}), 500


@app.route('/payments/<int:order_id>')
def get_payment_status(order_id: int):
    """Получить статус платежа (mock)"""
    logger.info(f"Getting payment status for order {order_id}")
    
    payments_data = load_response("payments.json")
    
    if "error" in payments_data:
        return jsonify(payments_data), 500
    
    # Ищем платеж по order_id
    payment = next(
        (p for p in payments_data.get("payments", []) if p.get("order_id") == order_id), 
        None
    )
    
    if payment:
        logger.info(f"Found payment for order {order_id}")
        return jsonify(payment), 200
    else:
        logger.info(f"No payment found for order {order_id}")
        return jsonify({"error": "Payment not found"}), 404


@app.route('/users/<int:user_id>/profile')
def get_user_profile(user_id: int):
    """Получить профиль пользователя (mock)"""
    logger.info(f"Getting profile for user {user_id}")
    
    users_data = load_response("users.json")
    
    if "error" in users_data:
        return jsonify(users_data), 500
    
    user = next(
        (u for u in users_data.get("users", []) if u.get("id") == user_id), 
        None
    )
    
    if user:
        logger.info(f"Found profile for user {user_id}")
        return jsonify(user), 200
    else:
        logger.info(f"No profile found for user {user_id}")
        return jsonify({"error": "User not found"}), 404


# Утилитарные эндпоинты для тестирования

@app.route('/simulate-error/<int:status_code>')
def simulate_error(status_code: int):
    """Симулировать ошибку с указанным статус-кодом"""
    logger.info(f"Simulating error with status code: {status_code}")
    
    error_messages = {
        400: "Bad Request - Simulated error",
        401: "Unauthorized - Simulated error",
        403: "Forbidden - Simulated error", 
        404: "Not Found - Simulated error",
        500: "Internal Server Error - Simulated error",
        503: "Service Unavailable - Simulated error"
    }
    
    message = error_messages.get(status_code, f"HTTP {status_code} - Simulated error")
    
    return jsonify({
        "error": message,
        "code": status_code,
        "simulated": True,
        "timestamp": datetime.utcnow().isoformat()
    }), status_code


@app.route('/slow-response/<int:delay>')
def slow_response(delay: int):
    """Ответ с задержкой (для тестирования таймаутов)"""
    delay = min(delay, 30)  # Ограничиваем максимальную задержку
    logger.info(f"Simulating slow response with {delay}s delay")
    
    time.sleep(delay)
    
    return jsonify({
        "message": f"Response after {delay} seconds",
        "delay_seconds": delay,
        "timestamp": datetime.utcnow().isoformat()
    })


@app.route('/random-response')
def random_response():
    """Случайный ответ для тестирования непредсказуемости"""
    responses = [
        ({"success": True, "data": "random_data"}, 200),
        ({"error": "Random failure"}, 500),
        ({"message": "Service temporarily unavailable"}, 503)
    ]
    
    response_data, status_code = random.choice(responses)
    logger.info(f"Random response: {status_code}")
    
    return jsonify(response_data), status_code


# Обработка ошибок
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "error": "Endpoint not found",
        "available_endpoints": [rule.rule for rule in app.url_map.iter_rules()]
    }), 404


@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal error: {error}")
    return jsonify({
        "error": "Internal server error",
        "message": "Something went wrong in the mock server"
    }), 500


if __name__ == '__main__':
    logger.info("Starting QA Mock Server...")
    logger.info(f"Responses path: {RESPONSES_PATH}")
    
    # Проверяем наличие файлов с данными
    for filename in ["orders.json", "payments.json", "users.json"]:
        filepath = os.path.join(RESPONSES_PATH, filename)
        if os.path.exists(filepath):
            logger.info(f"✅ Found response file: {filename}")
        else:
            logger.warning(f"⚠️  Missing response file: {filename}")
    
    app.run(host='0.0.0.0', port=8001, debug=True)