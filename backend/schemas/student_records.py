from datetime import date

from pydantic import BaseModel

from models import CompletionStatus, ProjectType


class StudentRecordProjectOut(BaseModel):
    project_title: str
    date: date
    completion_status: CompletionStatus


class StudentRecordProjectGroupOut(BaseModel):
    project_type: ProjectType

    completed_count: int
    partly_completed_count: int
    not_completed_count: int

    activity_score: float
    projects: list[StudentRecordProjectOut]


class StudentRecordSkillGameOut(BaseModel):
    name: str
    practice_count: int


class StudentRecordOut(BaseModel):
    student_id: int
    first_name: str
    last_name: str

    attended_sessions: int
    overall_activity_score: float

    project_groups: list[StudentRecordProjectGroupOut]
    skill_games: list[StudentRecordSkillGameOut]
