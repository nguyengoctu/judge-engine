from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "judgedb"
    db_user: str = "postgres"
    db_password: str = "postgres"
    redis_host: str = "localhost"
    redis_port: int = 6379
    rabbitmq_host: str = "localhost"
    rabbitmq_port: int = 5672

    class Config:
        env_file = ".env"


settings = Settings()
