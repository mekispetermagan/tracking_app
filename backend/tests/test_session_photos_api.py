from datetime import UTC, date, datetime, time, timedelta
from io import BytesIO
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from jose import jwt
from PIL import Image
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import routers._photos as photo_helpers
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
    SessionPhoto,
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
def photo_dirs(tmp_path, monkeypatch):
    original_dir = tmp_path / "original_photos"
    compressed_dir = tmp_path / "compressed_photos"

    original_dir.mkdir()
    compressed_dir.mkdir()

    monkeypatch.setattr(
        photo_helpers,
        "ORIGINAL_PHOTO_DIR",
        original_dir,
    )
    monkeypatch.setattr(
        photo_helpers,
        "COMPRESSED_PHOTO_DIR",
        compressed_dir,
    )

    return {
        "original": original_dir,
        "compressed": compressed_dir,
    }


@pytest.fixture()
def client(db_session, photo_dirs):
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
    return {
        "Authorization": f"Bearer {token}",
    }


def make_jpeg(
    size: tuple[int, int] = (1200, 800),
    with_metadata: bool = True,
) -> bytes:
    image = Image.new(
        "RGB",
        size,
        (120, 80, 40),
    )

    output = BytesIO()

    if with_metadata:
        exif = Image.Exif()
        exif[306] = "2026:06:07 14:00:00"

        image.save(
            output,
            format="JPEG",
            quality=95,
            exif=exif,
        )
    else:
        image.save(
            output,
            format="JPEG",
            quality=95,
        )

    return output.getvalue()


