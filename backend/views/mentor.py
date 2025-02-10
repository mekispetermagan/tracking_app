# TODO:
# refactor all functions with internal_utils.py, just like submit_story

# This module handles requests accessible with Mentor role

import os
import json
from flask import Blueprint, request, jsonify
from db import db
from models import (
    User,
    Mentor,
    CurriculumProject,
    SessionLog,
    Student,
    Skill,
    level_enum,
    project_size_enum,
    Course,
    Country,
    InvoiceData,
    Story,
    Photo
    )
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy.exc import IntegrityError
from datetime import datetime
from invoice.invoice import create_invoice
from send_email import send_invoice
from . import internal_utils as u

def record_to_dict(record):
    return {column.name: getattr(record, column.name) for column in record.__table__.columns}

mentor_bp = Blueprint('mentor', __name__)

# returns profile data based on the current token
@mentor_bp.route('/get_profile_data', methods=['POST'])
@jwt_required()
def get_profile_data():
    identity = json.loads(get_jwt_identity())
    id = identity.get("id", [])
    user = db.session.get(User, id)
    if not user:
        return jsonify({"msg": "User not found!"}), 404
    mentor = Mentor.query.filter(Mentor.user_id == id).first()
    if not mentor:
        return jsonify({"msg": "Mentor not found!"}), 404
    country_code = db.session.get(Country, mentor.country_id).code
    return jsonify({
        "email": user.email,
        "first_name": mentor.first_name,
        "last_name": mentor.last_name,
        "country_id": mentor.country_id,
        "country_code": country_code,
        "preferred_language": mentor.preferred_language,
        "active": mentor.active
    }), 200

# updates user and mentor data based on
# - the current token
# - the data received
@mentor_bp.route('/submit_profile', methods=['POST'])
@jwt_required()
def submit_profile():
    identity = json.loads(get_jwt_identity())
    id = identity.get("id", [])
    user = db.session.get(User, id)
    if not user:
        return jsonify({"msg": "User not found!"}), 404
    mentor = Mentor.query.filter(Mentor.user_id == id).first()
    if not mentor:
        return jsonify({"msg": "Mentor not found!"}), 404
    data = request.get_json()
    print(data)
    if data.get("first_name"):
        mentor.first_name = data["first_name"]
    if data.get("last_name"):
        mentor.last_name = data["last_name"]
    if data.get("country_id"):
        mentor.country_id = data["country_id"]
    if data.get("preferred_language"):
        mentor.preferred_language = data["preferred_language"]
    if data.get("active"):
        mentor.active = data["active"] == "on"
    db.session.commit();

    return jsonify({"msg": "under construction...",}), 200


# returns course and student data based on the current token
@mentor_bp.route('/get_courses', methods=['POST'])
@jwt_required()
def get_courses():
    try:
        identity = json.loads(get_jwt_identity())
        id = identity.get("id", [])
        mentor = Mentor.query.filter(Mentor.user_id == id).first()
        courses = mentor.courses
        course_dicts = [
            {
                "id": c.id,
                "name": c.name,
                "students": [
                    {
                        "id": s.id,
                        "first_name": s.first_name,
                        "last_name": s.last_name
                    }
                    for s in c.students
                ]
            }
            for c in courses
        ]
        return jsonify(course_dicts)

    except Exception as err:
        return jsonify({"msg": "Courses not found:", "error": str(err)}), 500

# returns mentor data based on the current token
@mentor_bp.route('/get_mentor_data', methods=['POST'])
@jwt_required()
def get_mentor_data():
    try:
        identity = json.loads(get_jwt_identity())
        id = identity.get("id", [])
        mentor = Mentor.query.filter(Mentor.user_id == id).first()
        language = mentor.preferred_language
        return jsonify({
            "id": mentor.id,
            "first_name": mentor.first_name,
            "last_name": mentor.last_name,
            "preferred_language": language
        })

    except Exception as err:
        return jsonify({"msg": "Mentor data not found:", "error": str(err)}), 500

# returns curriculum data
@mentor_bp.route('/get_curriculum', methods=['POST'])
@jwt_required()
def get_curriculum():
    try:
        curriculum = CurriculumProject.query.all()
        # list of project records:
        # { "id"   : 1,
        #   "title": "dino" }
        return jsonify([
            {
                "id": project.id,
                "title": project.title,
            }
            for project in curriculum
        ])

    except Exception as err:
        return jsonify({"msg": "Curriculum data not found:"+str(err), "error": str(err)}), 500

