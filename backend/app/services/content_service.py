import json
from typing import Any, Dict, Optional

from fastapi import HTTPException
from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError
from sqlalchemy.orm import Session

from app.database import SCHEMA_DIR
from app.models import PortfolioData, PortfolioVersion
from app.schemas import CommandType, PublishState, VisibilityState

SECTION_ITEM_COLLECTION = {
    "projects": "projects",
    "experience": "careers",
    "contact": None,
    "about": None,
}

SECTION_DEF_MAP = {
    "about": "aboutSection",
    "projects": "projectsSection",
    "experience": "experienceSection",
    "contact": "contactSection",
}


def load_schema_file(name: str) -> Dict[str, Any]:
    schema_path = SCHEMA_DIR / name
    if not schema_path.exists():
        raise HTTPException(status_code=500, detail=f"Schema file missing: {name}")
    return json.loads(schema_path.read_text(encoding="utf-8"))


def _build_section_schema(section: str) -> Dict[str, Any]:
    root_schema = load_schema_file("content-schema.json")
    definition_name = SECTION_DEF_MAP.get(section)
    if not definition_name:
        raise HTTPException(status_code=400, detail=f"No schema definition registered for section '{section}'")
    return {
        "$schema": root_schema.get("$schema", "https://json-schema.org/draft/2020-12/schema"),
        "$ref": f"#/$defs/{definition_name}",
        "$defs": root_schema.get("$defs", {}),
    }


def validate_section_schema(section: str, content: Dict[str, Any]) -> None:
    schema = _build_section_schema(section)
    validator = Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(content), key=lambda error: list(error.path))
    if not errors:
        return

    def _format_error(error: ValidationError) -> str:
        path = ".".join(str(part) for part in error.path)
        return f"{path or 'root'}: {error.message}"

    details = "; ".join(_format_error(error) for error in errors[:5])
    raise HTTPException(status_code=400, detail=f"Schema validation failed for section '{section}': {details}")


def get_section_record(db: Session, section: str) -> Optional[PortfolioData]:
    return db.query(PortfolioData).filter(PortfolioData.section == section).first()


def get_section_content(record: Optional[PortfolioData]) -> Dict[str, Any]:
    if not record:
        return {}
    try:
        return json.loads(record.content)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=500, detail=f"Stored JSON for section is invalid: {exc}") from exc


def deep_merge(existing: Dict[str, Any], patch: Dict[str, Any]) -> Dict[str, Any]:
    merged = dict(existing)
    for key, value in patch.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = deep_merge(merged[key], value)
        else:
            merged[key] = value
    return merged


def validate_status_block(status: Dict[str, Any]) -> None:
    visibility = status.get("visibility")
    state = status.get("state")
    if visibility is not None and visibility not in {item.value for item in VisibilityState}:
        raise HTTPException(status_code=400, detail="Invalid visibility value")
    if state is not None and state not in {item.value for item in PublishState}:
        raise HTTPException(status_code=400, detail="Invalid state value")


def normalize_status(content: Dict[str, Any], default_visibility: str = "visible") -> Dict[str, Any]:
    status = content.get("status", {})
    if not isinstance(status, dict):
        raise HTTPException(status_code=400, detail="status must be a JSON object")
    status.setdefault("visibility", default_visibility)
    status.setdefault("state", PublishState.PUBLISHED.value)
    validate_status_block(status)
    content["status"] = status
    return content


def find_item_index(items: list[Dict[str, Any]], target_id: str) -> int:
    for index, item in enumerate(items):
        item_id = item.get("id") or item.get("title") or item.get("credential_id")
        if str(item_id) == str(target_id):
            return index
    raise HTTPException(status_code=404, detail=f"Target item '{target_id}' not found")


def save_section_content(
    db: Session,
    section: str,
    content: Dict[str, Any],
    existing_record: Optional[PortfolioData] = None,
) -> PortfolioData:
    normalized = normalize_status(content)
    validate_section_schema(section, normalized)
    record = existing_record or get_section_record(db, section)
    if record:
        record.content = json.dumps(normalized)
        record.is_active = normalized["status"]["visibility"] != VisibilityState.HIDDEN.value
    else:
        record = PortfolioData(
            section=section,
            content=json.dumps(normalized),
            is_active=normalized["status"]["visibility"] != VisibilityState.HIDDEN.value,
        )
        db.add(record)
    db.commit()
    db.refresh(record)
    return record


def create_version_record(
    db: Session,
    *,
    section: str,
    action: str,
    actor_email: str,
    target_id: Optional[str],
    command_token: Optional[str],
    before: Dict[str, Any],
    after: Dict[str, Any],
) -> PortfolioVersion:
    version = PortfolioVersion(
        section=section,
        action=action,
        actor_email=actor_email,
        target_id=target_id,
        command_token=command_token,
        snapshot_before=json.dumps(before),
        snapshot_after=json.dumps(after),
    )
    db.add(version)
    db.commit()
    db.refresh(version)
    return version


