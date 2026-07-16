from datetime import datetime

from pydantic import BaseModel


class SessionPhotoOut(BaseModel):
    id: int
    session_log_id: int
    mentor_profile_id: int
    photo_number: int
    url: str
    uploaded_at: datetime
