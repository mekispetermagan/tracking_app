import os
from db import db
from functools import wraps
from flask import jsonify, current_app
import datetime

# get or create subdirectory with absolute path
def get_subdir(dir_name):
    base_path = os.path.dirname(os.path.abspath(__file__))
    root_path = os.path.dirname(base_path)
    subdir = os.path.join(root_path, dir_name)
    os.makedirs(subdir, exist_ok=True)
    return subdir

# extracts value from data dictionary
def extract(name, data):
    value = data.get(name)
    if not value:
        raise ValueError(f"Missing data: {name}")
    return value

# fetches record from model
def fetch_record(name, value, class_name):
    if name == "id":
        record = db.session.get(class_name, value)
    else:
        record = class_name.query.filter(getattr(class_name, name) == value).first()
    if not record:
        raise LookupError(f"{name}:{value} not found in {class_name}")
    return record

# combines extract and fetch
def extract_and_fetch(name, class_name, data):
    value = extract(name, data)
    return fetch_record(name, value, class_name)

def validate_year(value):
    try:
        year = int(value)
    except ValueError:
        raise ValueError(f"Invalid year: {value} is not an integer.")
    if not (2025 <= year <= 2100):
        raise ValueError(f"Invalid year: {year} is out of valid range (2025–2100).")
    return year

def validate_month(value):
    try:
        month = int(value)
    except ValueError:
        raise ValueError(f"Invalid month: {value} is not an integer.")
    if not (1 <= month <= 12):
        raise ValueError(f"Invalid month: {month} is out of range (1–12).")
    return month

def validate_date(value):
    try: 
        return datetime.strptime(value, '%Y-%m-%d').date()
    except ValueError as err:
        raise ValueError(f"Invalid date format: {value}. Expected format is YYYY-MM-DD.") from err

def handle_exceptions(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except ValueError as e:
            return jsonify({"msg": str(e)}), 400
        except LookupError as e:
            return jsonify({"msg": str(e)}), 404
        except Exception as e:
            current_app.logger.error(f"Unexpected error: {str(e)}", exc_info=True)
            return jsonify({"msg": "An unexpected error occurred. Please try again later."}), 500
    return wrapper
