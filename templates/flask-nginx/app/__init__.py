from flask import Flask, jsonify
import os

def create_app():
    app = Flask(__name__)
    app.config["APP_NAME"] = os.getenv("APP_NAME", "flask-nginx-svc")

    @app.get("/")
    def index():
        return jsonify(message=f"Hello from {app.config['APP_NAME']}!")

    @app.get("/health")
    def health():
        return jsonify(status="ok")

    return app
