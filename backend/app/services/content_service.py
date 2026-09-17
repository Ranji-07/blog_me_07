"""Validate and normalize manually seeded portfolio content."""

import json
from typing import Any

from fastapi import HTTPException
from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError

from app.database import SCHEMA_DIR

SECTION_DEF_MAP = {
    "about": "aboutSection",
    "projects": "projectsSection",
    "experience": "experienceSection",
    "journey": "journeySection",
    "contact": "contactSection",
}
PUBLISHED_STATES = {"draft", "published", "archived"}
VISIBILITY_VALUES = {"visible", "hidden", "in_progress"}


def validate_section_schema(section: str, content: dict[str, Any]) -> None:
    definition = SECTION_DEF_MAP.get(section)
    if not definition:
        raise HTTPException(status_code=400, detail=f"Unknown content section: {section}")
    schema_path = SCHEMA_DIR / "content-schema.json"
    if not schema_path.is_file():
        raise HTTPException(status_code=500, detail="Content schema file is missing")
    root_schema = json.loads(schema_path.read_text(encoding="utf-8"))
    schema = {
        "$schema": root_schema.get("$schema", "https://json-schema.org/draft/2020-12/schema"),
        "$ref": f"#/$defs/{definition}",
        "$defs": root_schema.get("$defs", {}),
    }
    errors = sorted(Draft202012Validator(schema).iter_errors(content), key=lambda error: list(error.path))
    if errors:
        def describe(error: ValidationError) -> str:
            path = ".".join(str(part) for part in error.path) or "root"
            return f"{path}: {error.message}"

        details = "; ".join(describe(error) for error in errors[:5])
        raise HTTPException(status_code=400, detail=f"Schema validation failed for section '{section}': {details}")


def normalize_content(content: dict[str, Any]) -> dict[str, Any]:
    normalized = json.loads(json.dumps(content))
    if "visible" in normalized:
        normalized["visible"] = bool(normalized["visible"])
    else:
        legacy_status = normalized.get("status")
        if isinstance(legacy_status, dict):
            visibility = legacy_status.get("visibility", "visible")
            if visibility not in VISIBILITY_VALUES:
                raise HTTPException(status_code=400, detail="Invalid visibility value")
            normalized["visible"] = visibility != "hidden"
            if legacy_status.get("updated_at") and "updated_at" not in normalized:
                normalized["updated_at"] = legacy_status["updated_at"]
        else:
            normalized["visible"] = True

    status = normalized.get("status", "published")
    if isinstance(status, dict):
        status = status.get("state", "published")
    if not isinstance(status, str) or status not in PUBLISHED_STATES:
        raise HTTPException(status_code=400, detail="Invalid status value")
    normalized["status"] = status
    return normalized


def is_content_active(content: dict[str, Any]) -> bool:
    return bool(content.get("visible", True)) and content.get("status") != "archived"