def photo_uploads(
    photo_data: bytes | None = None,
):
    data = photo_data or make_jpeg()

    return [
        (
            "files",
            (
                f"photo_{number}.jpg",
                data,
                "image/jpeg",
            ),
        )
        for number in range(1, 4)
    ]


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
        description="Course unavailable to Abdallah.",
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

    aisha = Student(
        first_name="Aisha",
        last_name="Namutebi",
        origin_country_id=uganda.id,
        birth_year=2014,
        gender="F",
        courses=[hillside],
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
        students=[aisha],
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
        what_worked="Students built the model.",
        challenges=None,
        next_step="Finish the program.",
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
        "hillside": hillside,
        "margret_only": margret_only,
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


def add_photo_records(
    db_session,
    session_log,
    mentor,
):
    photos = [
        SessionPhoto(
            session_log=session_log,
            mentor=mentor,
            photo_number=number,
            original_path=(
                f"original_photos/test_{session_log.id}_"
                f"{mentor.id}_{number}.jpg"
            ),
            compressed_path=(
                f"compressed_photos/test_{session_log.id}_"
                f"{mentor.id}_{number}.jpg"
            ),
        )
        for number in range(1, 4)
    ]

    db_session.add_all(photos)
    db_session.commit()

    return photos


def test_participating_mentor_can_submit_three_photos(
    client,
    seeded,
    db_session,
    photo_dirs,
):
    original_data = make_jpeg()

    response = client.post(
        (
            f"/api/mentor/session-logs/"
            f"{seeded['shared_log'].id}/photos"
        ),
        files=photo_uploads(original_data),
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 201

    data = response.json()

    assert len(data) == 3
    assert [
        photo["photo_number"]
        for photo in data
    ] == [1, 2, 3]

    assert all(
        photo["session_log_id"]
        == seeded["shared_log"].id
        for photo in data
    )
    assert all(
        photo["mentor_profile_id"]
        == seeded["abdallah"].id
        for photo in data
    )
    assert all(
        photo["url"].startswith(
            "/compressed_photos/",
        )
        for photo in data
    )

    stored = (
        db_session.query(SessionPhoto)
        .order_by(SessionPhoto.photo_number)
        .all()
    )

    assert len(stored) == 3

    for photo in stored:
        original_file = (
            photo_dirs["original"]
            / Path(photo.original_path).name
        )
        compressed_file = (
            photo_dirs["compressed"]
            / Path(photo.compressed_path).name
        )

        assert original_file.exists()
        assert compressed_file.exists()

        assert original_file.read_bytes() == original_data

        with Image.open(compressed_file) as image:
            assert image.format == "JPEG"
            assert image.width <= 720
            assert image.height <= 480
            assert len(image.getexif()) == 0


def test_photo_submission_requires_exactly_three_files(
    client,
    seeded,
    db_session,
):
    data = make_jpeg()

    response = client.post(
        (
            f"/api/mentor/session-logs/"
            f"{seeded['shared_log'].id}/photos"
        ),
        files=[
            (
                "files",
                (
                    "photo_1.jpg",
                    data,
                    "image/jpeg",
                ),
            ),
            (
                "files",
                (
                    "photo_2.jpg",
                    data,
                    "image/jpeg",
                ),
            ),
        ],
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "Exactly three photos are required"
    )
    assert db_session.query(SessionPhoto).count() == 0


def test_non_participant_cannot_submit_photos(
    client,
    seeded,
):
    response = client.post(
        (
            f"/api/mentor/session-logs/"
            f"{seeded['shared_log'].id}/photos"
        ),
        files=photo_uploads(),
        headers=auth_header(
            seeded["guest_token"],
        ),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Only participating mentors may submit photos"
    )


def test_admin_cannot_submit_photos(
    client,
    seeded,
):
    response = client.post(
        (
            f"/api/mentor/session-logs/"
            f"{seeded['shared_log'].id}/photos"
        ),
        files=photo_uploads(),
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code in (401, 403)


def test_setup_token_cannot_submit_photos(
    client,
    seeded,
):
    response = client.post(
        (
            f"/api/mentor/session-logs/"
            f"{seeded['shared_log'].id}/photos"
        ),
        files=photo_uploads(),
        headers=auth_header(
            seeded["setup_token"],
        ),
    )

    assert response.status_code in (401, 403)


def test_photos_cannot_be_submitted_twice(
    client,
    seeded,
):
    url = (
        f"/api/mentor/session-logs/"
        f"{seeded['shared_log'].id}/photos"
    )
    headers = auth_header(
        seeded["abdallah_token"],
    )

    first_response = client.post(
        url,
        files=photo_uploads(),
        headers=headers,
    )
    second_response = client.post(
        url,
        files=photo_uploads(),
        headers=headers,
    )

    assert first_response.status_code == 201
    assert second_response.status_code == 409
    assert second_response.json()["detail"] == (
        "Photos have already been submitted for this session"
    )


def test_failed_batch_removes_files_and_database_rows(
    client,
    seeded,
    db_session,
    photo_dirs,
):
    valid_data = make_jpeg()

    response = client.post(
        (
            f"/api/mentor/session-logs/"
            f"{seeded['shared_log'].id}/photos"
        ),
        files=[
            (
                "files",
                (
                    "photo_1.jpg",
                    valid_data,
                    "image/jpeg",
                ),
            ),
            (
                "files",
                (
                    "photo_2.jpg",
                    b"not an image",
                    "image/jpeg",
                ),
            ),
            (
                "files",
                (
                    "photo_3.jpg",
                    valid_data,
                    "image/jpeg",
                ),
            ),
        ],
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "Invalid photo file"
    )

    assert db_session.query(SessionPhoto).count() == 0
    assert list(photo_dirs["original"].iterdir()) == []
    assert list(photo_dirs["compressed"].iterdir()) == []


def test_mentor_can_get_photos_for_available_session(
    client,
    seeded,
    db_session,
):
    photos = add_photo_records(
        db_session,
        seeded["shared_log"],
        seeded["margret"],
    )

    response = client.get(
        (
            f"/api/shared/session-logs/"
            f"{seeded['shared_log'].id}/photos"
        ),
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 200

    data = response.json()

    assert [
        photo["id"]
        for photo in data
    ] == [
        photo.id
        for photo in photos
    ]


def test_mentor_cannot_get_photos_for_unavailable_session(
    client,
    seeded,
    db_session,
):
    add_photo_records(
        db_session,
        seeded["private_log"],
        seeded["margret"],
    )

    response = client.get(
        (
            f"/api/shared/session-logs/"
            f"{seeded['private_log'].id}/photos"
        ),
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Session log not available"
    )


def test_admin_can_get_photos_for_any_session(
    client,
    seeded,
    db_session,
):
    photos = add_photo_records(
        db_session,
        seeded["private_log"],
        seeded["margret"],
    )

    response = client.get(
        (
            f"/api/shared/session-logs/"
            f"{seeded['private_log'].id}/photos"
        ),
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200
    assert {
        photo["id"]
        for photo in response.json()
    } == {
        photo.id
        for photo in photos
    }


def test_admin_can_get_all_photos_for_course(
    client,
    seeded,
    db_session,
):
    abdallah_photos = add_photo_records(
        db_session,
        seeded["shared_log"],
        seeded["abdallah"],
    )
    margret_photos = add_photo_records(
        db_session,
        seeded["shared_log"],
        seeded["margret"],
    )

    response = client.get(
        (
            f"/api/shared/courses/"
            f"{seeded['hillside'].id}/photos"
        ),
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200
    assert {
        photo["id"]
        for photo in response.json()
    } == {
        photo.id
        for photo in (
            abdallah_photos
            + margret_photos
        )
    }


def test_mentor_can_get_photos_for_own_course(
    client,
    seeded,
    db_session,
):
    photos = add_photo_records(
        db_session,
        seeded["shared_log"],
        seeded["margret"],
    )

    response = client.get(
        (
            f"/api/shared/courses/"
            f"{seeded['hillside'].id}/photos"
        ),
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 200
    assert {
        photo["id"]
        for photo in response.json()
    } == {
        photo.id
        for photo in photos
    }


def test_mentor_cannot_get_photos_for_unavailable_course(
    client,
    seeded,
    db_session,
):
    add_photo_records(
        db_session,
        seeded["private_log"],
        seeded["margret"],
    )

    response = client.get(
        (
            f"/api/shared/courses/"
            f"{seeded['margret_only'].id}/photos"
        ),
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Course not available"
    )


def test_session_log_responses_do_not_include_photos(
    client,
    seeded,
):
    response = client.get(
        "/api/mentor/session-logs",
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 200

    for session_log in response.json():
        assert "photos" not in session_log
