from collections import Counter

from sqlalchemy.orm import Session

from models import (
    CompletionStatus,
    ProjectType,
    SessionLog,
    Student,
)
from schemas.student_records import (
    StudentRecordOut,
    StudentRecordProjectGroupOut,
    StudentRecordProjectOut,
    StudentRecordSkillGameOut,
)


_COMPLETION_SCORES = {
    CompletionStatus.COMPLETED: 1.0,
    CompletionStatus.PARTLY_COMPLETED: 0.5,
    CompletionStatus.NOT_COMPLETED: 0.0,
}


def _games_from_session_log(
    session_log: SessionLog,
) -> list[str]:
    if not session_log.games_played:
        return []

    return [
        game.strip()
        for game in session_log.games_played.split(",")
        if game.strip()
    ]


def build_student_record(
    db: Session,
    student: Student,
) -> StudentRecordOut:
    session_logs = (
        db.query(SessionLog)
        .join(SessionLog.students)
        .filter(Student.id == student.id)
        .order_by(
            SessionLog.date,
            SessionLog.id,
        )
        .all()
    )

    projects_by_type: dict[
        ProjectType,
        list[StudentRecordProjectOut],
    ] = {
        project_type: []
        for project_type in ProjectType
    }

    scores_by_type = {
        project_type: 0.0
        for project_type in ProjectType
    }

    completed_counts: Counter[ProjectType] = Counter()
    partly_completed_counts: Counter[ProjectType] = Counter()
    not_completed_counts: Counter[ProjectType] = Counter()
    game_counts: Counter[str] = Counter()

    for session_log in session_logs:
        project_type = session_log.project_type
        completion_status = (
            session_log.completion_status
        )

        projects_by_type[project_type].append(
            StudentRecordProjectOut(
                project_title=session_log.project_title,
                date=session_log.date,
                completion_status=completion_status,
            )
        )

        scores_by_type[project_type] += (
            _COMPLETION_SCORES[completion_status]
        )

        if completion_status == CompletionStatus.COMPLETED:
            completed_counts[project_type] += 1
        elif (
            completion_status
            == CompletionStatus.PARTLY_COMPLETED
        ):
            partly_completed_counts[project_type] += 1
        else:
            not_completed_counts[project_type] += 1

        game_counts.update(
            _games_from_session_log(session_log)
        )

    project_groups = [
        StudentRecordProjectGroupOut(
            project_type=project_type,
            completed_count=completed_counts[
                project_type
            ],
            partly_completed_count=partly_completed_counts[
                project_type
            ],
            not_completed_count=not_completed_counts[
                project_type
            ],
            activity_score=scores_by_type[
                project_type
            ],
            projects=projects_by_type[project_type],
        )
        for project_type in ProjectType
        if projects_by_type[project_type]
    ]

    skill_games = [
        StudentRecordSkillGameOut(
            name=name,
            practice_count=count,
        )
        for name, count in sorted(
            game_counts.items(),
            key=lambda item: item[0].casefold(),
        )
    ]

    return StudentRecordOut(
        student_id=student.id,
        first_name=student.first_name,
        last_name=student.last_name,
        attended_sessions=len(session_logs),
        overall_activity_score=sum(
            scores_by_type.values()
        ),
        project_groups=project_groups,
        skill_games=skill_games,
    )
