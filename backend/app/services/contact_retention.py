from datetime import timedelta

from sqlalchemy.orm import Session

from app.models import ContactSubmission
from app.config import settings
from app.utils.time import utc_now


def purge_expired_submissions(db: Session) -> int:
    cutoff = utc_now() - timedelta(days=settings.contact_retention_days)
    deleted = (
        db.query(ContactSubmission)
        .filter(ContactSubmission.created_at < cutoff)
        .delete(synchronize_session=False)
    )
    if deleted:
        db.commit()
    return deleted
