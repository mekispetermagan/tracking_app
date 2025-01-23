# This module handles requests with admin privileges

from flask import Blueprint, request, jsonify
from db import db
from models import (
    User, 
    RoleType, 
    UserRole, 
    Mentor, 
    Country, 
    Student, 
    Course, 
    MentorCourse,
    SessionLog, 
    SessionLogStudent
    )
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash
from sqlalchemy import or_

admin_bp = Blueprint('admin', __name__)

# Routes:
# /userdata         user data by id
# /mentorlist       all mentors
# /countrylist      all countries
# /studentlist      all students
# /courselist       all courses
# /manage_mentor    adds or edits user and mentor data
# /manage_course    adds or edits course data
# /manage_student   adds or edits student data
# /studentprogress  progress data for student

# Get data of specific user

@admin_bp.route('/userdata', methods=['POST'])
@jwt_required()
def get_user_data():
    data = request.get_json()
    if not data.id:
        return jsonify({"msg": "Missing data"}), 400
    try:
        user = User.query.filter(id == data.id).first()
        user_id = data.id
        first_name = user.first_name
        last_name = user.last_name
        email = user.email
        return jsonify({user_id, first_name, last_name, email})

    except Exception as err:
        return jsonify({"msg": "User not found: "+str(err), "error": str(err)}), 500

# Get all mentor data
@admin_bp.route('/mentorlist', methods=['POST'])
@jwt_required()
def get_mentor_list():
    mentors = Mentor.query.all()
    emails = [
        User.query.filter(User.id == mentor.user_id).first().email
        for mentor in mentors
        ]
    return jsonify([
        {   
            "id": mentor.id,
            "user_id": mentor.user_id,
            "first_name": mentor.first_name,
            "last_name": mentor.last_name,
            "preferred_language": mentor.preferred_language,
            "country_id": mentor.country_id,
            "active": mentor.active,
            "email": emails[i]
        }
        for i, mentor in enumerate(mentors)
        ]), 200

# TODO: switch to same method in shared
# Get the list of countries with English name
@admin_bp.route('/countrylist', methods=['POST'])
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


# Get all student data
@admin_bp.route('/studentlist', methods=['POST'])
@jwt_required()
def get_student_list():
    students = [
        { 
            "id": student.id,
            "first_name": student.first_name,
            "last_name": student.last_name,
            "country_id": student.country_id,
            "birth_year": student.birth_year,
            "active": student.active,
            "courses": [course.id for course in student.courses] 
        }
         for student in Student.query.all()]
    return jsonify(students), 200

# Get all course data

@admin_bp.route('/courselist', methods=['POST'])
@jwt_required()
def get_course_list():
    courses = [
        { 
            "id": course.id,
            "name": course.name,
            "description": course.description,
            "country_id": course.country_id,
            "active": course.active,
            # important: mentors assigned by id, not user_id
            "mentors": [mentor.id for mentor in course.mentors]
        }
         for course in Course.query.all()]
    return jsonify(courses)

# Add or edit mentor

@admin_bp.route('/manage_mentor', methods=['POST'])
@jwt_required()
def manage_mentor():
    data = request.get_json()
    print(data)
    # unpack data
    mode = data.get("mode") # "add" or "edit"
    user_id = data.get("userId") # None if mode = "add"
    first_name = data.get("firstName")
    last_name = data.get("lastName")
    preferred_language = data.get("preferredLanguage")
    country_id = data.get("countryId")
    email = data.get("email")
    pwd_unchanged = data.get("pwdUnchanged")
    password = data.get("password")
    active = data.get("active")
     
    # Input validation
    if not all([
        first_name, last_name, preferred_language, country_id, email, password
        ]):
        return jsonify({"msg": "Missing data"}), 400
    if mode == "add": # add new user and mentor records
        try:
            # Create new user record
            new_user = User(
                email=email,
                password_hash=generate_password_hash(password)
            )
            db.session.add(new_user)
            db.session.flush() # so that user gets an id
            if active:
                # Assign mentor role
                db.session.add(UserRole(user_id=new_user.id, role=RoleType.MENTOR))
            #create new mentor record
            db.session.add(Mentor(
                user_id=new_user.id,
                first_name=first_name, 
                last_name=last_name,
                preferred_language=preferred_language,
                country_id=country_id,
                active=active))
            db.session.commit()
            return jsonify({"msg": "New mentor added.", "user_id": new_user.id})
        except Exception as err:
            return jsonify({"msg": "Mentor couldn't be added: "+str(err), "error": str(err)}), 500
    else: # edit existing user and mentor records
        try:
            user = User.query.filter(User.id == user_id).first()
            user.email = email
            user.first_name = first_name
            user.last_name = last_name
            if not pwd_unchanged:
                user.password_hash=generate_password_hash(password)
            mentor = Mentor.query.filter(Mentor.user_id == user_id).first()
            mentor.first_name = first_name
            print(mentor.first_name, type(mentor.first_name))
            mentor.last_name = last_name
            mentor.preferred_language = preferred_language
            mentor.country_id = country_id
            mentor.active = active
            db.session.commit()
            return jsonify({
                "msg": "Mentor edited successfully.", 
                "user_id": user_id
                })
        except Exception as err:
            return jsonify({"msg": "Mentor couldn't be edited: "+str(err), "error": str(err)}), 500    

# Add or edit course

@admin_bp.route('/manage_course', methods=["POST"])
@jwt_required()
def manage_course():
    data = request.get_json()
    print(data)
    if data["mode"] == "add":
        try: 
            course = Course(
                name=data["name"],
                description=data["description"],
                country_id=data["country_id"],
            )
            print("course:", course)
            db.session.add(course)
            db.session.flush()
            mentor_links = [
                MentorCourse(
                    mentor_id=mentor_id,
                    course_id = course.id
                )
                for mentor_id in data["mentorIds"]
            ]
            print("mentor-links:", mentor_links)
            db.session.add_all(mentor_links)
            db.session.commit()
            return jsonify({
                "msg": "New course added.", 
                "id": course.id
                })
        except Exception as err:
            print(str(err))
            return jsonify({
                "msg": "Course couldn't be added: "+str(err), 
                "error": str(err)
                }), 500
    elif data["mode"] == "edit":
        try:
            course = Course.query.filter(Course.id == data["course_id"]).first()
            course.name = data["name"]
            course.description = data["description"]
            course.country_id = data["country_id"]
            course.mentors = Mentor.query.filter(Mentor.id.in_(data["mentorIds"])).all()
            db.session.commit()
            return jsonify({
                "msg": "Course edited.", 
                "id": course.id
                })
        except Exception as err:
            return jsonify({
                "msg": "Course couldn't be edited: "+str(err), 
                "error": str(err)
                }), 500
    else:
        return jsonify({"msg": "Unknown mode parameter."}), 500

# Track student progress
@admin_bp.route('/studentprogress', methods=['POST'])
@jwt_required()
def get_student_progress():
    data = request.get_json()
    student_id = data["student_id"]
    progress_records = (
        db.session.query(SessionLog)
        .join(SessionLogStudent, SessionLog.id == SessionLogStudent.session_log_id)
        .filter(SessionLogStudent.student_id == student_id)
        .all()
    )
    return jsonify([
        {
            "size": record.size,
            "level": record.level,
            "skills": [
                skill.id
                for skill in record.skills
            ]
        }
        for record in progress_records
    ])
