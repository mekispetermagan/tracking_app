from datetime import datetime, timedelta, UTC

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from database import Base, get_db
from main import app
from models import Account, AdminProfile, Country, MentorProfile
from security import hash_secret


@pytest.fixture()
def client():
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
        uganda = Country(code="UG", name="Uganda")
        db.add(uganda)
        db.flush()

        expiry = datetime.now(UTC) + timedelta(days=7)

        abdallah = Account(
            phone="0712345678",
            first_name="Abdallah",
            last_name="Kiggundu",
            country_id=uganda.id,
            preferred_language="en",
        )
        db.add(abdallah)
        db.flush()
        db.add(MentorProfile(
            account_id=abdallah.id,
            pin_hash=hash_secret("123456"),
            must_change_pin=True,
            temporary_pin_expires_at=expiry,
        ))

        margret = Account(
            phone="0774231538",
            first_name="Margret",
            last_name="Nakalema",
            country_id=uganda.id,
            preferred_language="en",
        )
        db.add(margret)
        db.flush()
        db.add(MentorProfile(
            account_id=margret.id,
            pin_hash=hash_secret("123456"),
            must_change_pin=True,
            temporary_pin_expires_at=expiry,
        ))
        db.add(AdminProfile(
            account_id=margret.id,
            password_hash=hash_secret("Margret123"),
            must_change_password=True,
            temporary_password_expires_at=expiry,
        ))

        peter = Account(
            phone="0781653508",
            first_name="Peter",
            last_name="Mekis",
            country_id=uganda.id,
            preferred_language="en",
        )
        db.add(peter)
        db.flush()
        db.add(AdminProfile(
            account_id=peter.id,
            password_hash=hash_secret("Peter123"),
            must_change_password=True,
            temporary_password_expires_at=expiry,
        ))

        db.commit()
    finally:
        db.close()

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)


def test_mentor_first_login_change_pin_and_login(client):
    response = client.post("/api/auth/mentor/login", json={
        "phone": "0712345678",
        "pin": "123456",
    })

    assert response.status_code == 200
    data = response.json()
    assert data["token_purpose"] == "setup"
    assert data["mode"] == "mentor"
    assert data["must_change_secret"] is True

    setup_token = data["access_token"]

    response = client.post(
        "/api/auth/mentor/change-pin",
        json={"new_pin": "654321"},
        headers={"Authorization": f"Bearer {setup_token}"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["token_purpose"] == "access"
    assert data["mode"] == "mentor"
    assert data["must_change_secret"] is False

    response = client.post("/api/auth/mentor/login", json={
        "phone": "0712345678",
        "pin": "123456",
    })
    assert response.status_code == 401

    response = client.post("/api/auth/mentor/login", json={
        "phone": "0712345678",
        "pin": "654321",
    })
    assert response.status_code == 200
    assert response.json()["token_purpose"] == "access"


def test_admin_first_login_change_password_and_login(client):
    response = client.post("/api/auth/admin/login", json={
        "phone": "0774231538",
        "password": "Margret123",
    })

    assert response.status_code == 200
    data = response.json()
    assert data["token_purpose"] == "setup"
    assert data["mode"] == "admin"
    assert data["must_change_secret"] is True

    setup_token = data["access_token"]

    response = client.post(
        "/api/auth/admin/change-password",
        json={"new_password": "123Margret456"},
        headers={"Authorization": f"Bearer {setup_token}"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["token_purpose"] == "access"
    assert data["mode"] == "admin"
    assert data["must_change_secret"] is False

    response = client.post("/api/auth/admin/login", json={
        "phone": "0774231538",
        "password": "Margret123",
    })
    assert response.status_code == 401

    response = client.post("/api/auth/admin/login", json={
        "phone": "0774231538",
        "password": "123Margret456",
    })
    assert response.status_code == 200
    assert response.json()["token_purpose"] == "access"


def test_mentor_and_admin_tokens_are_separated(client):
    mentor_login = client.post("/api/auth/mentor/login", json={
        "phone": "0712345678",
        "pin": "123456",
    })
    setup_token = mentor_login.json()["access_token"]

    mentor_change = client.post(
        "/api/auth/mentor/change-pin",
        json={"new_pin": "654321"},
        headers={"Authorization": f"Bearer {setup_token}"},
    )
    mentor_token = mentor_change.json()["access_token"]

    response = client.get(
        "/api/auth/mentor/me",
        headers={"Authorization": f"Bearer {mentor_token}"},
    )
    assert response.status_code == 200
    assert response.json()["mode"] == "mentor"

    response = client.get(
        "/api/auth/admin/me",
        headers={"Authorization": f"Bearer {mentor_token}"},
    )
    assert response.status_code == 403
    assert response.json()["detail"] == "Admin token required"

    admin_login = client.post("/api/auth/admin/login", json={
        "phone": "0774231538",
        "password": "Margret123",
    })
    setup_token = admin_login.json()["access_token"]

    admin_change = client.post(
        "/api/auth/admin/change-password",
        json={"new_password": "123Margret456"},
        headers={"Authorization": f"Bearer {setup_token}"},
    )
    admin_token = admin_change.json()["access_token"]

    response = client.get(
        "/api/auth/admin/me",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == 200
    assert response.json()["mode"] == "admin"

    response = client.get(
        "/api/auth/mentor/me",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == 403
    assert response.json()["detail"] == "Mentor token required"


def test_missing_profiles_fail(client):
    response = client.post("/api/auth/admin/login", json={
        "phone": "0712345678",
        "password": "Abdallah123",
    })
    assert response.status_code == 401

    response = client.post("/api/auth/mentor/login", json={
        "phone": "0781653508",
        "pin": "123456",
    })
    assert response.status_code == 401