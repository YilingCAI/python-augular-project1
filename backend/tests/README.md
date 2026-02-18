# Integration & E2E Tests

Complete test suite including integration tests for APIs and E2E tests for user flows.

## Structure

```
tests/
├── README.md                 # This file
├── __init__.py
├── integration/
│   ├── __init__.py
│   ├── test_api_flow.py     # Full API workflows (health, users, games)
│   ├── test_auth_flow.py    # Authentication workflows (register, login, tokens)
│   └── test_game_flow.py    # Game workflows (create, join, move, play)
│
└── e2e/
    ├── __init__.py
    ├── __pycache__/
    ├── README.md            # E2E testing guide
    └── test_user_flows.py   # Complete user journeys via UI (Playwright)
```

## Running Tests

### All Tests
```bash
# Run everything
make test

# Or manually
pytest tests/ -v
```

### Integration Tests Only
```bash
# Run all integration tests
pytest tests/integration/ -v

# Run specific file
pytest tests/integration/test_api_flow.py -v

# Run specific test
pytest tests/integration/test_auth_flow.py::test_login_with_correct_credentials -v

# With coverage
pytest tests/integration/ --cov=app --cov-report=html

# Specific test matching pattern
pytest tests/integration/ -k "auth" -v
```

### E2E Tests Only
```bash
# Run all E2E tests
pytest tests/e2e/ -v

# Run specific E2E test
pytest tests/e2e/test_user_flows.py::test_user_registration_e2e -v

# Run with browser headed mode (see browser)
pytest tests/e2e/ -v --headed

# Run with slowdown to see interactions
pytest tests/e2e/ -v --headed --slow-mo=1000

# Run against staging environment
BASE_URL=https://staging.example.com pytest tests/e2e/ -v
```

## Integration Tests

### Modules

**test_api_flow.py** - General API workflows
- Health check endpoint
- User registration flow
- User login and token generation
- User profile retrieval
- Protected endpoint validation

**test_auth_flow.py** - Authentication specific
- Registration with valid/invalid emails
- Weak password rejection
- Login with correct/incorrect credentials
- Nonexistent user handling
- JWT token structure verification
- Token expiration handling

**test_game_flow.py** - Game operations
- Create game
- Get user's games
- Get specific game
- Join game
- Make valid moves
- Invalid position rejection
- Occupied position rejection
- Authentication requirement

### Example Integration Test

```python
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_create_game_authenticated():
    """Test creating a game requires authentication"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register user
        await client.post("/users/register", json={
            "email": "test@example.com",
            "password": "Password123!"
        })
        
        # Get token
        login_resp = await client.post("/users/login", json={
            "email": "test@example.com",
            "password": "Password123!"
        })
        token = login_resp.json()["access_token"]
        
        # Create game
        response = await client.post(
            "/games/create_game",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 201
        assert "game_id" in response.json()
```

## E2E Tests

### Modules

**test_user_flows.py** - Complete user journeys via browser

- User registration through UI
- User login through UI
- Create and play game
- Invalid login rejection
- Protected route redirection
- Logout functionality
- Responsive design (mobile, tablet)
- Keyboard navigation
- Network error handling
- Accessibility features

### Setup

```bash
# Install Playwright
pip install pytest-playwright

# Install browsers
playwright install chromium

# Or just Firefox
playwright install firefox
```

### Example E2E Test

```python
import pytest
from playwright.async_api import Page

@pytest.mark.asyncio
async def test_user_registration_flow(page: Page):
    """Test complete registration through UI"""
    # Navigate to app
    await page.goto("http://localhost:4200")
    
    # Click register button
    await page.click("text=Register")
    
    # Fill form
    await page.fill("input[name='email']", "test@example.com")
    await page.fill("input[name='password']", "Password123!")
    
    # Submit
    await page.click("button:has-text('Create Account')")
    
    # Verify redirect
    await page.wait_for_url("**/dashboard")
    assert "dashboard" in page.url
```

