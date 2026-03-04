from app.logging_config import setup_logging
setup_logging("worker")

import logging
import threading
from contextlib import asynccontextmanager
from fastapi import FastAPI

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Start RabbitMQ consumer in background thread on app startup."""
    logger.info("Starting worker consumer thread...")
    from app.consumer import start_consumer

    consumer_thread = threading.Thread(target=start_consumer, daemon=True)
    consumer_thread.start()
    yield
    logger.info("Shutting down worker...")


app = FastAPI(
    title="Worker Service API",
    description="Background worker for code execution jobs.",
    version="1.0.0",
    docs_url="/docs",
    openapi_url="/openapi.json",
    lifespan=lifespan,
    openapi_tags=[
        {"name": "Health", "description": "Service health checks"},
    ],
)


@app.get("/health", tags=["Health"], summary="Health check")
async def health_check():
    return {"status": "UP", "service": "worker"}
