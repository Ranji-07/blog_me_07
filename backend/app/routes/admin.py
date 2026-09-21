"""JWT-protected CMS and contact-submission administration APIs."""

import json
from uuid import uuid4
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models import AdminUser, ContactSubmission, EmailEvent, JourneyEvent, PortfolioData, Project, Skill, SkillCategory, VisitLog
from app.schemas import APIResponse, AboutUpdate, JourneyCreate, JourneyResponse, JourneyUpdate, ProjectCreate, ProjectResponse, ProjectUpdate, SkillCreate, SkillResponse, SkillUpdate
from app.services.auth import get_current_admin
from app.services.contact_retention import purge_expired_submissions
from app.services.email_outbox import deliver_email_event, MAX_ATTEMPTS
from app.services.analytics import purge_expired_visits
from app.services.content_service import is_content_active, normalize_content, validate_section_schema
from app.services.versioning import archive_published_versions, create_version, latest_version, publish_latest_draft, serialize_version, version_history
from app.utils.time import utc_isoformat, utc_now

router = APIRouter(prefix="/api/admin")


def _analytics_window(db: Session, since):
    return db.query(VisitLog).filter(VisitLog.visited_at >= since)


@router.get("/analytics/overview", tags=["Admin"])
async def analytics_overview(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    now = utc_now()
    return {"visits_today": _analytics_window(db, now - timedelta(days=1)).count(), "visits_this_week": _analytics_window(db, now - timedelta(days=7)).count(), "visits_this_month": _analytics_window(db, now - timedelta(days=30)).count(), "contact_submissions": db.query(ContactSubmission).filter(ContactSubmission.created_at >= now - timedelta(days=30)).count(), "email_delivery": {status: count for status, count in db.query(EmailEvent.delivery_status, func.count(EmailEvent.id)).group_by(EmailEvent.delivery_status).all()}}

@router.get("/analytics/pages", tags=["Admin"])
async def analytics_pages(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    return {"pages": [{"page": page or "/", "visits": count} for page, count in db.query(VisitLog.page, func.count(VisitLog.id)).group_by(VisitLog.page).order_by(func.count(VisitLog.id).desc()).all()]}

@router.get("/analytics/projects", tags=["Admin"])
async def analytics_projects(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    rows = db.query(VisitLog.page, func.count(VisitLog.id)).filter(VisitLog.page.like("/projects/%")).group_by(VisitLog.page).order_by(func.count(VisitLog.id).desc()).all()
    return {"projects": [{"page": page, "interactions": count} for page, count in rows]}

@router.get("/analytics/timeline", tags=["Admin"])
async def analytics_timeline(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    rows = db.query(func.date(VisitLog.visited_at), func.count(VisitLog.id)).group_by(func.date(VisitLog.visited_at)).order_by(func.date(VisitLog.visited_at)).all()
    return {"timeline": [{"date": str(day), "visits": count} for day, count in rows]}

@router.post("/analytics/purge", tags=["Admin"])
async def purge_analytics(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    return {"deleted": purge_expired_visits(db)}


def _section(db: Session, name: str) -> PortfolioData:
    item = db.query(PortfolioData).filter(PortfolioData.section == name).one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail=f"{name.title()} content not found")
    return item


def _about(db: Session) -> dict:
    content = json.loads(_section(db, "about").content)
    categories = db.query(SkillCategory).options(joinedload(SkillCategory.skills)).order_by(SkillCategory.display_order, SkillCategory.name).all()
    content["skill_categories"] = {
        category.name: [skill.name for skill in sorted(category.skills, key=lambda value: (value.display_order, value.name)) if skill.is_active]
        for category in categories if category.is_active
    }
    return content


def _skill(skill: Skill) -> dict:
    return {"id": skill.id, "category": skill.category.name, "name": skill.name, "icon": skill.icon, "display_order": skill.display_order, "is_active": skill.is_active, "status": skill.status, "version": skill.version, "published_at": skill.published_at, "created_at": skill.created_at, "updated_at": skill.updated_at}


def _project(project: Project) -> dict:
    return {"id": project.id, "title": project.title, "slug": project.slug, "category": project.category, "description": project.description, "short_description": project.short_description, "technologies": project.technologies or [], "features": project.features or [], "images": project.images or [], "start_date": project.start_date, "end_date": project.end_date, "timeline_date": project.timeline_date, "associated_with": project.associated_with or project.timeline_parent, "github_url": project.github_url, "live_url": project.live_demo_url, "featured": project.featured, "status": project.status, "version": project.version, "published_at": project.published_at, "created_at": project.created_at, "updated_at": project.updated_at}


def _journey(event: JourneyEvent) -> dict:
    return {"id": event.id, "event_type": event.event_type, "date_label": event.date_label, "timeline_date": event.timeline_date, "organization": event.organization, "title": event.title, "timeline_label": event.timeline_label, "description": event.description, "parent_milestone": event.parent_milestone, "project_id": event.project_id, "certification_info": event.certification_info or {}, "technologies": event.technologies or [], "highlights": event.highlights or [], "is_current": event.is_current, "display_order": event.display_order, "status": event.status, "version": event.version, "published_at": event.published_at, "created_at": event.created_at, "updated_at": event.updated_at}


def _project_snapshot(item: Project) -> dict:
    return {"title": item.title, "slug": item.slug, "category": item.category, "timeline_date": item.timeline_date, "timeline_parent": item.timeline_parent, "start_date": item.start_date, "end_date": item.end_date, "associated_with": item.associated_with, "short_description": item.short_description, "description": item.description, "technologies": item.technologies or [], "features": item.features or [], "images": item.images or [], "github_url": item.github_url, "live_demo_url": item.live_demo_url, "featured": item.featured}


def _journey_snapshot(item: JourneyEvent) -> dict:
    return {"event_type": item.event_type, "date_label": item.date_label, "timeline_date": item.timeline_date, "organization": item.organization, "title": item.title, "timeline_label": item.timeline_label, "description": item.description, "parent_milestone": item.parent_milestone, "project_id": item.project_id, "certification_info": item.certification_info or {}, "technologies": item.technologies or [], "highlights": item.highlights or [], "is_current": item.is_current, "display_order": item.display_order}


def _skill_snapshot(item: Skill) -> dict:
    return {"category": item.category.name, "name": item.name, "icon": item.icon, "display_order": item.display_order, "is_active": item.is_active}


def _ensure_baseline(db: Session, *, content_type: str, item, snapshot: dict, changed_by: str) -> None:
    if latest_version(db, content_type, str(item.id)) is None and item.status == "published":
        create_version(db, content_type=content_type, content_id=str(item.id), snapshot=snapshot, changed_by=changed_by, action="baseline", version_status="published")
        db.flush()


def _draft(db: Session, *, content_type: str, item, snapshot: dict, changed_by: str, action: str = "draft") -> None:
    _ensure_baseline(db, content_type=content_type, item=item, snapshot=snapshot, changed_by=changed_by)
    item.version = (latest_version(db, content_type, str(item.id)).version if latest_version(db, content_type, str(item.id)) else 0) + 1
    item.status = "draft"
    item.published_at = None
    create_version(db, content_type=content_type, content_id=str(item.id), snapshot=snapshot, changed_by=changed_by, action=action, version_status="draft", version=item.version)


def _version_target(db: Session, content_type: str, item_id: int):
    model = {"project": Project, "journey": JourneyEvent, "skill": Skill}[content_type]
    query = db.query(model)
    if content_type == "skill":
        query = query.options(joinedload(Skill.category))
    item = query.filter(model.id == item_id).one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail=f"{content_type.title()} not found")
    return item


def _commit(db: Session, item):
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="A record with this unique value already exists") from exc
    db.refresh(item)
    return item


def _valid_project(db: Session, project_id: int | None) -> None:
    if project_id is not None and db.query(Project.id).filter(Project.id == project_id).scalar() is None:
        raise HTTPException(status_code=422, detail="project_id does not reference an existing project")


@router.get("/about", tags=["Admin"])
async def get_about(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    return _about(db)


@router.put("/about", tags=["Admin"])
async def update_about(payload: AboutUpdate, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = _section(db, "about")
    content = json.loads(item.content)
    content.update(payload.model_dump(exclude_unset=True))
    content["status"] = "draft"
    content = normalize_content(content)
    validate_section_schema("about", content)
    existing = latest_version(db, "about", str(item.id))
    if existing is None and json.loads(item.content).get("status", "published") == "published":
        create_version(db, content_type="about", content_id=str(item.id), snapshot=json.loads(item.content), changed_by=admin.email, action="baseline", version_status="published")
        db.flush()
    item.version = (latest_version(db, "about", str(item.id)).version if latest_version(db, "about", str(item.id)) else 0) + 1
    item.content, item.updated_at = json.dumps(content), utc_now()
    create_version(db, content_type="about", content_id=str(item.id), snapshot=content, changed_by=admin.email, action="draft", version_status="draft", version=item.version)
    _commit(db, item)
    return _about(db)


@router.get("/about/preview", tags=["Admin"])
async def preview_about(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = _section(db, "about")
    draft = latest_version(db, "about", str(item.id), status="draft")
    return {"status": "draft" if draft else "published", "version": draft.version if draft else item.version, "snapshot": draft.snapshot if draft else json.loads(item.content)}


@router.get("/about/versions", tags=["Admin"])
async def about_versions(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = _section(db, "about")
    return [serialize_version(entry) for entry in version_history(db, "about", str(item.id))]


@router.post("/about/publish", tags=["Admin"])
async def publish_about(admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = _section(db, "about")
    try: published = publish_latest_draft(db, "about", str(item.id))
    except ValueError as exc: raise HTTPException(status_code=409, detail=str(exc)) from exc
    content = dict(published.snapshot); content["status"] = "published"
    item.content, item.version, item.published_at, item.is_active = json.dumps(content), published.version, published.published_at, is_content_active(content)
    _commit(db, item)
    return _about(db)


@router.post("/about/unpublish", tags=["Admin"])
async def unpublish_about(admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = _section(db, "about")
    archive_published_versions(db, "about", str(item.id))
    content = json.loads(item.content); content["status"] = "archived"
    item.content, item.is_active, item.published_at = json.dumps(content), False, None
    create_version(db, content_type="about", content_id=str(item.id), snapshot=content, changed_by=admin.email, action="unpublish", version_status="archived")
    _commit(db, item)
    return APIResponse(status="success", message="About content unpublished")


@router.post("/about/versions/{version}/restore", tags=["Admin"])
async def restore_about(version: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = _section(db, "about")
    source = next((entry for entry in version_history(db, "about", str(item.id)) if entry.version == version), None)
    if source is None: raise HTTPException(status_code=404, detail="Version not found")
    content = dict(source.snapshot); content["status"] = "draft"
    item.version = (latest_version(db, "about", str(item.id)).version if latest_version(db, "about", str(item.id)) else 0) + 1
    item.content = json.dumps(content)
    create_version(db, content_type="about", content_id=str(item.id), snapshot=content, changed_by=admin.email, action="restore", version_status="draft", version=item.version)
    _commit(db, item)
    return {"status": "draft", "version": item.version, "restored_from": version}


@router.get("/skills", tags=["Admin"], response_model=list[SkillResponse])
async def get_skills(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    items = db.query(Skill).options(joinedload(Skill.category)).join(SkillCategory).order_by(SkillCategory.display_order, Skill.display_order, Skill.name).all()
    return [_skill(item) for item in items]


@router.post("/skills", tags=["Admin"], response_model=SkillResponse, status_code=status.HTTP_201_CREATED)
async def create_skill(payload: SkillCreate, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    category = db.query(SkillCategory).filter(SkillCategory.name == payload.category.strip()).one_or_none()
    if category is None:
        category = SkillCategory(name=payload.category.strip(), display_order=db.query(SkillCategory).count())
        db.add(category)
        db.flush()
    item = Skill(category_id=category.id, status="draft", version=1, **payload.model_dump(exclude={"category"}))
    db.add(item)
    db.flush()
    db.refresh(item, attribute_names=["category"])
    create_version(db, content_type="skill", content_id=str(item.id), snapshot=_skill_snapshot(item), changed_by=admin.email, action="create", version_status="draft", version=1)
    _commit(db, item)
    db.refresh(item, attribute_names=["category"])
    return _skill(item)


@router.put("/skills/{skill_id}", tags=["Admin"], response_model=SkillResponse)
async def update_skill(skill_id: int, payload: SkillUpdate, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = db.query(Skill).options(joinedload(Skill.category)).filter(Skill.id == skill_id).one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Skill not found")
    _ensure_baseline(db, content_type="skill", item=item, snapshot=_skill_snapshot(item), changed_by=admin.email)
    values = payload.model_dump(exclude_unset=True)
    category_name = values.pop("category", None)
    if category_name is not None:
        category = db.query(SkillCategory).filter(SkillCategory.name == category_name.strip()).one_or_none()
        if category is None:
            category = SkillCategory(name=category_name.strip(), display_order=db.query(SkillCategory).count())
            db.add(category)
            db.flush()
        item.category_id = category.id
    for field, value in values.items():
        setattr(item, field, value)
    item.updated_at = utc_now()
    db.flush()
    db.refresh(item, attribute_names=["category"])
    _draft(db, content_type="skill", item=item, snapshot=_skill_snapshot(item), changed_by=admin.email)
    _commit(db, item)
    db.refresh(item, attribute_names=["category"])
    return _skill(item)


@router.delete("/skills/{skill_id}", tags=["Admin"], response_model=APIResponse)
async def delete_skill(skill_id: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = _version_target(db, "skill", skill_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Skill not found")
    _ensure_baseline(db, content_type="skill", item=item, snapshot=_skill_snapshot(item), changed_by=admin.email)
    archive_published_versions(db, "skill", str(item.id))
    item.status, item.published_at, item.updated_at = "archived", None, utc_now()
    create_version(db, content_type="skill", content_id=str(item.id), snapshot=_skill_snapshot(item), changed_by=admin.email, action="archive", version_status="archived")
    _commit(db, item)
    return APIResponse(status="success", message="Skill archived")


@router.get("/projects", tags=["Admin"])
async def get_projects(page: int = Query(1, ge=1), page_size: int = Query(25, ge=1, le=100), _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    query = db.query(Project).order_by(Project.timeline_date.desc(), Project.id.desc())
    total = query.count()
    return {"items": [_project(item) for item in query.offset((page - 1) * page_size).limit(page_size).all()], "page": page, "page_size": page_size, "total": total}


@router.post("/projects", tags=["Admin"], response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
async def create_project(payload: ProjectCreate, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    values = payload.model_dump()
    values["github_url"] = str(values["github_url"]) if values["github_url"] else None
    live_url = values.pop("live_url")
    values["live_demo_url"] = str(live_url) if live_url else None
    for field in ("start_date", "end_date", "timeline_date"):
        values[field] = values[field].isoformat() if values[field] else None
    values["timeline_parent"] = values["associated_with"]
    values["status"] = "draft"
    item = Project(source_id=f"cms-{uuid4()}", **values)
    db.add(item)
    db.flush()
    create_version(db, content_type="project", content_id=str(item.id), snapshot=_project_snapshot(item), changed_by=admin.email, action="create", version_status="draft", version=1)
    _commit(db, item)
    return _project(item)


@router.get("/projects/{project_id}", tags=["Admin"], response_model=ProjectResponse)
async def get_project(project_id: int, _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = db.query(Project).filter(Project.id == project_id).one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Project not found")
    return _project(item)


@router.put("/projects/{project_id}", tags=["Admin"], response_model=ProjectResponse)
async def update_project(project_id: int, payload: ProjectUpdate, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = db.query(Project).filter(Project.id == project_id).one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Project not found")
    _ensure_baseline(db, content_type="project", item=item, snapshot=_project_snapshot(item), changed_by=admin.email)
    values = payload.model_dump(exclude_unset=True)
    values.pop("status", None)
    if "github_url" in values:
        values["github_url"] = str(values["github_url"]) if values["github_url"] else None
    if "live_url" in values:
        live_url = values.pop("live_url")
        values["live_demo_url"] = str(live_url) if live_url else None
    for field in ("start_date", "end_date", "timeline_date"):
        if field in values:
            values[field] = values[field].isoformat() if values[field] else None
    if "associated_with" in values:
        values["timeline_parent"] = values["associated_with"]
    for field, value in values.items():
        setattr(item, field, value)
    item.updated_at = utc_now()
    _draft(db, content_type="project", item=item, snapshot=_project_snapshot(item), changed_by=admin.email)
    _commit(db, item)
    return _project(item)


@router.delete("/projects/{project_id}", tags=["Admin"], response_model=APIResponse)
async def delete_project(project_id: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = db.query(Project).filter(Project.id == project_id).one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Project not found")
    _ensure_baseline(db, content_type="project", item=item, snapshot=_project_snapshot(item), changed_by=admin.email)
    archive_published_versions(db, "project", str(item.id))
    item.status, item.published_at, item.updated_at = "archived", None, utc_now()
    create_version(db, content_type="project", content_id=str(item.id), snapshot=_project_snapshot(item), changed_by=admin.email, action="archive", version_status="archived")
    _commit(db, item)
    return APIResponse(status="success", message="Project archived")


@router.get("/journey", tags=["Admin"], response_model=list[JourneyResponse])
async def get_journey(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    return [_journey(item) for item in db.query(JourneyEvent).order_by(JourneyEvent.display_order, JourneyEvent.timeline_date).all()]


@router.post("/journey", tags=["Admin"], response_model=JourneyResponse, status_code=status.HTTP_201_CREATED)
async def create_journey(payload: JourneyCreate, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    values = payload.model_dump()
    _valid_project(db, values["project_id"])
    values["timeline_date"] = values["timeline_date"].isoformat() if values["timeline_date"] else None
    item = JourneyEvent(source_id=f"cms-{uuid4()}", status="draft", version=1, **values)
    db.add(item)
    db.flush()
    create_version(db, content_type="journey", content_id=str(item.id), snapshot=_journey_snapshot(item), changed_by=admin.email, action="create", version_status="draft", version=1)
    _commit(db, item)
    return _journey(item)


@router.put("/journey/{event_id}", tags=["Admin"], response_model=JourneyResponse)
async def update_journey(event_id: int, payload: JourneyUpdate, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = db.query(JourneyEvent).filter(JourneyEvent.id == event_id).one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Journey event not found")
    _ensure_baseline(db, content_type="journey", item=item, snapshot=_journey_snapshot(item), changed_by=admin.email)
    values = payload.model_dump(exclude_unset=True)
    if "project_id" in values:
        _valid_project(db, values["project_id"])
    if "timeline_date" in values:
        values["timeline_date"] = values["timeline_date"].isoformat() if values["timeline_date"] else None
    for field, value in values.items():
        setattr(item, field, value)
    item.updated_at = utc_now()
    _draft(db, content_type="journey", item=item, snapshot=_journey_snapshot(item), changed_by=admin.email)
    _commit(db, item)
    return _journey(item)


@router.delete("/journey/{event_id}", tags=["Admin"], response_model=APIResponse)
async def delete_journey(event_id: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = db.query(JourneyEvent).filter(JourneyEvent.id == event_id).one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Journey event not found")
    _ensure_baseline(db, content_type="journey", item=item, snapshot=_journey_snapshot(item), changed_by=admin.email)
    archive_published_versions(db, "journey", str(item.id))
    item.status, item.published_at, item.updated_at = "archived", None, utc_now()
    create_version(db, content_type="journey", content_id=str(item.id), snapshot=_journey_snapshot(item), changed_by=admin.email, action="archive", version_status="archived")
    _commit(db, item)
    return APIResponse(status="success", message="Journey event archived")


def _apply_snapshot(db: Session, content_type: str, item, snapshot: dict) -> None:
    """Copy a historical snapshot into the editable draft record."""
    if content_type == "skill":
        category = db.query(SkillCategory).filter(SkillCategory.name == snapshot["category"]).one_or_none()
        if category is None:
            category = SkillCategory(name=snapshot["category"], display_order=db.query(SkillCategory).count())
            db.add(category)
            db.flush()
        item.category_id = category.id
        for key in ("name", "icon", "display_order", "is_active"):
            setattr(item, key, snapshot[key])
        return
    fields = _project_snapshot(item).keys() if content_type == "project" else _journey_snapshot(item).keys()
    for key in fields:
        if key in snapshot:
            setattr(item, key, snapshot[key])


def _publish(db: Session, content_type: str, item, admin: AdminUser):
    try:
        published = publish_latest_draft(db, content_type, str(item.id))
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    item.status, item.version, item.published_at, item.updated_at = "published", published.version, published.published_at, utc_now()
    return _commit(db, item)


def _unpublish(db: Session, content_type: str, item, admin: AdminUser):
    archive_published_versions(db, content_type, str(item.id))
    item.status, item.published_at, item.updated_at = "archived", None, utc_now()
    create_version(db, content_type=content_type, content_id=str(item.id), snapshot=( _project_snapshot(item) if content_type == "project" else _journey_snapshot(item) if content_type == "journey" else _skill_snapshot(item)), changed_by=admin.email, action="unpublish", version_status="archived")
    return _commit(db, item)


def _versions(db: Session, content_type: str, item_id: int):
    _version_target(db, content_type, item_id)
    return [serialize_version(entry) for entry in version_history(db, content_type, str(item_id))]


def _preview(db: Session, content_type: str, item_id: int):
    item = _version_target(db, content_type, item_id)
    entry = latest_version(db, content_type, str(item_id), status="draft")
    snapshot = entry.snapshot if entry else (_project_snapshot(item) if content_type == "project" else _journey_snapshot(item) if content_type == "journey" else _skill_snapshot(item))
    return {"status": "draft" if entry else item.status, "version": entry.version if entry else item.version, "snapshot": snapshot}


def _restore(db: Session, content_type: str, item_id: int, version: int, admin: AdminUser):
    item = _version_target(db, content_type, item_id)
    source = next((entry for entry in version_history(db, content_type, str(item_id)) if entry.version == version), None)
    if source is None:
        raise HTTPException(status_code=404, detail="Version not found")
    _apply_snapshot(db, content_type, item, source.snapshot)
    db.flush()
    if content_type == "skill":
        db.refresh(item, attribute_names=["category"])
    snapshot = _project_snapshot(item) if content_type == "project" else _journey_snapshot(item) if content_type == "journey" else _skill_snapshot(item)
    _draft(db, content_type=content_type, item=item, snapshot=snapshot, changed_by=admin.email, action="restore")
    _commit(db, item)
    return {"status": "draft", "version": item.version, "restored_from": version}


@router.post("/projects/{project_id}/publish", tags=["Admin"])
async def publish_project(project_id: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    return _project(_publish(db, "project", _version_target(db, "project", project_id), admin))

@router.post("/projects/{project_id}/unpublish", tags=["Admin"])
async def unpublish_project(project_id: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    return _project(_unpublish(db, "project", _version_target(db, "project", project_id), admin))

@router.get("/projects/{project_id}/preview", tags=["Admin"])
async def preview_project(project_id: int, _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _preview(db, "project", project_id)
@router.get("/projects/{project_id}/versions", tags=["Admin"])
async def project_versions(project_id: int, _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _versions(db, "project", project_id)
@router.post("/projects/{project_id}/versions/{version}/restore", tags=["Admin"])
async def restore_project(project_id: int, version: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _restore(db, "project", project_id, version, admin)

@router.post("/journey/{event_id}/publish", tags=["Admin"])
async def publish_journey(event_id: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _journey(_publish(db, "journey", _version_target(db, "journey", event_id), admin))
@router.post("/journey/{event_id}/unpublish", tags=["Admin"])
async def unpublish_journey(event_id: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _journey(_unpublish(db, "journey", _version_target(db, "journey", event_id), admin))
@router.get("/journey/{event_id}/preview", tags=["Admin"])
async def preview_journey(event_id: int, _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _preview(db, "journey", event_id)
@router.get("/journey/{event_id}/versions", tags=["Admin"])
async def journey_versions(event_id: int, _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _versions(db, "journey", event_id)
@router.post("/journey/{event_id}/versions/{version}/restore", tags=["Admin"])
async def restore_journey(event_id: int, version: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _restore(db, "journey", event_id, version, admin)

@router.post("/skills/{skill_id}/publish", tags=["Admin"])
async def publish_skill(skill_id: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _skill(_publish(db, "skill", _version_target(db, "skill", skill_id), admin))
@router.post("/skills/{skill_id}/unpublish", tags=["Admin"])
async def unpublish_skill(skill_id: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _skill(_unpublish(db, "skill", _version_target(db, "skill", skill_id), admin))
@router.get("/skills/{skill_id}/preview", tags=["Admin"])
async def preview_skill(skill_id: int, _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _preview(db, "skill", skill_id)
@router.get("/skills/{skill_id}/versions", tags=["Admin"])
async def skill_versions(skill_id: int, _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _versions(db, "skill", skill_id)
@router.post("/skills/{skill_id}/versions/{version}/restore", tags=["Admin"])
async def restore_skill(skill_id: int, version: int, admin: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return _restore(db, "skill", skill_id, version, admin)


@router.get("/submissions", tags=["Admin"])
async def get_contact_submissions(limit: int = Query(50, ge=1, le=100), _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    rows = db.query(ContactSubmission).order_by(ContactSubmission.created_at.desc()).limit(limit).all()
    return {"submissions": [{"id": item.id, "name": item.name, "email": item.email, "message": item.message, "created_at": utc_isoformat(item.created_at), "is_read": item.is_read} for item in rows]}


@router.delete("/submissions/{submission_id}", tags=["Admin"], response_model=APIResponse)
async def delete_contact_submission(submission_id: int, _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    item = db.query(ContactSubmission).filter(ContactSubmission.id == submission_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Contact submission not found")
    db.delete(item)
    db.commit()
    return APIResponse(status="success", message="Contact submission deleted")


@router.post("/submissions/purge", tags=["Admin"], response_model=APIResponse)
async def purge_contact_submissions(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    deleted = purge_expired_submissions(db)
    return APIResponse(status="success", message="Expired contact submissions purged", data={"deleted": deleted})


def _email_event(event: EmailEvent) -> dict:
    return {"id": event.id, "submission_id": event.contact_submission_id, "email_type": event.event_type, "recipient": event.recipient, "provider": event.provider, "status": event.delivery_status, "error_message": event.error_message, "attempts": event.attempts, "created_at": event.created_at, "sent_at": event.sent_at}


@router.get("/email-events", tags=["Admin"])
async def get_email_events(limit: int = Query(50, ge=1, le=100), _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    return {"email_events": [_email_event(event) for event in db.query(EmailEvent).order_by(EmailEvent.created_at.desc()).limit(limit).all()]}


@router.get("/email-events/{event_id}", tags=["Admin"])
async def get_email_event(event_id: int, _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    event = db.query(EmailEvent).filter(EmailEvent.id == event_id).one_or_none()
    if event is None: raise HTTPException(status_code=404, detail="Email event not found")
    return _email_event(event)


@router.post("/email-events/{event_id}/retry", tags=["Admin"])
async def retry_email_event(event_id: int, _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    event = db.query(EmailEvent).filter(EmailEvent.id == event_id).one_or_none()
    if event is None: raise HTTPException(status_code=404, detail="Email event not found")
    if event.attempts >= MAX_ATTEMPTS:
        raise HTTPException(status_code=409, detail="Retry limit reached")
    success = deliver_email_event(event_id)
    db.expire_all()
    return {**_email_event(db.query(EmailEvent).filter(EmailEvent.id == event_id).one()), "delivered": success}
