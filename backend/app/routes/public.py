import logging
import json
from html import escape

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, Request, status
from sqlalchemy import text
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models import ContactSubmission, ContentVersion, EmailEvent, JourneyEvent, PortfolioData, Project, Skill, SkillCategory, VisitLog
from app.schemas import APIResponse, ContactFormRequest
from app.services.email_service import (
    ADMIN_EMAIL,
    EMAIL_DELIVERY_MODE,
    is_email_configured,
    render_template,
    send_email,
)
from app.services.contact_retention import purge_expired_submissions
from app.services.email_outbox import deliver_email_event
from app.services.rate_limiter import rate_limiter
from app.services.analytics import purge_expired_visits, visit_dimensions
from app.services.metrics import metrics
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
        "ready": "/ready",
    }


@router.get("/health", tags=["General"])
async def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception:
        db_status = "unhealthy"

    return {
        "status": "healthy" if db_status == "healthy" else "degraded",
        "timestamp": utc_isoformat(utc_now()),
        "database": db_status,
    }


@router.get("/ready", tags=["General"])
async def readiness_check(db: Session = Depends(get_db)):
    """Report whether the API can serve database-backed portfolio content."""
    try:
        db.execute(text("SELECT 1"))
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"status": "not_ready", "database": "unhealthy"},
        ) from exc
    return {"status": "ready", "timestamp": utc_isoformat(utc_now()), "database": "healthy"}


def _load_visible_section(db: Session, section: str) -> dict:
    data = db.query(PortfolioData).filter(
        PortfolioData.section == section,
        PortfolioData.is_active == True,
    ).first()

    if not data:
        raise HTTPException(status_code=404, detail=f"{section.title()} section not found or hidden")

    return json.loads(data.content)


def _published_snapshot(db: Session, content_type: str, content_id: str) -> dict | None:
    row = db.query(ContentVersion).filter(
        ContentVersion.content_type == content_type,
        ContentVersion.content_id == content_id,
        ContentVersion.status == "published",
    ).order_by(ContentVersion.version.desc()).first()
    return row.snapshot if row else None


def _public_project(item: Project, snapshot: dict | None = None) -> dict:
    data = snapshot or {}
    source_id = int(item.source_id) if item.source_id.isdigit() else item.source_id
    return {
        "id": source_id,
        "title": data.get("title", item.title), "slug": data.get("slug", item.slug), "category": data.get("category", item.category),
        "timeline_date": data.get("timeline_date", item.timeline_date), "timeline_parent": data.get("associated_with") or data.get("timeline_parent") or item.associated_with or item.timeline_parent,
        "featured": data.get("featured", item.featured), "short_description": data.get("short_description", item.short_description) or "", "description": data.get("description", item.description) or "",
        "technologies": data.get("technologies", item.technologies) or [], "features": data.get("features", item.features) or [], "images": data.get("images", item.images) or [],
        "github": data.get("github_url", item.github_url) or "", "live_demo": data.get("live_demo_url", item.live_demo_url) or "", "status": "published",
    }


def _public_projects(db: Session, category: str | None = None) -> dict:
    content = _load_visible_section(db, "projects")
    projects = []
    for item in db.query(Project).filter(Project.status != "archived").order_by(Project.timeline_date, Project.id).all():
        snapshot = _published_snapshot(db, "project", str(item.id))
        if snapshot is None and item.status != "published":
            continue
        project = _public_project(item, snapshot)
        if not category or project["category"].lower() == category.lower(): projects.append(project)
    content["projects"] = projects
    return content


def _public_journey(db: Session) -> dict:
    content = _load_visible_section(db, "journey")
    events = []
    for item in db.query(JourneyEvent).filter(JourneyEvent.status != "archived").order_by(JourneyEvent.display_order, JourneyEvent.timeline_date).all():
        data = _published_snapshot(db, "journey", str(item.id))
        if data is None and item.status != "published": continue
        data = data or {}
        events.append({
            "id": item.source_id, "type": data.get("event_type", item.event_type), "date": data.get("date_label", item.date_label), "timeline_date": data.get("timeline_date", item.timeline_date),
            "organization": data.get("organization", item.organization), "title": data.get("title", item.title), "timeline_label": data.get("timeline_label", item.timeline_label) or "", "current": data.get("is_current", item.is_current),
            "description": data.get("description", item.description) or "", "technologies": data.get("technologies", item.technologies) or [], "highlights": data.get("highlights", item.highlights) or [],
            "link": (data.get("certification_info", item.certification_info) or {}).get("url", ""),
        })
    content["events"] = events
    return content


