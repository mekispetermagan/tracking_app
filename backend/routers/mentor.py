from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Response,
    status,
    File,
    UploadFile,
)

from dependencies import MentorAuth, get_current_mentor
from models import (
    Course,
    SessionLog,
    SessionLogMentor,
    SessionLogMentorRole,
    SessionPhoto,
)
from routers._management import (
    course_visible_to_mentor,
    ensure_phone_available,
    mentor_course_ids,
    mentor_to_out,
)
from routers._session_logs import session_log_to_out
from schemas.management import (
    MentorChangePinRequest,
    MentorOut,
    MentorSelfUpdateRequest,
)
from schemas.session_logs import (
    SessionLogCreateRequest,
    SessionLogOut,
)
from routers._photos import (
    delete_photo_files,
    photo_to_out,
    store_photo,
)
from schemas.photos import SessionPhotoOut
from security import hash_secret, verify_secret

router = APIRouter()


@router.get("/me", response_model=MentorOut)
def get_my_mentor_profile(
    auth: MentorAuth = Depends(get_current_mentor),
):
    return mentor_to_out(auth.profile)


@router.put("/me", response_model=MentorOut)
def update_my_mentor_profile(
    data: MentorSelfUpdateRequest,
    auth: MentorAuth = Depends(get_current_mentor),
):
    db = auth.db
    account = auth.account

    if data.first_name is not None:
        account.first_name = data.first_name

    if data.last_name is not None:
        account.last_name = data.last_name

    if data.phone is not None:
        ensure_phone_available(
            db,
            data.phone,
            current_account_id=account.id,
        )
        account.phone = data.phone

    db.commit()
    db.refresh(auth.profile)

    return mentor_to_out(auth.profile)


@router.put(
    "/me/pin",
    status_code=status.HTTP_204_NO_CONTENT,
)
def change_my_pin(
    data: MentorChangePinRequest,
    auth: MentorAuth = Depends(get_current_mentor),
):
    if not verify_secret(
        data.current_pin,
        auth.profile.pin_hash,
    ):
        raise HTTPException(
            status_code=400,
            detail="Current PIN is incorrect",
        )

    auth.profile.pin_hash = hash_secret(data.new_pin)
    auth.db.commit()

    return Response(
        status_code=status.HTTP_204_NO_CONTENT,
    )


@router.post(
    "/session-logs",
    response_model=SessionLogOut,
    status_code=status.HTTP_201_CREATED,
)
def create_session_log(
    data: SessionLogCreateRequest,
    auth: MentorAuth = Depends(get_current_mentor),
):
    db = auth.db
    course = db.get(Course, data.course_id)

    if not course:
        raise HTTPException(
            status_code=404,
            detail="Course not found",
        )

    if not course_visible_to_mentor(
        course,
        auth.profile,
    ):
        raise HTTPException(
            status_code=403,
            detail="Course not available",
        )

    course_students = {
        student.id: student
        for student in course.students
    }

    unavailable_student_ids = sorted(
        set(data.student_ids)
        - set(course_students)
    )

    if unavailable_student_ids:
        raise HTTPException(
            status_code=400,
            detail=(
                "One or more students are not enrolled "
                "in this course"
            ),
        )

    course_mentors = {
        mentor.id: mentor
        for mentor in course.mentors
    }

    participant_ids = (
        set(data.teaching_mentor_ids)
        | set(data.supporting_mentor_ids)
    )

    unavailable_mentor_ids = sorted(
        participant_ids - set(course_mentors)
    )

    if unavailable_mentor_ids:
        raise HTTPException(
            status_code=400,
            detail=(
                "One or more mentors are not assigned "
                "to this course"
            ),
        )

    inactive_mentor_ids = sorted(
        mentor_id
        for mentor_id in participant_ids
        if (
            not course_mentors[mentor_id].active
            or not course_mentors[mentor_id].account.active
        )
    )

    if inactive_mentor_ids:
        raise HTTPException(
            status_code=400,
            detail=(
                "One or more selected mentors are inactive"
            ),
        )

    mentor_participations = [
        SessionLogMentor(
            mentor=course_mentors[mentor_id],
            role=SessionLogMentorRole.TEACHING,
        )
        for mentor_id in data.teaching_mentor_ids
    ]

    mentor_participations.extend(
        SessionLogMentor(
            mentor=course_mentors[mentor_id],
            role=SessionLogMentorRole.SUPPORTING,
        )
        for mentor_id in data.supporting_mentor_ids
    )

    session_log = SessionLog(
        submitted_by=auth.profile,
        course=course,
        date=data.date,
        project_title=data.project_title,
        project_type=data.project_type,
        other_project_type=data.other_project_type,
        games_played=data.games_played,
        completion_status=data.completion_status,
        what_worked=data.what_worked,
        challenges=data.challenges,
        next_step=data.next_step,
        mentor_participations=mentor_participations,
        students=[
            course_students[student_id]
            for student_id in data.student_ids
        ],
    )

    db.add(session_log)
    db.commit()
    db.refresh(session_log)

    return session_log_to_out(session_log)


@router.get(
    "/session-logs",
    response_model=list[SessionLogOut],
)
def get_available_session_logs(
    auth: MentorAuth = Depends(get_current_mentor),
):
    course_ids = mentor_course_ids(auth.profile)

    if not course_ids:
        return []

    session_logs = (
        auth.db.query(SessionLog)
        .filter(
            SessionLog.course_id.in_(course_ids)
        )
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


@router.post(
    "/session-logs/{session_log_id}/photos",
    response_model=list[SessionPhotoOut],
    status_code=status.HTTP_201_CREATED,
)
async def submit_session_photos(
    session_log_id: int,
    files: list[UploadFile] = File(...),
    auth: MentorAuth = Depends(get_current_mentor),
):
    if len(files) != 3:
        raise HTTPException(
            status_code=400,
            detail="Exactly three photos are required",
        )

    db = auth.db
    session_log = db.get(
        SessionLog,
        session_log_id,
    )

    if not session_log:
        raise HTTPException(
            status_code=404,
            detail="Session log not found",
        )

    is_participant = any(
        participation.mentor_profile_id
        == auth.profile.id
        for participation
        in session_log.mentor_participations
    )

    if not is_participant:
        raise HTTPException(
            status_code=403,
            detail=(
                "Only participating mentors may "
                "submit photos"
            ),
        )

    existing_photo = (
        db.query(SessionPhoto)
        .filter(
            SessionPhoto.session_log_id
            == session_log.id,
            SessionPhoto.mentor_profile_id
            == auth.profile.id,
        )
        .first()
    )

    if existing_photo:
        raise HTTPException(
            status_code=409,
            detail=(
                "Photos have already been submitted "
                "for this session"
            ),
        )

    created_files = []
    photos = []

    try:
        for photo_number, upload in enumerate(
            files,
            start=1,
        ):
            (
                original_path,
                compressed_path,
                file_paths,
            ) = await store_photo(
                upload=upload,
                course_id=session_log.course_id,
                session_date=session_log.date,
                mentor_profile_id=auth.profile.id,
                photo_number=photo_number,
            )

            created_files.extend(file_paths)

            photos.append(
                SessionPhoto(
                    session_log=session_log,
                    mentor=auth.profile,
                    photo_number=photo_number,
                    original_path=original_path,
                    compressed_path=compressed_path,
                )
            )

        db.add_all(photos)
        db.commit()

        for photo in photos:
            db.refresh(photo)

    except Exception:
        db.rollback()
        delete_photo_files(created_files)
        raise

    return [
        photo_to_out(photo)
        for photo in photos
    ]
