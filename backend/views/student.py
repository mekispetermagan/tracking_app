from flask import Blueprint, request, jsonify
from db import db
from models import (
    Student, 
    StudentUser,
    SessionLog,
    SessionLogStudent
    )

student_bp = Blueprint('student', __name__)

@student_bp.route("/get_student_data", methods=["POSt"])
def get_student_data():
    data = request.get_json()
    if not data["id"]:
        return jsonify({"msg": "Missing data!"}), 400
    print(data["id"])
    try:
        user_id = data["id"]
        student_user = StudentUser.query.filter(
            StudentUser.id == user_id
            ).first()
        color_id = student_user.color_id
        mascot_id = student_user.mascot_id
        student = Student.query.filter(
            Student.student_user_id == user_id
            ).first()
        first_name = student.first_name
        last_name = student.last_name
        return jsonify({
            "id": data["id"], 
            "color_id": color_id, 
            "mascot_id": mascot_id,
            "first_name": first_name,
            "last_name": last_name
            })
    except Exception as err:
        return  jsonify({
            "msg": "Student user not found."+str(err),
            "error": str(err)
            }), 500

@student_bp.route("/get_student_progress", methods=["POSt"])
def get_student_progress():
    data = request.get_json()
    if not data["id"]:
        return jsonify({"msg": "Missing data!"}), 400
    print(data["id"])
    try:
        user_id = data["id"]
        student = Student.query.filter(
            Student.student_user_id == user_id
            ).first()
        first_name = student.first_name
        last_name = student.last_name
        student_id = student.id
        progress_records = (
        db.session.query(SessionLog)
            .join(SessionLogStudent, SessionLog.id == SessionLogStudent.session_log_id)
            .filter(SessionLogStudent.student_id == student_id)
            .all()
        )

        return jsonify({
            "id": data["id"], 
            "first_name": first_name,
            "last_name": last_name,
            "progress": [
                {
                    "size": record.size,
                    "level": record.level,
                    "skills": [
                        skill.id
                        for skill in record.skills
                    ]
                }
                for record in progress_records
            ]
            })
    except Exception as err:
        return  jsonify({
            "msg": "Student not found."+str(err),
            "error": str(err)
            }), 500
