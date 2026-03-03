# Backend

FastAPI backend with SQLAlchemy, Alembic, JWT auth, and pytest.

## Local setup

```bash
cd backend
poetry install
```

From project root (recommended):

```bash
cp config/.env.dev deploy/.env
docker compose -f deploy/docker-compose.yml up postgres backend --build
```

Endpoints:

- API: http://localhost:8000
- Swagger: http://localhost:8000/docs
- Health: http://localhost:8000/health

## Migrations

```bash
cd backend
poetry run alembic upgrade head
poetry run alembic revision --autogenerate -m "describe change"
```

## Testing

```bash
cd backend
poetry run pytest
poetry run pytest tests/unit -m unit -v
poetry run pytest tests/integration -m integration -v
```

Coverage:

```bash
poetry run pytest --cov=app --cov-report=html
open htmlcov/index.html
```

## Configuration

Configuration is loaded from environment variables via `app/core/config.py`.

Core variables:

- `ENVIRONMENT`
- `DATABASE_HOST` / `DATABASE_PORT` / `DATABASE_NAME` / `DATABASE_USER`
- `DATABASE_PASSWORD` (secret)
- `JWT_SECRET_KEY` (secret)
- `JWT_ALGORITHM`

In AWS, secrets come from AWS Secrets Manager through Terraform-provisioned runtime wiring.

## Structure

```text
backend/
├── app/
│   ├── api/
│   ├── core/
│   ├── db/
│   ├── models/
│   ├── schemas/
│   └── services/
├── alembic/
├── tests/
└── pyproject.toml
```

## CI/CD notes

- `ci.yml`: lint + unit/integration tests
- `staging.yml` and `release.yml`: build backend image and push to ECR
