from datetime import datetime, timedelta, UTC
from typing import Any

from fastapi import HTTPException
from jose import JWTError, jwt
from pwdlib import PasswordHash

from config import settings


password_hash = PasswordHash.recommended()


def hash_secret(secret: str) -> str:
    return password_hash.hash(secret)


def verify_secret(secret: str, hashed_secret: str) -> bool:
    return password_hash.verify(secret, hashed_secret)


def create_access_token(data: dict[str, Any], expires_minutes: int) -> str:
    payload = data.copy()
    payload["exp"] = datetime.now(UTC) + timedelta(minutes=expires_minutes)

    return jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def decode_token(token: str) -> dict[str, Any]:
    try:
        return jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")


def create_mentor_token(account_id: int, mentor_profile_id: int) -> str:
    return create_access_token(
        {
            "sub": str(account_id),
            "type": "mentor",
            "mentor_profile_id": mentor_profile_id,
        },
        settings.mentor_token_minutes,
    )


def create_admin_token(account_id: int, admin_profile_id: int) -> str:
    return create_access_token(
        {
            "sub": str(account_id),
            "type": "admin",
            "admin_profile_id": admin_profile_id,
        },
        settings.admin_token_minutes,
    )