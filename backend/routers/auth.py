from datetime import datetime, UTC

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from config import settings
from database import get_db
from models import Account
from schemas.auth import (
    MentorLoginRequest,
    AdminLoginRequest,
    ChangeMentorPinRequest,
    ChangeAdminPasswordRequest,
    AuthResponse,
)
from security import (
    verify_secret,
    hash_secret,
    create_access_token,
    create_mentor_token,
    create_admin_token,
)
from dependencies import (
    MentorAuth,
    AdminAuth,
    get_current_mentor,
    get_current_admin,
    get_mentor_setup,
    get_admin_setup,
)


router = APIRouter()


def expired(dt):
    if dt is None:
        return False
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=UTC)
    return dt < datetime.now(UTC)


def account_response(account, token, purpose, mode, must_change):
    return AuthResponse(
        access_token=token,
        token_purpose=purpose,
        mode=mode,
        must_change_secret=must_change,
        first_name=account.first_name,
        last_name=account.last_name,
        preferred_language=account.preferred_language,
    )


@router.post("/mentor/login", response_model=AuthResponse)
def mentor_login(data: MentorLoginRequest, db: Session = Depends(get_db)):
    account = db.query(Account).filter_by(phone=data.phone).first()

    if not account or not account.active or not account.mentor_profile:
        raise HTTPException(status_code=401, detail="Bad phone or PIN")

    profile = account.mentor_profile

    if not profile.active or not verify_secret(data.pin, profile.pin_hash):
        raise HTTPException(status_code=401, detail="Bad phone or PIN")

    if profile.must_change_pin:
        if expired(profile.temporary_pin_expires_at):
            raise HTTPException(status_code=403, detail="Temporary PIN expired")

        token = create_access_token(
            {
                "sub": str(account.id),
                "type": "mentor_setup",
                "mentor_profile_id": profile.id,
            },
            settings.temp_token_minutes,
        )
        return account_response(account, token, "setup", "mentor", True)

    token = create_mentor_token(account.id, profile.id)
    return account_response(account, token, "access", "mentor", False)


@router.post("/admin/login", response_model=AuthResponse)
def admin_login(data: AdminLoginRequest, db: Session = Depends(get_db)):
    account = db.query(Account).filter_by(phone=data.phone).first()

    if not account or not account.active or not account.admin_profile:
        raise HTTPException(status_code=401, detail="Bad phone or password")

    profile = account.admin_profile

    if not profile.active or not verify_secret(data.password, profile.password_hash):
        raise HTTPException(status_code=401, detail="Bad phone or password")

    if profile.must_change_password:
        if expired(profile.temporary_password_expires_at):
            raise HTTPException(status_code=403, detail="Temporary password expired")

        token = create_access_token(
            {
                "sub": str(account.id),
                "type": "admin_setup",
                "admin_profile_id": profile.id,
            },
            settings.temp_token_minutes,
        )
        return account_response(account, token, "setup", "admin", True)

    token = create_admin_token(account.id, profile.id)
    return account_response(account, token, "access", "admin", False)


@router.post("/mentor/change-pin", response_model=AuthResponse)
def change_mentor_pin(
    data: ChangeMentorPinRequest,
    auth: MentorAuth = Depends(get_mentor_setup),
):
    auth.profile.pin_hash = hash_secret(data.new_pin)
    auth.profile.must_change_pin = False
    auth.profile.temporary_pin_expires_at = None

    auth.db.commit()

    token = create_mentor_token(auth.account.id, auth.profile.id)
    return account_response(auth.account, token, "access", "mentor", False)


@router.post("/admin/change-password", response_model=AuthResponse)
def change_admin_password(
    data: ChangeAdminPasswordRequest,
    auth: AdminAuth = Depends(get_admin_setup),
):
    auth.profile.password_hash = hash_secret(data.new_password)
    auth.profile.must_change_password = False
    auth.profile.temporary_password_expires_at = None

    auth.db.commit()

    token = create_admin_token(auth.account.id, auth.profile.id)
    return account_response(auth.account, token, "access", "admin", False)


@router.get("/mentor/me")
def mentor_me(auth: MentorAuth = Depends(get_current_mentor)):
    return {
        "mode": "mentor",
        "account_id": auth.account.id,
        "mentor_profile_id": auth.profile.id,
        "first_name": auth.account.first_name,
        "last_name": auth.account.last_name,
        "preferred_language": auth.account.preferred_language,
    }


@router.get("/admin/me")
def admin_me(auth: AdminAuth = Depends(get_current_admin)):
    return {
        "mode": "admin",
        "account_id": auth.account.id,
        "admin_profile_id": auth.profile.id,
        "first_name": auth.account.first_name,
        "last_name": auth.account.last_name,
        "preferred_language": auth.account.preferred_language,
    }