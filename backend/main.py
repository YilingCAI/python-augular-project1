from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import users, health, game
from app.core.config import settings
from app.core.logging import setup_logging
import os

setup_logging()

# Create FastAPI app
app = FastAPI(
    title="Game API",
    version="1.0.0",
    debug=settings.DEBUG
)

# CORS Configuration
# Allow environment-based origins for different deployments
allowed_origins = os.getenv(settings.ALLOWED_ORIGINS, "http://localhost:4200").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["Authorization", "Content-Type"],
)

# Security headers middleware
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = \
"default-src 'self'; script-src 'self'; object-src 'none';"
    return response

# Include routers
app.include_router(game.router)
app.include_router(users.router)
app.include_router(health.router)
