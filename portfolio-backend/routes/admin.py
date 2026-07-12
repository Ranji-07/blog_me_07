import json
import logging
import os
import secrets
from datetime import timedelta
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, Depends, File, Form, Header, HTTPException, Query, UploadFile
from sqlalchemy.orm import Session

from database import BASE_DIR, get_db
from models import ContactSubmission, EmailCommand, PortfolioVersion
from schemas import APIResponse, EmailCommandRequest
from services.content_service import apply_admin_command, load_schema_file, rollback_to_version
from services.email_service import (
    ADMIN_API_KEY,
    ADMIN_EMAIL,
    build_confirmation_email,
    build_success_email,
    generate_confirmation_token,
    send_email,
)
from utils.time import ensure_utc, utc_isoformat, utc_now

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/admin")
APP_BASE_URL = os.getenv("APP_BASE_URL", "http://127.0.0.1:8000").rstrip("/")


def ensure_admin(auth_email: str, admin_token: Optional[str]) -> None:
    if not ADMIN_EMAIL:
        raise HTTPException(status_code=500, detail="Admin email not configured")
    if not ADMIN_API_KEY:
        raise HTTPException(status_code=500, detail="Admin API key not configured")
    if auth_email != ADMIN_EMAIL:
        logger.warning("Unauthorized attempt from: %s", auth_email)
        raise HTTPException(status_code=403, detail="Unauthorized email address")
    if not admin_token or not secrets.compare_digest(admin_token, ADMIN_API_KEY):
        logger.warning("Invalid admin token attempt from: %s", auth_email)
        raise HTTPException(status_code=403, detail="Invalid admin token")


def resolve_admin_token(
    body_token: Optional[str] = None,
    query_token: Optional[str] = None,
    form_token: Optional[str] = None,
    header_token: Optional[str] = None,
) -> Optional[str]:
    return header_token or body_token or query_token or form_token


@router.post("/email-command", tags=["Admin"], response_model=APIResponse)
async def process_email_command(
    request: EmailCommandRequest,
    background_tasks: BackgroundTasks,
    x_admin_token: Optional[str] = Header(default=None, alias="X-Admin-Token"),
    db: Session = Depends(get_db),
):
    ensure_admin(request.auth_email, resolve_admin_token(request.admin_token, header_token=x_admin_token))

    command_data = request.model_dump()
    token = generate_confirmation_token()
    expires_at = utc_now() + timedelta(hours=24)

    email_cmd = EmailCommand(
        command_type=request.action.value,
        email_from=request.auth_email,
        data=json.dumps(command_data),
        token=token,
        confirmed=False,
        expires_at=expires_at,
    )
    db.add(email_cmd)
    db.commit()

    confirmation_url = f"{APP_BASE_URL}/api/admin/confirm/{token}"
    background_tasks.add_task(
        send_email,
        request.auth_email,
        "Confirm Portfolio Admin Action",
        build_confirmation_email(request, confirmation_url),
    )

    logger.info(
        "Admin action pending confirmation: action=%s section=%s target=%s",
        request.action.value,
        request.section.value,
        request.target_id,
    )
    return APIResponse(
        status="pending",
        message="Confirmation email sent. Check your inbox.",
        data={
            "token": token,
            "confirmation_url": confirmation_url,
            "action": request.action.value,
            "section": request.section.value,
            "target_id": request.target_id,
        },
    )


@router.get("/confirm/{token}", tags=["Admin"])
async def confirm_update(
    token: str,
    auth_email: str = Query(...),
    admin_token: Optional[str] = Query(default=None),
    x_admin_token: Optional[str] = Header(default=None, alias="X-Admin-Token"),
    db: Session = Depends(get_db),
):
    ensure_admin(auth_email, resolve_admin_token(query_token=admin_token, header_token=x_admin_token))
    email_cmd = db.query(EmailCommand).filter(
        EmailCommand.token == token,
        EmailCommand.confirmed == False,
    ).first()

    if not email_cmd:
        raise HTTPException(status_code=404, detail="Invalid or expired token")

    if email_cmd.expires_at and ensure_utc(email_cmd.expires_at) < utc_now():
        raise HTTPException(status_code=410, detail="Token has expired")

    command = json.loads(email_cmd.data)
    if command.get("auth_email") != auth_email:
        raise HTTPException(status_code=403, detail="Confirmation email mismatch")

    result = apply_admin_command(command, db, command_token=token)

    email_cmd.confirmed = True
    db.commit()

    send_email(
        email_cmd.email_from,
        "Portfolio Action Completed",
        build_success_email(
            action=result["action"],
            section=result["section"],
            detail=f"Target: {result.get('target_id') or 'section-root'}",
        ),
    )

    logger.info("Portfolio action completed: %s", result)
    return APIResponse(
        status="success",
        message="Portfolio admin action completed successfully",
        data=result,
    )


