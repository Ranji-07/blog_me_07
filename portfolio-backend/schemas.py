from enum import Enum
from typing import Any, Dict, Optional

from pydantic import BaseModel, EmailStr, Field


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
    CONTACT = "contact"


class EmailCommandRequest(BaseModel):
    action: CommandType
    section: PortfolioSection
    target_id: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)
    auth_email: EmailStr
    admin_token: str = Field(..., min_length=16, max_length=256)


class ContactFormRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    contact: str = Field(..., min_length=5, max_length=50)
    message: str = Field(..., min_length=10, max_length=2000)


class APIResponse(BaseModel):
    status: str
    message: str
    data: Optional[Dict[str, Any]] = None
