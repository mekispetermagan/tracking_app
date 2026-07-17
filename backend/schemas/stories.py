from datetime import date, datetime

from pydantic import BaseModel, Field, field_validator


class StoryTextBase(BaseModel):
    text: str = Field(min_length=1)

    @field_validator("text")
    @classmethod
    def validate_text(cls, value: str) -> str:
        value = value.strip()

        if not value:
            raise ValueError("Story text is required")

        return value


class StoryCreateRequest(StoryTextBase):
    course_id: int


class StoryUpdateRequest(StoryTextBase):
    pass


class StoryRatingRequest(BaseModel):
    rating: int = Field(ge=1, le=5)


class StoryWinnerRequest(BaseModel):
    story_id: int


class StoryPhotoOut(BaseModel):
    id: int
    url: str
    uploaded_at: datetime


class StoryOutBase(StoryTextBase):
    id: int

    course_id: int
    course_name: str

    submitted_by_mentor_profile_id: int
    submitter_first_name: str
    submitter_last_name: str

    submission_month: date
    photo: StoryPhotoOut

    is_winner: bool

    created_at: datetime
    updated_at: datetime


class MentorStoryOut(StoryOutBase):
    my_rating: int | None
    can_rate: bool


class AdminStoryOut(StoryOutBase):
    active: bool

    rating_count: int
    average_rating: float | None


class StoryWinnerOut(BaseModel):
    month: date
    selected_at: datetime
    story: StoryOutBase
