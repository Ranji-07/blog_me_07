"""Validate and seed portfolio JSON files without replacing stored content by default."""

import argparse
import json
from dataclasses import dataclass
from pathlib import Path

from sqlalchemy import inspect

from app.database import CONTENT_DIR, SessionLocal, engine
from app.models import JourneyEvent, PortfolioData, Project, Skill, SkillCategory
from app.services.content_service import is_content_active, normalize_content, validate_section_schema
from app.utils.time import utc_now


@dataclass
class SeedResult:
    created: int = 0
    updated: int = 0
    skipped: int = 0


def _load_section_file(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _load_portfolio_sections() -> list[tuple[str, dict]]:
    section_files = [
        ("about", CONTENT_DIR / "about.json"),
        ("projects", CONTENT_DIR / "projects.json"),
        ("journey", CONTENT_DIR / "journey.json"),
        ("contact", CONTENT_DIR / "contact.json"),
    ]
    experience_file = CONTENT_DIR / "experience.json"
    if experience_file.exists():
        section_files.append(("experience", experience_file))

    missing = [str(path) for _, path in section_files if not path.exists()]
    if missing:
        raise FileNotFoundError(f"Missing content files: {', '.join(missing)}")
    return [(section, _load_section_file(path)) for section, path in section_files]


def _require_migrated_database() -> None:
    required_tables = {"portfolio_data", "projects", "journey_events", "skill_categories", "skills", "email_events"}
    missing = required_tables - set(inspect(engine).get_table_names())
    if missing:
        names = ", ".join(sorted(missing))
        raise RuntimeError(
            f"Database migration is required before seeding (missing: {names}). "
            "Run: python -m alembic upgrade head"
        )


def _write_or_skip(existing, values: dict, *, force: bool, result: SeedResult) -> None:
    if not force:
        result.skipped += 1
        return
    for field, value in values.items():
        setattr(existing, field, value)
    existing.updated_at = utc_now()
    result.updated += 1


def _seed_projects(db, content: dict, *, force: bool, result: SeedResult) -> None:
    for item in content.get("projects", []):
        values = {
            "source_id": str(item["id"]), "title": item["title"], "slug": item["slug"],
            "category": item["category"], "timeline_date": item.get("timeline_date"),
            "timeline_parent": item.get("timeline_parent"), "short_description": item.get("short_description"),
            "description": item.get("description"), "technologies": item.get("technologies", []),
            "features": item.get("features", []), "images": item.get("images", []),
            "github_url": item.get("github") or None, "live_demo_url": item.get("live_demo") or None,
            "featured": bool(item.get("featured", False)), "status": item.get("status", "published"),
        }
        existing = db.query(Project).filter(Project.source_id == values["source_id"]).one_or_none()
        if existing is None:
            db.add(Project(**values))
            result.created += 1
        else:
            _write_or_skip(existing, values, force=force, result=result)


def _seed_journey(db, content: dict, *, force: bool, result: SeedResult) -> None:
    for position, item in enumerate(content.get("events", [])):
        values = {
            "source_id": str(item["id"]), "event_type": item["type"], "date_label": item["date"],
            "timeline_date": item.get("timeline_date"), "organization": item["organization"],
            "title": item["title"], "timeline_label": item.get("timeline_label"),
            "description": item.get("description"), "technologies": item.get("technologies", []),
            "highlights": item.get("highlights", []), "is_current": bool(item.get("current", False)),
            "display_order": position,
        }
        existing = db.query(JourneyEvent).filter(JourneyEvent.source_id == values["source_id"]).one_or_none()
        if existing is None:
            db.add(JourneyEvent(**values))
            result.created += 1
        else:
            _write_or_skip(existing, values, force=force, result=result)


def _seed_skills(db, content: dict, *, force: bool, result: SeedResult) -> None:
    for category_position, (category_name, skill_names) in enumerate(content.get("skill_categories", {}).items()):
        category = db.query(SkillCategory).filter(SkillCategory.name == category_name).one_or_none()
        category_values = {"display_order": category_position, "is_active": True}
        if category is None:
            category = SkillCategory(name=category_name, **category_values)
            db.add(category)
            db.flush()
            result.created += 1
        else:
            _write_or_skip(category, category_values, force=force, result=result)
        for skill_position, skill_name in enumerate(skill_names):
            skill = db.query(Skill).filter(Skill.category_id == category.id, Skill.name == skill_name).one_or_none()
            skill_values = {"display_order": skill_position, "is_active": True}
            if skill is None:
                db.add(Skill(category_id=category.id, name=skill_name, **skill_values))
                result.created += 1
            else:
                _write_or_skip(skill, skill_values, force=force, result=result)


def seed_database(*, force: bool = False) -> SeedResult:
    """Seed missing records, or explicitly replace JSON-backed records with ``force=True``."""
    _require_migrated_database()
    sections = []
    for section, raw_data in _load_portfolio_sections():
        data = normalize_content(raw_data)
        validate_section_schema(section, data)
        sections.append((section, data))

    result = SeedResult()
    db = SessionLocal()
    try:
        for section, data in sections:
            existing = db.query(PortfolioData).filter(PortfolioData.section == section).one_or_none()
            values = {"content": json.dumps(data), "is_active": is_content_active(data)}
            if existing is None:
                db.add(PortfolioData(section=section, **values))
                result.created += 1
            else:
                _write_or_skip(existing, values, force=force, result=result)

            if section == "projects":
                _seed_projects(db, data, force=force, result=result)
            elif section == "journey":
                _seed_journey(db, data, force=force, result=result)
            elif section == "about":
                _seed_skills(db, data, force=force, result=result)
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()
    return result


def init_database(*, force: bool = False) -> SeedResult:
    """Compatibility entry point for existing local setup commands."""
    result = seed_database(force=force)
    action = "updated" if force else "created or preserved"
    print(f"Seed complete: {result.created} created, {result.updated} updated, {result.skipped} preserved ({action}).")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Validate and seed the portfolio database.")
    parser.add_argument("--force", action="store_true", help="Replace existing JSON-backed database records. Use deliberately.")
    arguments = parser.parse_args()
    init_database(force=arguments.force)
