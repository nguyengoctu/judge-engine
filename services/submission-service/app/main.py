from contextlib import asynccontextmanager
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
from app.routes import health
from app.routes import submissions
from app.routes import queue_status

# Import models so Base.metadata knows about them
from app.models import submission  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Flyway (problem-service) manages schema creation."""
    yield


app = FastAPI(
    title="Submission Service API",
    description="Handle code submissions, check execution status,\
        and manage leaderboards.",
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
        {
            "name": "Submissions",
            "description": "Code submission and execution"
        },
        {"name": "Queue", "description": "Queue monitoring"},
    ],
)

app.include_router(health.router, tags=["Health"])
app.include_router(submissions.router)
app.include_router(queue_status.router)

# Prometheus metrics - auto instruments all HTTP endpoints
# Exposes /metrics endpoint
Instrumentator().instrument(app).expose(app, endpoint="/metrics")
