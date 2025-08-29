from flask import Flask, jsonify, request
import os

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "demo-app"})

@app.route('/api/users')
def get_users():
    return jsonify([
        {"id": 1, "name": "Test User 1", "email": "user1@example.com"},
        {"id": 2, "name": "Test User 2", "email": "user2@example.com"}
    ])

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    return jsonify({
        "id": 123,
        "name": data.get("name"),
        "email": data.get("email"),
        "created": True
    }), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