# submits session log
@mentor_bp.route('/session_log', methods=['POST'])
@jwt_required()
def session_log():
    data = request.get_json()
    print(data)
    # validate non-project-specific data
    mentor_id = data.get("mentor_id")
    date = data.get("date")
    course_id = data.get("course_id")
    student_ids = data.get("students")
    roma = data.get("roma")
    issues = data.get("issues")
    if not all([
        mentor_id, date, course_id, student_ids, roma, issues
        ]):
        return jsonify({"msg": "Missing data."}), 400
    try:
        date = datetime.strptime(date, '%Y-%m-%d').date()
    except Exception as err:
        return jsonify({"msg": "Wrong date format."}), 500
    mentor = db.session.get(Mentor, mentor_id)
    if not mentor:
        return jsonify({"msg": "Mentor not found."}), 404
    course = db.session.get(Course, course_id)
    if not course:
        return jsonify({"msg": "Course not found."}), 404
    students = []
    for id in student_ids:
        student = db.session.get(Student, id)
        if not student:
            return jsonify({"msg": f"Student with ID {id} not found."}), 404
        students.append(student)

    # validate project-specific data
    project_id = data.get("project_id")
    # curriculum project
    if project_id:
        project = db.session.get(CurriculumProject, project_id)
        if not project:
            return jsonify({"msg": "Project not found."}), 404
        skills = project.skills
        level = project.level
        project_title = project.title
        size = project.size
    # custom project
    else:
        project_title = data.get("project_title")
        size = data.get("size")
        level = data.get("level")
        skills = data.get("skills")
        if not all([
            project_title, size, level, skills
            ]):
            return jsonify({"msg": "Missing data."}), 400
        if size not in project_size_enum.enums:
            return jsonify({"msg": "Level not found."}), 404
        if level not in level_enum.enums:
            return jsonify({"msg": "Level not found."}), 404
        skills = []
    for name in data["skills"]:
        skill = Skill.query.filter(Skill.name == name).first()
        if not skill:
            return jsonify({"msg": f"Skill '{name}' not found."}), 404
        skills.append(skill)

    # valid data: data submitted
    session_log = SessionLog(
        mentor_id=data["mentor_id"],
        course_id=data["course_id"],
        date=date,
        project_id=data["project_id"],
        project_title=project_title,
        size=size,
        level=level,
        students=students,
        roma=roma,
        skills=skills,
        issues=data["issues"]
    )
    db.session.add(session_log)
    db.session.commit()
    return jsonify({
        "msg": "Submission successful."
    }), 200

# Get mentor's student data
@mentor_bp.route('/studentlist', methods=['POST'])
@jwt_required()
def get_student_list():
    try:
        identity = json.loads(get_jwt_identity())
        user_id = identity["id"]
        mentor = Mentor.query.filter(Mentor.user_id == user_id).first()
        course_ids = [course.id for course in mentor.courses]
        students = Student.query.filter(
            Student.courses.any(Course.id.in_(course_ids))
        ).all()
        return jsonify([
            {
                "id": student.id,
                "first_name": student.first_name,
                "last_name": student.last_name,
                "country_id": student.country_id,
                "birth_year": student.birth_year,
                "gender": student.gender,
                "courses": [course.id for course in student.courses]
            }
            for student in students
            ])
    except Exception as err:
        return jsonify({"msg": "Student query failed: "+str(err), "error": str(err)}), 500


# Get mentor's course data
@mentor_bp.route('/courselist', methods=['POST'])
@jwt_required()
def get_course_list():
    try:
        identity = json.loads(get_jwt_identity())
        user_id = identity["id"]
        mentor = Mentor.query.filter(Mentor.user_id == user_id).first()
        return jsonify([
            {
                "id": course.id,
                "name": course.name,
                "description": course.description,
            }
            for course in mentor.courses
            ])
    except Exception as err:
        return jsonify({"msg": "Student query failed: "+str(err), "error": str(err)}), 500

# Get the list of countries in all languages
@mentor_bp.route('/countrylist', methods=['POST'])
@jwt_required()
def get_country_list():
    countries = [
        {
            "id": country.id,
            "code": country.code,
            "en": country.en,
            "hu": country.hu,
            "ua": country.ua,
        }
         for country in Country.query.all()]
    return jsonify(countries), 200


