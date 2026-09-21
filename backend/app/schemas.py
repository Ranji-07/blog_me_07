from datetime import date, datetime
from typing import Any, Dict, Literal, Optional

import re

from pydantic import BaseModel, ConfigDict, EmailStr, Field, HttpUrl, field_validator


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


class LoginRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    email: EmailStr
    password: str = Field(..., min_length=8, max_length=256)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


PublishStatus = Literal["draft", "published", "archived"]
JourneyType = Literal["Education", "Work", "Certification"]


class AboutUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str | None = Field(None, min_length=1, max_length=100)
    title: str | None = Field(None, max_length=160)
    roles: list[str] | None = Field(None, max_length=12)
    about_me: list[str] | None = Field(None, max_length=8)
    availability: str | None = Field(None, max_length=50)
    available_for_work: bool | None = None
    avatar_url: str | None = Field(None, max_length=2048)
    portrait_url: str | None = Field(None, max_length=2048)
    profile_image: str | None = Field(None, max_length=2048)
    resume: str | None = Field(None, max_length=2048)
    value_statement: str | None = Field(None, max_length=600)
    visible: bool | None = None
    status: PublishStatus | None = None


class SkillCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    category: str = Field(..., min_length=1, max_length=150)
    name: str = Field(..., min_length=1, max_length=150)
    icon: str | None = Field(None, max_length=255)
    display_order: int = Field(0, ge=0, le=10000)
    is_active: bool = True


class SkillUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    category: str | None = Field(None, min_length=1, max_length=150)
    name: str | None = Field(None, min_length=1, max_length=150)
    icon: str | None = Field(None, max_length=255)
    display_order: int | None = Field(None, ge=0, le=10000)
    is_active: bool | None = None


class ProjectCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str = Field(..., min_length=2, max_length=255)
    slug: str = Field(..., pattern=r"^[a-z0-9]+(?:-[a-z0-9]+)*$", max_length=255)
    category: str = Field(..., min_length=2, max_length=100)
    description: str = Field(..., min_length=10, max_length=8000)
    short_description: str | None = Field(None, max_length=500)
    technologies: list[str] = Field(default_factory=list, max_length=30)
    features: list[str] = Field(default_factory=list, max_length=30)
    images: list[str] = Field(default_factory=list, max_length=20)
    start_date: date | None = None
    end_date: date | None = None
    timeline_date: date | None = None
    associated_with: str | None = Field(None, max_length=255)
    github_url: HttpUrl | None = None
    live_url: HttpUrl | None = None
    featured: bool = False
    status: PublishStatus = "published"

    @field_validator("end_date")
    @classmethod
    def end_after_start(cls, value: date | None, info) -> date | None:
        start_date = info.data.get("start_date")
        if value and start_date and value < start_date:
            raise ValueError("end_date must not be earlier than start_date")
        return value


class ProjectUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str | None = Field(None, min_length=2, max_length=255)
    slug: str | None = Field(None, pattern=r"^[a-z0-9]+(?:-[a-z0-9]+)*$", max_length=255)
    category: str | None = Field(None, min_length=2, max_length=100)
    description: str | None = Field(None, min_length=10, max_length=8000)
    short_description: str | None = Field(None, max_length=500)
    technologies: list[str] | None = Field(None, max_length=30)
    features: list[str] | None = Field(None, max_length=30)
    images: list[str] | None = Field(None, max_length=20)
    start_date: date | None = None
    end_date: date | None = None
    timeline_date: date | None = None
    associated_with: str | None = Field(None, max_length=255)
    github_url: HttpUrl | None = None
    live_url: HttpUrl | None = None
    featured: bool | None = None
    status: PublishStatus | None = None


class JourneyCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    event_type: JourneyType
    date_label: str = Field(..., min_length=1, max_length=100)
    timeline_date: date | None = None
    organization: str = Field(..., min_length=1, max_length=255)
    title: str = Field(..., min_length=2, max_length=255)
    timeline_label: str | None = Field(None, max_length=255)
    description: str | None = Field(None, max_length=5000)
    parent_milestone: str | None = Field(None, max_length=255)
    project_id: int | None = Field(None, gt=0)
    certification_info: dict[str, str] = Field(default_factory=dict)
    technologies: list[str] = Field(default_factory=list, max_length=30)
    highlights: list[str] = Field(default_factory=list, max_length=30)
    is_current: bool = False
    display_order: int = Field(0, ge=0, le=10000)


class JourneyUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    event_type: JourneyType | None = None
    date_label: str | None = Field(None, min_length=1, max_length=100)
    timeline_date: date | None = None
    organization: str | None = Field(None, min_length=1, max_length=255)
    title: str | None = Field(None, min_length=2, max_length=255)
    timeline_label: str | None = Field(None, max_length=255)
    description: str | None = Field(None, max_length=5000)
    parent_milestone: str | None = Field(None, max_length=255)
    project_id: int | None = Field(None, gt=0)
    certification_info: dict[str, str] | None = None
    technologies: list[str] | None = Field(None, max_length=30)
    highlights: list[str] | None = Field(None, max_length=30)
    is_current: bool | None = None
    display_order: int | None = Field(None, ge=0, le=10000)


class SkillResponse(BaseModel):
    id: int
    category: str
    name: str
    icon: str | None
    display_order: int
    is_active: bool
    status: str
    version: int
    published_at: datetime | None
    created_at: datetime
    updated_at: datetime


class ProjectResponse(BaseModel):
    id: int
    title: str
    slug: str
    category: str
    description: str | None
    short_description: str | None
    technologies: list[str]
    features: list[str]
    images: list[str]
    start_date: str | None
    end_date: str | None
    timeline_date: str | None
    associated_with: str | None
    github_url: str | None
    live_url: str | None
    featured: bool
    status: str
    version: int
    published_at: datetime | None
    created_at: datetime
    updated_at: datetime


class JourneyResponse(BaseModel):
    id: int
    event_type: str
    date_label: str
    timeline_date: str | None
    organization: str
    title: str
    timeline_label: str | None
    description: str | None
    parent_milestone: str | None
    project_id: int | None
    certification_info: dict[str, str]
    technologies: list[str]
    highlights: list[str]
    is_current: bool
    display_order: int
    status: str
    version: int
    published_at: datetime | None
    created_at: datetime
    updated_at: datetime
