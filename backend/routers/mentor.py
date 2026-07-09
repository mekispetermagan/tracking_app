from fastapi import APIRouter, Depends

from dependencies import MentorAuth, get_current_mentor
from routers._management import (
    ensure_country_exists,
    ensure_phone_available,
    mentor_to_out,
)
from schemas.management import MentorOut, MentorSelfUpdateRequest

router = APIRouter()


@router.get("/me", response_model=MentorOut)
def get_my_mentor_profile(
    auth: MentorAuth = Depends(get_current_mentor),
):
    return mentor_to_out(auth.profile)


@router.put("/me", response_model=MentorOut)
def update_my_mentor_profile(
    data: MentorSelfUpdateRequest,
    auth: MentorAuth = Depends(get_current_mentor),
):
    db = auth.db
    account = auth.account

    if data.first_name is not None:
        account.first_name = data.first_name

    if data.last_name is not None:
        account.last_name = data.last_name

    if data.phone is not None:
        ensure_phone_available(db, data.phone, current_account_id=account.id)
        account.phone = data.phone

    if data.country_id is not None:
        ensure_country_exists(db, data.country_id)
        account.country_id = data.country_id

    if data.preferred_language is not None:
        account.preferred_language = data.preferred_language

    db.commit()
    db.refresh(auth.profile)

    return mentor_to_out(auth.profile)