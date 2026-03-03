# Test Architecture

Backend testing strategy and execution model.

## Test layers

```text
tests/
├── unit/         # fully mocked; no real DB/network
└── integration/  # real DB-backed API/repository tests
```

## Running tests

```bash
cd backend
poetry run pytest
poetry run pytest tests/unit -m unit -v
poetry run pytest tests/integration -m integration -v
poetry run pytest --cov=app --cov-report=html --cov-report=term-missing
```

## Markers

Defined in `backend/pytest.ini`:

- `unit`
- `integration`

## Fixture strategy

Key fixtures in `backend/tests/conftest.py`:

- session-level test engine
- per-test transactional DB session rollback isolation
- async HTTP client fixture with dependency override
- auth/token helper fixtures for protected endpoint tests

## Isolation model

Integration tests run in per-test transactions and roll back automatically to keep state clean between tests.

## CI behavior

`ci.yml` runs backend tests in dedicated steps:

- Unit tests
- Integration tests

Both are part of the required CI quality gate.
