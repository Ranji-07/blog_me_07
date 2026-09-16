from enum import Enum
from typing import Any, Dict, Optional

import re

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class CommandType(str, Enum):
    CREATE = "create"
    UPDATE = "update"
    DELETE = "delete"
    SET_VISIBILITY = "set_visibility"
    SET_STATUS = "set_status"
    UPLOAD_ASSET = "upload_asset"


class VisibilityState(str, Enum):
    VISIBLE = "visible"
    HIDDEN = "hidden"
    IN_PROGRESS = "in_progress"


class PublishState(str, Enum):
    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"


class PortfolioSection(str, Enum):
    ABOUT = "about"
    PROJECTS = "projects"
    EXPERIENCE = "experience"
    JOURNEY = "journey"
    CONTACT = "contact"


class EmailCommandRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    action: CommandType
    section: PortfolioSection
    target_id: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)
    auth_email: EmailStr


class ContactFormRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    message: str = Field(..., min_length=15, max_length=1000)

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: str) -> str:
        normalized = value.strip()
        if normalized.lower() in {"xxx", "test", "abc", "123", "asdf"}:
            raise ValueError("Please enter a meaningful name")
        if re.fullmatch(r"(.)\1{2,}", normalized.lower()):
            raise ValueError("Please enter a meaningful name")
        if not re.fullmatch(r"[A-Za-z]+(?:[ '-][A-Za-z]+)*", normalized):
            raise ValueError("Name must contain alphabetic characters only")
        return normalized

    @field_validator("message")
    @classmethod
    def validate_message(cls, value: str) -> str:
        normalized = value.strip()
        if "\x00" in normalized:
            raise ValueError("Message contains an invalid character")
        if normalized.lower() in {"xxx", "test", "abc", "123", "asdf"}:
            raise ValueError("Please enter a meaningful message")
        if re.fullmatch(r"(.)\1{2,}", normalized.lower()):
            raise ValueError("Please enter a meaningful message")
        return normalized


class APIResponse(BaseModel):
    status: str
    message: str
    data: Optional[Dict[str, Any]] = None
