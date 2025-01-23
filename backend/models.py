from db import db
from datetime import datetime, timezone
from enum import Enum
from sqlalchemy import or_

###############
# User models #
###############

# role types as enums
class RoleType(Enum):
    ADMIN = "admin"
    MENTOR = "mentor"

# - multiple mentors can belong to the same user
class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)

# linking users to roles
class UserRole(db.Model):
    __tablename__ = 'user_roles'
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), primary_key=True)
    role = db.Column(db.Enum(RoleType), nullable=False, primary_key=True)

class LoginMascot(db.Model):
    __tablename__ = 'login_mascots'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)

class LoginColor(db.Model):
    __tablename__ = 'login_colors'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)

# simplified login for students (color, mascot)
class StudentUser(db.Model):
    __tablename__ = 'student_users'
    id = db.Column(db.Integer, primary_key=True)
    color_id = db.Column(
        db.Integer, 
        db.ForeignKey('login_colors.id'), 
        nullable=False
        )
    mascot_id = db.Column(
        db.Integer, 
        db.ForeignKey('login_mascots.id'), 
        nullable=False
        )

##############
# User roles #
##############

class Student(db.Model):
    __tablename__ = 'students'
    id = db.Column(db.Integer, primary_key=True)
    student_user_id = db.Column(db.Integer, db.ForeignKey('student_users.id'), nullable=False)
    first_name = db.Column(db.String(50), nullable=False)
    last_name = db.Column(db.String(50), nullable=False)
    country_id = db.Column(db.Integer, db.ForeignKey('countries.id'), nullable=True)
    birth_year = db.Column(db.Integer, nullable=True)
    active = db.Column(db.Boolean, default=True, nullable=False)
    courses = db.relationship(
        'Course', 
        secondary='student_courses', 
        back_populates='students'
        )

class Mentor(db.Model):
    __tablename__ = 'mentors'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    first_name = db.Column(db.String(50), nullable=False)
    last_name = db.Column(db.String(50), nullable=False)
    country_id = db.Column(db.Integer, db.ForeignKey('countries.id'), nullable=True)
    # languages are handled by frontend; hence no foreignkey
    preferred_language = db.Column(db.String(2))
    active = db.Column(db.Boolean, default=True, nullable=False)
    courses = db.relationship(
        'Course', 
        secondary='mentor_courses', 
        back_populates='mentors'
        )

###################
# User attributes #
###################

# three-letter codes for countries: "hun", "svk", "ukr"
class Country(db.Model):
    __tablename__ = 'countries'
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(10), unique=True, nullable=False)  # e.g. 'hun'
    name = db.Column(db.String(20), unique=True, nullable=False)  # e.g. 'Hungary'

    # finds a country by any clue, looking in all columns:
    @classmethod
    def find_country(cls, clue):
        return cls.query.filter(
            cls.id  == clue | 
            cls.code  == clue | 
            cls.name  == clue
            ).first()

    @classmethod
    def id_from_code(cls, code):
        return cls.query.filter(cls.code == code).first().id
    
    @classmethod
    def code_from_id(cls, id):
        return cls.query.filter(cls.id == id).first().code

class Course(db.Model):
    __tablename__ = 'courses'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=False)
    students = db.relationship(
        'Student', 
        secondary='student_courses', 
        back_populates='courses'
        )
    mentors = db.relationship(
        'Mentor', 
        secondary='mentor_courses', 
        back_populates='courses'
        )
    country_id = db.Column(db.Integer, db.ForeignKey('countries.id'), nullable=False)
    active = db.Column(db.Boolean, default=True, nullable=False)

# linking mentors to courses
class MentorCourse(db.Model):
    __tablename__ = 'mentor_courses'
    mentor_id = db.Column(db.Integer, db.ForeignKey('mentors.id'), primary_key=True)
    course_id = db.Column(db.Integer, db.ForeignKey('courses.id'), primary_key=True)

