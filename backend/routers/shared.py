from dataclasses import dataclass
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from config import settings
from database import get_db
from models import Account, AdminProfile, Course, MentorProfile, Student
from routers._management import (
    apply_student_courses_as_admin,
    apply_student_courses_as_mentor,
    course_to_out,
    course_visible_to_mentor,
    ensure_country_exists,
    get_courses_by_ids,
    get_mentors_by_ids,
    get_students_by_ids,
    mentor_course_ids,
    student_to_out,
    student_visible_to_mentor,
    unique_ids,
)
from schemas.management import (
    CourseOut,
    CourseUpdateRequest,
    SharedMentorOut,
    StudentCreateRequest,
    StudentOut,
    StudentUpdateRequest,
)

router = APIRouter()
bearer = HTTPBearer()


@dataclass
class Actor:
    role: Literal["admin", "mentor"]
    account: Account
    profile: AdminProfile | MentorProfile
    db: Session


def student_to_actor_out(student: Student, actor: Actor) -> StudentOut:
    if actor.role == "admin":
        return student_to_out(student)

    return student_to_out(student, mentor_course_ids(actor.profile))


def get_current_actor(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
) -> Actor:
    try:
        claims = jwt.decode(
            credentials.credentials,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

    account = db.get(Account, int(claims["sub"]))

    if not account or not account.active:
        raise HTTPException(status_code=401, detail="Invalid token")

    token_type = claims.get("type")

    if token_type == "admin":
        profile = db.get(AdminProfile, claims.get("admin_profile_id"))

        if not profile or not profile.active or profile.account_id != account.id:
            raise HTTPException(status_code=401, detail="Invalid token")

        return Actor(role="admin", account=account, profile=profile, db=db)

    if token_type == "mentor":
        profile = db.get(MentorProfile, claims.get("mentor_profile_id"))

        if not profile or not profile.active or profile.account_id != account.id:
            raise HTTPException(status_code=401, detail="Invalid token")

        return Actor(role="mentor", account=account, profile=profile, db=db)

    raise HTTPException(status_code=403, detail="Access token required")


@router.get(
    "/mentors",
    response_model=list[SharedMentorOut],
)
def get_course_mentors(
    course_id: int,
    actor: Actor = Depends(get_current_actor),
):
    course = actor.db.get(Course, course_id)

    if not course:
        raise HTTPException(
            status_code=404,
            detail="Course not found",
        )

    if (
        actor.role == "mentor"
        and not course_visible_to_mentor(
            course,
            actor.profile,
        )
    ):
        raise HTTPException(
            status_code=403,
            detail="Course not available",
        )

    assigned_mentor_ids = {
        mentor.id
        for mentor in course.mentors
    }

    mentors_by_id = {
        mentor.id: mentor
        for mentor in course.mentors
    }

    for session_log in course.session_logs:
        mentors_by_id[
            session_log.submitted_by.id
        ] = session_log.submitted_by

        for participation in (
            session_log.mentor_participations
        ):
            mentors_by_id[
                participation.mentor.id
            ] = participation.mentor

    mentors = sorted(
        mentors_by_id.values(),
        key=lambda mentor: (
            mentor.account.first_name,
            mentor.account.last_name,
        ),
    )

    return [
        SharedMentorOut(
            id=mentor.id,
            first_name=mentor.account.first_name,
            last_name=mentor.account.last_name,
            active=(
                mentor.active
                and mentor.account.active
            ),
            assigned_to_course=(
                mentor.id in assigned_mentor_ids
            ),
        )
        for mentor in mentors
    ]


@router.get("/courses", response_model=list[CourseOut])
def get_courses(
    active_only: bool = True,
    actor: Actor = Depends(get_current_actor),
):
    db = actor.db

    if actor.role == "admin":
        query = db.query(Course)

        if active_only:
            query = query.filter(Course.active.is_(True))

        courses = query.order_by(Course.name).all()
        return [course_to_out(course) for course in courses]

    course_ids = mentor_course_ids(actor.profile)

    if not course_ids:
        return []

    query = db.query(Course).filter(Course.id.in_(course_ids))

    if active_only:
        query = query.filter(Course.active.is_(True))

    courses = query.order_by(Course.name).all()
    return [course_to_out(course) for course in courses]


@router.get("/courses/{course_id}", response_model=CourseOut)
def get_course(
    course_id: int,
    actor: Actor = Depends(get_current_actor),
):
    course = actor.db.get(Course, course_id)

    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    if actor.role == "mentor" and not course_visible_to_mentor(course, actor.profile):
        raise HTTPException(status_code=403, detail="Course not available")

    return course_to_out(course)


@router.put("/courses/{course_id}", response_model=CourseOut)
def update_course(
    course_id: int,
    data: CourseUpdateRequest,
    actor: Actor = Depends(get_current_actor),
):
    db = actor.db
    course = db.get(Course, course_id)

    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    if actor.role == "mentor":
        if not course_visible_to_mentor(course, actor.profile):
            raise HTTPException(status_code=403, detail="Course not available")

        if data.name is not None and data.name != course.name:
            raise HTTPException(status_code=403, detail="Mentor cannot change course name")

        if data.country_id is not None and data.country_id != course.country_id:
            raise HTTPException(status_code=403, detail="Mentor cannot change course country")

        if data.active is not None and data.active != course.active:
            raise HTTPException(status_code=403, detail="Mentor cannot change course status")

        if data.mentor_ids is not None:
            current_mentor_ids = {mentor.id for mentor in course.mentors}
            if set(unique_ids(data.mentor_ids)) != current_mentor_ids:
                raise HTTPException(status_code=403, detail="Mentor cannot assign or unassign mentors to courses")

        if data.student_ids is not None:
            requested_ids = set(unique_ids(data.student_ids))
            visible_ids = {
                student.id
                for student in db.query(Student)
                .join(Student.courses)
                .filter(Course.id.in_(mentor_course_ids(actor.profile)))
                .distinct()
                .all()
            }

            current_course_student_ids = {student.id for student in course.students}
            allowed_ids = visible_ids | current_course_student_ids

            if not requested_ids.issubset(allowed_ids):
                raise HTTPException(status_code=403, detail="Student not available")

    if data.name is not None:
        course.name = data.name

    if data.description is not None:
        course.description = data.description

    if data.country_id is not None:
        ensure_country_exists(db, data.country_id)
        course.country_id = data.country_id

    if data.day_of_week is not None:
        course.day_of_week = data.day_of_week

    if data.start_time is not None:
        course.start_time = data.start_time

    if data.active is not None:
        course.active = data.active

    if data.mentor_ids is not None:
        course.mentors = get_mentors_by_ids(db, data.mentor_ids)

    if data.student_ids is not None:
        course.students = get_students_by_ids(db, data.student_ids)

    db.commit()
    db.refresh(course)

    return course_to_out(course)


@router.get("/students", response_model=list[StudentOut])
def get_students(
    course_id: int | None = None,
    active_only: bool = True,
    actor: Actor = Depends(get_current_actor),
):
    db = actor.db

    if course_id is not None:
        course = db.get(Course, course_id)

        if not course:
            raise HTTPException(status_code=404, detail="Course not found")

        if actor.role == "mentor" and not course_visible_to_mentor(course, actor.profile):
            raise HTTPException(status_code=403, detail="Course not available")

        students = course.students

        if active_only:
            students = [student for student in students if student.active]

        return [
            student_to_actor_out(student, actor)
            for student in sorted(students, key=lambda s: (s.first_name, s.last_name))
        ]

    if actor.role == "admin":
        query = db.query(Student)

        if active_only:
            query = query.filter(Student.active.is_(True))

        students = query.order_by(Student.first_name, Student.last_name).all()
        return [student_to_actor_out(student, actor) for student in students]

    visible_course_ids = mentor_course_ids(actor.profile)

    if not visible_course_ids:
        return []

    query = (
        db.query(Student)
        .join(Student.courses)
        .filter(Course.id.in_(visible_course_ids))
        .distinct()
    )

    if active_only:
        query = query.filter(Student.active.is_(True))

    students = query.order_by(Student.first_name, Student.last_name).all()
    return [student_to_actor_out(student, actor) for student in students]


@router.get("/students/{student_id}", response_model=StudentOut)
def get_student(
    student_id: int,
    actor: Actor = Depends(get_current_actor),
):
    student = actor.db.get(Student, student_id)

    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    if actor.role == "mentor" and not student_visible_to_mentor(student, actor.profile):
        raise HTTPException(status_code=403, detail="Student not available")

    return student_to_actor_out(student, actor)


@router.post("/students", response_model=StudentOut)
def create_student(
    data: StudentCreateRequest,
    actor: Actor = Depends(get_current_actor),
):
    db = actor.db

    ensure_country_exists(db, data.origin_country_id)

    if actor.role == "mentor":
        if not data.active:
            raise HTTPException(status_code=403, detail="Mentor cannot create inactive student")

        if not data.course_ids:
            raise HTTPException(status_code=400, detail="Mentor must assign student to a course")

    student = Student(
        first_name=data.first_name,
        last_name=data.last_name,
        origin_country_id=data.origin_country_id,
        birth_year=data.birth_year,
        gender=data.gender,
        active=data.active,
    )

    db.add(student)
    db.flush()

    if actor.role == "admin":
        apply_student_courses_as_admin(db, student, data.course_ids)
    else:
        apply_student_courses_as_mentor(db, student, actor.profile, data.course_ids)

    db.commit()
    db.refresh(student)

    return student_to_actor_out(student, actor)


@router.put("/students/{student_id}", response_model=StudentOut)
def update_student(
    student_id: int,
    data: StudentUpdateRequest,
    actor: Actor = Depends(get_current_actor),
):
    db = actor.db
    student = db.get(Student, student_id)

    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    if actor.role == "mentor" and not student_visible_to_mentor(student, actor.profile):
        raise HTTPException(status_code=403, detail="Student not available")

    if data.first_name is not None:
        student.first_name = data.first_name

    if data.last_name is not None:
        student.last_name = data.last_name

    if data.origin_country_id is not None:
        ensure_country_exists(db, data.origin_country_id)
        student.origin_country_id = data.origin_country_id

    if data.birth_year is not None:
        student.birth_year = data.birth_year

    if data.gender is not None:
        student.gender = data.gender

    if data.active is not None:
        if actor.role == "mentor" and data.active != student.active:
            raise HTTPException(status_code=403, detail="Mentor cannot change student status")

        student.active = data.active

    if data.course_ids is not None:
        if actor.role == "admin":
            apply_student_courses_as_admin(db, student, data.course_ids)
        else:
            apply_student_courses_as_mentor(db, student, actor.profile, data.course_ids)

    db.commit()
    db.refresh(student)

    return student_to_actor_out(student, actor)
