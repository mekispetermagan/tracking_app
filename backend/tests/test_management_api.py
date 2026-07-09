from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from jose import jwt
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from config import settings
from database import Base, get_db
from main import app
from models import Account, AdminProfile, Country, Course, MentorProfile, Student


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    Base.metadata.create_all(bind=engine)

    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db

    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.clear()


def make_token(account_id: int, role: str, profile_id: int) -> str:
    claims = {
        "sub": str(account_id),
        "type": role,
        "exp": datetime.now(UTC) + timedelta(hours=1),
    }

    if role == "admin":
        claims["admin_profile_id"] = profile_id
    elif role == "mentor":
        claims["mentor_profile_id"] = profile_id

    return jwt.encode(
        claims,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def seeded(db_session):
    uganda = Country(code="UG", name="Uganda")
    db_session.add(uganda)
    db_session.flush()

    abdallah_account = Account(
        first_name="Abdallah",
        last_name="Kiggundu",
        phone="0712345678",
        country_id=uganda.id,
        preferred_language="en",
    )
    margret_account = Account(
        first_name="Margret",
        last_name="Nakalema",
        phone="0774231538",
        country_id=uganda.id,
        preferred_language="en",
    )
    peter_account = Account(
        first_name="Peter",
        last_name="Mekis",
        phone="0781653508",
        country_id=uganda.id,
        preferred_language="en",
    )

    db_session.add_all([abdallah_account, margret_account, peter_account])
    db_session.flush()

    abdallah = MentorProfile(
        account_id=abdallah_account.id,
        pin_hash="test",
        must_change_pin=False,
        active=True,
    )
    margret = MentorProfile(
        account_id=margret_account.id,
        pin_hash="test",
        must_change_pin=False,
        active=True,
    )
    admin = AdminProfile(
        account_id=peter_account.id,
        password_hash="test",
        must_change_password=False,
        active=True,
    )

    db_session.add_all([abdallah, margret, admin])
    db_session.flush()

    hillside = Course(
        name="Hillside Katalemwa",
        description="Digital education course at Hillside Katalemwa.",
        country_id=uganda.id,
        mentors=[abdallah, margret],
    )
    cdi = Course(
        name="CDI Luwero",
        description="Digital education course in Luwero.",
        country_id=uganda.id,
        mentors=[abdallah, margret],
    )
    margret_only = Course(
        name="Margret Only Course",
        description="Course visible only to Margret.",
        country_id=uganda.id,
        mentors=[margret],
    )

    db_session.add_all([hillside, cdi, margret_only])
    db_session.flush()

    students = [
        Student(
            first_name="Aisha",
            last_name="Namutebi",
            origin_country_id=uganda.id,
            birth_year=2014,
            gender="F",
            courses=[hillside],
        ),
        Student(
            first_name="Brian",
            last_name="Sserwadda",
            origin_country_id=uganda.id,
            birth_year=2014,
            gender="M",
            courses=[hillside],
        ),
        Student(
            first_name="Faith",
            last_name="Nakalema",
            origin_country_id=uganda.id,
            birth_year=2014,
            gender="F",
            courses=[cdi],
        ),
        Student(
            first_name="Grace",
            last_name="Namuli",
            origin_country_id=uganda.id,
            birth_year=2014,
            gender="F",
            courses=[margret_only],
        ),
    ]

    db_session.add_all(students)
    db_session.commit()

    return {
        "uganda": uganda,
        "admin": admin,
        "admin_account": peter_account,
        "abdallah": abdallah,
        "abdallah_account": abdallah_account,
        "margret": margret,
        "margret_account": margret_account,
        "hillside": hillside,
        "cdi": cdi,
        "margret_only": margret_only,
        "students": students,
        "admin_token": make_token(peter_account.id, "admin", admin.id),
        "abdallah_token": make_token(abdallah_account.id, "mentor", abdallah.id),
        "margret_token": make_token(margret_account.id, "mentor", margret.id),
        "setup_token": make_token(abdallah_account.id, "mentor_setup", abdallah.id),
    }


def test_setup_token_cannot_access_shared_endpoints(client, seeded):
    response = client.get(
        "/api/shared/courses",
        headers=auth_header(seeded["setup_token"]),
    )

    assert response.status_code in (401, 403)


def test_mentor_token_cannot_access_admin_endpoints(client, seeded):
    response = client.get(
        "/api/admin/mentors",
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code in (401, 403)


def test_admin_gets_all_mentors(client, seeded):
    response = client.get(
        "/api/admin/mentors",
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code == 200

    data = response.json()
    names = {(mentor["first_name"], mentor["last_name"]) for mentor in data}

    assert ("Abdallah", "Kiggundu") in names
    assert ("Margret", "Nakalema") in names


def test_mentor_gets_only_own_courses(client, seeded):
    response = client.get(
        "/api/shared/courses",
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    course_names = {course["name"] for course in response.json()}

    assert course_names == {"Hillside Katalemwa", "CDI Luwero"}


def test_admin_updates_mentor_course_assignments(client, seeded):
    response = client.put(
        f"/api/admin/mentors/{seeded['margret'].id}",
        json={
            "course_ids": [seeded["hillside"].id],
        },
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code == 200
    assert response.json()["course_ids"] == [seeded["hillside"].id]

    course_response = client.get(
        f"/api/shared/courses/{seeded['cdi'].id}",
        headers=auth_header(seeded["admin_token"]),
    )

    assert course_response.status_code == 200
    assert seeded["margret"].id not in course_response.json()["mentor_ids"]


def test_mentor_cannot_update_course_mentor_assignments(client, seeded):
    response = client.put(
        f"/api/shared/courses/{seeded['hillside'].id}",
        json={
            "mentor_ids": [seeded["abdallah"].id],
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403


def test_mentor_can_create_student_for_own_course(client, seeded):
    response = client.post(
        "/api/shared/students",
        json={
            "first_name": "Joan",
            "last_name": "Nakato",
            "origin_country_id": seeded["uganda"].id,
            "birth_year": 2015,
            "gender": "F",
            "course_ids": [seeded["hillside"].id],
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    data = response.json()

    assert data["first_name"] == "Joan"
    assert data["course_ids"] == [seeded["hillside"].id]


def test_mentor_cannot_create_student_for_other_mentors_course(client, seeded):
    response = client.post(
        "/api/shared/students",
        json={
            "first_name": "Wrong",
            "last_name": "Course",
            "origin_country_id": seeded["uganda"].id,
            "birth_year": 2015,
            "gender": "M",
            "course_ids": [seeded["margret_only"].id],
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403


def test_mentor_gets_only_students_from_own_courses(client, seeded):
    response = client.get(
        "/api/shared/students",
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    names = {(student["first_name"], student["last_name"]) for student in response.json()}

    assert ("Aisha", "Namutebi") in names
    assert ("Brian", "Sserwadda") in names
    assert ("Faith", "Nakalema") in names
    assert ("Grace", "Namuli") not in names


def test_mentor_cannot_get_student_from_other_mentors_course(client, seeded):
    other_student = seeded["students"][3]

    response = client.get(
        f"/api/shared/students/{other_student.id}",
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403


def test_admin_can_update_student_course_assignments(client, seeded):
    student = seeded["students"][0]

    response = client.put(
        f"/api/shared/students/{student.id}",
        json={
            "course_ids": [seeded["cdi"].id],
        },
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code == 200
    assert response.json()["course_ids"] == [seeded["cdi"].id]


def test_mentor_cannot_deactivate_student(client, seeded):
    student = seeded["students"][0]

    response = client.put(
        f"/api/shared/students/{student.id}",
        json={
            "active": False,
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403