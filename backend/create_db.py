from db import db  # Import user_db specifically
from app import app
from config import DevelopmentConfig  # Import the appropriate config
import models

# Apply the configuration to the app
app.config.from_object(DevelopmentConfig)

# Create the database tables
def create_database():
    with app.app_context():
        db.create_all()
        print("User database tables created successfully.")

if __name__ == '__main__':
    create_database()
