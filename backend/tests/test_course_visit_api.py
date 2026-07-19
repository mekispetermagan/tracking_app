from datetime import UTC, datetime, time, timedelta

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
    Country,
    Course,
    CourseVisitReport,
    MentorProfile,
    Student,
)


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite://",
        connect_args={
            "check_same_thread": False,
        },
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
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.clear()


def make_token(
    account_id: int,
    role: str,
    profile_id: int,
) -> str:
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
    return {
        "Authorization": f"Bearer {token}",
    }


@pytest.fixture()
def seeded(db_session):
    uganda = Country(
        code="UG",
        name="Uganda",
    )
    db_session.add(uganda)
    db_session.flush()

    peter_account = Account(
        first_name="Peter",
        last_name="Mekis",
        phone="0781653508",
        country_id=uganda.id,
        preferred_language="en",
    )
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
    guest_account = Account(
        first_name="Guest",
        last_name="Mentor",
        phone="0700000001",
        country_id=uganda.id,
        preferred_language="en",
    )

    db_session.add_all(
        [
            peter_account,
            abdallah_account,
            margret_account,
            guest_account,
        ]
    )
    db_session.flush()

    admin = AdminProfile(
        account_id=peter_account.id,
        password_hash="test",
        must_change_password=False,
        active=True,
    )
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
    guest = MentorProfile(
        account_id=guest_account.id,
        pin_hash="test",
        must_change_pin=False,
        active=True,
    )

    db_session.add_all(
        [
            admin,
            abdallah,
            margret,
            guest,
        ]
    )
    db_session.flush()

    hillside = Course(
        name="Hillside Katalemwa",
        description="Hillside course.",
        country_id=uganda.id,
        day_of_week=6,
        start_time=time(14, 0),
        mentors=[abdallah, margret],
    )
    other_course = Course(
        name="Other Course",
        description="Separate course.",
        country_id=uganda.id,
        day_of_week=5,
        start_time=time(10, 0),
        mentors=[guest],
    )

    db_session.add_all(
        [
            hillside,
            other_course,
        ]
    )
    db_session.flush()

    aisha = Student(
        first_name="Aisha",
        last_name="Namutebi",
        origin_country_id=uganda.id,
        birth_year=2014,
        gender="F",
        courses=[hillside],
    )
    brian = Student(
        first_name="Brian",
        last_name="Sserwadda",
        origin_country_id=uganda.id,
        birth_year=2014,
        gender="M",
        courses=[hillside],
    )
    grace = Student(
        first_name="Grace",
        last_name="Namuli",
        origin_country_id=uganda.id,
        birth_year=2014,
        gender="F",
        courses=[other_course],
    )

    db_session.add_all(
        [
            aisha,
            brian,
            grace,
        ]
    )
    db_session.commit()

    return {
        "admin": admin,
        "abdallah": abdallah,
        "margret": margret,
        "guest": guest,
        "hillside": hillside,
        "other_course": other_course,
        "aisha": aisha,
        "brian": brian,
        "grace": grace,
        "admin_token": make_token(
            peter_account.id,
            "admin",
            admin.id,
        ),
        "mentor_token": make_token(
            abdallah_account.id,
            "mentor",
            abdallah.id,
        ),
    }


def valid_report_payload(seeded):
    return {
        "course_id": seeded["hillside"].id,
        "date": "2026-06-14",
        "session_status": "fully_held",
        "teaching_took_place": "yes",
        "session_followed_plan": "partly",
        "learner_engagement": "most",
        "equipment_adequate": "partly",
        "environment_status": "safe_and_respectful",
        "what_happened": (
            "Students built and programmed a humanoid robot."
        ),
        "main_strength": (
            "Most students remained actively involved."
        ),
        "main_problem": (
            "Two laptop batteries failed."
        ),
        "support_provided": (
            "The students were reorganized into pairs."
        ),
        "course_health_rating": 4,
        "safeguarding_concern": False,
        "mentors": [
            {
                "mentor_id": seeded["margret"].id,
                "role": "teaching",
                "performance_rating": 4,
            },
            {
                "mentor_id": seeded["abdallah"].id,
                "role": "supporting",
                "performance_rating": 3,
            },
        ],
        "students": [
            {
                "student_id": seeded["brian"].id,
                "interviewed": False,
            },
            {
                "student_id": seeded["aisha"].id,
                "interviewed": True,
                "enjoyment": "yes",
                "learning": "clearly",
                "feels_safe": "yes",
                "note": (
                    "She could explain how the robot moved."
                ),
            },
        ],
        "actions": [
            {
                "category": "equipment",
                "description": (
                    "Replace the two unreliable batteries."
                ),
                "responsible_person": "Peter Mekis",
                "target_date": "2026-06-21",
            },
        ],
    }


