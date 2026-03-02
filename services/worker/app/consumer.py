import json
import logging
import os
import pika
import sqlalchemy
from sqlalchemy.orm import Session

from app.executor.mock_executor import mock_execute

logger = logging.getLogger(__name__)

RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "localhost")
RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", "5672"))
EXCHANGE = "submissions"
QUEUE = "submissions.execute"
ROUTING_KEY = "submissions.execute"

DB_URL = (
    f"postgresql://{os.getenv('DB_USER', 'postgres')}:{os.getenv('DB_PASSWORD', 'postgres')}"
    f"@{os.getenv('DB_HOST', 'localhost')}:{os.getenv('DB_PORT', '5432')}"
    f"/{os.getenv('DB_NAME', 'submissiondb')}"
)

engine = sqlalchemy.create_engine(DB_URL, pool_pre_ping=True)


def update_submission(submission_id: str, status: str, results: dict, execution_time: int, memory_used: int):
    """Update submission status directly in database."""
    with engine.connect() as conn:
        conn.execute(
            sqlalchemy.text(
                "UPDATE submissions SET status = :status, results = :results, "
                "execution_time = :exec_time, memory_used = :memory "
                "WHERE id = :id"
            ),
            {
                "id": submission_id,
                "status": status,
                "results": json.dumps(results),
                "exec_time": execution_time,
                "memory": memory_used,
            },
        )
        conn.commit()


def on_message(channel, method, properties, body):
    """Process a submission message from the queue."""
    try:
        message = json.loads(body)
        submission_id = message["submission_id"]
        code = message["code"]
        language = message["language"]

        logger.info(f"Processing submission {submission_id}, language={language}")

        # Update status to running
        update_submission(submission_id, "running", {}, 0, 0)

        # Execute mock
        result = mock_execute(code, language)

        # Map status
        final_status = result["status"]
        if final_status == "oom_killed":
            final_status = "failed"
        elif final_status == "timeout":
            final_status = "failed"

        # Update with results
        update_submission(
            submission_id,
            final_status,
            result,
            result.get("execution_time_ms", 0),
            result.get("memory_mb", 0),
        )

        logger.info(
            f"Submission {submission_id}: outcome={result['status']}, "
            f"cpu_time={result.get('execution_time_ms', 0)}ms, "
            f"memory={result.get('memory_mb', 0)}MB"
        )

        channel.basic_ack(delivery_tag=method.delivery_tag)

    except Exception as e:
        logger.error(f"Failed to process message: {e}")
        channel.basic_nack(delivery_tag=method.delivery_tag, requeue=False)


def start_consumer():
    """Connect to RabbitMQ and start consuming submission messages."""
    logger.info(f"Connecting to RabbitMQ at {RABBITMQ_HOST}:{RABBITMQ_PORT}")

    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host=RABBITMQ_HOST, port=RABBITMQ_PORT)
    )
    channel = connection.channel()

    channel.exchange_declare(exchange=EXCHANGE, exchange_type="direct", durable=True)
    channel.queue_declare(queue=QUEUE, durable=True)
    channel.queue_bind(queue=QUEUE, exchange=EXCHANGE, routing_key=ROUTING_KEY)

    # Process one message at a time (important for HPA — backlog = scale trigger)
    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue=QUEUE, on_message_callback=on_message)

    logger.info("Worker consumer started. Waiting for messages...")
    channel.start_consuming()
