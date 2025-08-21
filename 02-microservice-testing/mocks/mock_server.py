from flask import Flask, jsonify, request
import json
import os
from typing import Dict, Any


app = Flask(__name__)

# Путь к файлам с заготовленными ответами
RESPONSES_PATH = "/app/responses"


def load_response(filename: str) -> Dict[Any, Any]:
    """Загрузить заготовленный ответ из файла"""
    filepath = os.path.join(RESPONSES_PATH, filename)
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        return {"error": f"Response file {filename} not found"}
    except json.JSONDecodeError:
        return {"error": f"Invalid JSON in {filename}"}


@app.route('/health')
def health():
    """Health check для mock-сервера"""
    return jsonify({"status": "healthy", "service": "mock-server"})


@app.route('/orders/<int:user_id>')
def get_user_orders(user_id: int):
    """Получить заказы пользователя (mock)"""
    orders = load_response("orders.json")
    
    # Фильтруем заказы по user_id
    user_orders = [order for order in orders.get("orders", []) if order.get("user_id") == user_id]
    
    if user_orders:
        return jsonify({"orders": user_orders})
    else:
        return jsonify({"orders": []}), 200


@app.route('/orders', methods=['POST'])
def create_order():
    """Создать заказ (mock)"""
    order_data = request.get_json()
    
    # Валидация
    required_fields = ["user_id", "items", "total"]
    for field in required_fields:
        if field not in order_data:
            return jsonify({"error": f"Missing field: {field}"}), 400
    
    # Создаем mock ответ
    mock_order = {
        "id": 12345,  # Фиксированный ID для предсказуемости в тестах
        "user_id": order_data["user_id"],
        "items": order_data["items"],
        "total": order_data["total"],
        "status": "created",
        "created_at": "2023-12-01T10:00:00Z"
    }
    
    return jsonify(mock_order), 201


@app.route('/payments/<int:order_id>')
def get_payment_status(order_id: int):
    """Получить статус платежа (mock)"""
    payments = load_response("payments.json")
    
    # Ищем платеж по order_id
    payment = next((p for p in payments.get("payments", []) if p.get("order_id") == order_id), None)
    
    if payment:
        return jsonify(payment)
    else:
        return jsonify({"error": "Payment not found"}), 404


@app.route('/users/<int:user_id>/profile')
def get_user_profile(user_id: int):
    """Получить профиль пользователя (mock)"""
    users = load_response("users.json")
    
    user = next((u for u in users.get("users", []) if u.get("id") == user_id), None)
    
    if user:
        return jsonify(user)
    else:
        return jsonify({"error": "User not found"}), 404


# Эндпоинт для имитации ошибок (полезно для тестирования error handling)
@app.route('/simulate-error/<int:status_code>')
def simulate_error(status_code: int):
    """Симулировать ошибку с указанным статус-кодом"""
    error_messages = {
        400: "Bad Request",
        401: "Unauthorized",
        403: "Forbidden",
        404: "Not Found",
        500: "Internal Server Error",
        503: "Service Unavailable"
    }
    
    message = error_messages.get(status_code, "Unknown Error")
    return jsonify({"error": message}), status_code


# Эндпоинт для имитации медленного ответа
@app.route('/slow-response/<int:delay>')
def slow_response(delay: int):
    """Ответ с задержкой (для тестирования таймаутов)"""
    import time
    time.sleep(min(delay, 30))  # Ограничиваем максимальную задержку
    return jsonify({"message": f"Response after {delay} seconds"})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8001, debug=True)