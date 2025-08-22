from pydantic import BaseModel
import os


class Settings(BaseModel):
    app_name: str = os.getenv("APP_NAME", "fastapi-svc")
    env: str = os.getenv("ENV", "development")
    host: str = os.getenv("HOST", "0.0.0.0")
    port: int = int(os.getenv("PORT", "8000"))
    log_level: str = os.getenv("LOG_LEVEL", "info")
    allowed_origins: str = os.getenv("ALLOWED_ORIGINS", "*")
    database_url: str = os.getenv("DATABASE_URL", "postgresql://app:app@db:5432/app")
    redis_url: str = os.getenv("REDIS_URL", "redis://redis:6379/0")


settings = Settings()
