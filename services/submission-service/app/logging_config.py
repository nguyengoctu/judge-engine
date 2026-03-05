import logging
import sys
from datetime import datetime, timezone

from pythonjsonlogger import jsonlogger


class CustomJsonFormatter(jsonlogger.JsonFormatter):
    """JSON formatter with consistent field names
    across all Python services."""

    def __init__(self, service_name: str):
        super().__init__()
        self.service_name = service_name

    def add_fields(self, log_record, record, message_dict):
        super().add_fields(log_record, record, message_dict)
        log_record["timestamp"] = datetime.now(timezone.utc).isoformat()
        log_record["level"] = record.levelname
        log_record["service"] = self.service_name
        log_record["logger"] = record.name
        # Remove default fields we don't need
        log_record.pop("levelname", None)
        log_record.pop("name", None)


def setup_logging(service_name: str, level: int = logging.INFO):
    """Configure structured JSON logging for a Python service.

    Args:
        service_name: Name of the service
        (e.g., "submission-service", "worker")
        level: Default log level
    """
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(CustomJsonFormatter(service_name))

    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(level)

    # Reduce noise from third-party libraries
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("pika").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
