"""Privacy-preserving analytics parsing and retention."""
from hashlib import sha256
from urllib.parse import urlparse
from sqlalchemy.orm import Session
from app.config import settings
from app.models import VisitLog
from app.utils.time import utc_now
from datetime import timedelta
from uuid import uuid4

def _ua_value(ua: str, values: tuple[str, ...], fallback: str) -> str:
    return next((value for value in values if value.lower() in ua.lower()), fallback)

def visit_dimensions(user_agent: str, referrer: str | None, session_hint: str | None) -> dict:
    host = urlparse(referrer).hostname if referrer else None
    device = "mobile" if any(v in user_agent.lower() for v in ("mobile", "android", "iphone")) else "desktop"
    browser = _ua_value(user_agent, ("Edge", "Firefox", "Chrome", "Safari"), "Other")
    os_name = _ua_value(user_agent, ("Windows", "Android", "iPhone", "Mac OS", "Linux"), "Other")
    session = sha256(session_hint.encode()).hexdigest()[:32] if session_hint else None
    return {"visit_id": str(uuid4()), "device_type": device, "browser": browser, "operating_system": os_name, "referrer": host, "session_id": session}

def purge_expired_visits(db: Session) -> int:
    cutoff = utc_now() - timedelta(days=settings.analytics_retention_days)
    deleted = db.query(VisitLog).filter(VisitLog.visited_at < cutoff).delete(synchronize_session=False)
    db.commit()
    return deleted
