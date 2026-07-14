from datetime import date, datetime

from pydantic import BaseModel, Field, model_validator

from models import CompletionStatus, ProjectType


class SessionLogBase(BaseModel):
    date: date
    project_title: str = Field(min_length=1, max_length=100)
    project_type: ProjectType
    other_project_type: str | None = Field(default=None, max_length=100)

    games_played: str | None = None
    completion_status: CompletionStatus

    what_worked: str | None = None
    challenges: str | None = None
    next_step: str | None = None

    @model_validator(mode="after")
    def validate_project_type(self):
        other_project_type = (
            self.other_project_type.strip()
            if self.other_project_type
            else None
        )

        if self.project_type == ProjectType.OTHER:
            if not other_project_type:
                raise ValueError(
                    "Other project type must be specified"
                )

            self.other_project_type = other_project_type
        else:
            self.other_project_type = None

        return self


class SessionLogCreateRequest(SessionLogBase):
    course_id: int
    student_ids: list[int] = Field(min_length=1)

    @model_validator(mode="after")
    def validate_student_ids(self):
        if len(self.student_ids) != len(set(self.student_ids)):
            raise ValueError("Student IDs must be unique")

        return self


class SessionLogOut(SessionLogBase):
    id: int
    mentor_profile_id: int
    course_id: int
    student_ids: list[int]
    created_at: datetime
