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

    app.dependency_overrides[get_db] = (
        override_get_db
    )

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
        "exp": (
            datetime.now(UTC)
            + timedelta(hours=1)
        ),
    }

    if role == "admin":
        claims["admin_profile_id"] = profile_id
    elif role in {
        "mentor",
        "mentor_setup",
    }:
        claims["mentor_profile_id"] = profile_id

    return jwt.encode(
        claims,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def auth_header(
    token: str,
) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {token}",
    }


def make_session_log(
    *,
    mentor: MentorProfile,
    course: Course,
    session_date: date,
    project_title: str,
    project_type: ProjectType,
    completion_status: CompletionStatus,
    students: list[Student],
    games_played: str | None = None,
) -> SessionLog:
    return SessionLog(
        submitted_by=mentor,
        mentor_participations=[
            SessionLogMentor(
                mentor=mentor,
                role=(
                    SessionLogMentorRole.TEACHING
                ),
            ),
        ],
        course=course,
        date=session_date,
        project_title=project_title,
        project_type=project_type,
        completion_status=completion_status,
        games_played=games_played,
        students=students,
    )


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
        ],
    )
    margret_only = Course(
        name="Margret Only",
        description=(
            "Course unavailable to Abdallah."
        ),
        country_id=uganda.id,
        day_of_week=2,
        start_time=time(16, 30),
        mentors=[margret],
    )

    db_session.add_all(
        [
            hillside,
            margret_only,
        ]
    )
    db_session.flush()

    faith = Student(
        first_name="Faith",
        last_name="Nakalema",
        origin_country_id=uganda.id,
        birth_year=2014,
        gender="F",
        courses=[
            hillside,
            margret_only,
        ],
    )
    grace = Student(
        first_name="Grace",
        last_name="Namuli",
        origin_country_id=uganda.id,
        birth_year=2014,
        gender="F",
        courses=[margret_only],
    )
    no_activity = Student(
        first_name="Aisha",
        last_name="Namutebi",
        origin_country_id=uganda.id,
        birth_year=2015,
        gender="F",
        courses=[hillside],
    )

    db_session.add_all(
        [
            faith,
            grace,
            no_activity,
        ]
    )
    db_session.flush()

    logs = [
        make_session_log(
            mentor=margret,
            course=hillside,
            session_date=date(2026, 5, 16),
            project_title="Dino game",
            project_type=ProjectType.SCRATCH,
            completion_status=(
                CompletionStatus.COMPLETED
            ),
            games_played=(
                "Logic game, Reading game"
            ),
            students=[faith],
        ),
        make_session_log(
            mentor=margret,
            course=hillside,
            session_date=date(2026, 5, 30),
            project_title="Drawing game",
            project_type=ProjectType.SCRATCH,
            completion_status=(
                CompletionStatus.PARTLY_COMPLETED
            ),
            games_played="Math train",
            students=[faith],
        ),
        make_session_log(
            mentor=margret,
            course=hillside,
            session_date=date(2026, 6, 6),
            project_title="Growing flower",
            project_type=ProjectType.SCRATCH,
            completion_status=(
                CompletionStatus.COMPLETED
            ),
            games_played=(
                "Logic game, Mixed letters"
            ),
            students=[faith],
        ),
        make_session_log(
            mentor=margret,
            course=margret_only,
            session_date=date(2026, 6, 13),
            project_title="Simple car",
            project_type=ProjectType.ROBOTICS,
            completion_status=(
                CompletionStatus.PARTLY_COMPLETED
            ),
            games_played="Shopping game",
            students=[faith],
        ),
        make_session_log(
            mentor=margret,
            course=margret_only,
            session_date=date(2026, 6, 20),
            project_title="Advanced car",
            project_type=ProjectType.ROBOTICS,
            completion_status=(
                CompletionStatus.NOT_COMPLETED
            ),
            games_played="Bible game",
            students=[faith],
        ),
        make_session_log(
            mentor=margret,
            course=margret_only,
            session_date=date(2026, 6, 27),
            project_title="Drawing app",
            project_type=(
                ProjectType.APP_INVENTOR
            ),
            completion_status=(
                CompletionStatus.COMPLETED
            ),
            games_played="Reading game",
            students=[faith],
        ),
        make_session_log(
            mentor=margret,
            course=margret_only,
            session_date=date(2026, 7, 4),
            project_title="Puppy",
            project_type=ProjectType.ROBOTICS,
            completion_status=(
                CompletionStatus.COMPLETED
            ),
            games_played="Memory game",
            students=[grace],
        ),
    ]

    db_session.add_all(logs)
    db_session.commit()

    return {
        "admin": admin,
        "abdallah": abdallah,
        "margret": margret,
        "guest": guest,
        "faith": faith,
        "grace": grace,
        "no_activity": no_activity,
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
        "guest_token": make_token(
            guest_account.id,
            "mentor",
            guest.id,
        ),
        "setup_token": make_token(
            abdallah_account.id,
            "mentor_setup",
            abdallah.id,
        ),
    }


