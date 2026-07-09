from datetime import datetime, timedelta, UTC

from pwdlib import PasswordHash

from config import settings
from database import Base, engine, SessionLocal
from models import (
    Account,
    AdminProfile,
    Country,
    Course,
    MentorProfile,
    Student,
)

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

    return account


def get_mentor_profile(db, first_name, last_name):
    return (
        db.query(MentorProfile)
        .join(Account)
        .filter(
            Account.first_name == first_name,
            Account.last_name == last_name,
        )
        .one()
    )


def add_course_with_students(db, name, description, country_id, mentors, students):
    course = Course(
        name=name,
        description=description,
        country_id=country_id,
        mentors=mentors,
    )
    db.add(course)
    db.flush()

    for student_data in students:
        student = Student(
            first_name=student_data["first_name"],
            last_name=student_data["last_name"],
            origin_country_id=country_id,
            birth_year=student_data["birth_year"],
            gender=student_data["gender"],
            courses=[course],
        )
        db.add(student)

    return course


def main():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        uganda = get_or_create_uganda(db)

        add_account(db, "Abdallah", "Kiggundu", "0712345678", uganda.id, mentor_pin="123456")
        add_account(db, "Margret", "Nakalema", "0774231538", uganda.id, mentor_pin="123456", admin_password="Margret123")
        add_account(db, "Peter", "Mekis", "0781653508", uganda.id, admin_password="Peter123")

        abdallah = get_mentor_profile(db, "Abdallah", "Kiggundu")
        margret = get_mentor_profile(db, "Margret", "Nakalema")

        shared_mentors = [abdallah, margret]

        add_course_with_students(
            db=db,
            name="Hillside Katalemwa",
            description="Digital education course at Hillside Katalemwa.",
            country_id=uganda.id,
            mentors=shared_mentors,
            students=[
                {"first_name": "Aisha", "last_name": "Namutebi", "birth_year": 2014, "gender": "F"},
                {"first_name": "Brenda", "last_name": "Nakato", "birth_year": 2015, "gender": "F"},
                {"first_name": "Claire", "last_name": "Nabunya", "birth_year": 2014, "gender": "F"},
                {"first_name": "Doreen", "last_name": "Nansubuga", "birth_year": 2013, "gender": "F"},
                {"first_name": "Esther", "last_name": "Namukasa", "birth_year": 2015, "gender": "F"},
                {"first_name": "Brian", "last_name": "Sserwadda", "birth_year": 2014, "gender": "M"},
                {"first_name": "Daniel", "last_name": "Kato", "birth_year": 2013, "gender": "M"},
                {"first_name": "Emmanuel", "last_name": "Mugisha", "birth_year": 2015, "gender": "M"},
                {"first_name": "Isaac", "last_name": "Lwanga", "birth_year": 2014, "gender": "M"},
                {"first_name": "Joshua", "last_name": "Mutebi", "birth_year": 2013, "gender": "M"},
            ],
        )

        add_course_with_students(
            db=db,
            name="CDI Luwero",
            description="Digital education course in Luwero with Change Development Initiatives.",
            country_id=uganda.id,
            mentors=shared_mentors,
            students=[
                {"first_name": "Faith", "last_name": "Nakalema", "birth_year": 2014, "gender": "F"},
                {"first_name": "Gloria", "last_name": "Nabirye", "birth_year": 2015, "gender": "F"},
                {"first_name": "Joan", "last_name": "Namugga", "birth_year": 2014, "gender": "F"},
                {"first_name": "Mercy", "last_name": "Akello", "birth_year": 2013, "gender": "F"},
                {"first_name": "Sarah", "last_name": "Nakku", "birth_year": 2015, "gender": "F"},
                {"first_name": "Aaron", "last_name": "Kisembo", "birth_year": 2014, "gender": "M"},
                {"first_name": "David", "last_name": "Mukasa", "birth_year": 2013, "gender": "M"},
                {"first_name": "Ivan", "last_name": "Sekidde", "birth_year": 2015, "gender": "M"},
                {"first_name": "Martin", "last_name": "Kiggundu", "birth_year": 2014, "gender": "M"},
                {"first_name": "Samuel", "last_name": "Nsubuga", "birth_year": 2013, "gender": "M"},
            ],
        )

        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    main()