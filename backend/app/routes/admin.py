"""Admin access to stored contact submissions.

Portfolio content editing is intentionally handled outside this API for now.
"""

import logging
import secrets
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import ContactSubmission
from app.schemas import APIResponse
from app.services.contact_retention import purge_expired_submissions
from app.services.email_service import ADMIN_API_KEY, ADMIN_EMAIL
from app.utils.time import utc_isoformat

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/admin")


def ensure_admin(auth_email: str, admin_token: Optional[str]) -> None:
    if not ADMIN_EMAIL or not ADMIN_API_KEY:
        raise HTTPException(status_code=500, detail="Admin access is not configured")
    if auth_email != ADMIN_EMAIL or not admin_token or not secrets.compare_digest(admin_token, ADMIN_API_KEY):
        logger.warning("Invalid admin access attempt")
        raise HTTPException(status_code=403, detail="Invalid admin credentials")


@router.get("/submissions", tags=["Admin"])
async def get_contact_submissions(
    auth_email: str = Query(...),
    limit: int = Query(50, ge=1, le=100),
    x_admin_token: Optional[str] = Header(default=None, alias="X-Admin-Token"),
    db: Session = Depends(get_db),
):
    ensure_admin(auth_email, x_admin_token)
    submissions = db.query(ContactSubmission).order_by(ContactSubmission.created_at.desc()).limit(limit).all()
    return {
        "submissions": [
            {
                "id": item.id,
                "name": item.name,
                "email": item.email,
                "message": item.message,
                "created_at": utc_isoformat(item.created_at),
                "is_read": item.is_read,
            }
            for item in submissions
        ]
    }


@router.delete("/submissions/{submission_id}", tags=["Admin"], response_model=APIResponse)
async def delete_contact_submission(
    submission_id: int,
    auth_email: str = Query(...),
    x_admin_token: Optional[str] = Header(default=None, alias="X-Admin-Token"),
    db: Session = Depends(get_db),
):
    ensure_admin(auth_email, x_admin_token)
    submission = db.query(ContactSubmission).filter(ContactSubmission.id == submission_id).first()
    if not submission:
        raise HTTPException(status_code=404, detail="Contact submission not found")
    db.delete(submission)
    db.commit()
    return APIResponse(status="success", message="Contact submission deleted")


@router.post("/submissions/purge", tags=["Admin"], response_model=APIResponse)
async def purge_contact_submissions(
    auth_email: str = Query(...),
    x_admin_token: Optional[str] = Header(default=None, alias="X-Admin-Token"),
    db: Session = Depends(get_db),
):
    ensure_admin(auth_email, x_admin_token)
    deleted = purge_expired_submissions(db)
    return APIResponse(status="success", message="Expired contact submissions purged", data={"deleted": deleted})
