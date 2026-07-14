from fastapi import HTTPException
from sqlalchemy.orm import Session

from models import Account, Country, Course, MentorProfile, Student
from schemas.management import CourseOut, MentorOut, StudentOut


def unique_ids(ids: list[int]) -> list[int]:
    return list(dict.fromkeys(ids))


def ensure_country_exists(db: Session, country_id: int | None):
    if country_id is not None and db.get(Country, country_id) is None:
        raise HTTPException(status_code=400, detail="Country not found")


def ensure_phone_available(db: Session, phone: str, current_account_id: int | None = None):
    query = db.query(Account).filter(Account.phone == phone)

    if current_account_id is not None:
        query = query.filter(Account.id != current_account_id)

    if query.first():
        raise HTTPException(status_code=409, detail="Phone number already exists")


def get_courses_by_ids(db: Session, course_ids: list[int]) -> list[Course]:
    course_ids = unique_ids(course_ids)

    if not course_ids:
        return []

    courses = db.query(Course).filter(Course.id.in_(course_ids)).all()

    if len(courses) != len(course_ids):
        raise HTTPException(status_code=400, detail="Invalid course id")

    return courses


def get_mentors_by_ids(db: Session, mentor_ids: list[int]) -> list[MentorProfile]:
    mentor_ids = unique_ids(mentor_ids)

    if not mentor_ids:
        return []

    mentors = db.query(MentorProfile).filter(MentorProfile.id.in_(mentor_ids)).all()

    if len(mentors) != len(mentor_ids):
        raise HTTPException(status_code=400, detail="Invalid mentor id")

    return mentors


def get_students_by_ids(db: Session, student_ids: list[int]) -> list[Student]:
    student_ids = unique_ids(student_ids)

    if not student_ids:
        return []

    students = db.query(Student).filter(Student.id.in_(student_ids)).all()

    if len(students) != len(student_ids):
        raise HTTPException(status_code=400, detail="Invalid student id")

    return students


def mentor_course_ids(mentor: MentorProfile) -> set[int]:
    return {course.id for course in mentor.courses}


def course_visible_to_mentor(course: Course, mentor: MentorProfile) -> bool:
    return any(assigned.id == mentor.id for assigned in course.mentors)


def student_visible_to_mentor(student: Student, mentor: MentorProfile) -> bool:
    visible_course_ids = mentor_course_ids(mentor)
    return any(course.id in visible_course_ids for course in student.courses)


def apply_student_courses_as_admin(db: Session, student: Student, course_ids: list[int]):
    student.courses = get_courses_by_ids(db, course_ids)


def apply_student_courses_as_mentor(db: Session, student: Student, mentor: MentorProfile, course_ids: list[int]):
    requested_course_ids = set(unique_ids(course_ids))
    visible_course_ids = mentor_course_ids(mentor)

    if not requested_course_ids.issubset(visible_course_ids):
        raise HTTPException(status_code=403, detail="Cannot assign student to this course")

    requested_courses = get_courses_by_ids(db, list(requested_course_ids))
    outside_courses = [
        course for course in student.courses
        if course.id not in visible_course_ids
    ]

    student.courses = outside_courses + requested_courses


def mentor_to_out(mentor: MentorProfile) -> MentorOut:
    account = mentor.account

    return MentorOut(
        id=mentor.id,
        account_id=account.id,
        first_name=account.first_name,
        last_name=account.last_name,
        phone=account.phone,
        country_id=account.country_id,
        preferred_language=account.preferred_language,
        active=account.active and mentor.active,
        course_ids=[course.id for course in mentor.courses],
    )


def course_to_out(course: Course) -> CourseOut:
    return CourseOut(
        id=course.id,
        name=course.name,
        description=course.description,
        country_id=course.country_id,
        day_of_week=course.day_of_week,
        start_time=course.start_time,
        active=course.active,
        mentor_ids=[mentor.id for mentor in course.mentors],
        student_ids=[student.id for student in course.students],
    )

def student_to_out(student: Student) -> StudentOut:
    return StudentOut(
        id=student.id,
        first_name=student.first_name,
        last_name=student.last_name,
        origin_country_id=student.origin_country_id,
        birth_year=student.birth_year,
        gender=student.gender,
        active=student.active,
        course_ids=[course.id for course in student.courses],
    )