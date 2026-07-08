from typing import Literal

from pydantic import BaseModel, Field


class MentorLoginRequest(BaseModel):
    phone: str
    pin: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class AdminLoginRequest(BaseModel):
    phone: str
    password: str = Field(min_length=6)


class ChangeMentorPinRequest(BaseModel):
    new_pin: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class ChangeAdminPasswordRequest(BaseModel):
    new_password: str = Field(min_length=6)


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    token_purpose: Literal["access", "setup"]
    mode: Literal["mentor", "admin"]
    must_change_secret: bool
    first_name: str
    last_name: str
    preferred_language: str