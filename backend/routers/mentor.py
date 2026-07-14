from fastapi import APIRouter, Depends, HTTPException, Response, status

from dependencies import MentorAuth, get_current_mentor
from routers._management import (
    ensure_country_exists,
    ensure_phone_available,
    mentor_to_out,
)
from security import hash_secret, verify_secret

from schemas.management import MentorChangePinRequest, MentorOut, MentorSelfUpdateRequest

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

    db.commit()
    db.refresh(auth.profile)

    return mentor_to_out(auth.profile)


@router.put("/me/pin", status_code=status.HTTP_204_NO_CONTENT)
def change_my_pin(
    data: MentorChangePinRequest,
    auth: MentorAuth = Depends(get_current_mentor),
):
    if not verify_secret(data.current_pin, auth.profile.pin_hash):
        raise HTTPException(status_code=400, detail="Current PIN is incorrect")

    auth.profile.pin_hash = hash_secret(data.new_pin)
    auth.db.commit()

    return Response(status_code=status.HTTP_204_NO_CONTENT)
