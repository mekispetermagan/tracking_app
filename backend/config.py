from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str = "sqlite:///./progress_dev.db"

    jwt_secret_key: str = "change-me-in-env"
    jwt_algorithm: str = "HS256"

    mentor_token_minutes: int = 60
    admin_token_minutes: int = 30
    temp_token_minutes: int = 10
    temporary_secret_days: int = 7

    model_config = SettingsConfigDict(env_file=".env")


settings = Settings()