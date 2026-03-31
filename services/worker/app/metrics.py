from prometheus_client import Counter, Histogram, Gauge

# Total jobs processed by language and final status
jobs_processed_total = Counter(
    "worker_jobs_processed_total",
    "Total jobs processed by the worker",
    ["language", "status"],
)

# Total job processing failures (unhandled exceptions)
jobs_failed_total = Counter(
    "worker_jobs_failed_total",
    "Total jobs that failed with unhandled exceptions",
)

# Code execution duration (actual container/mock run time)
job_execution_duration = Histogram(
    "worker_job_execution_duration_seconds",
    "Time spent executing code (container runtime)",
    buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0],
)

# Currently running jobs
jobs_in_progress = Gauge(
    "worker_jobs_in_progress",
    "Number of jobs currently being executed",
)
