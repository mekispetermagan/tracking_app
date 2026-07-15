from datetime import date, datetime

from pydantic import BaseModel, Field, model_validator

from models import CompletionStatus, ProjectType


class SessionLogBase(BaseModel):
    date: date
    project_title: str = Field(
        min_length=1,
        max_length=100,
    )
    project_type: ProjectType
    other_project_type: str | None = Field(
        default=None,
        max_length=100,
    )

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

    teaching_mentor_ids: list[int] = Field(
        min_length=1,
    )
    supporting_mentor_ids: list[int] = Field(
        default_factory=list,
    )

    student_ids: list[int] = Field(
        min_length=1,
    )

    @model_validator(mode="after")
    def validate_ids(self):
        if len(self.student_ids) != len(set(self.student_ids)):
            raise ValueError(
                "Student IDs must be unique"
            )

        if len(self.teaching_mentor_ids) != len(
            set(self.teaching_mentor_ids)
        ):
            raise ValueError(
                "Teaching mentor IDs must be unique"
            )

        if len(self.supporting_mentor_ids) != len(
            set(self.supporting_mentor_ids)
        ):
            raise ValueError(
                "Supporting mentor IDs must be unique"
            )

        overlap = (
            set(self.teaching_mentor_ids)
            & set(self.supporting_mentor_ids)
        )

        if overlap:
            raise ValueError(
                "A mentor cannot be both teaching and supporting"
            )

        return self


class SessionLogOut(SessionLogBase):
    id: int
    submitted_by_mentor_profile_id: int
    course_id: int

    teaching_mentor_ids: list[int]
    supporting_mentor_ids: list[int]
    student_ids: list[int]

    created_at: datetime
