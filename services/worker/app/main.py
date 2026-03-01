from fastapi import FastAPI

app = FastAPI(
    title="Worker Service API",
    description="Background worker for code execution jobs.",
    version="1.0.0",
    docs_url="/docs",
    openapi_url="/openapi.json",
    openapi_tags=[
        {"name": "Health", "description": "Service health checks"},
    ],
)


@app.get("/health", tags=["Health"], summary="Health check")
async def health_check():
    return {"status": "UP", "service": "worker"}
