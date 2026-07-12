from datetime import UTC, datetime


def utc_now() -> datetime:
    return datetime.now(UTC)


def ensure_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def utc_isoformat(value: datetime) -> str:
    return ensure_utc(value).isoformat()


def utc_display(value: datetime, fmt: str = "%Y-%m-%d %H:%M:%S UTC") -> str:
    return ensure_utc(value).strftime(fmt)
