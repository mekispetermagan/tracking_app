from datetime import UTC, date, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import selectinload

from config import settings
from dependencies import AdminAuth, get_current_admin
from models import (
    Account,
    Course,
    CourseVisitAction,
    CourseVisitMentor,
    CourseVisitReport,
    CourseVisitStudent,
    MentorProfile,
    SessionLog,
    Story,
    StoryOfMonth,
)
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

from routers._session_logs import session_log_to_out
from schemas.session_logs import SessionLogOut

from routers._stories import (
    admin_story_to_out,
    current_month,
    normalize_month,
    story_winner_to_out,
)
from schemas.stories import (
    AdminStoryOut,
    StoryUpdateRequest,
    StoryWinnerOut,
    StoryWinnerRequest,
)

from routers._course_visits import course_visit_report_to_out
from schemas.course_visits import (
    CourseVisitReportCreateRequest,
    CourseVisitReportOut,
)

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
        day_of_week=data.day_of_week,
        start_time=data.start_time,
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

@router.get(
    "/session-logs",
    response_model=list[SessionLogOut],
)
def get_session_logs(
    auth: AdminAuth = Depends(get_current_admin),
):
    session_logs = (
        auth.db.query(SessionLog)
        .order_by(
            SessionLog.date.desc(),
            SessionLog.id.desc(),
        )
        .all()
    )

    return [
        session_log_to_out(session_log)
        for session_log in session_logs
    ]


@router.get(
    "/stories",
    response_model=list[AdminStoryOut],
)
def get_stories_for_admin(
    month: date | None = None,
    active_only: bool = True,
    auth: AdminAuth = Depends(
        get_current_admin,
    ),
):
    selected_month = (
        normalize_month(month)
        if month is not None
        else current_month()
    )

    query = auth.db.query(Story).filter(
        Story.submission_month
        == selected_month,
    )

    if active_only:
        query = query.filter(
            Story.active.is_(True),
        )

    stories = query.order_by(
        Story.created_at.desc(),
        Story.id.desc(),
    ).all()

    return [
        admin_story_to_out(story)
        for story in stories
    ]


@router.put(
    "/stories/{story_id}",
    response_model=AdminStoryOut,
)
def update_story(
    story_id: int,
    data: StoryUpdateRequest,
    auth: AdminAuth = Depends(
        get_current_admin,
    ),
):
    db = auth.db
    story = db.get(
        Story,
        story_id,
    )

    if not story:
        raise HTTPException(
            status_code=404,
            detail="Story not found",
        )

    story.text = data.text

    db.commit()
    db.refresh(story)

    return admin_story_to_out(story)


@router.post(
    "/stories/{story_id}/deactivate",
    response_model=AdminStoryOut,
)
def deactivate_story(
    story_id: int,
    auth: AdminAuth = Depends(
        get_current_admin,
    ),
):
    db = auth.db
    story = db.get(
        Story,
        story_id,
    )

    if not story:
        raise HTTPException(
            status_code=404,
            detail="Story not found",
        )

    story.active = False

    if story.story_of_month is not None:
        db.delete(
            story.story_of_month,
        )

    db.commit()
    db.refresh(story)

    return admin_story_to_out(story)


@router.put(
    "/story-winners/{month}",
    response_model=StoryWinnerOut,
)
def select_story_winner(
    month: date,
    data: StoryWinnerRequest,
    auth: AdminAuth = Depends(
        get_current_admin,
    ),
):
    db = auth.db
    selected_month = normalize_month(
        month,
    )

    if selected_month >= current_month():
        raise HTTPException(
            status_code=409,
            detail=(
                "A winner can only be selected "
                "after the month has ended"
            ),
        )

    story = db.get(
        Story,
        data.story_id,
    )

    if not story or not story.active:
        raise HTTPException(
            status_code=404,
            detail="Story not found",
        )

    if (
        story.submission_month
        != selected_month
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Story does not belong "
                "to this month"
            ),
        )

    winner = (
        db.query(StoryOfMonth)
        .filter(
            StoryOfMonth.month
            == selected_month,
        )
        .first()
    )

    selected_at = datetime.now(UTC)

    if winner:
        winner.story = story
        winner.selected_by = auth.profile
        winner.selected_at = selected_at
    else:
        winner = StoryOfMonth(
            month=selected_month,
            story=story,
            selected_by=auth.profile,
            selected_at=selected_at,
        )
        db.add(winner)

    db.commit()
    db.refresh(winner)

    return story_winner_to_out(
        winner,
    )

