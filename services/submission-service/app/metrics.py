from prometheus_client import Counter, Histogram

# Total submissions by programming language
submissions_total = Counter(
    "submissions_total",
    "Total number of submissions",
    ["language"],
)

# Submissions grouped by result status (pending, accepted, wrong_answer, error...)
submissions_by_status = Counter(
    "submissions_by_status_total",
    "Total submissions by result status",
    ["status"],
)

# Failed attempts to publish submission to RabbitMQ
queue_publish_errors_total = Counter(
    "queue_publish_errors_total",
    "Total failed attempts to publish to RabbitMQ",
)

# Time spent creating a submission (DB insert + queue publish)
submission_create_duration = Histogram(
    "submission_create_duration_seconds",
    "Time spent creating a submission (DB + queue publish)",
    buckets=[0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5],
)

