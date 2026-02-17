# Tic Tac Toe Game - Full Stack Application

A complete full-stack Tic Tac Toe game application with a Python FastAPI backend and Angular frontend.

## Project Overview

This is a web-based Tic Tac Toe game with the following features:
- User authentication (registration & login)
- Create new games
- Join existing games by game ID
- Real-time game board interactions
- Win/loss tracking
- Responsive design

## Architecture

### Tech Stack

**Backend:**
- Python 3.10+
- FastAPI (modern async web framework)
- PostgreSQL (database)
- SQLAlchemy (ORM)
- Alembic (database migrations)
- JWT authentication
- Pytest (testing)

**Frontend:**
- Angular 19 (latest)
- TypeScript 5.6
- RxJS (reactive programming)
- Angular Router (routing)
- Tailwind CSS 4 (styling)
- Standalone components

**Infrastructure:**
- Docker & Docker Compose
- Terraform (IaC)
- AWS (deployment target)

## Project Structure

```
.
├── backend/                    # FastAPI application
│   ├── app/
│   │   ├── api/               # API endpoints
│   │   ├── core/              # Core utilities
│   │   ├── db/                # Database configuration
│   │   ├── models/            # SQLAlchemy models
│   │   ├── schemas/           # Pydantic schemas
│   │   ├── services/          # Business logic
│   │   └── main.py            # FastAPI app
│   ├── tests/                 # Unit tests
│   ├── alembic/               # Database migrations
│   └── requirements.txt
├── frontend/                   # Angular application (MIGRATED FROM REACT)
│   ├── src/
│   │   ├── app/
│   │   │   ├── components/    # Angular components
│   │   │   ├── services/      # Services (API, Auth, Game)
│   │   │   ├── core/          # Guards, interceptors
│   │   │   └── types/         # TypeScript interfaces
│   │   ├── environments/      # Environment config
│   │   ├── styles.css         # Global styles
│   │   └── main.ts            # Bootstrap
│   ├── package.json
│   └── angular.json
├── deploy/                     # Docker compose
├── infra/                      # Terraform configuration
└── scripts/                    # Utility scripts
```

## Getting Started

### Prerequisites

- **macOS**: Install Homebrew, Node.js 18+, Python 3.10+, PostgreSQL 16+, Docker
- **Linux**: Use package manager for Node.js, Python, PostgreSQL, Docker
- **Windows**: Use WSL2 with above tools

### Quick Start with Docker

The easiest way to run the entire application:

```bash
cd deploy
docker-compose up -d
```

Services will be available at:
- Frontend: http://localhost:4200
- Backend API: http://localhost:8000
- Database: localhost:5432

### Manual Setup

#### Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up database
alembic upgrade head

# Run server
uvicorn app.main:app --reload --port 8000
```

Backend will be available at `http://localhost:8000`

#### Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm start
```

Frontend will be available at `http://localhost:4200`

## Development Workflow

### Backend Development

```bash
cd backend

# Activate virtual environment
source venv/bin/activate

# Run development server with auto-reload
make dev  # or: uvicorn app.main:app --reload

# Run tests
make test

# Run linting
make lint
```

### Frontend Development

```bash
cd frontend

# Start development server
npm start

# Run tests
npm test

# Run linting
npm run lint
npm run lint:fix
```

## API Documentation

Once the backend is running, visit `http://localhost:8000/docs` for interactive API documentation (Swagger UI).

### Key Endpoints

**Authentication:**
- `POST /users/register` - Register new user
- `POST /users/login` - User login (returns JWT token)
- `GET /users/me` - Get current user profile

**Games:**
- `POST /games/create_game` - Create new game
- `POST /games/{game_id}/join` - Join existing game
- `POST /games/move` - Make a move
- `GET /games` - Get user's games
- `GET /games/{game_id}` - Get specific game

## Database

### Migrations

Create new migration:
```bash
cd backend
alembic revision --autogenerate -m "description"
```

Run migrations:
```bash
alembic upgrade head
```

## Testing

