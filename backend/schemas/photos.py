from datetime import date, datetime

from pydantic import BaseModel


class SessionPhotoOut(BaseModel):
    id: int
    session_log_id: int
    mentor_profile_id: int
    mentor_name: str
    session_date: date
    photo_number: int
    url: str
    uploaded_at: datetime
