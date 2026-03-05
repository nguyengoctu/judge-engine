from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    rabbitmq_host: str = "localhost"
    rabbitmq_port: int = 5672
    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "submissiondb"
    db_user: str = "postgres"
    db_password: str = "postgres"
    redis_host: str = "localhost"
    redis_port: int = 6379

    # Executor config
    executor_mode: str = "mock"  # "mock" or "docker"
    sandbox_memory_limit: str = "256m"
    sandbox_cpu_limit: float = 0.5
    sandbox_timeout: int = 10
    sandbox_pids_limit: int = 50

    class Config:
        env_file = ".env"


settings = Settings()
