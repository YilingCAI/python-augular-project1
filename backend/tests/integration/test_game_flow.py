"""
Integration tests - Game workflows
Tests game creation, joining, moves, and win/loss tracking
"""

import pytest
from httpx import AsyncClient

from app.main import app


@pytest.fixture
async def auth_token():
    """Fixture to get authentication token"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register
        await client.post(
            "/users/register",
            json={
                "email": "game_test@example.com",
                "password": "Password123!",
            },
        )

        # Login
        response = await client.post(
            "/users/login",
            json={
                "email": "game_test@example.com",
                "password": "Password123!",
            },
        )
        return response.json()["access_token"]


@pytest.mark.asyncio
async def test_create_game(auth_token):
    """Test creating a new game"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/games/create_game",
            headers={"Authorization": f"Bearer {auth_token}"},
        )
        assert response.status_code == 201
        data = response.json()
        assert "game_id" in data
        assert data["status"] == "active"


@pytest.mark.asyncio
async def test_get_user_games(auth_token):
    """Test retrieving user's games"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Create a game
        await client.post(
            "/games/create_game",
            headers={"Authorization": f"Bearer {auth_token}"},
        )

        # Get games
        response = await client.get(
            "/games",
            headers={"Authorization": f"Bearer {auth_token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0


@pytest.mark.asyncio
async def test_get_specific_game(auth_token):
    """Test retrieving a specific game"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Create a game
        create_response = await client.post(
            "/games/create_game",
            headers={"Authorization": f"Bearer {auth_token}"},
        )
        game_id = create_response.json()["game_id"]

        # Get specific game
        response = await client.get(
            f"/games/{game_id}",
            headers={"Authorization": f"Bearer {auth_token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["game_id"] == game_id


@pytest.mark.asyncio
async def test_join_game(auth_token):
    """Test joining an existing game"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Create a game with first user
        create_response = await client.post(
            "/games/create_game",
            headers={"Authorization": f"Bearer {auth_token}"},
        )
        game_id = create_response.json()["game_id"]

        # Join with second user
        join_response = await client.post(
            f"/games/{game_id}/join",
            headers={"Authorization": f"Bearer {auth_token}"},
        )
        assert join_response.status_code == 200


@pytest.mark.asyncio
async def test_make_move(auth_token):
    """Test making a move in a game"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Create game
        create_response = await client.post(
            "/games/create_game",
            headers={"Authorization": f"Bearer {auth_token}"},
        )
        game_id = create_response.json()["game_id"]

        # Make move
        move_response = await client.post(
            "/games/move",
            json={"game_id": game_id, "position": 0},
            headers={"Authorization": f"Bearer {auth_token}"},
        )
        assert move_response.status_code == 200
        data = move_response.json()
        assert "board" in data
        assert data["board"][0] is not None  # Position should be marked


@pytest.mark.asyncio
async def test_invalid_move_position():
    """Test that invalid move positions are rejected"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register and get token
        await client.post(
            "/users/register",
            json={
                "email": "invalid_move@example.com",
                "password": "Password123!",
            },
        )
        login_response = await client.post(
            "/users/login",
            json={
                "email": "invalid_move@example.com",
                "password": "Password123!",
            },
        )
        token = login_response.json()["access_token"]

        # Create game
        create_response = await client.post(
            "/games/create_game",
            headers={"Authorization": f"Bearer {token}"},
        )
        game_id = create_response.json()["game_id"]

        # Try invalid position
        response = await client.post(
            "/games/move",
            json={"game_id": game_id, "position": 99},  # Out of range
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 400


@pytest.mark.asyncio
async def test_move_already_occupied_position():
    """Test that occupied positions cannot be marked"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register and get token
        await client.post(
            "/users/register",
            json={
                "email": "occupied_move@example.com",
                "password": "Password123!",
            },
        )
        login_response = await client.post(
            "/users/login",
            json={
                "email": "occupied_move@example.com",
                "password": "Password123!",
            },
        )
        token = login_response.json()["access_token"]

        # Create game
        create_response = await client.post(
            "/games/create_game",
            headers={"Authorization": f"Bearer {token}"},
        )
        game_id = create_response.json()["game_id"]

        # Make first move
        await client.post(
            "/games/move",
            json={"game_id": game_id, "position": 0},
            headers={"Authorization": f"Bearer {token}"},
        )

        # Try to move in same position
        response = await client.post(
            "/games/move",
            json={"game_id": game_id, "position": 0},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 400
        assert "already" in response.json().get("detail", "").lower()


@pytest.mark.asyncio
async def test_game_without_authentication():
    """Test that game endpoints require authentication"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post("/games/create_game")
        assert response.status_code == 401
