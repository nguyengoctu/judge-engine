import json
import logging
import pika
from app.config import settings

logger = logging.getLogger(__name__)

EXCHANGE = "submissions"
QUEUE = "submissions.execute"
ROUTING_KEY = "submissions.execute"


def get_connection():
    return pika.BlockingConnection(
        pika.ConnectionParameters(
            host=settings.rabbitmq_host,
            port=settings.rabbitmq_port,
        )
    )


def publish_submission(submission_id: str, code: str, language: str):
    """Publish a submission message to RabbitMQ for worker processing."""
    try:
        connection = get_connection()
        channel = connection.channel()

        channel.exchange_declare(
            exchange=EXCHANGE, exchange_type="direct", durable=True
        )
        channel.queue_declare(queue=QUEUE, durable=True)
        channel.queue_bind(
            queue=QUEUE, exchange=EXCHANGE, routing_key=ROUTING_KEY
        )

        message = json.dumps(
            {
                "submission_id": submission_id,
                "code": code,
                "language": language,
            }
        )

        channel.basic_publish(
            exchange=EXCHANGE,
            routing_key=ROUTING_KEY,
            body=message,
            properties=pika.BasicProperties(
                delivery_mode=2,  # persistent
                content_type="application/json",
            ),
        )

        logger.info(f"Published submission {submission_id} to queue")
        connection.close()
    except Exception as e:
        logger.error(f"Failed to publish submission {submission_id}: {e}")
        raise
