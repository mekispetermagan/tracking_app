from datetime import datetime, timedelta, UTC

from pwdlib import PasswordHash

from config import settings
from database import Base, engine, SessionLocal
from models import Account, MentorProfile, AdminProfile, Country

password_hash = PasswordHash.recommended()


def hash_secret(secret: str) -> str:
    return password_hash.hash(secret)

def get_or_create_uganda(db):
    country = db.query(Country).filter_by(name="Uganda").first()
    if not country:
        country = Country(code="UG", name="Uganda")
        db.add(country)
        db.flush()
    return country


def add_account(db, first_name, last_name, phone, country_id, mentor_pin=None, admin_password=None):
    account = Account(
        first_name=first_name,
        last_name=last_name,
        phone=phone,
        country_id=country_id,
        preferred_language="en",
    )
    db.add(account)
    db.flush()

    expiry = datetime.now(UTC) + timedelta(days=settings.temporary_secret_days)

    if mentor_pin:
        db.add(MentorProfile(
            account_id=account.id,
            pin_hash=hash_secret(mentor_pin),
            must_change_pin=True,
            temporary_pin_expires_at=expiry,
        ))

    if admin_password:
        db.add(AdminProfile(
            account_id=account.id,
            password_hash=hash_secret(admin_password),
            must_change_password=True,
            temporary_password_expires_at=expiry,
        ))


def main():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        uganda = get_or_create_uganda(db)

        add_account(db, "Abdallah", "Kiggundu", "0712345678", uganda.id, mentor_pin="123456")
        add_account(db, "Margret", "Nakalema", "0774231538", uganda.id, mentor_pin="123456", admin_password="Margret123")
        add_account(db, "Peter", "Mekis", "0781653508", uganda.id, admin_password="Peter123")

        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    main()