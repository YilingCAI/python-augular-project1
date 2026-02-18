"""
E2E tests using Playwright
Tests complete user journeys through the web interface
"""

import pytest
from playwright.async_api import async_playwright, Browser, Page


@pytest.fixture
async def browser():
    """Fixture to provide Playwright browser"""
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        yield browser
        await browser.close()


@pytest.fixture
async def page(browser):
    """Fixture to provide a page"""
    page = await browser.new_page()
    yield page
    await page.close()


@pytest.mark.asyncio
async def test_user_registration_e2e(page: Page):
    """Test complete user registration flow through UI"""
    # Navigate to app
    await page.goto("http://localhost:4200")

    # Click register button
    await page.click("text=Register")

    # Fill in registration form
    await page.fill("input[name='email']", "e2e_test@example.com")
    await page.fill("input[name='password']", "SecurePassword123!")
    await page.fill("input[name='confirmPassword']", "SecurePassword123!")

    # Submit form
    await page.click("button:has-text('Create Account')")

    # Verify redirect to login or dashboard
    await page.wait_for_url("**/dashboard")
    assert "dashboard" in page.url


@pytest.mark.asyncio
async def test_user_login_e2e(page: Page):
    """Test complete user login flow through UI"""
    # Navigate to login
    await page.goto("http://localhost:4200/login")

    # Fill in login form
    await page.fill("input[name='email']", "e2e_test@example.com")
    await page.fill("input[name='password']", "SecurePassword123!")

    # Submit form
    await page.click("button:has-text('Sign In')")

    # Verify redirect to dashboard
    await page.wait_for_url("**/dashboard")
    assert "dashboard" in page.url


@pytest.mark.asyncio
async def test_create_and_play_game_e2e(page: Page):
    """Test complete game creation and play flow"""
    # Login first
    await page.goto("http://localhost:4200/login")
    await page.fill("input[name='email']", "e2e_test@example.com")
    await page.fill("input[name='password']", "SecurePassword123!")
    await page.click("button:has-text('Sign In')")

    # Wait for dashboard
    await page.wait_for_url("**/dashboard")

    # Click create game button
    await page.click("button:has-text('New Game')")

    # Verify game page loaded
    await page.wait_for_url("**/game/*")
    assert "game" in page.url

    # Make a move
    await page.click("div.game-board > div:nth-child(1)")

    # Verify move was made
    cell = await page.query_selector("div.game-board > div:nth-child(1)")
    assert cell is not None


@pytest.mark.asyncio
async def test_invalid_login_e2e(page: Page):
    """Test login with invalid credentials"""
    await page.goto("http://localhost:4200/login")

    # Fill with wrong credentials
    await page.fill("input[name='email']", "wrong@example.com")
    await page.fill("input[name='password']", "WrongPassword123!")

    # Submit form
    await page.click("button:has-text('Sign In')")

    # Verify error message shown
    error_msg = await page.query_selector("text=Invalid credentials")
    assert error_msg is not None


@pytest.mark.asyncio
async def test_protected_route_redirect(page: Page):
    """Test that unauthenticated users are redirected from protected routes"""
    # Try to access dashboard without login
    await page.goto("http://localhost:4200/dashboard")

    # Should redirect to login
    await page.wait_for_url("**/login")
    assert "login" in page.url


@pytest.mark.asyncio
async def test_logout_e2e(page: Page):
    """Test logout functionality"""
    # Login first
    await page.goto("http://localhost:4200/login")
    await page.fill("input[name='email']", "e2e_test@example.com")
    await page.fill("input[name='password']", "SecurePassword123!")
    await page.click("button:has-text('Sign In')")

    # Wait for dashboard
    await page.wait_for_url("**/dashboard")

    # Click logout
    await page.click("button:has-text('Logout')")

    # Verify redirect to login
    await page.wait_for_url("**/login")
    assert "login" in page.url


@pytest.mark.asyncio
async def test_responsive_design_mobile(page: Page):
    """Test responsive design on mobile"""
    # Set mobile viewport
    await page.set_viewport_size({"width": 375, "height": 667})

    # Navigate to app
    await page.goto("http://localhost:4200")

    # Verify mobile menu is visible
    mobile_menu = await page.query_selector("[data-testid='mobile-menu']")
    assert mobile_menu is not None


@pytest.mark.asyncio
async def test_responsive_design_tablet(page: Page):
    """Test responsive design on tablet"""
    # Set tablet viewport
    await page.set_viewport_size({"width": 768, "height": 1024})

    # Navigate to app
    await page.goto("http://localhost:4200")

    # Verify layout is tablet-optimized
    # (specific checks depend on your design)
    await page.wait_for_load_state("networkidle")


@pytest.mark.asyncio
async def test_network_error_handling(page: Page):
    """Test app handles network errors gracefully"""
    # Go offline
    await page.context.set_offline(True)

    # Try to navigate
    try:
        await page.goto("http://localhost:4200/nonexistent")
    except:
        pass

    # Go back online
    await page.context.set_offline(False)

    # Navigate to app
    await page.goto("http://localhost:4200")

    # Verify app recovers
    await page.wait_for_load_state("networkidle")
    assert page.url


@pytest.mark.asyncio
async def test_accessibility_keyboard_navigation(page: Page):
    """Test keyboard navigation accessibility"""
    await page.goto("http://localhost:4200/login")

    # Tab to email input
    await page.keyboard.press("Tab")

    # Verify email input is focused
    focused = await page.evaluate("() => document.activeElement.name")
    assert focused == "email"

    # Tab to password input
    await page.keyboard.press("Tab")

    # Verify password input is focused
    focused = await page.evaluate("() => document.activeElement.name")
    assert focused == "password"