def _public_about(db: Session) -> dict:
    record = db.query(PortfolioData).filter(PortfolioData.section == "about").first()
    if record is None:
        raise HTTPException(status_code=404, detail="About section not found")
    content = _published_snapshot(db, "about", str(record.id))
    if content is None:
        content = _load_visible_section(db, "about")
        if content.get("status", "published") != "published":
            raise HTTPException(status_code=404, detail="About section not published")
    else:
        content = dict(content)
    skills: dict[str, list[tuple[int, str]]] = {}
    for skill in db.query(Skill).options(joinedload(Skill.category)).filter(Skill.status != "archived").all():
        data = _published_snapshot(db, "skill", str(skill.id))
        if data is None and skill.status != "published": continue
        data = data or {"category": skill.category.name, "name": skill.name, "display_order": skill.display_order, "is_active": skill.is_active}
        if data.get("is_active", True): skills.setdefault(data["category"], []).append((data.get("display_order", 0), data["name"]))
    content["skill_categories"] = {category: [name for _, name in sorted(values)] for category, values in skills.items()}
    return content


@router.get("/api/portfolio/about", tags=["Portfolio"])
async def get_about(db: Session = Depends(get_db)):
    return _public_about(db)


@router.get("/api/portfolio/projects", tags=["Portfolio"])
async def get_projects(
    db: Session = Depends(get_db),
    category: str | None = Query(None, description="Filter projects by category"),
):
    return _public_projects(db, category)


@router.get("/api/portfolio/contact", tags=["Portfolio"])
async def get_contact(db: Session = Depends(get_db)):
    return _load_visible_section(db, "contact")


@router.get("/api/portfolio/journey", tags=["Portfolio"])
async def get_journey(db: Session = Depends(get_db)):
    return _public_journey(db)


@router.get("/api/portfolio/all", tags=["Portfolio"])
async def get_all_portfolio(db: Session = Depends(get_db)):
    return {
        "about": _public_about(db),
        "projects": _public_projects(db),
        "journey": _public_journey(db),
        "contact": _load_visible_section(db, "contact"),
    }


@router.post("/api/analytics/visit", tags=["Analytics"], status_code=204)
async def record_visit(request: Request, db: Session = Depends(get_db)):
    await rate_limiter.enforce(
        request,
        scope="analytics",
        limit=120,
        window_seconds=60,
    )
    page = request.query_params.get("page", "/")[:255]
    dimensions = visit_dimensions(request.headers.get("user-agent", ""), request.headers.get("referer"), request.headers.get("x-portfolio-session"))
    purge_expired_visits(db)
    db.add(
        VisitLog(
            ip=None,
            user_agent=request.headers.get("user-agent"),
            page=page,
            **dimensions,
        )
    )
    db.commit()
    metrics.inc("analytics_visits_total")


@router.post("/api/portfolio/contact-form", tags=["Contact"], response_model=APIResponse)
async def submit_contact_form(
    form: ContactFormRequest,
    http_request: Request,
    background_tasks: BackgroundTasks,
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
    admin_event = EmailEvent(contact_submission_id=submission.id, event_type="contact_owner", recipient=ADMIN_EMAIL, provider=EMAIL_DELIVERY_MODE, subject=f"Portfolio contact from {form.name}", html_body=admin_body, plain_body=f"Name: {form.name}\nEmail: {form.email}\n\n{form.message}", reply_to=str(form.email))
    visitor_event = EmailEvent(contact_submission_id=submission.id, event_type="contact_visitor", recipient=str(form.email), provider=EMAIL_DELIVERY_MODE, subject="We received your portfolio message", html_body=visitor_body, plain_body=f"Thanks for contacting {owner_name}. Your message:\n\n{form.message}\n\nReply to this email to continue the conversation.", reply_to=ADMIN_EMAIL)
    db.add_all([admin_event, visitor_event])
    db.commit()
    metrics.inc("contact_submissions_total")
    background_tasks.add_task(deliver_email_event, admin_event.id)
    background_tasks.add_task(deliver_email_event, visitor_event.id)

    logger.info("Contact form submitted by %s", form.name)
    return APIResponse(
        status="success",
        message="Message saved. Delivery is being processed.",
        data={"visitor_copy_sent": False, "submission_id": submission.id, "delivery_status": "pending"},
    )
