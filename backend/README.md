# Backend README

FastAPI microservices backend with PostgreSQL database.

## Quick Start

```bash
# Install dependencies
cd backend
pip install -e .

# Create .env
cp ../.env.example .env.local
nano .env.local

# Run locally
make backend
# or
python -m uvicorn app.main:app --reload

# Visit http://localhost:8000
# API docs: http://localhost:8000/docs
```

## Project Structure

```
backend/
├── README.md                 # This file
├── main.py                  # Application entry point
├── pyproject.toml           # Python dependencies and config
├── pytest.ini               # pytest configuration
├── alembic.ini              # Database migration config
│
├── app/
│   ├── __init__.py
│   ├── core/                # Core utilities
│   │   ├── config.py       # Configuration management
│   │   └── security.py     # JWT and auth utilities
│   ├── api/                 # API endpoints
│   │   ├── __init__.py
│   │   ├── users.py        # User endpoints
│   │   ├── games.py        # Game endpoints
│   │   └── health.py       # Health check endpoint
│   ├── db/                  # Database
│   │   ├── __init__.py
│   │   ├── base.py         # SQLAlchemy setup
│   │   ├── session.py      # Database session
│   │   └── models.py       # ORM models (see models/)
│   ├── models/              # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── user.py         # User model
│   │   └── game.py         # Game model
│   ├── schemas/             # Pydantic schemas (serialization)
│   │   ├── __init__.py
│   │   ├── user.py         # User schemas
│   │   └── game.py         # Game schemas
│   ├── services/            # Business logic
│   │   ├── __init__.py
│   │   ├── user_service.py # User operations
│   │   └── game_service.py # Game operations
│   └── main.py              # FastAPI app instance
│
├── tests/                   # Unit tests
│   ├── __init__.py
│   ├── conftest.py         # Pytest fixtures
│   ├── test_health.py      # Health endpoint tests
│   ├── test_users.py       # User endpoint tests
│   └── test_game.py        # Game endpoint tests
│
├── alembic/                 # Database migrations
│   ├── env.py
│   ├── script.py.mako
│   └── versions/           # Migration files
│
└── .dockerignore
```

## Technologies

- **Framework**: FastAPI 0.104+
- **Database**: PostgreSQL 16
- **ORM**: SQLAlchemy 2.0
- **Migrations**: Alembic
- **Testing**: pytest + httpx
- **Auth**: JWT (PyJWT)
- **Validation**: Pydantic v2

## API Endpoints

### Health Check
```
GET /health
Response: {"status": "healthy"}
```

### Authentication
```
POST /users/register
Body: {"email": "user@example.com", "password": "secret"}
Response: {"id": "uuid", "email": "user@example.com"}

POST /users/login
Body: {"email": "user@example.com", "password": "secret"}
Response: {"access_token": "jwt-token", "token_type": "bearer"}

GET /users/me
Headers: Authorization: Bearer <token>
Response: {"id": "uuid", "email": "user@example.com"}
```

### Games
```
POST /games/create_game
Headers: Authorization: Bearer <token>
Response: {"game_id": "uuid", "status": "active"}

POST /games/{game_id}/join
Headers: Authorization: Bearer <token>
Body: {}
Response: {"game_id": "uuid", "players": []}

POST /games/move
Headers: Authorization: Bearer <token>
Body: {"game_id": "uuid", "position": 0}
Response: {"game_id": "uuid", "board": [...], "winner": null}

GET /games
Headers: Authorization: Bearer <token>
Response: [{"game_id": "uuid", ...}]

GET /games/{game_id}
Headers: Authorization: Bearer <token>
Response: {"game_id": "uuid", ...}
```

See http://localhost:8000/docs (Swagger) for complete API.

## Database

### Connection
```bash
# From .env
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# Connect directly
psql postgresql://user:password@localhost:5432/dbname
```

### Migrations

Create migration:
```bash
alembic revision --autogenerate -m "add user table"
```

Run migrations:
```bash
alembic upgrade head
```

Check status:
```bash
alembic current
alembic history
```

Rollback:
```bash
alembic downgrade -1  # Rollback one migration
```

## Development

