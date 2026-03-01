from fastapi import APIRouter

router = APIRouter()


@router.get("/health", summary="Health check", description="Returns service health status.")
async def health_check():
    return {"status": "UP", "service": "submission-service"}
