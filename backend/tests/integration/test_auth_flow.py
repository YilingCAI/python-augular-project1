"""
Integration tests - Authentication workflows
Tests user authentication, registration, and token management
"""

import pytest
from httpx import AsyncClient

from app.main import app


@pytest.mark.asyncio
async def test_register_with_valid_email():
    """Test user registration with valid email"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/users/register",
            json={
                "email": "valid@example.com",
                "password": "ValidPassword123!",
            },
        )
        assert response.status_code == 201


@pytest.mark.asyncio
async def test_register_with_duplicate_email():
    """Test user registration fails with duplicate email"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        email = "duplicate@example.com"

        # Register first user
        await client.post(
            "/users/register",
            json={
                "email": email,
                "password": "Password123!",
            },
        )

        # Try to register with same email
        response = await client.post(
            "/users/register",
            json={
                "email": email,
                "password": "DifferentPassword123!",
            },
        )
        assert response.status_code == 400
        assert "already registered" in response.json().get("detail", "").lower()


@pytest.mark.asyncio
async def test_register_with_weak_password():
    """Test registration fails with weak password"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/users/register",
            json={
                "email": "weak_password@example.com",
                "password": "123",  # Too short
            },
        )
        assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
async def test_login_with_correct_credentials():
    """Test login succeeds with correct credentials"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        email = "login_correct@example.com"
        password = "CorrectPassword123!"

        # Register
        await client.post(
            "/users/register",
            json={"email": email, "password": password},
        )

        # Login
        response = await client.post(
            "/users/login",
            json={"email": email, "password": password},
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data


@pytest.mark.asyncio
async def test_login_with_incorrect_password():
    """Test login fails with incorrect password"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        email = "login_incorrect@example.com"

        # Register
        await client.post(
            "/users/register",
            json={"email": email, "password": "CorrectPassword123!"},
        )

        # Try login with wrong password
        response = await client.post(
            "/users/login",
            json={"email": email, "password": "WrongPassword123!"},
        )
        assert response.status_code == 401


@pytest.mark.asyncio
async def test_login_with_nonexistent_user():
    """Test login fails with nonexistent email"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/users/login",
            json={
                "email": "nonexistent@example.com",
                "password": "AnyPassword123!",
            },
        )
        assert response.status_code == 401


@pytest.mark.asyncio
async def test_token_expiration():
    """Test that expired tokens are rejected"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register and login
        email = "token_test@example.com"
        await client.post(
            "/users/register",
            json={"email": email, "password": "Password123!"},
        )

        response = await client.post(
            "/users/login",
            json={"email": email, "password": "Password123!"},
        )
        token = response.json()["access_token"]

        # Token should work initially
        response = await client.get(
            "/users/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200

        # Note: Full expiration test requires time travel or mocking
        # This is a placeholder for the concept


@pytest.mark.asyncio
async def test_jwt_token_structure():
    """Test that JWT token has correct structure"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register and login
        email = "jwt_test@example.com"
        await client.post(
            "/users/register",
            json={"email": email, "password": "Password123!"},
        )

        response = await client.post(
            "/users/login",
            json={"email": email, "password": "Password123!"},
        )
        token = response.json()["access_token"]

        # JWT has 3 parts separated by dots
        assert token.count(".") == 2
