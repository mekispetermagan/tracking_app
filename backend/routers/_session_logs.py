from models import (
    SessionLog,
    SessionLogMentorRole,
)
from schemas.session_logs import SessionLogOut


def session_log_to_out(
    session_log: SessionLog,
) -> SessionLogOut:
    teaching_mentor_ids = sorted(
        participation.mentor_profile_id
        for participation in session_log.mentor_participations
        if participation.role
        == SessionLogMentorRole.TEACHING
    )

    supporting_mentor_ids = sorted(
        participation.mentor_profile_id
        for participation in session_log.mentor_participations
        if participation.role
        == SessionLogMentorRole.SUPPORTING
    )

    return SessionLogOut(
        id=session_log.id,
        submitted_by_mentor_profile_id=(
            session_log.submitted_by_mentor_profile_id
        ),
        course_id=session_log.course_id,
        date=session_log.date,
        project_title=session_log.project_title,
        project_type=session_log.project_type,
        other_project_type=session_log.other_project_type,
        games_played=session_log.games_played,
        completion_status=session_log.completion_status,
        what_worked=session_log.what_worked,
        challenges=session_log.challenges,
        next_step=session_log.next_step,
        teaching_mentor_ids=teaching_mentor_ids,
        supporting_mentor_ids=supporting_mentor_ids,
        student_ids=sorted(
            student.id
            for student in session_log.students
        ),
        created_at=session_log.created_at,
    )