### Run Locally
```bash
# Backend only
make backend

# Or manually
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Running Tests
```bash
# All tests
make backend-test

# Or manually
pytest
pytest -v              # Verbose
pytest --cov=app       # With coverage
pytest tests/test_users.py  # Specific test file
pytest tests/test_users.py::test_register  # Specific test
```

### Linting & Formatting
```bash
# Lint
ruff check .

# Format
black --line-length 100 .
```

## Configuration

### Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/myproject

# Security
SECRET_KEY=your-secret-key-here
JWT_SECRET_KEY=your-jwt-secret-here
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Server
HOST=0.0.0.0
PORT=8000
DEBUG=true
```

### Config File

See `app/core/config.py` for all configurable settings.

```python
class Settings(BaseSettings):
    project_name: str = "MyProject"
    database_url: str
    secret_key: str
    jwt_algorithm: str = "HS256"
    debug: bool = False
    
    class Config:
        env_file = ".env.local"
```

## Docker

### Build
```bash
docker build -t myproject-backend:local .
```

### Run
```bash
docker run -e DATABASE_URL=... -p 8000:8000 myproject-backend:local
```

### With Docker Compose
```bash
cd deploy
docker-compose up backend postgres
```

## Debugging

### Print Debug Info
```python
# In code
from fastapi import logger

logger.error(f"User ID: {user_id}")
```

### Check Database
```bash
# Connect to database
psql $DATABASE_URL

# List tables
\dt

# Query users
SELECT * FROM users;

# Query games
SELECT * FROM games;
```

### View Logs
```bash
# Local development
tail -f backend.log

# Docker
docker logs <container-id>

# Production (AWS)
aws logs tail /aws/ecs/myproject-staging --follow
```

## Dependencies

### Main Dependencies
```toml
fastapi = "^0.104"
uvicorn = "^0.24"
sqlalchemy = "^2.0"
alembic = "^1.12"
psycopg2-binary = "^2.9"
pydantic = "^2.0"
pydantic-settings = "^2.0"
pyjwt = "^2.8"
python-dotenv = "^1.0"
```

### Dev Dependencies
```toml
pytest = "^7.4"
pytest-asyncio = "^0.21"
pytest-cov = "^4.1"
httpx = "^0.24"
black = "^23.0"
ruff = "^0.1"
```

To add a new dependency:
```bash
pip install new-package
pip freeze > requirements.txt
```

## Performance Tips

1. **Add database indexes** on frequently queried fields
2. **Use connection pooling** (SQLAlchemy default)
3. **Optimize N+1 queries** with eager loading
4. **Use async/await** for I/O operations

## Security Best Practices

1. ✅ Validate all inputs (Pydantic handles this)
2. ✅ Hash passwords with bcrypt
3. ✅ Use JWT for authentication
4. ✅ Implement rate limiting
5. ✅ Use HTTPS in production
6. ✅ Never log sensitive data
7. ✅ Use environment variables for secrets
8. ✅ Escape SQL parameters (SQLAlchemy handles this)

## Troubleshooting

### Database Connection Error
```bash
# Check database is running
docker-compose -f deploy/docker-compose.yml ps postgres

# Check connection string
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL -c "SELECT 1"
```

### Port Already in Use
```bash
lsof -i :8000
kill -9 <PID>
```

### Import Errors
```bash
# Ensure backend directory is in Python path
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Or reinstall
pip install -e .
```

## Deployment

### Build Docker Image
```bash
make docker-build ENV=staging IMAGE_TAG=v1.0.0
```

### Deploy to ECS
```bash
make ecs-deploy ENV=staging IMAGE_TAG=v1.0.0
```

### View Logs
```bash
aws logs tail /aws/ecs/myproject-staging --follow
```

## Further Reading

- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [SQLAlchemy Docs](https://docs.sqlalchemy.org/)
- [Alembic Docs](https://alembic.sqlalchemy.org/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [JWT.io](https://jwt.io/)

## Related Documentation

- [README.md](../README.md) - Project overview
- [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) - System design
- [../frontend/README.md](../frontend/README.md) - Frontend docs
- [../infra/README.md](../infra/README.md) - Infrastructure docs
