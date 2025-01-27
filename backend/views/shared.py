# This module handles requests accessible with both admin 
# and mentor roles.

import json
from flask import Blueprint, request, jsonify
from db import db
from models import (
    User,
    Country,
    Course,
    StudentUser,
    Student
    )
from flask_jwt_extended import jwt_required, get_jwt_identity

shared_bp = Blueprint('common', __name__)


# Get user's email
@shared_bp.route('/get_email', methods=['POST'])
@jwt_required()
def get_email():
    identity = json.loads(get_jwt_identity())
    id = identity.get("id")
    user = db.session.get(User, id)
    email = user.email
    return jsonify({"email": email}), 200


# Get the list of countries with English name
@shared_bp.route('/countrylist', methods=['POST'])
@jwt_required()
def get_country_list():
    countries = [
        { 
            "id": country.id,
            "code": country.code,
            "name": country.name,
        }
         for country in Country.query.all()]
    return jsonify(countries), 200


# Add or edit student
@shared_bp.route('/manage_student', methods=["POST"])
@jwt_required()
def manage_student():
    data = request.get_json()
    print(data)
    if not all(data.get(key) for key in [
        "first_name", 
        "last_name",
        "country_id",
        "birth_year", 
        "gender",
        "course_ids",
        "active"
        ]):
        return jsonify({"msg": "Missing data!"}), 400
    course_ids = data["course_ids"]
    courses = Course.query.filter(Course.id.in_(course_ids)).all()
    if len(courses) != len(course_ids):
        return jsonify({"msg": "Invalid course IDs."}), 400
    # existing student: modify records
    if data["student_id"]:
        student = Student.query.get(data["student_id"])
        if not student:
            return jsonify({"msg": "Student not found!"}), 404
        user_id = student.student_user_id
        student_user = StudentUser.query.get(user_id)
        if not student_user:
            return jsonify({"msg": "Student user not found!"}), 404
        student.first_name = data["first_name"]
        student.last_name = data["last_name"]
        student.country_id = data["country_id"]
        student.birth_year = data["birth_year"]
        student.gender = data["gender"]
        student.active = data["active"]
        student.courses = courses
        db.session.commit()
        return jsonify({"msg": "Student updated successfully."}), 200
    # new student: create records
    else:
        student_user = StudentUser(
            color_id = 2,
            mascot_id = 2
            )
        db.session.add(student_user)
        db.session.flush()
        user_id = student_user.id
        student = Student(
            student_user_id = user_id,
            first_name = data["first_name"],
            last_name = data["last_name"],
            country_id = data["country_id"],
            birth_year = data["birth_year"],
            gender = data["gender"],
            active = data["active"],
            courses = courses
            )
        db.session.add(student)
        db.session.commit()
        return jsonify({"msg": "Student added successfully."}), 200
