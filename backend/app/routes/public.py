import logging
import json
from html import escape

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import ContactSubmission, PortfolioData, VisitLog
from app.schemas import APIResponse, ContactFormRequest
from app.services.email_service import (
    ADMIN_EMAIL,
    is_email_configured,
    render_template,
    send_email,
)
from app.services.contact_retention import purge_expired_submissions
from app.services.rate_limiter import get_client_ip, rate_limiter
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
    }


@router.get("/health", tags=["General"])
async def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception as exc:
        db_status = "unhealthy"

    return {
        "status": "healthy" if db_status == "healthy" else "degraded",
        "timestamp": utc_isoformat(utc_now()),
        "database": db_status,
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


@router.get("/api/portfolio/contact", tags=["Portfolio"])
async def get_contact(db: Session = Depends(get_db)):
    return _load_visible_section(db, "contact")


@router.get("/api/portfolio/journey", tags=["Portfolio"])
async def get_journey(db: Session = Depends(get_db)):
    return _load_visible_section(db, "journey")


@router.get("/api/portfolio/all", tags=["Portfolio"])
async def get_all_portfolio(db: Session = Depends(get_db)):
    sections = ["about", "projects", "journey", "contact"]
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
    await rate_limiter.enforce(
        request,
        scope="analytics",
        limit=120,
        window_seconds=60,
    )
    client_ip = get_client_ip(request)

    db.add(
        VisitLog(
            ip=client_ip,
            user_agent=request.headers.get("user-agent"),
        )
    )
    db.commit()


@router.post("/api/portfolio/contact-form", tags=["Contact"], response_model=APIResponse)
async def submit_contact_form(
    form: ContactFormRequest,
    http_request: Request,
    db: Session = Depends(get_db),
):
    await rate_limiter.enforce(
        http_request,
        scope="contact",
        limit=5,
        window_seconds=3600,
    )
    if not is_email_configured():
        raise HTTPException(status_code=503, detail="Contact email is not configured yet. Please try again later.")
    purge_expired_submissions(db)
    submission = ContactSubmission(
        name=form.name,
        email=form.email,
        message=form.message,
    )
    db.add(submission)
    db.commit()

    owner = db.query(PortfolioData).filter(PortfolioData.section == "about").first()
    owner_name = json.loads(owner.content).get("name", "Portfolio owner") if owner else "Portfolio owner"
    values = {
        "visitor_name": escape(form.name),
        "visitor_email": escape(str(form.email)),
        "message_html": escape(form.message).replace("\n", "<br>"),
        "received_at": escape(utc_display(utc_now())),
        "owner_name": escape(str(owner_name)),
        "admin_email": escape(ADMIN_EMAIL),
    }
    admin_body = render_template("contact_admin.html", css_name="contact_email.css", **values)
    visitor_body = render_template("contact_visitor.html", css_name="contact_email.css", **values)
    admin_sent = send_email(
        ADMIN_EMAIL,
        f"Portfolio contact from {form.name}",
        admin_body,
        reply_to=str(form.email),
        plain_body=f"Name: {form.name}\nEmail: {form.email}\n\n{form.message}",
    )
    if not admin_sent:
        logger.error("Contact submission %s was saved but admin notification failed", submission.id)
        raise HTTPException(status_code=503, detail="Message saved, but email delivery failed. Please contact the owner directly.")

    visitor_sent = send_email(
        str(form.email),
        "We received your portfolio message",
        visitor_body,
        reply_to=ADMIN_EMAIL,
        plain_body=f"Thanks for contacting {owner_name}. Your message:\n\n{form.message}\n\nReply to this email to continue the conversation.",
    )

    logger.info("Contact form submitted by %s", form.name)
    return APIResponse(
        status="success",
        message="Message sent to the owner." if not visitor_sent else "Message sent. A copy was emailed to you.",
        data={"visitor_copy_sent": visitor_sent},
    )
