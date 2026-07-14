from models import SessionLog
from schemas.session_logs import SessionLogOut


def session_log_to_out(session_log: SessionLog) -> SessionLogOut:
    return SessionLogOut(
        id=session_log.id,
        mentor_profile_id=session_log.mentor_profile_id,
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
        student_ids=sorted(
            student.id for student in session_log.students
        ),
        created_at=session_log.created_at,
    )