@router.post(
    "/stories/{story_id}/activate",
    response_model=AdminStoryOut,
)
def activate_story(
    story_id: int,
    auth: AdminAuth = Depends(
        get_current_admin,
    ),
):
    db = auth.db
    story = db.get(
        Story,
        story_id,
    )

    if not story:
        raise HTTPException(
            status_code=404,
            detail="Story not found",
        )

    if story.active:
        return admin_story_to_out(story)

    replacement = (
        db.query(Story)
        .filter(
            Story.submitted_by_mentor_profile_id
            == story.submitted_by_mentor_profile_id,
            Story.submission_month
            == story.submission_month,
            Story.active.is_(True),
            Story.id != story.id,
        )
        .first()
    )

    if replacement:
        raise HTTPException(
            status_code=409,
            detail=(
                "The mentor already has another active "
                "story for this month"
            ),
        )

    story.active = True

    try:
        db.commit()
        db.refresh(story)
    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail=(
                "The mentor already has another active "
                "story for this month"
            ),
        )

    return admin_story_to_out(story)


@router.post(
    "/course-visit-reports",
    response_model=CourseVisitReportOut,
    status_code=status.HTTP_201_CREATED,
)
def create_course_visit_report(
    data: CourseVisitReportCreateRequest,
    auth: AdminAuth = Depends(get_current_admin),
):
    db = auth.db
    course = db.get(Course, data.course_id)

    if not course:
        raise HTTPException(
            status_code=404,
            detail="Course not found",
        )

    course_mentors = {
        mentor.id: mentor
        for mentor in course.mentors
    }
    mentor_ids = {
        mentor.mentor_id
        for mentor in data.mentors
    }

    if not mentor_ids.issubset(course_mentors):
        raise HTTPException(
            status_code=400,
            detail=(
                "One or more mentors are not assigned "
                "to this course"
            ),
        )

    course_students = {
        student.id: student
        for student in course.students
    }
    student_ids = {
        student.student_id
        for student in data.students
    }

    if not student_ids.issubset(course_students):
        raise HTTPException(
            status_code=400,
            detail=(
                "One or more students are not enrolled "
                "in this course"
            ),
        )

    report = CourseVisitReport(
        submitted_by=auth.profile,
        course=course,
        date=data.date,
        session_status=data.session_status,
        teaching_took_place=data.teaching_took_place,
        session_followed_plan=data.session_followed_plan,
        learner_engagement=data.learner_engagement,
        equipment_adequate=data.equipment_adequate,
        environment_status=data.environment_status,
        what_happened=data.what_happened,
        main_strength=data.main_strength,
        main_problem=data.main_problem,
        support_provided=data.support_provided,
        course_health_rating=data.course_health_rating,
        safeguarding_concern=data.safeguarding_concern,
        safeguarding_note=data.safeguarding_note,
        mentors=[
            CourseVisitMentor(
                mentor=course_mentors[item.mentor_id],
                role=item.role,
                performance_rating=item.performance_rating,
            )
            for item in data.mentors
        ],
        students=[
            CourseVisitStudent(
                student=course_students[item.student_id],
                interviewed=item.interviewed,
                enjoyment=item.enjoyment,
                learning=item.learning,
                feels_safe=item.feels_safe,
                note=item.note,
            )
            for item in data.students
        ],
        actions=[
            CourseVisitAction(
                category=item.category,
                description=item.description,
                responsible_person=item.responsible_person,
                target_date=item.target_date,
            )
            for item in data.actions
        ],
    )

    db.add(report)
    db.commit()
    db.refresh(report)

    return course_visit_report_to_out(report)


@router.get(
    "/course-visit-reports",
    response_model=list[CourseVisitReportOut],
)
def get_course_visit_reports(
    auth: AdminAuth = Depends(get_current_admin),
):
    reports = (
        auth.db.query(CourseVisitReport)
        .options(
            selectinload(CourseVisitReport.mentors),
            selectinload(CourseVisitReport.students),
            selectinload(CourseVisitReport.actions),
        )
        .order_by(
            CourseVisitReport.date.desc(),
            CourseVisitReport.id.desc(),
        )
        .all()
    )

    return [
        course_visit_report_to_out(report)
        for report in reports
    ]
