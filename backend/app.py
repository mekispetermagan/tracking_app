import env_setup
from flask import Flask
from flask_jwt_extended import JWTManager
from views import (
    auth_bp, 
    admin_bp, 
    mentor_bp,
    shared_bp,
    student_bp
    )  # blueprints are packed in views
from db import db
from config import DevelopmentConfig, ProductionConfig
import os
from flask_cors import CORS
from datetime import timedelta

# Initialize Flask app
app = Flask(__name__)

# Tokens expire in 1 hour
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=1)

# Needed for development in case two different instances are needed from two different ports.
# CORS(app, origins=["http://localhost:10001", "http://localhost:10002"])

print(os.environ.get('FLASK_ENV'))
# Load config based on environment variable
if os.environ.get('FLASK_ENV') == 'production':
    app.config.from_object(ProductionConfig)
    CORS(app, origins=['https://afterschoolgeekery.org'])  # Explicitly allow production origin
else:
    app.config.from_object(DevelopmentConfig)
    CORS(app, origins=['http://localhost:10001'])  # Allow local testing


# Initialize Extensions for both databases
db.init_app(app)  # Initialize database
jwt = JWTManager(app)  # Initialize JWT manager

# Register Blueprints
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(admin_bp, url_prefix='/api/admin')
app.register_blueprint(mentor_bp, url_prefix='/api/mentor')
app.register_blueprint(shared_bp, url_prefix='/api/shared')
app.register_blueprint(student_bp, url_prefix='/api/student')

# Run the app
if __name__ == '__main__':
    app.run(debug=True, port=5000)