def rollback_to_version(
    db: Session,
    *,
    version: PortfolioVersion,
    actor_email: str,
    command_token: Optional[str] = None,
) -> PortfolioData:
    if not version.snapshot_before:
        raise HTTPException(status_code=400, detail="Selected version has no rollback snapshot")

    target_snapshot = json.loads(version.snapshot_before)
    current_record = get_section_record(db, version.section)
    current_content = get_section_content(current_record)
    restored_record = save_section_content(db, version.section, target_snapshot, current_record)
    create_version_record(
        db,
        section=version.section,
        action="rollback",
        actor_email=actor_email,
        target_id=str(version.id),
        command_token=command_token,
        before=current_content,
        after=target_snapshot,
    )
    return restored_record


def apply_admin_command(command: Dict[str, Any], db: Session, command_token: Optional[str] = None) -> Dict[str, Any]:
    action = command["action"]
    section = command["section"]
    target_id = command.get("target_id")
    payload = command.get("payload", {})
    actor_email = command["auth_email"]

    record = get_section_record(db, section)
    content = get_section_content(record)
    before_content = json.loads(json.dumps(content))

    if action == CommandType.CREATE.value:
        if target_id:
            collection = payload.get("collection") or SECTION_ITEM_COLLECTION.get(section)
            item = payload.get("item")
            if not collection or not isinstance(item, dict):
                raise HTTPException(status_code=400, detail="Create item requires payload.collection and payload.item")
            content.setdefault(collection, [])
            content[collection].append(item)
        else:
            content = payload
        save_section_content(db, section, content, record)
        create_version_record(
            db,
            section=section,
            action=action,
            actor_email=actor_email,
            target_id=target_id,
            command_token=command_token,
            before=before_content,
            after=content,
        )
        return {"section": section, "target_id": target_id, "action": action}

    if not record:
        raise HTTPException(status_code=404, detail=f"Section '{section}' not found")

    if action == CommandType.UPDATE.value:
        if target_id:
            collection = payload.get("collection") or SECTION_ITEM_COLLECTION.get(section)
            patch = payload.get("item") or payload.get("content")
            if not collection or not isinstance(patch, dict):
                raise HTTPException(status_code=400, detail="Update item requires payload.collection and payload.item")
            items = content.get(collection, [])
            index = find_item_index(items, target_id)
            items[index] = deep_merge(items[index], patch)
            content[collection] = items
        else:
            content = deep_merge(content, payload)
        save_section_content(db, section, content, record)
        create_version_record(
            db,
            section=section,
            action=action,
            actor_email=actor_email,
            target_id=target_id,
            command_token=command_token,
            before=before_content,
            after=content,
        )
        return {"section": section, "target_id": target_id, "action": action}

    if action == CommandType.DELETE.value:
        if target_id:
            collection = payload.get("collection") or SECTION_ITEM_COLLECTION.get(section)
            if not collection:
                raise HTTPException(status_code=400, detail="Delete item requires payload.collection")
            items = content.get(collection, [])
            index = find_item_index(items, target_id)
            deleted = items.pop(index)
            content[collection] = items
            save_section_content(db, section, content, record)
            create_version_record(
                db,
                section=section,
                action=action,
                actor_email=actor_email,
                target_id=target_id,
                command_token=command_token,
                before=before_content,
                after=content,
            )
            return {"section": section, "target_id": target_id, "action": action, "deleted": deleted}
        content["status"] = {
            **content.get("status", {}),
            "visibility": VisibilityState.HIDDEN.value,
            "state": PublishState.ARCHIVED.value,
        }
        save_section_content(db, section, content, record)
        create_version_record(
            db,
            section=section,
            action=action,
            actor_email=actor_email,
            target_id=target_id,
            command_token=command_token,
            before=before_content,
            after=content,
        )
        return {"section": section, "target_id": None, "action": action}

    if action == CommandType.SET_VISIBILITY.value:
        visibility = payload.get("visibility")
        if visibility not in {item.value for item in VisibilityState}:
            raise HTTPException(status_code=400, detail="payload.visibility is required")
        content["status"] = {**content.get("status", {}), "visibility": visibility}
        save_section_content(db, section, content, record)
        create_version_record(
            db,
            section=section,
            action=action,
            actor_email=actor_email,
            target_id=target_id,
            command_token=command_token,
            before=before_content,
            after=content,
        )
        return {"section": section, "visibility": visibility, "action": action}

    if action == CommandType.SET_STATUS.value:
        status_patch = payload.get("status")
        if not isinstance(status_patch, dict):
            raise HTTPException(status_code=400, detail="payload.status must be an object")
        validate_status_block(status_patch)
        content["status"] = {**content.get("status", {}), **status_patch}
        save_section_content(db, section, content, record)
        create_version_record(
            db,
            section=section,
            action=action,
            actor_email=actor_email,
            target_id=target_id,
            command_token=command_token,
            before=before_content,
            after=content,
        )
        return {"section": section, "status": content["status"], "action": action}

    raise HTTPException(status_code=400, detail="Unsupported admin action")
