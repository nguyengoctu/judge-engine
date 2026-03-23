import json
import logging
import os
import pika
import time
import sqlalchemy

logger = logging.getLogger(__name__)

# Consumer state (used by health check)
consumer_connected = False

EXECUTOR_MODE = os.getenv("EXECUTOR_MODE", "mock")
RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "localhost")
RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", "5672"))
EXCHANGE = "submissions"
QUEUE = "submissions.execute"
ROUTING_KEY = "submissions.execute"

_db_user = os.getenv("DB_USER", "postgres")
_db_pass = os.getenv("DB_PASSWORD", "postgres")
_db_host = os.getenv("DB_HOST", "localhost")
_db_port = os.getenv("DB_PORT", "5432")
_db_name = os.getenv("DB_NAME", "judgedb")

DB_URL = (
    f"postgresql://{_db_user}:{_db_pass}"
    f"@{_db_host}:{_db_port}/{_db_name}"
)

engine = sqlalchemy.create_engine(DB_URL, pool_pre_ping=True)


def _get_executor():
    """Get the appropriate executor function based on EXECUTOR_MODE."""
    if EXECUTOR_MODE == "docker":
        from app.executor.docker_executor import docker_execute

        return docker_execute
    else:
        from app.executor.mock_executor import mock_execute

        return mock_execute


execute = _get_executor()


def update_submission(
    submission_id: str,
    status: str,
    results: dict,
    execution_time: int,
    memory_used: int,
):
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

        logger.info(
            f"Processing submission {submission_id}, "
            f"language={language}, executor={EXECUTOR_MODE}"
        )

        # Update status to running
        update_submission(submission_id, "running", {}, 0, 0)

        # Execute code
        result = execute(code, language)

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
    """Connect to RabbitMQ with retry
    and start consuming submission messages."""
    global consumer_connected
    max_retries = 30
    retry_delay = 5

    for attempt in range(1, max_retries + 1):
        try:
            logger.info(
                f"Connecting to RabbitMQ at {RABBITMQ_HOST}:{RABBITMQ_PORT} "
                f"(attempt {attempt}/{max_retries})"
            )

            connection = pika.BlockingConnection(
                pika.ConnectionParameters(host=RABBITMQ_HOST,
                                          port=RABBITMQ_PORT)
            )
            channel = connection.channel()

            channel.exchange_declare(exchange=EXCHANGE,
                                     exchange_type="direct",
                                     durable=True)
            channel.queue_declare(queue=QUEUE, durable=True)
            channel.queue_bind(queue=QUEUE, exchange=EXCHANGE,
                               routing_key=ROUTING_KEY)

            # Process one message at a time
            # (important for HPA — backlog = scale trigger)
            channel.basic_qos(prefetch_count=1)
            channel.basic_consume(queue=QUEUE, on_message_callback=on_message)

            consumer_connected = True
            logger.info("Worker consumer started. Waiting for messages...")
            channel.start_consuming()

        except pika.exceptions.AMQPConnectionError:
            consumer_connected = False
            logger.warning(
                f"RabbitMQ not ready, retrying in {retry_delay}s... "
                f"({attempt}/{max_retries})"
            )
            time.sleep(retry_delay)

        except Exception as e:
            consumer_connected = False
            logger.error(f"Consumer error: {e}, retrying in {retry_delay}s...")
            time.sleep(retry_delay)

    consumer_connected = False
    logger.error("Failed to connect to RabbitMQ after all retries")
