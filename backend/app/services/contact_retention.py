import os
from datetime import timedelta

from sqlalchemy.orm import Session

from app.models import ContactSubmission
from app.utils.time import utc_now


def purge_expired_submissions(db: Session) -> int:
    retention_days = int(os.getenv("CONTACT_RETENTION_DAYS", "90"))
    cutoff = utc_now() - timedelta(days=max(retention_days, 1))
    deleted = (
        db.query(ContactSubmission)
        .filter(ContactSubmission.created_at < cutoff)
        .delete(synchronize_session=False)
    )
    if deleted:
        db.commit()
    return deleted
