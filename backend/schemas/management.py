from typing import Literal
from datetime import time
from pydantic import BaseModel, Field


Gender = Literal["M", "F", "N"]


class MentorOut(BaseModel):
    id: int
    account_id: int
    first_name: str
    last_name: str
    phone: str
    country_id: int | None
    preferred_language: str
    active: bool
    course_ids: list[int]


class CourseOut(BaseModel):
    id: int
    name: str
    description: str
    country_id: int
    day_of_week: int
    start_time: time
    active: bool
    mentor_ids: list[int]
    student_ids: list[int]

class StudentOut(BaseModel):
    id: int
    first_name: str
    last_name: str
    origin_country_id: int | None
    birth_year: int | None
    gender: Gender | None
    active: bool
    course_ids: list[int]


class MentorCreateRequest(BaseModel):
    first_name: str
    last_name: str
    phone: str
    country_id: int | None = None
    preferred_language: str = Field(default="en", min_length=2, max_length=2)
    temporary_pin: str = Field(min_length=6, max_length=64)
    active: bool = True
    course_ids: list[int] = Field(default_factory=list)


class MentorUpdateRequest(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    country_id: int | None = None
    preferred_language: str | None = Field(default=None, min_length=2, max_length=2)
    active: bool | None = None
    course_ids: list[int] | None = None


class MentorResetPinRequest(BaseModel):
    temporary_pin: str = Field(min_length=6, max_length=64)


class MentorSelfUpdateRequest(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    country_id: int | None = None
    preferred_language: str | None = Field(default=None, min_length=2, max_length=2)


class CourseUpdateRequest(BaseModel):
    name: str | None = None
    description: str | None = None
    country_id: int | None = None
    day_of_week: int | None = Field(default=None, ge=0, le=6)
    start_time: time | None = None
    active: bool | None = None
    mentor_ids: list[int] | None = None
    student_ids: list[int] | None = None

class CourseCreateRequest(BaseModel):
    name: str
    description: str = ""
    country_id: int
    day_of_week: int = Field(ge=0, le=6)
    start_time: time
    active: bool = True
    mentor_ids: list[int] = Field(default_factory=list)
    student_ids: list[int] = Field(default_factory=list)


class StudentCreateRequest(BaseModel):
    first_name: str
    last_name: str
    origin_country_id: int | None = None
    birth_year: int | None = None
    gender: Gender | None = None
    active: bool = True
    course_ids: list[int] = Field(default_factory=list)


class StudentUpdateRequest(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    origin_country_id: int | None = None
    birth_year: int | None = None
    gender: Gender | None = None
    active: bool | None = None
    course_ids: list[int] | None = None
