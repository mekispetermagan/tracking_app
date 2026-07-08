from dataclasses import dataclass

from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from database import get_db
from models import Account, MentorProfile, AdminProfile
from security import decode_token


bearer = HTTPBearer()


@dataclass
class MentorAuth:
    db: Session
    account: Account
    profile: MentorProfile


@dataclass
class AdminAuth:
    db: Session
    account: Account
    profile: AdminProfile


def get_claims(credentials: HTTPAuthorizationCredentials = Depends(bearer)):
    return decode_token(credentials.credentials)


def get_int_claim(claims: dict, key: str) -> int:
    try:
        return int(claims[key])
    except (KeyError, TypeError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid token")


def get_account(db: Session, claims: dict) -> Account:
    account = db.get(Account, get_int_claim(claims, "sub"))

    if not account or not account.active:
        raise HTTPException(status_code=401, detail="Invalid token")

    return account


def get_mentor_profile(db: Session, claims: dict) -> MentorProfile:
    profile = db.get(MentorProfile, get_int_claim(claims, "mentor_profile_id"))

    if not profile or not profile.active:
        raise HTTPException(status_code=401, detail="Invalid token")

    return profile


def get_admin_profile(db: Session, claims: dict) -> AdminProfile:
    profile = db.get(AdminProfile, get_int_claim(claims, "admin_profile_id"))

    if not profile or not profile.active:
        raise HTTPException(status_code=401, detail="Invalid token")

    return profile


def get_current_mentor(
    claims: dict = Depends(get_claims),
    db: Session = Depends(get_db),
) -> MentorAuth:
    if claims.get("type") != "mentor":
        raise HTTPException(status_code=403, detail="Mentor token required")

    account = get_account(db, claims)
    profile = get_mentor_profile(db, claims)

    if profile.account_id != account.id:
        raise HTTPException(status_code=401, detail="Invalid token")

    if profile.must_change_pin:
        raise HTTPException(status_code=403, detail="PIN change required")

    return MentorAuth(db=db, account=account, profile=profile)


def get_current_admin(
    claims: dict = Depends(get_claims),
    db: Session = Depends(get_db),
) -> AdminAuth:
    if claims.get("type") != "admin":
        raise HTTPException(status_code=403, detail="Admin token required")

    account = get_account(db, claims)
    profile = get_admin_profile(db, claims)

    if profile.account_id != account.id:
        raise HTTPException(status_code=401, detail="Invalid token")

    if profile.must_change_password:
        raise HTTPException(status_code=403, detail="Password change required")

    return AdminAuth(db=db, account=account, profile=profile)


def get_mentor_setup(
    claims: dict = Depends(get_claims),
    db: Session = Depends(get_db),
) -> MentorAuth:
    if claims.get("type") != "mentor_setup":
        raise HTTPException(status_code=403, detail="Mentor setup token required")

    account = get_account(db, claims)
    profile = get_mentor_profile(db, claims)

    if profile.account_id != account.id:
        raise HTTPException(status_code=401, detail="Invalid token")

    if not profile.must_change_pin:
        raise HTTPException(status_code=403, detail="PIN already changed")

    return MentorAuth(db=db, account=account, profile=profile)


def get_admin_setup(
    claims: dict = Depends(get_claims),
    db: Session = Depends(get_db),
) -> AdminAuth:
    if claims.get("type") != "admin_setup":
        raise HTTPException(status_code=403, detail="Admin setup token required")

    account = get_account(db, claims)
    profile = get_admin_profile(db, claims)

    if profile.account_id != account.id:
        raise HTTPException(status_code=401, detail="Invalid token")

    if not profile.must_change_password:
        raise HTTPException(status_code=403, detail="Password already changed")

    return AdminAuth(db=db, account=account, profile=profile)