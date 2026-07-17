from datetime import UTC, date, datetime, time, timedelta

import pytest
from fastapi.testclient import TestClient
from jose import jwt
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import routers.mentor as mentor_router
from config import settings
from database import Base, get_db
from main import app
from models import (
    Account,
    AdminProfile,
    Country,
    Course,
    MentorProfile,
    Story,
    StoryMentorRating,
    StoryOfMonth,
    StoryPhoto,
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


@pytest.fixture(autouse=True)
def fake_story_photo_storage(monkeypatch):
    async def fake_store_story_photo(
        upload,
        story_id,
        submission_date,
        mentor_profile_id,
    ):
        filename = (
            f"{story_id:02d}_"
            f"{submission_date:%Y%m%d}_"
            f"{mentor_profile_id:02d}_"
            "123456.jpg"
        )

        return (
            f"original_story_photos/{filename}",
            f"compressed_story_photos/{filename}",
            [],
        )

    monkeypatch.setattr(
        mentor_router,
        "store_story_photo",
        fake_store_story_photo,
    )


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


def story_form(
    course_id: int,
    text: str = "A new story from the course.",
):
    return {
        "data": {
            "course_id": str(course_id),
            "text": text,
        },
        "files": {
            "photo": (
                "story.jpg",
                b"fake photo content",
                "image/jpeg",
            ),
        },
    }


def story_datetime(
    month: date,
    day: int = 1,
    hour: int = 10,
) -> datetime:
    return datetime(
        month.year,
        month.month,
        day,
        hour,
        tzinfo=UTC,
    )


def add_story(
    db,
    mentor,
    course,
    month,
    suffix,
    *,
    active=True,
):
    submitted_at = story_datetime(month)

    story = Story(
        submitted_by=mentor,
        course=course,
        text=f"Story {suffix}",
        submission_month=month,
        active=active,
        created_at=submitted_at,
        updated_at=submitted_at,
    )

    story.photo = StoryPhoto(
        original_path=(
            f"original_story_photos/{suffix}.jpg"
        ),
        compressed_path=(
            f"compressed_story_photos/{suffix}.jpg"
        ),
        uploaded_at=submitted_at,
    )

    db.add(story)
    db.flush()

    return story


@pytest.fixture()
def seeded(db_session):
    current_month = (
        datetime.now(UTC)
        .date()
        .replace(day=1)
    )
    previous_month = (
        current_month - timedelta(days=1)
    ).replace(day=1)

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
    )
    margret_account = Account(
        first_name="Margret",
        last_name="Nakalema",
        phone="0774231538",
        country_id=uganda.id,
    )
    stephen_account = Account(
        first_name="Stephen",
        last_name="Juuko",
        phone="0123456789",
        country_id=uganda.id,
    )
    guest_account = Account(
        first_name="Guest",
        last_name="Mentor",
        phone="0700000001",
        country_id=uganda.id,
    )
    peter_account = Account(
        first_name="Peter",
        last_name="Mekis",
        phone="0781653508",
        country_id=uganda.id,
    )

    db_session.add_all(
        [
            abdallah_account,
            margret_account,
            stephen_account,
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
    stephen = MentorProfile(
        account_id=stephen_account.id,
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
            stephen,
            guest,
            admin,
        ]
    )
    db_session.flush()

    hillside = Course(
        name="Hillside Katalemwa",
        description="Hillside course.",
        country_id=uganda.id,
        day_of_week=6,
        start_time=time(14, 0),
        active=True,
        mentors=[
            abdallah,
            margret,
        ],
    )
    cdi = Course(
        name="CDI Luwero",
        description="CDI course.",
        country_id=uganda.id,
        day_of_week=5,
        start_time=time(10, 0),
        active=True,
        mentors=[
            margret,
            stephen,
        ],
    )
    inactive_course = Course(
        name="Inactive Course",
        description="Inactive course.",
        country_id=uganda.id,
        day_of_week=0,
        start_time=time(10, 0),
        active=False,
        mentors=[
            guest,
            abdallah,
        ],
    )

    db_session.add_all(
        [
            hillside,
            cdi,
            inactive_course,
        ]
    )
    db_session.flush()

    previous_abdallah_story = add_story(
        db_session,
        abdallah,
        hillside,
        previous_month,
        "previous_abdallah",
    )
    previous_margret_story = add_story(
        db_session,
        margret,
        hillside,
        previous_month,
        "previous_margret",
    )
    current_stephen_story = add_story(
        db_session,
        stephen,
        cdi,
        current_month,
        "current_stephen",
    )
    inactive_current_abdallah_story = add_story(
        db_session,
        abdallah,
        hillside,
        current_month,
        "inactive_current_abdallah",
        active=False,
    )

    db_session.add_all(
        [
            StoryMentorRating(
                story=previous_abdallah_story,
                mentor=margret,
                rating=5,
            ),
            StoryMentorRating(
                story=previous_abdallah_story,
                mentor=stephen,
                rating=4,
            ),
            StoryMentorRating(
                story=previous_margret_story,
                mentor=abdallah,
                rating=3,
            ),
            StoryMentorRating(
                story=previous_margret_story,
                mentor=stephen,
                rating=5,
            ),
            StoryMentorRating(
                story=current_stephen_story,
                mentor=margret,
                rating=4,
            ),
            StoryMentorRating(
                story=inactive_current_abdallah_story,
                mentor=margret,
                rating=2,
            ),
        ]
    )

    winner = StoryOfMonth(
        month=previous_month,
        story=previous_abdallah_story,
        selected_by=admin,
        selected_at=story_datetime(current_month, hour=9),
    )
    db_session.add(winner)
    db_session.commit()

    return {
        "current_month": current_month,
        "previous_month": previous_month,
        "admin": admin,
        "abdallah": abdallah,
        "margret": margret,
        "stephen": stephen,
        "guest": guest,
        "hillside": hillside,
        "cdi": cdi,
        "inactive_course": inactive_course,
        "previous_abdallah_story": (
            previous_abdallah_story
        ),
        "previous_margret_story": (
            previous_margret_story
        ),
        "current_stephen_story": (
            current_stephen_story
        ),
        "inactive_current_abdallah_story": (
            inactive_current_abdallah_story
        ),
        "winner": winner,
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
        "stephen_token": make_token(
            stephen_account.id,
            "mentor",
            stephen.id,
        ),
        "guest_token": make_token(
            guest_account.id,
            "mentor",
            guest.id,
        ),
    }


def test_mentor_can_submit_story(
    client,
    seeded,
    db_session,
):
    form = story_form(
        seeded["hillside"].id,
        "A new story from Margret.",
    )

    response = client.post(
        "/api/mentor/stories",
        data=form["data"],
        files=form["files"],
        headers=auth_header(
            seeded["margret_token"],
        ),
    )

    assert response.status_code == 201

    data = response.json()

    assert data["text"] == (
        "A new story from Margret."
    )
    assert data["course_id"] == (
        seeded["hillside"].id
    )
    assert (
        data["submitted_by_mentor_profile_id"]
        == seeded["margret"].id
    )
    assert data["submission_month"] == (
        seeded["current_month"].isoformat()
    )
    assert data["active"] if "active" in data else True
    assert data["my_rating"] is None
    assert data["can_rate"] is False
    assert data["is_winner"] is False
    assert data["photo"]["url"].startswith(
        "/compressed_story_photos/"
    )

    stored = db_session.get(
        Story,
        data["id"],
    )

    assert stored is not None
    assert stored.active is True
    assert stored.photo is not None
    assert stored.submission_month == (
        seeded["current_month"]
    )


def test_story_submission_requires_photo(
    client,
    seeded,
):
    response = client.post(
        "/api/mentor/stories",
        data={
            "course_id": str(
                seeded["hillside"].id
            ),
            "text": "Story without photo.",
        },
        headers=auth_header(
            seeded["margret_token"],
        ),
    )

    assert response.status_code == 422


def test_mentor_cannot_submit_to_unassigned_course(
    client,
    seeded,
):
    form = story_form(
        seeded["cdi"].id,
    )

    response = client.post(
        "/api/mentor/stories",
        data=form["data"],
        files=form["files"],
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Course not available"
    )


def test_second_active_story_same_month_is_rejected(
    client,
    seeded,
):
    form = story_form(
        seeded["cdi"].id,
        "Stephen's second story.",
    )

    response = client.post(
        "/api/mentor/stories",
        data=form["data"],
        files=form["files"],
        headers=auth_header(
            seeded["stephen_token"],
        ),
    )

    assert response.status_code == 409
    assert response.json()["detail"] == (
        "You have already submitted "
        "a story this month"
    )


def test_inactive_story_does_not_block_replacement(
    client,
    seeded,
):
    form = story_form(
        seeded["hillside"].id,
        "Abdallah's replacement story.",
    )

    response = client.post(
        "/api/mentor/stories",
        data=form["data"],
        files=form["files"],
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 201

    assert response.json()["text"] == (
        "Abdallah's replacement story."
    )


def test_mentor_story_list_hides_inactive_stories(
    client,
    seeded,
):
    query_month = seeded[
        "current_month"
    ].replace(day=15)

    response = client.get(
        "/api/mentor/stories",
        params={
            "month": query_month.isoformat(),
        },
        headers=auth_header(
            seeded["margret_token"],
        ),
    )

    assert response.status_code == 200

    data = response.json()

    assert [
        story["id"]
        for story in data
    ] == [
        seeded["current_stephen_story"].id,
    ]

    story = data[0]

    assert story["my_rating"] == 4
    assert story["can_rate"] is True
    assert "rating_count" not in story
    assert "average_rating" not in story


def test_admin_story_list_hides_inactive_by_default(
    client,
    seeded,
):
    response = client.get(
        "/api/admin/stories",
        params={
            "month": (
                seeded["current_month"].isoformat()
            ),
        },
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200

    assert [
        story["id"]
        for story in response.json()
    ] == [
        seeded["current_stephen_story"].id,
    ]


def test_admin_can_include_inactive_stories(
    client,
    seeded,
):
    response = client.get(
        "/api/admin/stories",
        params={
            "month": (
                seeded["current_month"].isoformat()
            ),
            "active_only": "false",
        },
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200

    stories = {
        story["id"]: story
        for story in response.json()
    }

    assert set(stories) == {
        seeded["current_stephen_story"].id,
        seeded[
            "inactive_current_abdallah_story"
        ].id,
    }

    assert stories[
        seeded["current_stephen_story"].id
    ]["active"] is True

    assert stories[
        seeded[
            "inactive_current_abdallah_story"
        ].id
    ]["active"] is False


def test_admin_story_output_contains_rating_summary(
    client,
    seeded,
):
    response = client.get(
        "/api/admin/stories",
        params={
            "month": (
                seeded["current_month"].isoformat()
            ),
        },
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200

    story = response.json()[0]

    assert story["rating_count"] == 1
    assert story["average_rating"] == 4


def test_mentor_can_create_and_update_rating(
    client,
    seeded,
    db_session,
):
    story_id = seeded[
        "current_stephen_story"
    ].id

    response = client.put(
        f"/api/mentor/stories/{story_id}/rating",
        json={"rating": 5},
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 200
    assert response.json()["my_rating"] == 5
    assert response.json()["can_rate"] is True

    response = client.put(
        f"/api/mentor/stories/{story_id}/rating",
        json={"rating": 2},
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 200
    assert response.json()["my_rating"] == 2

    ratings = (
        db_session.query(StoryMentorRating)
        .filter(
            StoryMentorRating.story_id
            == story_id,
            StoryMentorRating.mentor_profile_id
            == seeded["abdallah"].id,
        )
        .all()
    )

    assert len(ratings) == 1
    assert ratings[0].rating == 2


def test_mentor_cannot_rate_own_story(
    client,
    seeded,
):
    story_id = seeded[
        "current_stephen_story"
    ].id

    response = client.put(
        f"/api/mentor/stories/{story_id}/rating",
        json={"rating": 5},
        headers=auth_header(
            seeded["stephen_token"],
        ),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "You cannot rate your own story"
    )


def test_mentor_without_active_course_cannot_rate(
    client,
    seeded,
):
    story_id = seeded[
        "current_stephen_story"
    ].id

    response = client.put(
        f"/api/mentor/stories/{story_id}/rating",
        json={"rating": 5},
        headers=auth_header(
            seeded["guest_token"],
        ),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == (
        "Only mentors assigned to an "
        "active course may rate stories"
    )


def test_rating_must_be_between_one_and_five(
    client,
    seeded,
):
    story_id = seeded[
        "current_stephen_story"
    ].id

    response = client.put(
        f"/api/mentor/stories/{story_id}/rating",
        json={"rating": 6},
        headers=auth_header(
            seeded["abdallah_token"],
        ),
    )

    assert response.status_code == 422


def test_past_story_rating_is_closed(
    client,
    seeded,
):
    story_id = seeded[
        "previous_abdallah_story"
    ].id

    response = client.put(
        f"/api/mentor/stories/{story_id}/rating",
        json={"rating": 3},
        headers=auth_header(
            seeded["margret_token"],
        ),
    )

    assert response.status_code == 409
    assert response.json()["detail"] == (
        "Rating period is closed"
    )


def test_admin_can_edit_story_text(
    client,
    seeded,
    db_session,
):
    story_id = seeded[
        "current_stephen_story"
    ].id

    response = client.put(
        f"/api/admin/stories/{story_id}",
        json={
            "text": "Edited story text.",
        },
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200

    data = response.json()

    assert data["text"] == "Edited story text."
    assert data["rating_count"] == 1
    assert data["average_rating"] == 4

    stored = db_session.get(
        Story,
        story_id,
    )

    assert stored.text == "Edited story text."


def test_admin_deactivation_hides_story_but_preserves_data(
    client,
    seeded,
    db_session,
):
    story = seeded[
        "current_stephen_story"
    ]
    photo_id = story.photo.id

    response = client.post(
        f"/api/admin/stories/{story.id}/deactivate",
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200

    data = response.json()

    assert data["active"] is False
    assert data["rating_count"] == 1
    assert data["average_rating"] == 4

    assert db_session.get(
        StoryPhoto,
        photo_id,
    ) is not None

    rating_count = (
        db_session.query(StoryMentorRating)
        .filter(
            StoryMentorRating.story_id
            == story.id,
        )
        .count()
    )

    assert rating_count == 1

    mentor_response = client.get(
        "/api/mentor/stories",
        params={
            "month": (
                seeded["current_month"].isoformat()
            ),
        },
        headers=auth_header(
            seeded["margret_token"],
        ),
    )

    assert mentor_response.status_code == 200
    assert mentor_response.json() == []


def test_admin_can_reactivate_story(
    client,
    seeded,
):
    story_id = seeded[
        "current_stephen_story"
    ].id

    deactivate_response = client.post(
        f"/api/admin/stories/{story_id}/deactivate",
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert deactivate_response.status_code == 200

    activate_response = client.post(
        f"/api/admin/stories/{story_id}/activate",
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert activate_response.status_code == 200

    data = activate_response.json()

    assert data["active"] is True
    assert data["rating_count"] == 1
    assert data["average_rating"] == 4
    assert data["is_winner"] is False


def test_admin_cannot_reactivate_when_replacement_exists(
    client,
    seeded,
    db_session,
):
    inactive_story = seeded[
        "inactive_current_abdallah_story"
    ]

    add_story(
        db_session,
        seeded["abdallah"],
        seeded["hillside"],
        seeded["current_month"],
        "active_replacement",
    )
    db_session.commit()

    response = client.post(
        (
            f"/api/admin/stories/"
            f"{inactive_story.id}/activate"
        ),
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 409
    assert response.json()["detail"] == (
        "The mentor already has another active "
        "story for this month"
    )


def test_admin_can_replace_previous_month_winner(
    client,
    seeded,
    db_session,
):
    new_winner_story = seeded[
        "previous_margret_story"
    ]

    response = client.put(
        (
            "/api/admin/story-winners/"
            f"{seeded['previous_month'].isoformat()}"
        ),
        json={
            "story_id": new_winner_story.id,
        },
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200

    data = response.json()

    assert data["month"] == (
        seeded["previous_month"].isoformat()
    )
    assert data["story"]["id"] == (
        new_winner_story.id
    )
    assert data["story"]["is_winner"] is True

    winners = (
        db_session.query(StoryOfMonth)
        .filter(
            StoryOfMonth.month
            == seeded["previous_month"],
        )
        .all()
    )

    assert len(winners) == 1
    assert winners[0].story_id == (
        new_winner_story.id
    )


def test_admin_cannot_select_current_month_winner(
    client,
    seeded,
):
    response = client.put(
        (
            "/api/admin/story-winners/"
            f"{seeded['current_month'].isoformat()}"
        ),
        json={
            "story_id": seeded[
                "current_stephen_story"
            ].id,
        },
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 409
    assert response.json()["detail"] == (
        "A winner can only be selected "
        "after the month has ended"
    )


def test_shared_winner_archive_returns_no_ratings(
    client,
    seeded,
):
    response = client.get(
        "/api/shared/story-winners",
        headers=auth_header(
            seeded["margret_token"],
        ),
    )

    assert response.status_code == 200

    data = response.json()

    assert len(data) == 1
    assert data[0]["month"] == (
        seeded["previous_month"].isoformat()
    )

    story = data[0]["story"]

    assert story["id"] == seeded[
        "previous_abdallah_story"
    ].id
    assert story["is_winner"] is True
    assert "my_rating" not in story
    assert "rating_count" not in story
    assert "average_rating" not in story


def test_deactivating_winner_removes_it_from_archive(
    client,
    seeded,
    db_session,
):
    story_id = seeded[
        "previous_abdallah_story"
    ].id

    response = client.post(
        f"/api/admin/stories/{story_id}/deactivate",
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code == 200
    assert response.json()["is_winner"] is False

    assert (
        db_session.query(StoryOfMonth)
        .filter(
            StoryOfMonth.story_id
            == story_id,
        )
        .first()
        is None
    )

    archive_response = client.get(
        "/api/shared/story-winners",
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert archive_response.status_code == 200
    assert archive_response.json() == []


def test_mentor_cannot_access_admin_story_management(
    client,
    seeded,
):
    response = client.put(
        (
            f"/api/admin/stories/"
            f"{seeded['current_stephen_story'].id}"
        ),
        json={
            "text": "Unauthorized edit.",
        },
        headers=auth_header(
            seeded["margret_token"],
        ),
    )

    assert response.status_code in (401, 403)


def test_admin_cannot_submit_mentor_story(
    client,
    seeded,
):
    form = story_form(
        seeded["hillside"].id,
    )

    response = client.post(
        "/api/mentor/stories",
        data=form["data"],
        files=form["files"],
        headers=auth_header(
            seeded["admin_token"],
        ),
    )

    assert response.status_code in (401, 403)