# linking students to courses
class StudentCourse(db.Model):
    __tablename__ = 'student_courses'
    student_id = db.Column(
        db.Integer, 
        db.ForeignKey('students.id'), 
        primary_key=True
        )
    course_id = db.Column(db.Integer, db.ForeignKey('courses.id'), primary_key=True)


###################
# Progress models #
###################

level_enum = db.Enum('novice', 'intermediate', 'advanced', 'master', name='project_levels')
age_group_enum = db.Enum('8-10', '11-14', '15+', name='age_groups')
project_size_enum = db.Enum('full_project', 'mini_project', name='project_sizes')

class CurriculumProject(db.Model):
    __tablename__ = 'curriculum_projects'
    id = db.Column(db.Integer, primary_key=True)
    level = db.Column(level_enum, nullable=False)
    age_group = db.Column(age_group_enum, nullable=False)
    size = db.Column(project_size_enum, nullable=False)
    skills = db.relationship('Skill', secondary='curriculum_project_skills')
    title = db.Column(db.String(100), nullable=False)

class Skill(db.Model):
    __tablename__ = 'skills'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)

class CurriculumProjectSkill(db.Model):
    __tablename__ = 'curriculum_project_skills'
    project_id = db.Column(
        db.Integer, 
        db.ForeignKey('curriculum_projects.id'), 
        primary_key=True
        )
    skill_id = db.Column(db.Integer, db.ForeignKey('skills.id'), primary_key=True)

class SessionLogStudent(db.Model):
    __tablename__ = 'session_log_students'
    session_log_id = db.Column(
        db.Integer, 
        db.ForeignKey('session_logs.id'), 
        primary_key=True
        )
    student_id = db.Column(
        db.Integer, 
        db.ForeignKey('students.id'), 
        primary_key=True
        )

class SessionLogSkill(db.Model):
    __tablename__ = 'session_log_skills'
    session_log_id = db.Column(db.Integer, db.ForeignKey('session_logs.id'), primary_key=True)
    skill_id = db.Column(db.Integer, db.ForeignKey('skills.id'), primary_key=True)

class SessionLog(db.Model):
    __tablename__ = 'session_logs'
    id = db.Column(db.Integer, primary_key=True)
    mentor_id = db.Column(db.Integer, db.ForeignKey('mentors.id'), nullable=False)
    course_id = db.Column(db.Integer, db.ForeignKey('courses.id'), nullable=False)
    date = db.Column(db.Date, default=lambda:datetime.now(timezone.utc), nullable=False)
    project_id = db.Column(
        db.Integer, 
        db.ForeignKey('curriculum_projects.id'), 
        nullable=True  # null: custom project
        )
    project_title = db.Column(db.String(100), nullable=False)
    size = db.Column(project_size_enum, nullable=False)
    level = db.Column(level_enum, nullable=False)
    skills = db.relationship('Skill', secondary='session_log_skills')
    students = db.relationship('Student', secondary='session_log_students')
    issues = db.Column(db.String(300), nullable=False)

##################
# Invoice models #
##################


class InvoiceData(db.Model):
    __tablename__ = "invoice_data"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), unique=True, nullable=False)
    name = db.Column(db.String(30), nullable=False)
    postal_code = db.Column(db.String(10), nullable=False)
    city = db.Column(db.String(20), nullable=False)
    street = db.Column(db.String(30), nullable=False)
    country = db.Column(db.String(20), nullable=False)
    number = db.Column(db.Integer, nullable=False)
    account_name = db.Column(db.String(30), nullable=False)
    account_address = db.Column(db.String(30), nullable=False)
    bank = db.Column(db.String(30), nullable=False)
    iban = db.Column(db.String(40), nullable=False)
    swift = db.Column(db.String(15), nullable=False)

class Invoice(db.Model):
    __tablename__ = "invoice"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    number = db.Column(db.Integer, nullable=False)
    date = db.Column(db.Date, default=lambda:datetime.now(timezone.utc), nullable=False)
    file_path = db.Column(db.String(60), nullable=False)