## Test Coverage

### Current Coverage
- ✅ User registration and validation
- ✅ User authentication (login/logout)
- ✅ JWT token generation and validation
- ✅ Game creation and management
- ✅ Game move validation
- ✅ API error handling
- ✅ Protected endpoint access control
- ✅ UI responsiveness
- ✅ Complete user workflows

### Target Coverage
- ✅ 80%+ code coverage (integration tests)
- ✅ All user-facing workflows (E2E tests)
- ✅ Error scenarios
- ✅ Edge cases

## Running with Coverage

### Integration Tests with Coverage
```bash
pytest tests/integration/ \
  --cov=app \
  --cov-report=html \
  --cov-report=term-missing

# View report
open htmlcov/index.html
```

### Coverage by Module
```bash
# See which modules need coverage
pytest tests/integration/ --cov=app --cov-report=term-missing | grep -E "^app/"
```

## Debugging Tests

### Run Single Test with Output
```bash
pytest tests/integration/test_auth_flow.py::test_login_with_correct_credentials -v -s
```

### Show Full Error Traceback
```bash
pytest tests/ -v --tb=long
```

### Drop into Debugger on Failure
```bash
pytest tests/ -v --pdb
```

### Run Slowly to See What's Happening
```bash
# E2E tests with slowdown
pytest tests/e2e/ -v --headed --slow-mo=2000
```

### Generate HTML Report
```bash
pytest tests/ -v --html=report.html --self-contained-html
open report.html
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Run Integration Tests
  run: pytest tests/integration/ -v --cov=app

- name: Run E2E Tests
  run: |
    pip install pytest-playwright
    playwright install
    pytest tests/e2e/ -v --html=report.html

- name: Upload Report
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: test-report
    path: report.html
```

## Best Practices

### Integration Tests
✅ Test complete workflows, not just functions
✅ Use fixtures for common setup (auth tokens, users)
✅ Test both success and failure paths
✅ Use meaningful assertion messages
✅ Clean up test data (use transactions or fixtures)
✅ Make tests independent (no dependencies between tests)

### E2E Tests
✅ Test user-facing workflows
✅ Avoid testing implementation details
✅ Use Page Object Model for larger suites
✅ Wait for elements properly
✅ Use explicit waits, not sleeps
✅ Mock external services
✅ Take screenshots on failure

## Troubleshooting

### Tests Timeout
```bash
# Increase timeout globally
pytest tests/ -v --timeout=30
```

### "Port already in use" Error
```bash
# Kill process using port
lsof -i :8000
kill -9 <PID>
```

### E2E Tests: Browser Won't Launch
```bash
# Reinstall browsers
playwright install --with-deps

# Install system dependencies (Linux)
sudo apt-get install libatk1.0-0 libatk-bridge2.0-0
```

### E2E Tests: Element Not Found
- Check element selectors: `await page.locator("text=Button").click()`
- Wait for element: `await page.wait_for_selector("input[name='email']")`
- Use data-testid attributes: `await page.click("[data-testid='login-button']")`

### Flaky Tests
- Add explicit waits: `await page.wait_for_load_state("networkidle")`
- Increase timeouts for CI/CD
- Use `wait_for_*` methods instead of sleeps

## Performance

### Run Tests in Parallel
```bash
# Install pytest-xdist
pip install pytest-xdist

# Run in parallel
pytest tests/ -v -n auto
```

### Run Only Changed Tests
```bash
# With pytest-watch
pip install pytest-watch

ptw tests/
```

## Continuous Improvement

Track and update:
- Test execution time
- Coverage reports
- Flaky test patterns
- New test requirements
- Test maintenance costs

## Related Documentation

- [README.md](../README.md) - Project overview
- [backend/README.md](../backend/README.md) - Backend setup and testing
- [frontend/README.md](../frontend/README.md) - Frontend setup and testing
- [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) - System architecture
- [tests/e2e/README.md](./e2e/README.md) - Detailed E2E testing guide

