"""Environment-backed configuration for the portfolio backend."""

import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()


def _as_bool(value: str | None, *, default: bool = False) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _as_origins(value: str | None) -> tuple[str, ...]:
    raw_value = value or "http://127.0.0.1:58115,http://localhost:58115"
    origins = tuple(origin.strip() for origin in raw_value.split(",") if origin.strip())
    if "*" in origins:
        raise RuntimeError("CORS_ALLOW_ORIGINS must list explicit origins")
    return origins


@dataclass(frozen=True)
class Settings:
    environment: str
    database_url: str
    database_echo: bool
    cors_allow_origins: tuple[str, ...]
    cors_allow_origin_regex: str | None
    trust_proxy_headers: bool
    contact_retention_days: int
    analytics_retention_days: int
    admin_email: str
    jwt_secret_key: str
    jwt_algorithm: str
    jwt_access_token_minutes: int
    email_delivery_mode: str
    gmail_sender_email: str
    email_outbox_dir: str
    gmail_oauth_client_file: str
    gmail_token_file: str


def load_settings() -> Settings:
    admin_email = os.getenv("ADMIN_EMAIL", "").strip()
    return Settings(
        environment=os.getenv("APP_ENV", "development").strip().lower(),
        database_url=os.getenv("DATABASE_URL", "sqlite:///./portfolio_dev.db").strip(),
        database_echo=_as_bool(os.getenv("DATABASE_ECHO")),
        cors_allow_origins=_as_origins(os.getenv("CORS_ALLOW_ORIGINS")),
        cors_allow_origin_regex=os.getenv(
            "CORS_ALLOW_ORIGIN_REGEX", r"^http://(localhost|127\.0\.0\.1):\d+$"
        )
        or None,
        trust_proxy_headers=_as_bool(os.getenv("TRUST_PROXY_HEADERS")),
        contact_retention_days=max(1, int(os.getenv("CONTACT_RETENTION_DAYS", "90"))),
        analytics_retention_days=max(1, int(os.getenv("ANALYTICS_RETENTION_DAYS", "90"))),
        admin_email=admin_email,
        jwt_secret_key=os.getenv("JWT_SECRET_KEY", "").strip(),
        jwt_algorithm=os.getenv("JWT_ALGORITHM", "HS256").strip(),
        jwt_access_token_minutes=max(1, int(os.getenv("JWT_ACCESS_TOKEN_MINUTES", "60"))),
        email_delivery_mode=os.getenv("EMAIL_DELIVERY_MODE", "log").strip().lower(),
        gmail_sender_email=os.getenv("GMAIL_SENDER_EMAIL", admin_email).strip(),
        email_outbox_dir=os.getenv("EMAIL_OUTBOX_DIR", "./dev_outbox").strip(),
        gmail_oauth_client_file=os.getenv("GMAIL_OAUTH_CLIENT_FILE", ".secrets/gmail_client.json").strip(),
        gmail_token_file=os.getenv("GMAIL_TOKEN_FILE", ".secrets/gmail_token.json").strip(),
    )


settings = load_settings()
