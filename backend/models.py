from __future__ import annotations

from datetime import UTC, datetime, time

from sqlalchemy import Boolean, CheckConstraint, DateTime, ForeignKey, Integer, String, Time
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


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