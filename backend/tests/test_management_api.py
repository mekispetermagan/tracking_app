from datetime import UTC, date, datetime, time, timedelta

import pytest
from fastapi.testclient import TestClient
from jose import jwt
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from config import settings
from database import Base, get_db
from main import app
from models import (
    Account,
    AdminProfile,
    CompletionStatus,
    Country,
    Course,
    MentorProfile,
    ProjectType,
    SessionLog,
    SessionLogMentor,
    SessionLogMentorRole,
    Student,
)

@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=engine,
    )

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

    db_session.add_all(
        [
            abdallah_account,
            margret_account,
            peter_account,
        ]
    )
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
        day_of_week=6,
        start_time=time(14, 0),
        mentors=[abdallah, margret],
    )
    cdi = Course(
        name="CDI Luwero",
        description="Digital education course in Luwero.",
        country_id=uganda.id,
        day_of_week=5,
        start_time=time(10, 0),
        mentors=[abdallah, margret],
    )
    margret_only = Course(
        name="Margret Only Course",
        description="Course visible only to Margret.",
        country_id=uganda.id,
        day_of_week=2,
        start_time=time(16, 30),
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
        "admin_token": make_token(
            peter_account.id,
            "admin",
            admin.id,
        ),
        "abdallah_token": make_token(
            abdallah_account.id,
            "mentor",
            abdallah.id,
        ),
        "margret_token": make_token(
            margret_account.id,
            "mentor",
            margret.id,
        ),
        "setup_token": make_token(
            abdallah_account.id,
            "mentor_setup",
            abdallah.id,
        ),
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
    names = {
        (mentor["first_name"], mentor["last_name"])
        for mentor in data
    }

    assert ("Abdallah", "Kiggundu") in names
    assert ("Margret", "Nakalema") in names


def test_mentor_gets_only_own_courses(client, seeded):
    response = client.get(
        "/api/shared/courses",
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    courses = response.json()
    course_names = {course["name"] for course in courses}

    assert course_names == {
        "Hillside Katalemwa",
        "CDI Luwero",
    }

    hillside = next(
        course
        for course in courses
        if course["name"] == "Hillside Katalemwa"
    )

    assert hillside["day_of_week"] == 6
    assert hillside["start_time"] == "14:00:00"


def test_admin_creates_course_with_day_and_start_time(client, seeded):
    response = client.post(
        "/api/admin/courses",
        json={
            "name": "Kirinnyabigo",
            "description": "Course in Kirinnyabigo.",
            "country_id": seeded["uganda"].id,
            "day_of_week": 1,
            "start_time": "15:30:00",
            "active": True,
            "mentor_ids": [
                seeded["abdallah"].id,
                seeded["margret"].id,
            ],
            "student_ids": [],
        },
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code == 200

    data = response.json()

    assert data["name"] == "Kirinnyabigo"
    assert data["day_of_week"] == 1
    assert data["start_time"] == "15:30:00"
    assert set(data["mentor_ids"]) == {
        seeded["abdallah"].id,
        seeded["margret"].id,
    }


def test_admin_updates_course_day_and_start_time(client, seeded):
    response = client.put(
        f"/api/shared/courses/{seeded['hillside'].id}",
        json={
            "day_of_week": 3,
            "start_time": "17:45:00",
        },
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code == 200

    data = response.json()

    assert data["day_of_week"] == 3
    assert data["start_time"] == "17:45:00"


def test_course_rejects_day_above_six(client, seeded):
    response = client.put(
        f"/api/shared/courses/{seeded['hillside'].id}",
        json={
            "day_of_week": 7,
        },
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code == 422


def test_course_rejects_negative_day(client, seeded):
    response = client.put(
        f"/api/shared/courses/{seeded['hillside'].id}",
        json={
            "day_of_week": -1,
        },
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code == 422


def test_admin_updates_mentor_course_assignments(client, seeded):
    response = client.put(
        f"/api/admin/mentors/{seeded['margret'].id}",
        json={
            "course_ids": [seeded["hillside"].id],
        },
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code == 200
    assert response.json()["course_ids"] == [
        seeded["hillside"].id,
    ]

    course_response = client.get(
        f"/api/shared/courses/{seeded['cdi'].id}",
        headers=auth_header(seeded["admin_token"]),
    )

    assert course_response.status_code == 200
    assert (
        seeded["margret"].id
        not in course_response.json()["mentor_ids"]
    )


def test_mentor_can_update_course_description_day_and_time(client, seeded):
    response = client.put(
        f"/api/shared/courses/{seeded['hillside'].id}",
        json={
            "description": "Updated course description.",
            "day_of_week": 2,
            "start_time": "17:30:00",
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    data = response.json()

    assert data["description"] == "Updated course description."
    assert data["day_of_week"] == 2
    assert data["start_time"] == "17:30:00"


def test_mentor_cannot_update_course_name(client, seeded):
    response = client.put(
        f"/api/shared/courses/{seeded['hillside'].id}",
        json={
            "name": "Renamed Course",
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Mentor cannot change course name"
    )


def test_mentor_cannot_update_course_country(client, seeded):
    response = client.put(
        f"/api/shared/courses/{seeded['hillside'].id}",
        json={
            "country_id": seeded["uganda"].id + 1,
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Mentor cannot change course country"
    )


def test_mentor_cannot_update_course_status(client, seeded):
    response = client.put(
        f"/api/shared/courses/{seeded['hillside'].id}",
        json={
            "active": False,
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Mentor cannot change course status"
    )


def test_mentor_cannot_update_course_mentor_assignments(
    client,
    seeded,
):
    response = client.put(
        f"/api/shared/courses/{seeded['hillside'].id}",
        json={
            "mentor_ids": [seeded["abdallah"].id],
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Mentor cannot assign or unassign mentors to courses"
    )


def test_mentor_can_submit_unchanged_restricted_course_fields(
    client,
    seeded,
):
    response = client.put(
        f"/api/shared/courses/{seeded['hillside'].id}",
        json={
            "name": seeded["hillside"].name,
            "country_id": seeded["hillside"].country_id,
            "active": seeded["hillside"].active,
            "mentor_ids": [
                mentor.id
                for mentor in seeded["hillside"].mentors
            ],
            "description": "Changed by mentor.",
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200
    assert response.json()["description"] == "Changed by mentor."


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
    assert data["course_ids"] == [
        seeded["hillside"].id,
    ]


def test_mentor_cannot_create_student_for_other_mentors_course(
    client,
    seeded,
):
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

    names = {
        (student["first_name"], student["last_name"])
        for student in response.json()
    }

    assert ("Aisha", "Namutebi") in names
    assert ("Brian", "Sserwadda") in names
    assert ("Faith", "Nakalema") in names
    assert ("Grace", "Namuli") not in names


def test_mentor_cannot_get_student_from_other_mentors_course(
    client,
    seeded,
):
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
    assert response.json()["course_ids"] == [
        seeded["cdi"].id,
    ]


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


def test_mentor_must_assign_new_student_to_course(client, seeded):
    response = client.post(
        "/api/shared/students",
        json={
            "first_name": "No",
            "last_name": "Course",
            "origin_country_id": seeded["uganda"].id,
            "birth_year": 2015,
            "gender": "F",
            "course_ids": [],
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "Mentor must assign student to a course"
    )


def test_mentor_cannot_create_inactive_student(client, seeded):
    response = client.post(
        "/api/shared/students",
        json={
            "first_name": "Inactive",
            "last_name": "Student",
            "origin_country_id": seeded["uganda"].id,
            "birth_year": 2015,
            "gender": "M",
            "active": False,
            "course_ids": [seeded["hillside"].id],
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Mentor cannot create inactive student"
    )


def test_mentor_student_reads_hide_other_mentors_course_ids(
    client,
    seeded,
    db_session,
):
    shared_student = Student(
        first_name="Shared",
        last_name="Student",
        origin_country_id=seeded["uganda"].id,
        birth_year=2014,
        gender="F",
        courses=[
            seeded["hillside"],
            seeded["margret_only"],
        ],
    )
    db_session.add(shared_student)
    db_session.commit()

    list_response = client.get(
        "/api/shared/students",
        headers=auth_header(seeded["abdallah_token"]),
    )
    course_response = client.get(
        f"/api/shared/students?course_id={seeded['hillside'].id}",
        headers=auth_header(seeded["abdallah_token"]),
    )
    detail_response = client.get(
        f"/api/shared/students/{shared_student.id}",
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert list_response.status_code == 200
    assert course_response.status_code == 200
    assert detail_response.status_code == 200

    list_student = next(
        student
        for student in list_response.json()
        if student["id"] == shared_student.id
    )
    course_student = next(
        student
        for student in course_response.json()
        if student["id"] == shared_student.id
    )

    expected_course_ids = [seeded["hillside"].id]

    assert list_student["course_ids"] == expected_course_ids
    assert course_student["course_ids"] == expected_course_ids
    assert detail_response.json()["course_ids"] == expected_course_ids

    admin_response = client.get(
        f"/api/shared/students/{shared_student.id}",
        headers=auth_header(seeded["admin_token"]),
    )

    assert admin_response.status_code == 200
    assert set(admin_response.json()["course_ids"]) == {
        seeded["hillside"].id,
        seeded["margret_only"].id,
    }


def test_mentor_update_preserves_other_mentors_course_assignments(
    client,
    seeded,
    db_session,
):
    shared_student = Student(
        first_name="Shared",
        last_name="Update",
        origin_country_id=seeded["uganda"].id,
        birth_year=2014,
        gender="M",
        courses=[
            seeded["hillside"],
            seeded["margret_only"],
        ],
    )
    db_session.add(shared_student)
    db_session.commit()

    response = client.put(
        f"/api/shared/students/{shared_student.id}",
        json={
            "course_ids": [seeded["cdi"].id],
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200
    assert response.json()["course_ids"] == [seeded["cdi"].id]

    admin_response = client.get(
        f"/api/shared/students/{shared_student.id}",
        headers=auth_header(seeded["admin_token"]),
    )

    assert admin_response.status_code == 200
    assert set(admin_response.json()["course_ids"]) == {
        seeded["cdi"].id,
        seeded["margret_only"].id,
    }


def test_mentor_can_unassign_student_from_all_own_courses(
    client,
    seeded,
    db_session,
):
    shared_student = Student(
        first_name="Disappearing",
        last_name="Student",
        origin_country_id=seeded["uganda"].id,
        birth_year=2014,
        gender="F",
        courses=[
            seeded["hillside"],
            seeded["margret_only"],
        ],
    )
    db_session.add(shared_student)
    db_session.commit()

    response = client.put(
        f"/api/shared/students/{shared_student.id}",
        json={"course_ids": []},
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200
    assert response.json()["course_ids"] == []

    mentor_response = client.get(
        f"/api/shared/students/{shared_student.id}",
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert mentor_response.status_code == 403

    admin_response = client.get(
        f"/api/shared/students/{shared_student.id}",
        headers=auth_header(seeded["admin_token"]),
    )

    assert admin_response.status_code == 200
    assert admin_response.json()["course_ids"] == [
        seeded["margret_only"].id,
    ]


def test_mentor_cannot_assign_existing_student_to_foreign_course(
    client,
    seeded,
):
    student = seeded["students"][0]

    response = client.put(
        f"/api/shared/students/{student.id}",
        json={
            "course_ids": [seeded["margret_only"].id],
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Cannot assign student to this course"
    )

    admin_response = client.get(
        f"/api/shared/students/{student.id}",
        headers=auth_header(seeded["admin_token"]),
    )

    assert admin_response.status_code == 200
    assert admin_response.json()["course_ids"] == [
        seeded["hillside"].id,
    ]


def test_mentor_can_edit_visible_student_details(client, seeded):
    student = seeded["students"][0]

    response = client.put(
        f"/api/shared/students/{student.id}",
        json={
            "first_name": "Aishah",
            "last_name": "Namutebi-Kato",
            "birth_year": 2013,
            "gender": "F",
            "course_ids": [
                seeded["hillside"].id,
                seeded["cdi"].id,
            ],
        },
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    data = response.json()

    assert data["first_name"] == "Aishah"
    assert data["last_name"] == "Namutebi-Kato"
    assert data["birth_year"] == 2013
    assert data["gender"] == "F"
    assert set(data["course_ids"]) == {
        seeded["hillside"].id,
        seeded["cdi"].id,
    }

def test_mentor_gets_mentors_for_assigned_course(
    client,
    seeded,
):
    response = client.get(
        (
            "/api/shared/mentors"
            f"?course_id={seeded['hillside'].id}"
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    data = response.json()
    mentors_by_id = {
        mentor["id"]: mentor
        for mentor in data
    }

    assert set(mentors_by_id) == {
        seeded["abdallah"].id,
        seeded["margret"].id,
    }

    assert mentors_by_id[seeded["abdallah"].id] == {
        "id": seeded["abdallah"].id,
        "first_name": "Abdallah",
        "last_name": "Kiggundu",
        "active": True,
        "assigned_to_course": True,
    }

    assert mentors_by_id[seeded["margret"].id] == {
        "id": seeded["margret"].id,
        "first_name": "Margret",
        "last_name": "Nakalema",
        "active": True,
        "assigned_to_course": True,
    }


def test_shared_mentor_response_excludes_private_fields(
    client,
    seeded,
):
    response = client.get(
        (
            "/api/shared/mentors"
            f"?course_id={seeded['hillside'].id}"
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    for mentor in response.json():
        assert set(mentor) == {
            "id",
            "first_name",
            "last_name",
            "active",
            "assigned_to_course",
        }

        assert "phone" not in mentor
        assert "account_id" not in mentor
        assert "course_ids" not in mentor


def test_mentor_cannot_get_mentors_for_unavailable_course(
    client,
    seeded,
):
    response = client.get(
        (
            "/api/shared/mentors"
            f"?course_id={seeded['margret_only'].id}"
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Course not available"
    )


def test_admin_gets_mentors_for_any_course(
    client,
    seeded,
):
    response = client.get(
        (
            "/api/shared/mentors"
            f"?course_id={seeded['margret_only'].id}"
        ),
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code == 200

    assert response.json() == [
        {
            "id": seeded["margret"].id,
            "first_name": "Margret",
            "last_name": "Nakalema",
            "active": True,
            "assigned_to_course": True,
        },
    ]


def test_inactive_assigned_mentor_is_listed(
    client,
    seeded,
    db_session,
):
    account = Account(
        first_name="Inactive",
        last_name="Mentor",
        phone="0700000001",
        country_id=seeded["uganda"].id,
        preferred_language="en",
    )
    db_session.add(account)
    db_session.flush()

    mentor = MentorProfile(
        account_id=account.id,
        pin_hash="test",
        must_change_pin=False,
        active=False,
    )

    seeded["hillside"].mentors.append(mentor)

    db_session.add(mentor)
    db_session.commit()

    response = client.get(
        (
            "/api/shared/mentors"
            f"?course_id={seeded['hillside'].id}"
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    inactive = next(
        item
        for item in response.json()
        if item["id"] == mentor.id
    )

    assert inactive == {
        "id": mentor.id,
        "first_name": "Inactive",
        "last_name": "Mentor",
        "active": False,
        "assigned_to_course": True,
    }


def test_historical_mentor_remains_visible_after_unassignment(
    client,
    seeded,
    db_session,
):
    account = Account(
        first_name="Former",
        last_name="Mentor",
        phone="0700000002",
        country_id=seeded["uganda"].id,
        preferred_language="en",
    )
    db_session.add(account)
    db_session.flush()

    former_mentor = MentorProfile(
        account_id=account.id,
        pin_hash="test",
        must_change_pin=False,
        active=True,
    )
    db_session.add(former_mentor)
    db_session.flush()

    session_log = SessionLog(
        submitted_by=former_mentor,
        course=seeded["hillside"],
        date=date(2026, 7, 1),
        project_title="Historical project",
        project_type=ProjectType.SCRATCH,
        completion_status=CompletionStatus.COMPLETED,
        mentor_participations=[
            SessionLogMentor(
                mentor=former_mentor,
                role=SessionLogMentorRole.TEACHING,
            ),
        ],
        students=[seeded["students"][0]],
    )

    db_session.add(session_log)
    db_session.commit()

    assert former_mentor not in seeded["hillside"].mentors

    response = client.get(
        (
            "/api/shared/mentors"
            f"?course_id={seeded['hillside'].id}"
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    historical = next(
        item
        for item in response.json()
        if item["id"] == former_mentor.id
    )

    assert historical == {
        "id": former_mentor.id,
        "first_name": "Former",
        "last_name": "Mentor",
        "active": True,
        "assigned_to_course": False,
    }


def test_get_course_mentors_returns_not_found(
    client,
    seeded,
):
    response = client.get(
        "/api/shared/mentors?course_id=999999",
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Course not found"
