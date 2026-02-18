import pytest
from types import SimpleNamespace
from unittest.mock import MagicMock
from fastapi import HTTPException

from app.api import users
from app.schemas.user import UserCreate


def test_register_user(client):
    response = client.post(
        "/users/register",
        json={
            "username": "testuser",
            "password": "Strongpassword4"
        }
    )

    assert response.status_code == 201
    data = response.json()

    assert data["username"] == "testuser"
    assert "id" in data
    assert "password" not in data  # ensure password not returned


def test_login_user(client):
    # Register first
    register_response = client.post(
        "/users/register",
        json={
            "username": "testuser",
            "password": "Strongpassword4"
        }
    )
    assert register_response.status_code == 201

    # Login (OAuth2 form → must use data=)
    response = client.post(
        "/users/login",
        data={
            "username": "testuser",
            "password": "Strongpassword4"
        }
    )

    assert response.status_code == 200
    data = response.json()

    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_read_current_user(client):
    # Register
    register_response = client.post(
        "/users/register",
        json={
            "username": "testuser",
            "password": "Strongpassword4"
        }
    )
    assert register_response.status_code == 201

    # Login
    login_response = client.post(
        "/users/login",
        data={
            "username": "testuser",
            "password": "Strongpassword4"
        }
    )
    assert login_response.status_code == 200

    login_data = login_response.json()
    assert "access_token" in login_data

    token = login_data["access_token"]

    # Call protected route
    response = client.get(
        "/users/me",
        headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 200
    user_data = response.json()

    assert user_data["username"] == "testuser"


# Successful registration
def test_register_success():
    mock_db = MagicMock()
    mock_db.query.return_value.filter.return_value.first.return_value = None
    mock_db.add.return_value = None
    mock_db.commit.return_value = None
    mock_db.refresh.return_value = None

    user_in = UserCreate(username="alice", password="secret")
    result = users.register(user_in, db=mock_db)

    assert result.username == "alice"
    assert result.wins == 0
    mock_db.add.assert_called_once()
    mock_db.commit.assert_called_once()
    mock_db.refresh.assert_called_once()


# Registration with existing username should raise 400
def test_register_existing_username():
    mock_db = MagicMock()
    existing = SimpleNamespace(username="alice")
    mock_db.query.return_value.filter.return_value.first.return_value = existing

    user_in = UserCreate(username="alice", password="secret")
    with pytest.raises(HTTPException) as exc:
        users.register(user_in, db=mock_db)
    assert exc.value.status_code == 400


# Successful login
def test_login_success(monkeypatch):
    mock_db = MagicMock()
    db_user = SimpleNamespace(id=1, username="alice", password="hashed")
    mock_db.query.return_value.filter.return_value.first.return_value = db_user

    monkeypatch.setattr("app.api.users.verify_password", lambda pw, h: True)
    monkeypatch.setattr("app.api.users.create_access_token", lambda data: "token123")

    form = SimpleNamespace(username="alice", password="secret")
    resp = users.login(form_data=form, db=mock_db)

    assert resp["access_token"] == "token123"
    assert resp["token_type"] == "bearer"


# Failed login should raise 401 and include WWW-Authenticate header
def test_login_failure(monkeypatch):
    mock_db = MagicMock()
    db_user = SimpleNamespace(id=1, username="alice", password="hashed")
    mock_db.query.return_value.filter.return_value.first.return_value = db_user

    monkeypatch.setattr("app.api.users.verify_password", lambda pw, h: False)

    form = SimpleNamespace(username="alice", password="wrong")
    with pytest.raises(HTTPException) as exc:
        users.login(form_data=form, db=mock_db)
    assert exc.value.status_code == 401
    assert exc.value.headers.get("WWW-Authenticate") == "Bearer"


# read_my_profile returns expected dict
def test_read_my_profile():
    current_user = SimpleNamespace(id=1, username="alice", wins=5)
    resp = users.read_my_profile(current_user=current_user)
    assert resp == {"id": 1, "username": "alice", "wins": 5}


def test_read_my_profile_no_user():
    with pytest.raises(HTTPException) as exc:
        users.read_my_profile(current_user=None)
    assert exc.value.status_code == 401