# provides invoice data to pre-fill form
@mentor_bp.route('/get_invoice_data', methods=['POST'])
@jwt_required()
def get_invoice_data():
    data = request.get_json()
    id = json.loads(get_jwt_identity())["id"]
    mentor = Mentor.query.filter(Mentor.user_id == id).first()
    if not mentor:
        return jsonify({"msg": "Mentor not found!"}), 404
    invoice_data = InvoiceData.query.filter(InvoiceData.user_id == id).first()
    if not invoice_data:
        name = " ".join([mentor.first_name, mentor.last_name])
        invoice_data = InvoiceData(
            user_id=id,
            name=name,
            postal_code="",
            city="",
            street="",
            country="",
            number=1,
            account_name=name,
            account_address="",
            bank="",
            iban="",
            swift=""
        )
        db.session.add(invoice_data)
        db.session.commit()
    return jsonify(record_to_dict(invoice_data))

# submits invoice
@mentor_bp.route('/submit_invoice', methods=['POST'])
@jwt_required()
def submit_invoice():
    data = request.get_json()
    print(data)
    user_id = json.loads(get_jwt_identity())["id"]
    mentor = Mentor.query.filter(Mentor.user_id == user_id).first()
    if not mentor:
        return jsonify({"msg": "Mentor not found!"}), 404

    # step 1: update invoice data in the database
    valid_keys = {col.name for col in InvoiceData.__table__.columns if col.name not in ["id", "user_id"]}
    update_data = {k: v for k, v in data.items() if k in valid_keys}
    print("valid_keys:", valid_keys)
    print("update_data.keys():", update_data.keys())
    if (
        valid_keys != update_data.keys() or
        "date" not in data.keys() or
        "period" not in data.keys()
        ):
        return jsonify({"msg": "Missing data!"}), 400
    update_data["number"] = int(update_data["number"]) + 1
    update_data["user_id"] = user_id
    invoice_data = InvoiceData.query.filter(InvoiceData.user_id == user_id).first()
    if not invoice_data:
        invoice_data = InvoiceData(**update_data)
        db.session.add(invoice_data)
    else:
        for key, value in update_data.items():
            setattr(invoice_data, key, value)
    db.session.commit()

    # step 2: create invoice
    template_data = {f"{{{{{k}}}}}": v for k, v in data.items()}
    invoice_file = create_invoice(template_data, user_id)

    # step 3: email invoice
    send_invoice(
        {
            "name": invoice_data.name,
            "number": data["number"],
            "period": data["period"]},
        invoice_file
        )

    return jsonify({"msg": "Submission successful!"}), 200

# submits story
@mentor_bp.route('/submit_story', methods=['POST'])
@jwt_required()
@u.handle_exceptions
def submit_story():
    data = request.get_json()
    print(data)
    course_id = u.extract("course_id", data)
    year = u.validate_year(u.extract("year", data))
    month = u.validate_month(u.extract("month", data))
    story = u.extract("story", data)
    identity = json.loads(get_jwt_identity())
    user_id = identity["id"]
    mentor_id = Mentor.query.filter(Mentor.user_id == user_id).first().id
    story_record = Story(
        mentor_id=mentor_id,
        course_id=course_id,
        year=year,
        month=month,
        story=story
    )
    db.session.add(story_record)
    db.session.commit()
    return jsonify({
        "msg": "Submission successful."
    }), 200

# submits photos
@mentor_bp.route('/submit_photos', methods=['POST'])
@jwt_required()
@u.handle_exceptions
def submit_photos():
    date_str = request.form.get("date")
    date = datetime.strptime(date_str, "%Y-%m-%d") if date_str else None
    image_files = request.files.getlist("image-file")
    print(image_files)
    photo_dir = u.get_subdir("mentor_photos")
    user_id = json.loads(get_jwt_identity())["id"]
    mentor = u.fetch_record("user_id", user_id, Mentor)
    mentor_id = mentor.id
    country_id = mentor.country_id
    for file in image_files:
        if file and file.filename:
            new_filename = f"{mentor_id}_{file.filename}"
            file_path = os.path.join(photo_dir, new_filename)
            file.save(file_path)
            record = Photo(
                date=date,
                mentor_id=mentor_id,
                country_id=country_id,
                filename=new_filename,
            )
            db.session.add(record)
    try:
        db.session.commit()
        return jsonify({
            "msg": "Submission successful."
        }), 200
    except IntegrityError as e:
        db.session.rollback()
        raise ValueError("A photo with this filename already exists.")
