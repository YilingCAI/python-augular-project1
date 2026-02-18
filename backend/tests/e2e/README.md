# End-to-End Tests

Playwright-based E2E tests for complete user journeys.

## Setup

### Install Dependencies
```bash
# Install Playwright
pip install pytest-playwright

# Install browser
playwright install chromium
```

### Configuration

**pytest.ini** (if needed):
```ini
[pytest]
markers =
    asyncio: marks tests as async (deselect with '-m "not asyncio"')
    e2e: marks tests as E2E (slow, full browser)
```

## Running E2E Tests

### Run All Tests
```bash
pytest tests/e2e/ -v
```

### Run Specific Test
```bash
pytest tests/e2e/test_user_flows.py::test_user_registration_e2e -v
```

### Run with Screenshots
```bash
pytest tests/e2e/ -v --screenshot=on
```

### Run with Video Recording
```bash
pytest tests/e2e/ -v --video=retain-on-failure
```

### Run Against Staging
```bash
BASE_URL=https://staging.example.com pytest tests/e2e/ -v
```

### Run in Parallel
```bash
pytest tests/e2e/ -v -n auto
```

## Test Coverage

### Authentication
- ✅ User registration
- ✅ User login with valid credentials
- ✅ Login with invalid credentials
- ✅ Logout functionality
- ✅ Protected route redirection

### Game Flows
- ✅ Create new game
- ✅ Play game with moves
- ✅ View game history
- ✅ Join existing game

### UI/UX
- ✅ Responsive design (mobile, tablet, desktop)
- ✅ Keyboard navigation
- ✅ Error message display
- ✅ Loading states

### Network
- ✅ Network error handling
- ✅ Offline mode handling
- ✅ Slow network simulation

### Accessibility
- ✅ Keyboard navigation
- ✅ ARIA labels
- ✅ Focus management

## Example Test Structure

```python
@pytest.mark.asyncio
async def test_example_flow(page: Page):
    """Test description"""
    # Navigate
    await page.goto("http://localhost:4200")
    
    # Interact
    await page.fill("input[name='email']", "test@example.com")
    await page.click("button:has-text('Submit')")
    
    # Assert
    await page.wait_for_url("**/dashboard")
    assert "dashboard" in page.url
```

## Debugging

### View Test Report
```bash
pytest tests/e2e/ --html=report.html --self-contained-html
```

### Run with Debug Info
```bash
pytest tests/e2e/ -v -s --tb=short
```

### Slow Motion
```bash
pytest tests/e2e/ -v --headed --slow-mo=1000
```

## Best Practices

1. **Use Page Object Model** for larger suites
2. **Wait for elements properly** (use wait_for_* methods)
3. **Clean up data** after tests (use fixtures)
4. **Make tests independent** (no test dependencies)
5. **Use meaningful assertions** (be specific)
6. **Mock external services** (APIs, analytics)
7. **Test user workflows** (not implementation details)

## Continuous Integration

### GitHub Actions
```yaml
- name: Run E2E Tests
  run: |
    pip install pytest-playwright
    playwright install
    pytest tests/e2e/ -v --html=report.html
    
- name: Upload Report
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: e2e-report
    path: report.html
```

## Troubleshooting

### Tests Timeout
```bash
# Increase timeout
pytest tests/e2e/ -v --timeout=30
```

### Element Not Found
- Check selectors are correct
- Wait for page load: `await page.wait_for_load_state("networkidle")`
- Use better selectors: `text=` or `[data-testid=]`

### Flaky Tests
- Add explicit waits
- Use `wait_for_*` methods
- Increase timeouts for CI/CD

### Screenshots/Videos Not Generated
```bash
# Install video codec
apt-get install libopus0 libvpx6 libsnappy1v5

# Run with video
pytest tests/e2e/ --video=on
```

## Further Reading

- [Playwright Docs](https://playwright.dev/python/)
- [Pytest Fixtures](https://docs.pytest.org/en/stable/fixture.html)
- [Page Object Model](https://playwright.dev/python/docs/pom)
- [Best Practices](https://playwright.dev/python/docs/best-practices)

## Related Documentation

- [tests/README.md](../README.md) - Test overview
- [backend/README.md](../../backend/README.md) - Backend testing
- [frontend/README.md](../../frontend/README.md) - Frontend testing
