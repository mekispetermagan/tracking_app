from __future__ import annotations

from datetime import UTC, date, datetime, time
from enum import Enum
from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    Enum as SqlEnum,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    Time,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class ProjectType(str, Enum):
    SCRATCH = "scratch"
    ROBOTICS = "robotics"
    APP_INVENTOR = "app_inventor"
    WEB_DEVELOPMENT = "web_development"
    OTHER = "other"


class CompletionStatus(str, Enum):
    COMPLETED = "completed"
    PARTLY_COMPLETED = "partly_completed"
    NOT_COMPLETED = "not_completed"


class SessionLogMentorRole(str, Enum):
    TEACHING = "teaching"
    SUPPORTING = "supporting"


class Country(Base):
    __tablename__ = "countries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    code: Mapped[str] = mapped_column(String(10), unique=True, nullable=False)

    name: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)

    accounts: Mapped[list[Account]] = relationship(back_populates="country")

    students: Mapped[list[Student]] = relationship(back_populates="origin_country")

    courses: Mapped[list[Course]] = relationship(back_populates="country")


class Account(Base):
    __tablename__ = "accounts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    phone: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)

    first_name: Mapped[str] = mapped_column(String(50), nullable=False)

    last_name: Mapped[str] = mapped_column(String(50), nullable=False)

    country_id: Mapped[int | None] = mapped_column(ForeignKey("countries.id"), nullable=True)

    country: Mapped[Country | None] = relationship(back_populates="accounts")

    preferred_language: Mapped[str] = mapped_column(String(2), default="en", nullable=False)

    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    mentor_profile: Mapped[MentorProfile | None] = relationship(back_populates="account")

    admin_profile: Mapped[AdminProfile | None] = relationship(back_populates="account")


class MentorProfile(Base):
    __tablename__ = "mentor_profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    account_id: Mapped[int] = mapped_column(ForeignKey("accounts.id"), unique=True, nullable=False)

    pin_hash: Mapped[str] = mapped_column(String(255), nullable=False)

    must_change_pin: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    temporary_pin_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    failed_attempts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    locked_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    account: Mapped[Account] = relationship(back_populates="mentor_profile")

    courses: Mapped[list[Course]] = relationship(
        secondary="mentor_courses",
        back_populates="mentors",
    )

    uploaded_session_photos: Mapped[list[SessionPhoto]] = relationship(
        back_populates="mentor",
    )

    submitted_session_logs: Mapped[list[SessionLog]] = relationship(
        back_populates="submitted_by",
        foreign_keys="SessionLog.submitted_by_mentor_profile_id",
    )

    session_log_participations: Mapped[list[SessionLogMentor]] = relationship(
        back_populates="mentor",
    )

    submitted_stories: Mapped[list[Story]] = relationship(
        back_populates="submitted_by",
        foreign_keys="Story.submitted_by_mentor_profile_id",
    )

    story_ratings: Mapped[list[StoryMentorRating]] = relationship(
        back_populates="mentor",
        cascade="all, delete-orphan",
    )

    course_visit_observations: Mapped[list[CourseVisitMentor]] = relationship(
        back_populates="mentor",
    )


class AdminProfile(Base):
    __tablename__ = "admin_profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    account_id: Mapped[int] = mapped_column(ForeignKey("accounts.id"), unique=True, nullable=False)

    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)

    must_change_password: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    temporary_password_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    failed_attempts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    locked_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    account: Mapped[Account] = relationship(back_populates="admin_profile")

    selected_stories_of_month: Mapped[list[StoryOfMonth]] = relationship(
        back_populates="selected_by",
    )

    course_visit_reports: Mapped[list[CourseVisitReport]] = relationship(
        back_populates="submitted_by",
    )


class Student(Base):
    __tablename__ = "students"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    first_name: Mapped[str] = mapped_column(String(50), nullable=False)

    last_name: Mapped[str] = mapped_column(String(50), nullable=False)

    origin_country_id: Mapped[int | None] = mapped_column(ForeignKey("countries.id"), nullable=True)

    origin_country: Mapped[Country | None] = relationship(back_populates="students")

    birth_year: Mapped[int | None] = mapped_column(Integer, nullable=True)

    gender: Mapped[str | None] = mapped_column(String(1), nullable=True)

    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    courses: Mapped[list[Course]] = relationship(
        secondary="student_courses",
        back_populates="students",
    )

    session_logs: Mapped[list[SessionLog]] = relationship(
        secondary="session_log_students",
        back_populates="students",
    )

    course_visit_observations: Mapped[list[CourseVisitStudent]] = relationship(
        back_populates="student",
    )