def test_admin_gets_complete_student_record(
    client,
    seeded,
):
    response = client.get(
        (
            f"/api/shared/students/"
            f"{seeded['faith'].id}/record"
        ),
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200

    assert response.json() == {
        "student_id": seeded["faith"].id,
        "first_name": "Faith",
        "last_name": "Nakalema",
        "attended_sessions": 6,
        "overall_activity_score": 4.0,
        "project_groups": [
            {
                "project_type": "scratch",
                "completed_count": 2,
                "partly_completed_count": 1,
                "not_completed_count": 0,
                "activity_score": 2.5,
                "projects": [
                    {
                        "project_title": (
                            "Dino game"
                        ),
                        "date": "2026-05-16",
                        "completion_status": (
                            "completed"
                        ),
                    },
                    {
                        "project_title": (
                            "Drawing game"
                        ),
                        "date": "2026-05-30",
                        "completion_status": (
                            "partly_completed"
                        ),
                    },
                    {
                        "project_title": (
                            "Growing flower"
                        ),
                        "date": "2026-06-06",
                        "completion_status": (
                            "completed"
                        ),
                    },
                ],
            },
            {
                "project_type": "robotics",
                "completed_count": 0,
                "partly_completed_count": 1,
                "not_completed_count": 1,
                "activity_score": 0.5,
                "projects": [
                    {
                        "project_title": (
                            "Simple car"
                        ),
                        "date": "2026-06-13",
                        "completion_status": (
                            "partly_completed"
                        ),
                    },
                    {
                        "project_title": (
                            "Advanced car"
                        ),
                        "date": "2026-06-20",
                        "completion_status": (
                            "not_completed"
                        ),
                    },
                ],
            },
            {
                "project_type": (
                    "app_inventor"
                ),
                "completed_count": 1,
                "partly_completed_count": 0,
                "not_completed_count": 0,
                "activity_score": 1.0,
                "projects": [
                    {
                        "project_title": (
                            "Drawing app"
                        ),
                        "date": "2026-06-27",
                        "completion_status": (
                            "completed"
                        ),
                    },
                ],
            },
        ],
        "skill_games": [
            {
                "name": "Bible game",
                "practice_count": 1,
            },
            {
                "name": "Logic game",
                "practice_count": 2,
            },
            {
                "name": "Math train",
                "practice_count": 1,
            },
            {
                "name": "Mixed letters",
                "practice_count": 1,
            },
            {
                "name": "Reading game",
                "practice_count": 2,
            },
            {
                "name": "Shopping game",
                "practice_count": 1,
            },
        ],
    }


def test_mentor_gets_student_activity_from_all_courses(
    client,
    seeded,
):
    response = client.get(
        (
            f"/api/shared/students/"
            f"{seeded['faith'].id}/record"
        ),
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 200

    data = response.json()

    assert data["attended_sessions"] == 6
    assert data["overall_activity_score"] == 4.0

    robotics_group = next(
        group
        for group in data["project_groups"]
        if group["project_type"] == "robotics"
    )

    assert [
        project["project_title"]
        for project in robotics_group["projects"]
    ] == [
        "Simple car",
        "Advanced car",
    ]


def test_mentor_cannot_get_unavailable_student_record(
    client,
    seeded,
):
    response = client.get(
        (
            f"/api/shared/students/"
            f"{seeded['grace'].id}/record"
        ),
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Student not available"
    )


def test_admin_can_get_any_student_record(
    client,
    seeded,
):
    response = client.get(
        (
            f"/api/shared/students/"
            f"{seeded['grace'].id}/record"
        ),
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200

    data = response.json()

    assert data["student_id"] == (
        seeded["grace"].id
    )
    assert data["attended_sessions"] == 1
    assert data["overall_activity_score"] == 1.0

    assert data["project_groups"] == [
        {
            "project_type": "robotics",
            "completed_count": 1,
            "partly_completed_count": 0,
            "not_completed_count": 0,
            "activity_score": 1.0,
            "projects": [
                {
                    "project_title": "Puppy",
                    "date": "2026-07-04",
                    "completion_status": (
                        "completed"
                    ),
                },
            ],
        },
    ]


def test_student_without_activity_returns_empty_record(
    client,
    seeded,
):
    response = client.get(
        (
            f"/api/shared/students/"
            f"{seeded['no_activity'].id}/record"
        ),
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 200

    assert response.json() == {
        "student_id": (
            seeded["no_activity"].id
        ),
        "first_name": "Aisha",
        "last_name": "Namutebi",
        "attended_sessions": 0,
        "overall_activity_score": 0.0,
        "project_groups": [],
        "skill_games": [],
    }


def test_unknown_student_record_returns_404(
    client,
    seeded,
):
    response = client.get(
        "/api/shared/students/999999/record",
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 404
    assert response.json()["detail"] == (
        "Student not found"
    )


def test_setup_token_cannot_get_student_record(
    client,
    seeded,
):
    response = client.get(
        (
            f"/api/shared/students/"
            f"{seeded['faith'].id}/record"
        ),
        headers=auth_header(
            seeded["setup_token"],
        ),
    )

    assert response.status_code in (401, 403)
