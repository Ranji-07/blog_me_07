"""Durable, retryable delivery jobs for contact emails."""

from app.database import SessionLocal
from app.models import EmailEvent
from app.services.email_service import EMAIL_DELIVERY_MODE, send_email
from app.utils.time import utc_now
from app.services.metrics import metrics

MAX_ATTEMPTS = 3


def deliver_email_event(event_id: int) -> bool:
    """Send one persisted event. A failure remains observable and retryable."""
    db = SessionLocal()
    try:
        event = db.query(EmailEvent).filter(EmailEvent.id == event_id).one_or_none()
        if event is None or event.delivery_status == "sent":
            return event is not None
        if event.attempts >= MAX_ATTEMPTS:
            event.delivery_status = "failed"
            db.commit()
            return False
        event.attempts += 1
        event.delivery_status = "pending"
        db.commit()
        success = send_email(event.recipient, event.subject or "Portfolio message", event.html_body or "", reply_to=event.reply_to, plain_body=event.plain_body)
        event.delivery_status = "sent" if success else "failed"
        event.sent_at = utc_now() if success else None
        event.error_message = None if success else f"Delivery failed using {EMAIL_DELIVERY_MODE}."
        db.commit()
        metrics.inc("email_delivery_total", f'status="{"sent" if success else "failed"}"')
        return success
    except Exception as exc:
        db.rollback()
        event = db.query(EmailEvent).filter(EmailEvent.id == event_id).one_or_none()
        if event:
            event.delivery_status = "failed"
            event.error_message = str(exc)[:2000]
            db.commit()
        metrics.inc("background_job_failures_total", 'job="email_delivery"')
        return False
    finally:
        db.close()
