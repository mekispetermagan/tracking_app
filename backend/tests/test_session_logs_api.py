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
    elif role in {"mentor", "mentor_setup"}:
        claims["mentor_profile_id"] = profile_id

    return jwt.encode(
        claims,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def session_log_payload(
    course_id: int,
    student_ids: list[int],
    teaching_mentor_ids: list[int],
    supporting_mentor_ids: list[int] | None = None,
    **overrides,
):
    payload = {
        "course_id": course_id,
        "date": "2026-07-05",
        "project_title": "Crazy letters",
        "project_type": "scratch",
        "other_project_type": None,
        "games_played": "Mixed letters",
        "completion_status": "completed",
        "what_worked": "Students understood the project.",
        "challenges": "Some needed help with debugging.",
        "next_step": "Add another animation.",
        "teaching_mentor_ids": teaching_mentor_ids,
        "supporting_mentor_ids": supporting_mentor_ids or [],
        "student_ids": student_ids,
    }

    payload.update(overrides)
    return payload


@pytest.fixture()
def seeded(db_session):
    uganda = Country(
        code="UG",
        name="Uganda",
    )
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
    guest_account = Account(
        first_name="Guest",
        last_name="Mentor",
        phone="0700000001",
        country_id=uganda.id,
        preferred_language="en",
    )
    inactive_account = Account(
        first_name="Inactive",
        last_name="Mentor",
        phone="0700000002",
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
            guest_account,
            inactive_account,
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
    guest = MentorProfile(
        account_id=guest_account.id,
        pin_hash="test",
        must_change_pin=False,
        active=True,
    )
    inactive = MentorProfile(
        account_id=inactive_account.id,
        pin_hash="test",
        must_change_pin=False,
        active=False,
    )
    admin = AdminProfile(
        account_id=peter_account.id,
        password_hash="test",
        must_change_password=False,
        active=True,
    )

    db_session.add_all(
        [
            abdallah,
            margret,
            guest,
            inactive,
            admin,
        ]
    )
    db_session.flush()

    hillside = Course(
        name="Hillside Katalemwa",
        description="Shared course.",
        country_id=uganda.id,
        day_of_week=6,
        start_time=time(14, 0),
        mentors=[
            abdallah,
            margret,
            inactive,
        ],
    )
    abdallah_only = Course(
        name="Abdallah Only",
        description="Course assigned only to Abdallah.",
        country_id=uganda.id,
        day_of_week=5,
        start_time=time(10, 0),
        mentors=[abdallah],
    )
    margret_only = Course(
        name="Margret Only",
        description="Course assigned only to Margret.",
        country_id=uganda.id,
        day_of_week=2,
        start_time=time(16, 30),
        mentors=[margret],
    )

    db_session.add_all(
        [
            hillside,
            abdallah_only,
            margret_only,
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
    faith = Student(
        first_name="Faith",
        last_name="Nakalema",
        origin_country_id=uganda.id,
        birth_year=2014,
        gender="F",
        courses=[abdallah_only],
    )
    grace = Student(
        first_name="Grace",
        last_name="Namuli",
        origin_country_id=uganda.id,
        birth_year=2014,
        gender="F",
        courses=[margret_only],
    )

    db_session.add_all(
        [
            aisha,
            brian,
            faith,
            grace,
        ]
    )
    db_session.flush()

    shared_log = SessionLog(
        submitted_by=margret,
        mentor_participations=[
            SessionLogMentor(
                mentor=margret,
                role=SessionLogMentorRole.TEACHING,
            ),
            SessionLogMentor(
                mentor=abdallah,
                role=SessionLogMentorRole.SUPPORTING,
            ),
        ],
        course=hillside,
        date=date(2026, 6, 7),
        project_title="Dancing animation",
        project_type=ProjectType.SCRATCH,
        games_played="Reading game",
        completion_status=CompletionStatus.COMPLETED,
        what_worked="Pair work worked well.",
        challenges=None,
        next_step="Continue with Crazy letters.",
        students=[aisha, brian],
    )
    private_log = SessionLog(
        submitted_by=margret,
        mentor_participations=[
            SessionLogMentor(
                mentor=margret,
                role=SessionLogMentorRole.TEACHING,
            ),
        ],
        course=margret_only,
        date=date(2026, 6, 10),
        project_title="Puppy",
        project_type=ProjectType.ROBOTICS,
        games_played="Logic game",
        completion_status=CompletionStatus.PARTLY_COMPLETED,
        what_worked="Students built the basic model.",
        challenges="Programming took longer than expected.",
        next_step="Finish the movement program.",
        students=[grace],
    )

    db_session.add_all(
        [
            shared_log,
            private_log,
        ]
    )
    db_session.commit()

    return {
        "admin": admin,
        "abdallah": abdallah,
        "margret": margret,
        "guest": guest,
        "inactive": inactive,
        "hillside": hillside,
        "abdallah_only": abdallah_only,
        "margret_only": margret_only,
        "aisha": aisha,
        "brian": brian,
        "faith": faith,
        "grace": grace,
        "shared_log": shared_log,
        "private_log": private_log,
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


def test_mentor_can_submit_session_log(
    client,
    seeded,
    db_session,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [
                seeded["aisha"].id,
                seeded["brian"].id,
            ],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
            ],
            supporting_mentor_ids=[
                seeded["margret"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 201

    data = response.json()

    assert data["submitted_by_mentor_profile_id"] == (
        seeded["abdallah"].id
    )
    assert data["course_id"] == seeded["hillside"].id
    assert data["project_title"] == "Crazy letters"
    assert data["project_type"] == "scratch"
    assert data["games_played"] == "Mixed letters"
    assert data["teaching_mentor_ids"] == [
        seeded["abdallah"].id,
    ]
    assert data["supporting_mentor_ids"] == [
        seeded["margret"].id,
    ]
    assert set(data["student_ids"]) == {
        seeded["aisha"].id,
        seeded["brian"].id,
    }

    stored = db_session.get(SessionLog, data["id"])

    assert stored is not None
    assert stored.submitted_by_mentor_profile_id == (
        seeded["abdallah"].id
    )
    assert {
        participation.mentor_profile_id:
            participation.role
        for participation in stored.mentor_participations
    } == {
        seeded["abdallah"].id:
            SessionLogMentorRole.TEACHING,
        seeded["margret"].id:
            SessionLogMentorRole.SUPPORTING,
    }
    assert {
        student.id
        for student in stored.students
    } == {
        seeded["aisha"].id,
        seeded["brian"].id,
    }


def test_submitter_does_not_have_to_be_present(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [seeded["aisha"].id],
            teaching_mentor_ids=[
                seeded["margret"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 201

    data = response.json()

    assert data["submitted_by_mentor_profile_id"] == (
        seeded["abdallah"].id
    )
    assert data["teaching_mentor_ids"] == [
        seeded["margret"].id,
    ]
    assert data["supporting_mentor_ids"] == []


def test_admin_cannot_submit_session_log(client, seeded):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [seeded["aisha"].id],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
            ],
        ),
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code in (401, 403)


def test_setup_token_cannot_submit_session_log(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [seeded["aisha"].id],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
            ],
        ),
        headers=auth_header(seeded["setup_token"]),
    )

    assert response.status_code in (401, 403)


def test_mentor_cannot_submit_log_for_unavailable_course(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["margret_only"].id,
            [seeded["grace"].id],
            teaching_mentor_ids=[
                seeded["margret"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Course not available"


def test_mentor_cannot_include_student_from_another_course(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [
                seeded["aisha"].id,
                seeded["grace"].id,
            ],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "One or more students are not enrolled in this course"
    )


def test_session_log_requires_at_least_one_student(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 422


def test_session_log_rejects_duplicate_student_ids(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [
                seeded["aisha"].id,
                seeded["aisha"].id,
            ],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 422


def test_session_log_requires_teaching_mentor(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [seeded["aisha"].id],
            teaching_mentor_ids=[],
            supporting_mentor_ids=[
                seeded["margret"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 422


def test_session_log_rejects_duplicate_teaching_mentors(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [seeded["aisha"].id],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
                seeded["abdallah"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 422


def test_session_log_rejects_duplicate_supporting_mentors(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [seeded["aisha"].id],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
            ],
            supporting_mentor_ids=[
                seeded["margret"].id,
                seeded["margret"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 422


def test_session_log_rejects_overlapping_mentor_roles(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [seeded["aisha"].id],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
            ],
            supporting_mentor_ids=[
                seeded["abdallah"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 422


def test_unassigned_mentor_cannot_be_selected(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [seeded["aisha"].id],
            teaching_mentor_ids=[
                seeded["guest"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "One or more mentors are not assigned to this course"
    )


def test_inactive_mentor_cannot_be_selected(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [seeded["aisha"].id],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
            ],
            supporting_mentor_ids=[
                seeded["inactive"].id,
            ],
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "One or more selected mentors are inactive"
    )


def test_other_project_type_must_be_specified(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [seeded["aisha"].id],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
            ],
            project_type="other",
            other_project_type=None,
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 422


def test_other_project_type_is_removed_for_known_type(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/session-logs",
        json=session_log_payload(
            seeded["hillside"].id,
            [seeded["aisha"].id],
            teaching_mentor_ids=[
                seeded["abdallah"].id,
            ],
            project_type="scratch",
            other_project_type="Something else",
        ),
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 201
    assert response.json()["other_project_type"] is None


def test_mentor_gets_logs_from_own_courses_only(
    client,
    seeded,
):
    response = client.get(
        "/api/mentor/session-logs",
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    log_ids = {
        session_log["id"]
        for session_log in response.json()
    }

    assert seeded["shared_log"].id in log_ids
    assert seeded["private_log"].id not in log_ids


def test_mentor_sees_other_mentors_log_for_shared_course(
    client,
    seeded,
):
    response = client.get(
        "/api/mentor/session-logs",
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code == 200

    shared_log = next(
        session_log
        for session_log in response.json()
        if session_log["id"] == seeded["shared_log"].id
    )

    assert shared_log[
        "submitted_by_mentor_profile_id"
    ] == seeded["margret"].id
    assert shared_log["course_id"] == seeded["hillside"].id
    assert shared_log["teaching_mentor_ids"] == [
        seeded["margret"].id,
    ]
    assert shared_log["supporting_mentor_ids"] == [
        seeded["abdallah"].id,
    ]


def test_admin_gets_all_session_logs(client, seeded):
    response = client.get(
        "/api/admin/session-logs",
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code == 200

    data = response.json()
    log_ids = {
        session_log["id"]
        for session_log in data
    }

    assert log_ids == {
        seeded["shared_log"].id,
        seeded["private_log"].id,
    }

    shared_log = next(
        session_log
        for session_log in data
        if session_log["id"] == seeded["shared_log"].id
    )

    assert shared_log[
        "submitted_by_mentor_profile_id"
    ] == seeded["margret"].id
    assert shared_log["teaching_mentor_ids"] == [
        seeded["margret"].id,
    ]
    assert shared_log["supporting_mentor_ids"] == [
        seeded["abdallah"].id,
    ]


def test_mentor_cannot_access_admin_session_logs(
    client,
    seeded,
):
    response = client.get(
        "/api/admin/session-logs",
        headers=auth_header(seeded["abdallah_token"]),
    )

    assert response.status_code in (401, 403)


def test_session_logs_are_ordered_newest_first(
    client,
    seeded,
):
    response = client.get(
        "/api/admin/session-logs",
        headers=auth_header(seeded["admin_token"]),
    )

    assert response.status_code == 200

    dates = [
        session_log["date"]
        for session_log in response.json()
    ]

    assert dates == sorted(dates, reverse=True)
