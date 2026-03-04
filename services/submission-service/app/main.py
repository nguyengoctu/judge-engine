from app.logging_config import setup_logging
setup_logging("submission-service")

from contextlib import asynccontextmanager
from fastapi import FastAPI
from sqlalchemy import text
from app.database import engine, Base
from app.routes import health
from app.routes import submissions
from app.routes import queue_status

# Import models so Base.metadata knows about them
from app.models import submission  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Create tables on startup if they don't exist."""
    with engine.begin() as conn:
        conn.execute(text('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'))
        Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Submission Service API",
    description="Handle code submissions, check execution status, and manage leaderboards.",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    contact={
        "name": "Online Judge Team",
    },
    openapi_tags=[
        {"name": "Health", "description": "Service health checks"},
        {"name": "Submissions", "description": "Code submission and execution"},
        {"name": "Queue", "description": "Queue monitoring"},
    ],
)

app.include_router(health.router, tags=["Health"])
app.include_router(submissions.router)
app.include_router(queue_status.router)

