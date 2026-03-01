from fastapi import FastAPI
from app.routes import health

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
        {"name": "Competitions", "description": "Competition leaderboards"},
    ],
)

app.include_router(health.router, tags=["Health"])
