import asyncio
import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request

from app.config import settings


class InMemoryRateLimiter:
    """Process-local guard for public endpoints until Redis is introduced."""

    def __init__(self) -> None:
        self._events: dict[tuple[str, str], deque[float]] = defaultdict(deque)
        self._lock = asyncio.Lock()

    async def enforce(
        self,
        request: Request,
        *,
        scope: str,
        limit: int,
        window_seconds: int,
    ) -> None:
        key = (scope, get_client_ip(request))
        now = time.monotonic()
        async with self._lock:
            events = self._events[key]
            while events and now - events[0] >= window_seconds:
                events.popleft()
            if len(events) >= limit:
                raise HTTPException(
                    status_code=429,
                    detail="Too many requests. Please try again later.",
                    headers={"Retry-After": str(window_seconds)},
                )
            events.append(now)


def get_client_ip(request: Request) -> str:
    if settings.trust_proxy_headers:
        forwarded_for = request.headers.get("x-forwarded-for", "")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


rate_limiter = InMemoryRateLimiter()
