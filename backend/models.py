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
    Integer,
    String,
    Text,
    Time,
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

    submitted_session_logs: Mapped[list[SessionLog]] = relationship(
        back_populates="submitted_by",
        foreign_keys="SessionLog.submitted_by_mentor_profile_id",
    )

    session_log_participations: Mapped[list[SessionLogMentor]] = relationship(
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
