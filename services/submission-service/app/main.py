from fastapi import FastAPI
from app.routes import health
from app.routes import submissions
from app.routes import queue_status

app = FastAPI(
    title="Submission Service API",
    description="Handle code submissions, check execution status, and manage leaderboards.",
    version="1.0.0",
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
