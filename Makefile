.PHONY: help install dev test lint format clean build backend frontend backend-test frontend-test

# Default target
help:
    @echo "Available commands:"
    @echo "  make install          - Install dependencies for both frontend and backend"
    @echo "  make dev              - Run both frontend and backend in development mode"
    @echo "  make backend          - Run backend only"
    @echo "  make frontend         - Run frontend only"
    @echo "  make test             - Run all tests"
    @echo "  make backend-test     - Run backend tests"
    @echo "  make frontend-test    - Run frontend tests"
    @echo "  make lint             - Run linter for both projects"
    @echo "  make format           - Format code for both projects"
    @echo "  make build            - Build both frontend and backend"
    @echo "  make clean            - Clean all build artifacts and dependencies"

# Install dependencies
install:
    @echo "Installing backend dependencies..."
    cd backend && pip install -r requirements.txt
    @echo "Installing frontend dependencies..."
    cd frontend && npm install

# Development - Run both frontend and backend
dev:
    @echo "Starting development environment..."
    @echo "Backend will run on http://localhost:8000"
    @echo "Frontend will run on http://localhost:4200"
    @(cd backend && python -m uvicorn main:app --reload) & \
    (cd frontend && npm start)

# Run backend only
backend:
    @echo "Starting backend on http://localhost:8000"
    cd backend && python -m uvicorn main:app --reload

# Run frontend only
frontend:
    @echo "Starting frontend on http://localhost:4200"
    cd frontend && npm start

# Run all tests
test: backend-test frontend-test
    @echo "All tests completed!"

# Run backend tests
backend-test:
    @echo "Running backend tests..."
    cd backend && python -m pytest -v --tb=short

# Run frontend tests
frontend-test:
    @echo "Running frontend tests..."
    cd frontend && npm run test -- --watch=false --browsers=ChromeHeadless

# Lint code
lint:
    @echo "Linting backend..."
    cd backend && python -m pylint **/*.py || true
    @echo "Linting frontend..."
    cd frontend && npm run lint

# Format code
format:
    @echo "Formatting backend..."
    cd backend && python -m black . && python -m isort .
    @echo "Formatting frontend..."
    cd frontend && npm run format

# Build for production
build:
    @echo "Building backend..."
    cd backend && python -m PyInstaller main.py --onefile || true
    @echo "Building frontend..."
    cd frontend && npm run build

# Clean build artifacts and dependencies
clean:
    @echo "Cleaning up..."
    rm -rf backend/__pycache__
    rm -rf backend/.pytest_cache
    rm -rf backend/dist
    rm -rf backend/build
    rm -rf frontend/dist
    rm -rf frontend/.angular
    rm -rf frontend/node_modules
    @echo "Clean completed!"