def test_admin_submits_course_visit_report(
    client,
    db_session,
    seeded,
):
    response = client.post(
        "/api/admin/course-visit-reports",
        json=valid_report_payload(seeded),
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 201

    data = response.json()

    assert data["submitted_by_admin_profile_id"] == (
        seeded["admin"].id
    )
    assert data["course_id"] == seeded["hillside"].id
    assert data["date"] == "2026-06-14"
    assert data["session_status"] == "fully_held"
    assert data["course_health_rating"] == 4
    assert data["safeguarding_concern"] is False
    assert data["safeguarding_note"] is None

    assert data["mentors"] == [
        {
            "mentor_id": seeded["abdallah"].id,
            "role": "supporting",
            "performance_rating": 3,
        },
        {
            "mentor_id": seeded["margret"].id,
            "role": "teaching",
            "performance_rating": 4,
        },
    ]

    assert data["students"] == [
        {
            "student_id": seeded["aisha"].id,
            "interviewed": True,
            "enjoyment": "yes",
            "learning": "clearly",
            "feels_safe": "yes",
            "note": (
                "She could explain how the robot moved."
            ),
        },
        {
            "student_id": seeded["brian"].id,
            "interviewed": False,
            "enjoyment": None,
            "learning": None,
            "feels_safe": None,
            "note": None,
        },
    ]

    assert len(data["actions"]) == 1
    assert data["actions"][0]["category"] == "equipment"
    assert data["actions"][0]["description"] == (
        "Replace the two unreliable batteries."
    )
    assert data["actions"][0]["responsible_person"] == (
        "Peter Mekis"
    )
    assert data["actions"][0]["target_date"] == (
        "2026-06-21"
    )
    assert data["actions"][0]["completed"] is False
    assert data["actions"][0]["completed_at"] is None

    assert data["created_at"]
    assert data["updated_at"]

    assert (
        db_session.query(CourseVisitReport).count()
        == 1
    )


def test_admin_gets_all_course_visit_reports(
    client,
    seeded,
):
    first = valid_report_payload(seeded)

    second = valid_report_payload(seeded)
    second.update(
        {
            "course_id": seeded["other_course"].id,
            "date": "2026-07-05",
            "what_happened": (
                "Students practised a drawing activity."
            ),
            "mentors": [
                {
                    "mentor_id": seeded["guest"].id,
                    "role": "teaching",
                    "performance_rating": 4,
                },
            ],
            "students": [
                {
                    "student_id": seeded["grace"].id,
                    "interviewed": True,
                    "enjoyment": "yes",
                    "learning": "partly",
                    "feels_safe": "yes",
                },
            ],
            "actions": [],
        }
    )

    for payload in (first, second):
        response = client.post(
            "/api/admin/course-visit-reports",
            json=payload,
            headers=auth_header(
                seeded["admin_token"],
            ),
        )

        assert response.status_code == 201

    response = client.get(
        "/api/admin/course-visit-reports",
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200

    reports = response.json()

    assert len(reports) == 2
    assert [
        report["course_id"]
        for report in reports
    ] == [
        seeded["other_course"].id,
        seeded["hillside"].id,
    ]
    assert [
        report["date"]
        for report in reports
    ] == [
        "2026-07-05",
        "2026-06-14",
    ]


@pytest.mark.parametrize(
    ("method", "payload"),
    [
        ("get", None),
        ("post", "valid"),
    ],
)
def test_mentor_cannot_access_course_visit_reports(
    client,
    seeded,
    method,
    payload,
):
    kwargs = {
        "headers": auth_header(
            seeded["mentor_token"],
        ),
    }

    if payload == "valid":
        kwargs["json"] = valid_report_payload(
            seeded,
        )

    response = getattr(client, method)(
        "/api/admin/course-visit-reports",
        **kwargs,
    )

    assert response.status_code in (401, 403)


def test_unknown_course_is_rejected(
    client,
    seeded,
):
    payload = valid_report_payload(seeded)
    payload["course_id"] = 999999

    response = client.post(
        "/api/admin/course-visit-reports",
        json=payload,
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 404
    assert response.json()["detail"] == (
        "Course not found"
    )


def test_unassigned_mentor_is_rejected(
    client,
    seeded,
):
    payload = valid_report_payload(seeded)
    payload["mentors"] = [
        {
            "mentor_id": seeded["guest"].id,
            "role": "teaching",
            "performance_rating": 4,
        },
    ]

    response = client.post(
        "/api/admin/course-visit-reports",
        json=payload,
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "One or more mentors are not assigned "
        "to this course"
    )


def test_unenrolled_student_is_rejected(
    client,
    seeded,
):
    payload = valid_report_payload(seeded)
    payload["students"] = [
        {
            "student_id": seeded["grace"].id,
            "interviewed": False,
        },
    ]

    response = client.post(
        "/api/admin/course-visit-reports",
        json=payload,
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "One or more students are not enrolled "
        "in this course"
    )


def test_duplicate_participant_ids_are_rejected(
    client,
    seeded,
):
    payload = valid_report_payload(seeded)
    payload["mentors"].append(
        payload["mentors"][0].copy()
    )

    response = client.post(
        "/api/admin/course-visit-reports",
        json=payload,
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 422


def test_interview_requires_all_answers(
    client,
    seeded,
):
    payload = valid_report_payload(seeded)
    del payload["students"][1]["feels_safe"]

    response = client.post(
        "/api/admin/course-visit-reports",
        json=payload,
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 422


def test_held_session_requires_observation_answers(
    client,
    seeded,
):
    payload = valid_report_payload(seeded)
    payload["learner_engagement"] = None

    response = client.post(
        "/api/admin/course-visit-reports",
        json=payload,
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 422


def test_not_held_session_can_be_reported(
    client,
    seeded,
):
    payload = valid_report_payload(seeded)
    payload.update(
        {
            "session_status": "not_held",
            "teaching_took_place": "no",
            "session_followed_plan": None,
            "learner_engagement": None,
            "equipment_adequate": None,
            "environment_status": None,
            "what_happened": (
                "No mentor or students arrived "
                "for the session."
            ),
            "course_health_rating": 1,
            "mentors": [],
            "students": [],
            "actions": [],
        }
    )

    response = client.post(
        "/api/admin/course-visit-reports",
        json=payload,
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 201
    assert response.json()["session_status"] == (
        "not_held"
    )


def test_safeguarding_concern_requires_note(
    client,
    seeded,
):
    payload = valid_report_payload(seeded)
    payload["safeguarding_concern"] = True

    response = client.post(
        "/api/admin/course-visit-reports",
        json=payload,
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 422