@router.post("/upload-image", tags=["Admin"], response_model=APIResponse)
async def upload_image(
    file: UploadFile = File(...),
    auth_email: str = Form(...),
    admin_token: str = Form(...),
    asset_type: str = Form("image"),
):
    ensure_admin(auth_email, admin_token)

    allowed_types = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="Invalid file type. Allowed: JPEG, PNG, GIF, WebP")

    contents = await file.read()
    if len(contents) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large. Max 5MB")

    upload_dir = BASE_DIR / "uploaded_images"
    upload_dir.mkdir(exist_ok=True)
    file_path = upload_dir / file.filename
    file_path.write_bytes(contents)

    asset_url = f"/images/{file.filename}"
    logger.info("Image uploaded: %s", file.filename)
    return APIResponse(
        status="success",
        message="Asset uploaded successfully",
        data={
            "filename": file.filename,
            "asset_type": asset_type,
            "asset": {
                "url": asset_url,
                "image_url": asset_url if asset_type == "image" else None,
                "icon_url": asset_url if asset_type == "icon" else None,
                "mime_type": file.content_type,
                "size_bytes": len(contents),
            },
        },
    )


@router.post("/seed", tags=["Admin"], response_model=APIResponse)
async def seed_database(
    auth_email: str = Query(...),
    admin_token: Optional[str] = Query(default=None),
    x_admin_token: Optional[str] = Header(default=None, alias="X-Admin-Token"),
):
    ensure_admin(auth_email, resolve_admin_token(query_token=admin_token, header_token=x_admin_token))
    try:
        from init_db import init_database

        init_database()
        return APIResponse(status="success", message="Database seeded successfully!")
    except Exception as exc:
        logger.error("Error seeding database: %s", exc)
        raise HTTPException(status_code=500, detail=f"Error seeding database: {str(exc)}") from exc


@router.get("/history", tags=["Admin"], response_model=APIResponse)
async def get_portfolio_history(
    auth_email: str = Query(...),
    admin_token: Optional[str] = Query(default=None),
    section: Optional[str] = Query(default=None),
    limit: int = Query(50, ge=1, le=200),
    x_admin_token: Optional[str] = Header(default=None, alias="X-Admin-Token"),
    db: Session = Depends(get_db),
):
    ensure_admin(auth_email, resolve_admin_token(query_token=admin_token, header_token=x_admin_token))

    query = db.query(PortfolioVersion)
    if section:
        query = query.filter(PortfolioVersion.section == section)
    versions = query.order_by(PortfolioVersion.created_at.desc()).limit(limit).all()

    return APIResponse(
        status="success",
        message="Portfolio history fetched successfully",
        data={
            "versions": [
                {
                    "id": item.id,
                    "section": item.section,
                    "action": item.action,
                    "actor_email": item.actor_email,
                    "target_id": item.target_id,
                    "command_token": item.command_token,
                    "created_at": utc_isoformat(item.created_at),
                    "snapshot_before": json.loads(item.snapshot_before) if item.snapshot_before else None,
                    "snapshot_after": json.loads(item.snapshot_after) if item.snapshot_after else None,
                }
                for item in versions
            ]
        },
    )


@router.post("/history/{version_id}/rollback", tags=["Admin"], response_model=APIResponse)
async def rollback_portfolio_version(
    version_id: int,
    auth_email: str = Query(...),
    admin_token: Optional[str] = Query(default=None),
    x_admin_token: Optional[str] = Header(default=None, alias="X-Admin-Token"),
    db: Session = Depends(get_db),
):
    ensure_admin(auth_email, resolve_admin_token(query_token=admin_token, header_token=x_admin_token))

    version = db.query(PortfolioVersion).filter(PortfolioVersion.id == version_id).first()
    if not version:
        raise HTTPException(status_code=404, detail="Version not found")

    rollback_to_version(db, version=version, actor_email=auth_email)

    logger.info("Portfolio version %s rolled back by %s", version_id, auth_email)
    return APIResponse(
        status="success",
        message="Portfolio version rolled back successfully",
        data={
            "rolled_back_version_id": version.id,
            "section": version.section,
            "restored_snapshot": json.loads(version.snapshot_before) if version.snapshot_before else {},
        },
    )


@router.get("/schema/{name}", tags=["Admin"])
async def get_schema(name: str):
    allowed = {
        "content": "content-schema.json",
        "example": "content-schema-example.json",
    }
    if name not in allowed:
        raise HTTPException(status_code=404, detail="Unknown schema document")
    return load_schema_file(allowed[name])


@router.get("/submissions", tags=["Admin"])
async def get_contact_submissions(
    auth_email: str = Query(...),
    admin_token: Optional[str] = Query(default=None),
    limit: int = Query(50, ge=1, le=100),
    x_admin_token: Optional[str] = Header(default=None, alias="X-Admin-Token"),
    db: Session = Depends(get_db),
):
    ensure_admin(auth_email, resolve_admin_token(query_token=admin_token, header_token=x_admin_token))
    submissions = db.query(ContactSubmission).order_by(
        ContactSubmission.created_at.desc()
    ).limit(limit).all()

    return {
        "submissions": [
            {
                "id": item.id,
                "name": item.name,
                "email": item.email,
                "contact": item.contact,
                "message": item.message,
                "created_at": utc_isoformat(item.created_at),
                "is_read": item.is_read,
            }
            for item in submissions
        ]
    }
