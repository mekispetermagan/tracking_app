from datetime import date, datetime

from pydantic import BaseModel, Field, model_validator

from models import (
    CourseVisitActionCategory,
    CourseVisitAnswer,
    CourseVisitEnvironmentStatus,
    CourseVisitLearnerEngagement,
    CourseVisitMentorRole,
    CourseVisitSessionStatus,
    CourseVisitStudentEnjoyment,
    CourseVisitStudentLearning,
    CourseVisitStudentSafety,
)


class CourseVisitMentorCreate(BaseModel):
    mentor_id: int
    role: CourseVisitMentorRole | None = None
    performance_rating: int | None = Field(
        default=None,
        ge=1,
        le=5,
    )


class CourseVisitMentorOut(CourseVisitMentorCreate):
    pass


class CourseVisitStudentCreate(BaseModel):
    student_id: int
    interviewed: bool = False
    enjoyment: CourseVisitStudentEnjoyment | None = None
    learning: CourseVisitStudentLearning | None = None
    feels_safe: CourseVisitStudentSafety | None = None
    note: str | None = Field(
        default=None,
        max_length=500,
    )

    @model_validator(mode="after")
    def validate_interview(self):
        answers = (
            self.enjoyment,
            self.learning,
            self.feels_safe,
        )

        if self.interviewed and any(
            answer is None for answer in answers
        ):
            raise ValueError(
                "All interview answers are required"
            )

        if not self.interviewed and (
            any(answer is not None for answer in answers)
            or self.note is not None
        ):
            raise ValueError(
                "Interview data requires interviewed=true"
            )

        return self


class CourseVisitStudentOut(CourseVisitStudentCreate):
    pass


class CourseVisitActionCreate(BaseModel):
    category: CourseVisitActionCategory
    description: str = Field(
        min_length=1,
        max_length=500,
    )
    responsible_person: str | None = Field(
        default=None,
        max_length=100,
    )
    target_date: date | None = None


class CourseVisitActionOut(CourseVisitActionCreate):
    id: int
    completed: bool
    completed_at: datetime | None


class CourseVisitReportBase(BaseModel):
    date: date
    session_status: CourseVisitSessionStatus
    teaching_took_place: CourseVisitAnswer
    session_followed_plan: CourseVisitAnswer | None = None
    learner_engagement: CourseVisitLearnerEngagement | None = None
    equipment_adequate: CourseVisitAnswer | None = None
    environment_status: CourseVisitEnvironmentStatus | None = None

    what_happened: str = Field(
        min_length=1,
        max_length=500,
    )
    main_strength: str | None = Field(
        default=None,
        max_length=500,
    )
    main_problem: str | None = Field(
        default=None,
        max_length=500,
    )
    support_provided: str | None = Field(
        default=None,
        max_length=500,
    )

    course_health_rating: int = Field(
        ge=1,
        le=5,
    )

    safeguarding_concern: bool = False
    safeguarding_note: str | None = Field(
        default=None,
        max_length=1000,
    )


class CourseVisitReportCreateRequest(CourseVisitReportBase):
    course_id: int

    mentors: list[CourseVisitMentorCreate] = Field(
        default_factory=list,
    )
    students: list[CourseVisitStudentCreate] = Field(
        default_factory=list,
    )
    actions: list[CourseVisitActionCreate] = Field(
        default_factory=list,
    )

    @model_validator(mode="after")
    def validate_report(self):
        mentor_ids = [
            mentor.mentor_id
            for mentor in self.mentors
        ]
        student_ids = [
            student.student_id
            for student in self.students
        ]

        if len(mentor_ids) != len(set(mentor_ids)):
            raise ValueError(
                "Mentor IDs must be unique"
            )

        if len(student_ids) != len(set(student_ids)):
            raise ValueError(
                "Student IDs must be unique"
            )

        observation_values = (
            self.session_followed_plan,
            self.learner_engagement,
            self.equipment_adequate,
            self.environment_status,
        )

        if (
            self.session_status
            == CourseVisitSessionStatus.NOT_HELD
        ):
            if self.teaching_took_place != CourseVisitAnswer.NO:
                raise ValueError(
                    "Teaching must be no when "
                    "the session was not held"
                )

            if any(
                value is not None
                for value in observation_values
            ):
                raise ValueError(
                    "Session observations must be empty "
                    "when the session was not held"
                )
        elif any(
            value is None
            for value in observation_values
        ):
            raise ValueError(
                "All session observations are required "
                "when the session was held"
            )

        safeguarding_note = (
            self.safeguarding_note.strip()
            if self.safeguarding_note
            else None
        )

        if (
            self.safeguarding_concern
            and not safeguarding_note
        ):
            raise ValueError(
                "Safeguarding note is required "
                "when there is a concern"
            )

        self.safeguarding_note = (
            safeguarding_note
            if self.safeguarding_concern
            else None
        )

        return self


class CourseVisitReportOut(CourseVisitReportBase):
    id: int
    submitted_by_admin_profile_id: int
    course_id: int

    mentors: list[CourseVisitMentorOut]
    students: list[CourseVisitStudentOut]
    actions: list[CourseVisitActionOut]

    created_at: datetime
    updated_at: datetime
