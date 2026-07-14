from typing import Literal

from pydantic import BaseModel

from schemas._validation import Password, Phone, Pin


class MentorLoginRequest(BaseModel):
    phone: Phone
    pin: Pin


class AdminLoginRequest(BaseModel):
    phone: Phone
    password: Password


class ChangeMentorPinRequest(BaseModel):
    new_pin: Pin


class ChangeAdminPasswordRequest(BaseModel):
    new_password: Password


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    token_purpose: Literal["access", "setup"]
    mode: Literal["mentor", "admin"]
    must_change_secret: bool
    first_name: str
    last_name: str
    preferred_language: str