class Course(Base):
    __tablename__ = "courses"
    __table_args__ = (
        CheckConstraint(
            "day_of_week BETWEEN 0 AND 6",
            name="ck_courses_day_of_week",
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str] = mapped_column(String(255), default="", nullable=False)

    country_id: Mapped[int] = mapped_column(ForeignKey("countries.id"), nullable=False)
    country: Mapped[Country] = relationship(back_populates="courses")

    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    day_of_week: Mapped[int] = mapped_column(Integer, nullable=False)
    start_time: Mapped[time] = mapped_column(Time, nullable=False)

    #0: Monday 6: Sunday
    mentors: Mapped[list[MentorProfile]] = relationship(
        secondary="mentor_courses",
        back_populates="courses",
    )

    students: Mapped[list[Student]] = relationship(
        secondary="student_courses",
        back_populates="courses",
    )

    session_logs: Mapped[list[SessionLog]] = relationship(
        back_populates="course",
    )

    stories: Mapped[list[Story]] = relationship(
        back_populates="course",
    )

    visit_reports: Mapped[list[CourseVisitReport]] = relationship(
        back_populates="course",
    )


class MentorCourse(Base):
    __tablename__ = "mentor_courses"

    mentor_profile_id: Mapped[int] = mapped_column(
        ForeignKey("mentor_profiles.id"),
        primary_key=True,
    )

    course_id: Mapped[int] = mapped_column(
        ForeignKey("courses.id"),
        primary_key=True,
    )


class StudentCourse(Base):
    __tablename__ = "student_courses"

    student_id: Mapped[int] = mapped_column(
        ForeignKey("students.id"),
        primary_key=True,
    )

    course_id: Mapped[int] = mapped_column(
        ForeignKey("courses.id"),
        primary_key=True,
    )


class SessionLogStudent(Base):
    __tablename__ = "session_log_students"

    session_log_id: Mapped[int] = mapped_column(
        ForeignKey("session_logs.id", ondelete="CASCADE"),
        primary_key=True,
    )

    student_id: Mapped[int] = mapped_column(
        ForeignKey("students.id"),
        primary_key=True,
    )


class SessionLogMentor(Base):
    __tablename__ = "session_log_mentors"

    session_log_id: Mapped[int] = mapped_column(
        ForeignKey("session_logs.id", ondelete="CASCADE"),
        primary_key=True,
    )

    mentor_profile_id: Mapped[int] = mapped_column(
        ForeignKey("mentor_profiles.id"),
        primary_key=True,
    )

    role: Mapped[SessionLogMentorRole] = mapped_column(
        SqlEnum(
            SessionLogMentorRole,
            name="session_log_mentor_roles",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [
                item.value for item in enum
            ],
        ),
        nullable=False,
    )

    session_log: Mapped[SessionLog] = relationship(
        back_populates="mentor_participations",
    )

    mentor: Mapped[MentorProfile] = relationship(
        back_populates="session_log_participations",
    )


class SessionLog(Base):
    __tablename__ = "session_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    submitted_by_mentor_profile_id: Mapped[int] = mapped_column(
        ForeignKey("mentor_profiles.id"),
        nullable=False,
    )

    course_id: Mapped[int] = mapped_column(
        ForeignKey("courses.id"),
        nullable=False,
    )

    date: Mapped[date] = mapped_column(
        Date,
        default=date.today,
        nullable=False,
    )

    project_title: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    project_type: Mapped[ProjectType] = mapped_column(
        SqlEnum(
            ProjectType,
            name="project_types",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=False,
    )
    other_project_type: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    games_played: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    completion_status: Mapped[CompletionStatus] = mapped_column(
        SqlEnum(
            CompletionStatus,
            name="completion_statuses",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=False,
    )

    what_worked: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    challenges: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    next_step: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    submitted_by: Mapped[MentorProfile] = relationship(
        back_populates="submitted_session_logs",
        foreign_keys=[submitted_by_mentor_profile_id],
    )

    mentor_participations: Mapped[list[SessionLogMentor]] = relationship(
        back_populates="session_log",
        cascade="all, delete-orphan",
    )

    course: Mapped[Course] = relationship(
        back_populates="session_logs",
    )

    students: Mapped[list[Student]] = relationship(
        secondary="session_log_students",
        back_populates="session_logs",
    )

    photos: Mapped[list[SessionPhoto]] = relationship(
        back_populates="session_log",
        cascade="all, delete-orphan",
    )


class SessionPhoto(Base):
    __tablename__ = "session_photos"
    __table_args__ = (
        CheckConstraint(
            "photo_number BETWEEN 1 AND 3",
            name="ck_session_photos_photo_number",
        ),
        UniqueConstraint(
            "session_log_id",
            "mentor_profile_id",
            "photo_number",
            name="uq_session_photos_log_mentor_number",
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    session_log_id: Mapped[int] = mapped_column(
        ForeignKey("session_logs.id", ondelete="CASCADE"),
        nullable=False,
    )

    mentor_profile_id: Mapped[int] = mapped_column(
        ForeignKey("mentor_profiles.id"),
        nullable=False,
    )

    photo_number: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    original_path: Mapped[str] = mapped_column(
        String(500),
        unique=True,
        nullable=False,
    )

    compressed_path: Mapped[str] = mapped_column(
        String(500),
        unique=True,
        nullable=False,
    )

    uploaded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    session_log: Mapped[SessionLog] = relationship(
        back_populates="photos",
    )

    mentor: Mapped[MentorProfile] = relationship(
        back_populates="uploaded_session_photos",
    )


class Story(Base):
    __tablename__ = "stories"
    __table_args__ = (
        Index(
            "uq_stories_active_submitter_month",
            "submitted_by_mentor_profile_id",
            "submission_month",
            unique=True,
            sqlite_where=text("active = 1"),
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    submitted_by_mentor_profile_id: Mapped[int] = mapped_column(
        ForeignKey("mentor_profiles.id"),
        nullable=False,
    )

    course_id: Mapped[int] = mapped_column(
        ForeignKey("courses.id"),
        nullable=False,
    )

    text: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    submission_month: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        onupdate=lambda: datetime.now(UTC),
        nullable=False,
    )

    submitted_by: Mapped[MentorProfile] = relationship(
        back_populates="submitted_stories",
        foreign_keys=[submitted_by_mentor_profile_id],
    )

    course: Mapped[Course] = relationship(
        back_populates="stories",
    )

    photo: Mapped[StoryPhoto | None] = relationship(
        back_populates="story",
        cascade="all, delete-orphan",
        uselist=False,
    )

    ratings: Mapped[list[StoryMentorRating]] = relationship(
        back_populates="story",
        cascade="all, delete-orphan",
    )

    story_of_month: Mapped[StoryOfMonth | None] = relationship(
        back_populates="story",
        cascade="all, delete-orphan",
        uselist=False,
    )


class StoryPhoto(Base):
    __tablename__ = "story_photos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    story_id: Mapped[int] = mapped_column(
        ForeignKey("stories.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )

    original_path: Mapped[str] = mapped_column(
        String(500),
        unique=True,
        nullable=False,
    )

    compressed_path: Mapped[str] = mapped_column(
        String(500),
        unique=True,
        nullable=False,
    )

    uploaded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    story: Mapped[Story] = relationship(
        back_populates="photo",
    )


class StoryMentorRating(Base):
    __tablename__ = "story_mentor_ratings"
    __table_args__ = (
        CheckConstraint(
            "rating BETWEEN 1 AND 5",
            name="ck_story_mentor_ratings_rating",
        ),
        UniqueConstraint(
            "story_id",
            "mentor_profile_id",
            name="uq_story_mentor_ratings_story_mentor",
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    story_id: Mapped[int] = mapped_column(
        ForeignKey("stories.id", ondelete="CASCADE"),
        nullable=False,
    )

    mentor_profile_id: Mapped[int] = mapped_column(
        ForeignKey("mentor_profiles.id"),
        nullable=False,
    )

    rating: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        onupdate=lambda: datetime.now(UTC),
        nullable=False,
    )

    story: Mapped[Story] = relationship(
        back_populates="ratings",
    )

    mentor: Mapped[MentorProfile] = relationship(
        back_populates="story_ratings",
    )


class StoryOfMonth(Base):
    __tablename__ = "stories_of_month"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    month: Mapped[date] = mapped_column(
        Date,
        unique=True,
        nullable=False,
    )

    story_id: Mapped[int] = mapped_column(
        ForeignKey("stories.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )

    selected_by_admin_profile_id: Mapped[int] = mapped_column(
        ForeignKey("admin_profiles.id"),
        nullable=False,
    )

    selected_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    story: Mapped[Story] = relationship(
        back_populates="story_of_month",
    )

    selected_by: Mapped[AdminProfile] = relationship(
        back_populates="selected_stories_of_month",
    )


class CourseVisitSessionStatus(str, Enum):
    FULLY_HELD = "fully_held"
    PARTLY_HELD = "partly_held"
    NOT_HELD = "not_held"


class CourseVisitAnswer(str, Enum):
    YES = "yes"
    PARTLY = "partly"
    NO = "no"


class CourseVisitLearnerEngagement(str, Enum):
    ALMOST_ALL = "almost_all"
    MOST = "most"
    ABOUT_HALF = "about_half"
    FEW = "few"


class CourseVisitEnvironmentStatus(str, Enum):
    SAFE_AND_RESPECTFUL = "safe_and_respectful"
    MINOR_CONCERN = "minor_concern"
    SERIOUS_CONCERN = "serious_concern"


class CourseVisitMentorRole(str, Enum):
    TEACHING = "teaching"
    SUPPORTING = "supporting"


class CourseVisitStudentEnjoyment(str, Enum):
    YES = "yes"
    MIXED = "mixed"
    NO = "no"


class CourseVisitStudentLearning(str, Enum):
    CLEARLY = "clearly"
    PARTLY = "partly"
    NO = "no"


class CourseVisitStudentSafety(str, Enum):
    YES = "yes"
    UNSURE = "unsure"
    NO = "no"


class CourseVisitActionCategory(str, Enum):
    MENTOR_COACHING = "mentor_coaching"
    FOLLOW_UP_VISIT = "follow_up_visit"
    CURRICULUM_SUPPORT = "curriculum_support"
    EQUIPMENT = "equipment"
    ATTENDANCE_RETENTION = "attendance_retention"
    VENUE_SCHEDULING = "venue_scheduling"
    STAFFING = "staffing"
    PARTNER_DISCUSSION = "partner_discussion"
    SAFEGUARDING = "safeguarding"
    OTHER = "other"


class CourseVisitReport(Base):
    __tablename__ = "course_visit_reports"
    __table_args__ = (
        CheckConstraint(
            "course_health_rating BETWEEN 1 AND 5",
            name="ck_course_visit_reports_health_rating",
        ),
        Index(
            "ix_course_visit_reports_course_date",
            "course_id",
            "date",
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    submitted_by_admin_profile_id: Mapped[int] = mapped_column(
        ForeignKey("admin_profiles.id"),
        nullable=False,
    )

    course_id: Mapped[int] = mapped_column(
        ForeignKey("courses.id"),
        nullable=False,
    )

    date: Mapped[date] = mapped_column(
        Date,
        default=date.today,
        nullable=False,
    )

    session_status: Mapped[CourseVisitSessionStatus] = mapped_column(
        SqlEnum(
            CourseVisitSessionStatus,
            name="course_visit_session_statuses",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=False,
    )

    teaching_took_place: Mapped[CourseVisitAnswer] = mapped_column(
        SqlEnum(
            CourseVisitAnswer,
            name="course_visit_teaching_answers",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=False,
    )

    session_followed_plan: Mapped[CourseVisitAnswer | None] = mapped_column(
        SqlEnum(
            CourseVisitAnswer,
            name="course_visit_plan_answers",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=True,
    )

    learner_engagement: Mapped[
        CourseVisitLearnerEngagement | None
    ] = mapped_column(
        SqlEnum(
            CourseVisitLearnerEngagement,
            name="course_visit_learner_engagement_levels",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=True,
    )

    equipment_adequate: Mapped[CourseVisitAnswer | None] = mapped_column(
        SqlEnum(
            CourseVisitAnswer,
            name="course_visit_equipment_answers",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=True,
    )

    environment_status: Mapped[
        CourseVisitEnvironmentStatus | None
    ] = mapped_column(
        SqlEnum(
            CourseVisitEnvironmentStatus,
            name="course_visit_environment_statuses",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=True,
    )

    what_happened: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    main_strength: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    main_problem: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    support_provided: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    course_health_rating: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    safeguarding_concern: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    safeguarding_note: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        onupdate=lambda: datetime.now(UTC),
        nullable=False,
    )

    submitted_by: Mapped[AdminProfile] = relationship(
        back_populates="course_visit_reports",
    )

    course: Mapped[Course] = relationship(
        back_populates="visit_reports",
    )

    mentors: Mapped[list[CourseVisitMentor]] = relationship(
        back_populates="visit_report",
        cascade="all, delete-orphan",
    )

    students: Mapped[list[CourseVisitStudent]] = relationship(
        back_populates="visit_report",
        cascade="all, delete-orphan",
    )

    actions: Mapped[list[CourseVisitAction]] = relationship(
        back_populates="visit_report",
        cascade="all, delete-orphan",
    )


class CourseVisitMentor(Base):
    __tablename__ = "course_visit_mentors"
    __table_args__ = (
        CheckConstraint(
            "performance_rating IS NULL "
            "OR performance_rating BETWEEN 1 AND 5",
            name="ck_course_visit_mentors_performance_rating",
        ),
    )

    course_visit_report_id: Mapped[int] = mapped_column(
        ForeignKey("course_visit_reports.id", ondelete="CASCADE"),
        primary_key=True,
    )

    mentor_profile_id: Mapped[int] = mapped_column(
        ForeignKey("mentor_profiles.id"),
        primary_key=True,
    )

    role: Mapped[CourseVisitMentorRole | None] = mapped_column(
        SqlEnum(
            CourseVisitMentorRole,
            name="course_visit_mentor_roles",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=True,
    )

    performance_rating: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    visit_report: Mapped[CourseVisitReport] = relationship(
        back_populates="mentors",
    )

    mentor: Mapped[MentorProfile] = relationship(
        back_populates="course_visit_observations",
    )


class CourseVisitStudent(Base):
    __tablename__ = "course_visit_students"

    course_visit_report_id: Mapped[int] = mapped_column(
        ForeignKey("course_visit_reports.id", ondelete="CASCADE"),
        primary_key=True,
    )

    student_id: Mapped[int] = mapped_column(
        ForeignKey("students.id"),
        primary_key=True,
    )

    interviewed: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    enjoyment: Mapped[
        CourseVisitStudentEnjoyment | None
    ] = mapped_column(
        SqlEnum(
            CourseVisitStudentEnjoyment,
            name="course_visit_student_enjoyment_answers",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=True,
    )

    learning: Mapped[
        CourseVisitStudentLearning | None
    ] = mapped_column(
        SqlEnum(
            CourseVisitStudentLearning,
            name="course_visit_student_learning_answers",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=True,
    )

    feels_safe: Mapped[
        CourseVisitStudentSafety | None
    ] = mapped_column(
        SqlEnum(
            CourseVisitStudentSafety,
            name="course_visit_student_safety_answers",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=True,
    )

    note: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    visit_report: Mapped[CourseVisitReport] = relationship(
        back_populates="students",
    )

    student: Mapped[Student] = relationship(
        back_populates="course_visit_observations",
    )


class CourseVisitAction(Base):
    __tablename__ = "course_visit_actions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    course_visit_report_id: Mapped[int] = mapped_column(
        ForeignKey("course_visit_reports.id", ondelete="CASCADE"),
        nullable=False,
    )

    category: Mapped[CourseVisitActionCategory] = mapped_column(
        SqlEnum(
            CourseVisitActionCategory,
            name="course_visit_action_categories",
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            values_callable=lambda enum: [item.value for item in enum],
        ),
        nullable=False,
    )

    description: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    responsible_person: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    target_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )

    completed: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    visit_report: Mapped[CourseVisitReport] = relationship(
        back_populates="actions",
    )
