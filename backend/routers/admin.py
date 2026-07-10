from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException

from config import settings
from dependencies import AdminAuth, get_current_admin
from models import Account, Course, MentorProfile
from routers._management import (
    course_to_out,
    ensure_country_exists,
    ensure_phone_available,
    get_courses_by_ids,
    get_mentors_by_ids,
    get_students_by_ids,
    mentor_to_out,
)
from schemas.management import (
    CourseCreateRequest,
    CourseOut,
    MentorCreateRequest,
    MentorOut,
    MentorResetPinRequest,
    MentorUpdateRequest,
)
from security import hash_secret

router = APIRouter()


@router.get("/mentors", response_model=list[MentorOut])
def get_mentors(
    active_only: bool = False,
    auth: AdminAuth = Depends(get_current_admin),
):
    db = auth.db
    query = db.query(MentorProfile).join(Account)

    if active_only:
        query = query.filter(Account.active.is_(True), MentorProfile.active.is_(True))

    mentors = query.order_by(Account.first_name, Account.last_name).all()
    return [mentor_to_out(mentor) for mentor in mentors]


@router.get("/mentors/{mentor_id}", response_model=MentorOut)
def get_mentor(
    mentor_id: int,
    auth: AdminAuth = Depends(get_current_admin),
):
    mentor = auth.db.get(MentorProfile, mentor_id)

    if not mentor:
        raise HTTPException(status_code=404, detail="Mentor not found")

    return mentor_to_out(mentor)


@router.post("/mentors", response_model=MentorOut)
def create_mentor(
    data: MentorCreateRequest,
    auth: AdminAuth = Depends(get_current_admin),
):
    db = auth.db

    ensure_country_exists(db, data.country_id)
    ensure_phone_available(db, data.phone)

    account = Account(
        first_name=data.first_name,
        last_name=data.last_name,
        phone=data.phone,
        country_id=data.country_id,
        preferred_language=data.preferred_language,
        active=data.active,
    )
    db.add(account)
    db.flush()

    expiry = datetime.now(UTC) + timedelta(days=settings.temporary_secret_days)

    mentor = MentorProfile(
        account_id=account.id,
        pin_hash=hash_secret(data.temporary_pin),
        must_change_pin=True,
        temporary_pin_expires_at=expiry,
        active=data.active,
    )
    mentor.courses = get_courses_by_ids(db, data.course_ids)

    db.add(mentor)
    db.commit()
    db.refresh(mentor)

    return mentor_to_out(mentor)


@router.put("/mentors/{mentor_id}", response_model=MentorOut)
def update_mentor(
    mentor_id: int,
    data: MentorUpdateRequest,
    auth: AdminAuth = Depends(get_current_admin),
):
    db = auth.db
    mentor = db.get(MentorProfile, mentor_id)

    if not mentor:
        raise HTTPException(status_code=404, detail="Mentor not found")

    account = mentor.account

    if data.first_name is not None:
        account.first_name = data.first_name

    if data.last_name is not None:
        account.last_name = data.last_name

    if data.phone is not None:
        ensure_phone_available(db, data.phone, current_account_id=account.id)
        account.phone = data.phone

    if data.country_id is not None:
        ensure_country_exists(db, data.country_id)
        account.country_id = data.country_id

    if data.preferred_language is not None:
        account.preferred_language = data.preferred_language

    if data.active is not None:
        account.active = data.active
        mentor.active = data.active

    if data.course_ids is not None:
        mentor.courses = get_courses_by_ids(db, data.course_ids)

    db.commit()
    db.refresh(mentor)

    return mentor_to_out(mentor)


@router.post("/mentors/{mentor_id}/reset-pin", response_model=MentorOut)
def reset_mentor_pin(
    mentor_id: int,
    data: MentorResetPinRequest,
    auth: AdminAuth = Depends(get_current_admin),
):
    db = auth.db
    mentor = db.get(MentorProfile, mentor_id)

    if not mentor:
        raise HTTPException(status_code=404, detail="Mentor not found")

    mentor.pin_hash = hash_secret(data.temporary_pin)
    mentor.must_change_pin = True
    mentor.temporary_pin_expires_at = (
        datetime.now(UTC) + timedelta(days=settings.temporary_secret_days)
    )
    mentor.failed_attempts = 0
    mentor.locked_until = None

    db.commit()
    db.refresh(mentor)

    return mentor_to_out(mentor)


@router.post("/mentors/{mentor_id}/deactivate", response_model=MentorOut)
def deactivate_mentor(
    mentor_id: int,
    auth: AdminAuth = Depends(get_current_admin),
):
    db = auth.db
    mentor = db.get(MentorProfile, mentor_id)

    if not mentor:
        raise HTTPException(status_code=404, detail="Mentor not found")

    mentor.active = False
    mentor.account.active = False

    db.commit()
    db.refresh(mentor)

    return mentor_to_out(mentor)


@router.post("/courses", response_model=CourseOut)
def create_course(
    data: CourseCreateRequest,
    auth: AdminAuth = Depends(get_current_admin),
):
    db = auth.db

    ensure_country_exists(db, data.country_id)

    course = Course(
        name=data.name,
        description=data.description,
        country_id=data.country_id,
        active=data.active,
    )
    course.mentors = get_mentors_by_ids(db, data.mentor_ids)
    course.students = get_students_by_ids(db, data.student_ids)

    db.add(course)
    db.commit()
    db.refresh(course)

    return course_to_out(course)


@router.post("/courses/{course_id}/deactivate", response_model=CourseOut)
def deactivate_course(
    course_id: int,
    auth: AdminAuth = Depends(get_current_admin),
):
    db = auth.db
    course = db.get(Course, course_id)

    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    course.active = False

    db.commit()
    db.refresh(course)

    return course_to_out(course)