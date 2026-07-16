import os
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

# Load env variables from .env
load_dotenv()

class Settings(BaseSettings):
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", "postgresql+asyncpg://rashid@localhost:5432/wealth_tracker"
    )
    # Connection pool configurations
    DB_POOL_SIZE: int = int(os.getenv("DB_POOL_SIZE", "10"))
    DB_MAX_OVERFLOW: int = int(os.getenv("DB_MAX_OVERFLOW", "20"))
    DB_POOL_TIMEOUT: float = float(os.getenv("DB_POOL_TIMEOUT", "30.0"))

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