### Backend Tests
```bash
cd backend
pytest
pytest -v  # Verbose
pytest --cov  # With coverage
```

### Frontend Tests
```bash
cd frontend
npm test
npm test -- --code-coverage
```

## Deployment

### Docker Build

```bash
# Build specific services
docker-compose build frontend
docker-compose build backend

# Or build all
docker-compose build
```

### AWS Deployment

See [TERRAFORM_INFRASTRUCTURE.md](./TERRAFORM_INFRASTRUCTURE.md) for Infrastructure as Code deployment.

## Configuration

### Environment Variables

**Backend (.env):**
```
DATABASE_URL=postgresql://user:password@localhost/dbname
SECRET_KEY=your-secret-key-here
```

**Frontend (.env.local):**
```
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000
```

## Frontend Migration from React to Angular ⭐

The frontend was refactored from React/Next.js to **Angular 19** with the following improvements:
- **Type Safety**: Stronger TypeScript implementation with strict mode
- **State Management**: RxJS observables with services and BehaviorSubjects
- **Dependency Injection**: Built-in Angular DI system for better code organization
- **Performance**: Ahead-of-time compilation and standalone components
- **Testing**: Integrated Jasmine/Karma testing framework
- **Architecture**: Clear separation of concerns with services, components, and interceptors

### What's New in the Angular Frontend:
- ✅ All 6 React components migrated to Angular standalone components
- ✅ API services with centralized HTTP client
- ✅ Authentication service with token management
- ✅ HTTP interceptors for auto-token injection and global error handling
- ✅ Route guards for protected pages
- ✅ Reactive forms with validation
- ✅ RxJS observables for state management
- ✅ Same styling and UX maintained
- ✅ Docker support for containerization

See [frontend/ANGULAR_MIGRATION.md](./frontend/ANGULAR_MIGRATION.md) for detailed migration information.

## Documentation

- [Backend Refactoring Guide](./BACKEND_REFACTORING.md)
- [Frontend Refactoring Guide](./FRONTEND_REFACTORING.md)
- [Infrastructure as Code (Terraform)](./TERRAFORM_INFRASTRUCTURE.md)
- [CI/CD Workflows](./CI_CD_WORKFLOWS.md)
- [Commands Reference](./COMMANDS_REFERENCE.md)
- [Quick Start Guide](./QUICK_START.md)
- [Implementation Summary](./IMPLEMENTATION_SUMMARY.md)
- [Angular Migration Details](./frontend/ANGULAR_MIGRATION.md) ⭐ **NEW**

## Troubleshooting

### Backend Issues

**Port 8000 already in use:**
```bash
lsof -i :8000
kill -9 <PID>
# Or use different port:
uvicorn app.main:app --port 8001
```

**Database connection errors:**
- Ensure PostgreSQL is running
- Check DATABASE_URL environment variable
- Run `alembic upgrade head`

### Frontend Issues

**Port 4200 already in use:**
```bash
ng serve --port 4300
```

**API connection errors:**
- Ensure backend is running on port 8000
- Check `environment.ts` for correct API URL
- Verify CORS settings on backend

**Build errors:**
```bash
# Clear cache and reinstall
rm -rf node_modules dist
npm install
npm run build
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request

## License

See [LICENSE](./LICENSE) file for details.

## Contact & Support

For issues, questions, or contributions, please open an issue in the repository.

## Recent Updates

### Frontend Migration to Angular 19 (Latest) ⭐
- ✅ Migrated from React/Next.js to Angular 19
- ✅ Implemented standalone components
- ✅ Created services for API, Auth, and Game logic
- ✅ Added HTTP interceptors for auth and error handling
- ✅ Configured routing with protection guards
- ✅ Set up Tailwind CSS styling with components
- ✅ Updated Docker configuration
- ✅ Enhanced type safety throughout

### Backend & Infrastructure
- ✅ FastAPI backend with async support
- ✅ PostgreSQL database with migrations
- ✅ JWT authentication
- ✅ Docker containerization
- ✅ Terraform infrastructure code
- ✅ CI/CD pipeline configuration
