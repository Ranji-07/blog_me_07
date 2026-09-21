"""Immutable draft, publication, and restoration helpers for CMS records."""

from datetime import datetime
from typing import Any

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models import ContentVersion
from app.utils.time import utc_now


def next_version(db: Session, content_type: str, content_id: str) -> int:
    latest = db.query(func.max(ContentVersion.version)).filter(
        ContentVersion.content_type == content_type,
        ContentVersion.content_id == content_id,
    ).scalar()
    return (latest or 0) + 1


def create_version(
    db: Session,
    *,
    content_type: str,
    content_id: str,
    snapshot: dict[str, Any],
    changed_by: str,
    action: str,
    version_status: str = "draft",
    version: int | None = None,
) -> ContentVersion:
    entry = ContentVersion(
        content_type=content_type,
        content_id=content_id,
        version=version or next_version(db, content_type, content_id),
        status=version_status,
        snapshot=snapshot,
        changed_by=changed_by,
        action=action,
        published_at=utc_now() if version_status == "published" else None,
    )
    db.add(entry)
    return entry


def latest_version(db: Session, content_type: str, content_id: str, *, status: str | None = None) -> ContentVersion | None:
    query = db.query(ContentVersion).filter(
        ContentVersion.content_type == content_type,
        ContentVersion.content_id == content_id,
    )
    if status:
        query = query.filter(ContentVersion.status == status)
    return query.order_by(ContentVersion.version.desc()).first()


def version_history(db: Session, content_type: str, content_id: str) -> list[ContentVersion]:
    return db.query(ContentVersion).filter(
        ContentVersion.content_type == content_type,
        ContentVersion.content_id == content_id,
    ).order_by(ContentVersion.version.desc()).all()


def publish_latest_draft(db: Session, content_type: str, content_id: str) -> ContentVersion:
    draft = latest_version(db, content_type, content_id, status="draft")
    if draft is None:
        raise ValueError("No draft version is available to publish")
    draft.status = "published"
    draft.published_at = utc_now()
    return draft


def archive_published_versions(db: Session, content_type: str, content_id: str) -> None:
    db.query(ContentVersion).filter(
        ContentVersion.content_type == content_type,
        ContentVersion.content_id == content_id,
        ContentVersion.status == "published",
    ).update({"status": "archived"}, synchronize_session=False)


def serialize_version(entry: ContentVersion) -> dict[str, Any]:
    return {
        "version": entry.version,
        "status": entry.status,
        "snapshot": entry.snapshot,
        "changed_by": entry.changed_by,
        "action": entry.action,
        "changed_at": entry.changed_at,
        "published_at": entry.published_at,
    }
