"""
Integration tests - Full API workflows
Tests complete user flows through the API
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.main import app
from app.schemas.user import UserCreate, UserLogin
from app.schemas.game import GameCreate


@pytest.mark.asyncio
async def test_user_registration_flow():
    """Test user registration workflow"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register new user
        response = await client.post(
            "/users/register",
            json={
                "email": "newuser@example.com",
                "password": "SecurePassword123!",
            },
        )
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "newuser@example.com"
        assert "id" in data
        assert "password" not in data  # Password not returned


@pytest.mark.asyncio
async def test_user_login_flow():
    """Test user login and token generation"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register user first
        await client.post(
            "/users/register",
            json={
                "email": "login_test@example.com",
                "password": "SecurePassword123!",
            },
        )

        # Login
        response = await client.post(
            "/users/login",
            json={
                "email": "login_test@example.com",
                "password": "SecurePassword123!",
            },
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_get_user_profile_with_token():
    """Test retrieving user profile with valid token"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register user
        await client.post(
            "/users/register",
            json={
                "email": "profile_test@example.com",
                "password": "SecurePassword123!",
            },
        )

        # Login to get token
        login_response = await client.post(
            "/users/login",
            json={
                "email": "profile_test@example.com",
                "password": "SecurePassword123!",
            },
        )
        token = login_response.json()["access_token"]

        # Get profile
        response = await client.get(
            "/users/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "profile_test@example.com"


@pytest.mark.asyncio
async def test_protected_endpoint_without_token():
    """Test that protected endpoints reject requests without token"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/users/me")
        assert response.status_code == 401


@pytest.mark.asyncio
async def test_protected_endpoint_with_invalid_token():
    """Test that protected endpoints reject invalid tokens"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/users/me",
            headers={"Authorization": "Bearer invalid_token"},
        )
        assert response.status_code == 401


@pytest.mark.asyncio
async def test_health_check():
    """Test health check endpoint"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
