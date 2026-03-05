import logging
from fastapi import APIRouter
from app.services.queue import get_connection, QUEUE

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/queue", tags=["Queue"])


@router.get("/status", summary="Queue status",
            description="Returns message count and\
                 consumer count for the submissions queue.")
def queue_status():
    try:
        connection = get_connection()
        channel = connection.channel()
        result = channel.queue_declare(queue=QUEUE, durable=True, passive=True)
        data = {
            "queue": QUEUE,
            "messages": result.method.message_count,
            "consumers": result.method.consumer_count,
        }
        connection.close()
        return data
    except Exception:
        return {"queue": QUEUE, "messages": 0, "consumers": 0}
