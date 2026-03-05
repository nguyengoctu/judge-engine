import logging
import os
import threading
from contextlib import asynccontextmanager
from fastapi import FastAPI

from app.logging_config import setup_logging

setup_logging("worker")

logger = logging.getLogger(__name__)

EXECUTOR_MODE = os.getenv("EXECUTOR_MODE", "mock")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Pre-pull runner images and start RabbitMQ consumer on app startup."""
    logger.info(f"Worker starting with executor_mode={EXECUTOR_MODE}")

    if EXECUTOR_MODE == "docker":
        from app.executor.docker_executor import pull_runner_images
        pull_runner_images()

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
