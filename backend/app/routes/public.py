import logging
import json

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, Request
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import ContactSubmission, PortfolioData, VisitLog
from app.schemas import APIResponse, ContactFormRequest
from app.services.email_service import (
    ADMIN_API_KEY,
    ADMIN_EMAIL,
    can_send_real_email,
    get_email_delivery_mode,
    is_email_configured,
    send_email,
)
from app.utils.time import utc_display, utc_isoformat, utc_now

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/", tags=["General"])
async def root():
    return {
        "name": "Portfolio API",
        "version": "2.0.0",
        "status": "running",
        "docs": "/docs",
        "health": "/health",
        "admin_configured": ADMIN_EMAIL is not None,
        "admin_auth_configured": bool(ADMIN_EMAIL and ADMIN_API_KEY),
        "email_delivery_mode": get_email_delivery_mode(),
        "real_email_ready": can_send_real_email(),
    }


@router.get("/health", tags=["General"])
async def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception as exc:
        db_status = f"unhealthy: {str(exc)}"

    return {
        "status": "healthy" if db_status == "healthy" else "degraded",
        "timestamp": utc_isoformat(utc_now()),
        "database": db_status,
        "email_configured": is_email_configured(),
        "email_delivery_mode": get_email_delivery_mode(),
        "real_email_ready": can_send_real_email(),
        "admin_auth_configured": bool(ADMIN_EMAIL and ADMIN_API_KEY),
    }


def _load_visible_section(db: Session, section: str) -> dict:
    data = db.query(PortfolioData).filter(
        PortfolioData.section == section,
        PortfolioData.is_active == True,
    ).first()

    if not data:
        raise HTTPException(status_code=404, detail=f"{section.title()} section not found or hidden")

    return json.loads(data.content)


@router.get("/api/portfolio/about", tags=["Portfolio"])
async def get_about(db: Session = Depends(get_db)):
    return _load_visible_section(db, "about")


@router.get("/api/portfolio/projects", tags=["Portfolio"])
async def get_projects(
    db: Session = Depends(get_db),
    category: str | None = Query(None, description="Filter projects by category"),
):
    projects = _load_visible_section(db, "projects")
    if category and "projects" in projects:
        projects["projects"] = [
            project
            for project in projects["projects"]
            if project.get("category", "").lower() == category.lower()
        ]
    return projects


@router.get("/api/portfolio/experience", tags=["Portfolio"])
async def get_experience(db: Session = Depends(get_db)):
    return _load_visible_section(db, "experience")


@router.get("/api/portfolio/contact", tags=["Portfolio"])
async def get_contact(db: Session = Depends(get_db)):
    return _load_visible_section(db, "contact")


@router.get("/api/portfolio/all", tags=["Portfolio"])
async def get_all_portfolio(db: Session = Depends(get_db)):
    sections = ["about", "projects", "experience", "contact"]
    result = {}
    for section in sections:
        data = db.query(PortfolioData).filter(
            PortfolioData.section == section,
            PortfolioData.is_active == True,
        ).first()
        result[section] = json.loads(data.content) if data else None
    return result


@router.post("/api/analytics/visit", tags=["Analytics"], status_code=204)
async def record_visit(request: Request, db: Session = Depends(get_db)):
    forwarded_for = request.headers.get("x-forwarded-for", "")
    client_ip = forwarded_for.split(",")[0].strip() if forwarded_for else None
    if not client_ip and request.client:
        client_ip = request.client.host

    db.add(
        VisitLog(
            ip=client_ip,
            user_agent=request.headers.get("user-agent"),
        )
    )
    db.commit()


@router.post("/api/portfolio/contact-form", tags=["Contact"], response_model=APIResponse)
async def submit_contact_form(
    request: ContactFormRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    submission = ContactSubmission(
        name=request.name,
        email=request.email,
        contact=request.contact,
        message=request.message,
    )
    db.add(submission)
    db.commit()

    if ADMIN_EMAIL:
        email_body = f"""
        <h2>New Contact Form Submission</h2>
        <table style="width:100%; border-collapse: collapse;">
            <tr><td style="padding:8px; border-bottom:1px solid #333;"><strong>Name:</strong></td><td style="padding:8px; border-bottom:1px solid #333;">{request.name}</td></tr>
            <tr><td style="padding:8px; border-bottom:1px solid #333;"><strong>Email:</strong></td><td style="padding:8px; border-bottom:1px solid #333;">{request.email}</td></tr>
            <tr><td style="padding:8px; border-bottom:1px solid #333;"><strong>Contact:</strong></td><td style="padding:8px; border-bottom:1px solid #333;">{request.contact}</td></tr>
        </table>
        <h3>Message:</h3>
        <p style="background:#0F172A; padding:15px; border-radius:8px;">{request.message}</p>
        <p style="color:#94A3B8; font-size:12px;">Received at: {utc_display(utc_now())}</p>
        """
        background_tasks.add_task(
            send_email,
            ADMIN_EMAIL,
            f"Portfolio Contact: {request.name}",
            email_body,
        )

    logger.info("Contact form submitted by %s", request.name)
    return APIResponse(
        status="success",
        message="Message sent successfully. We'll get back to you soon!",
    )
