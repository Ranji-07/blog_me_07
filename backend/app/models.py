from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Index, Integer, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import relationship

from app.database import Base
from app.utils.time import utc_now


class PortfolioData(Base):
    __tablename__ = "portfolio_data"

    id = Column(Integer, primary_key=True, index=True)
    section = Column(String(50), index=True, unique=True)
    content = Column(Text)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    is_active = Column(Boolean, default=True)
    version = Column(Integer, nullable=False, default=1)
    published_at = Column(DateTime(timezone=True), nullable=True)


class ContactSubmission(Base):
    __tablename__ = "contact_submissions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100))
    email = Column(String(255))
    message = Column(Text)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    is_read = Column(Boolean, default=False)
    email_events = relationship("EmailEvent", back_populates="contact_submission", cascade="all, delete-orphan")


class VisitLog(Base):
    __tablename__ = "visit_logs"

    id = Column(Integer, primary_key=True, index=True)
    ip = Column(String(64), nullable=True)  # Deprecated: new visits deliberately leave this empty.
    user_agent = Column(Text, nullable=True)
    visited_at = Column(DateTime(timezone=True), default=utc_now, index=True)
    visit_id = Column(String(64), nullable=True, unique=True, index=True)
    page = Column(String(255), nullable=True, index=True)
    device_type = Column(String(32), nullable=True, index=True)
    browser = Column(String(64), nullable=True)
    operating_system = Column(String(64), nullable=True)
    referrer = Column(String(255), nullable=True)
    session_id = Column(String(64), nullable=True, index=True)


class Project(Base):
    """Normalized project data seeded from the public projects JSON section."""

    __tablename__ = "projects"
    __table_args__ = (
        Index("ix_projects_source_id", "source_id"),
        Index("ix_projects_slug", "slug"),
    )

    id = Column(Integer, primary_key=True)
    source_id = Column(String(100), unique=True, nullable=False)
    title = Column(String(255), nullable=False)
    slug = Column(String(255), nullable=False, unique=True)
    category = Column(String(100), nullable=False, index=True)
    timeline_date = Column(String(32), nullable=True, index=True)
    timeline_parent = Column(String(255), nullable=True)
    start_date = Column(String(32), nullable=True)
    end_date = Column(String(32), nullable=True)
    associated_with = Column(String(255), nullable=True)
    short_description = Column(Text, nullable=True)
    description = Column(Text, nullable=True)
    technologies = Column(JSON, nullable=False, default=list)
    features = Column(JSON, nullable=False, default=list)
    images = Column(JSON, nullable=False, default=list)
    github_url = Column(String(2048), nullable=True)
    live_demo_url = Column(String(2048), nullable=True)
    featured = Column(Boolean, nullable=False, default=False, index=True)
    status = Column(String(32), nullable=False, default="published", index=True)
    version = Column(Integer, nullable=False, default=1)
    published_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    journey_events = relationship("JourneyEvent", back_populates="project")


class JourneyEvent(Base):
    """Education, work, and certification milestones for the portfolio timeline."""

    __tablename__ = "journey_events"
    __table_args__ = (Index("ix_journey_events_source_id", "source_id"),)

    id = Column(Integer, primary_key=True)
    source_id = Column(String(100), unique=True, nullable=False)
    event_type = Column(String(50), nullable=False, index=True)
    date_label = Column(String(100), nullable=False)
    timeline_date = Column(String(32), nullable=True, index=True)
    organization = Column(String(255), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    timeline_label = Column(String(255), nullable=True)
    description = Column(Text, nullable=True)
    parent_milestone = Column(String(255), nullable=True)
    certification_info = Column(JSON, nullable=True, default=dict)
    technologies = Column(JSON, nullable=False, default=list)
    highlights = Column(JSON, nullable=False, default=list)
    is_current = Column(Boolean, nullable=False, default=False, index=True)
    display_order = Column(Integer, nullable=False, default=0)
    status = Column(String(32), nullable=False, default="published", index=True)
    version = Column(Integer, nullable=False, default=1)
    published_at = Column(DateTime(timezone=True), nullable=True)
    project_id = Column(Integer, ForeignKey("projects.id", ondelete="SET NULL"), nullable=True, index=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    project = relationship("Project", back_populates="journey_events")


class SkillCategory(Base):
    __tablename__ = "skill_categories"

    id = Column(Integer, primary_key=True)
    name = Column(String(150), nullable=False, unique=True)
    display_order = Column(Integer, nullable=False, default=0)
    is_active = Column(Boolean, nullable=False, default=True, index=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    skills = relationship("Skill", back_populates="category", cascade="all, delete-orphan")


class Skill(Base):
    __tablename__ = "skills"
    __table_args__ = (UniqueConstraint("category_id", "name", name="uq_skill_category_name"),)

    id = Column(Integer, primary_key=True)
    category_id = Column(Integer, ForeignKey("skill_categories.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(150), nullable=False)
    icon = Column(String(255), nullable=True)
    display_order = Column(Integer, nullable=False, default=0)
    is_active = Column(Boolean, nullable=False, default=True, index=True)
    status = Column(String(32), nullable=False, default="published", index=True)
    version = Column(Integer, nullable=False, default=1)
    published_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    category = relationship("SkillCategory", back_populates="skills")


class EmailEvent(Base):
    __tablename__ = "email_events"

    id = Column(Integer, primary_key=True)
    contact_submission_id = Column(
        Integer,
        ForeignKey("contact_submissions.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
    event_type = Column(String(80), nullable=False, index=True)
    recipient = Column(String(255), nullable=False, index=True)
    provider = Column(String(80), nullable=False, default="gmail_api")
    delivery_status = Column(String(32), nullable=False, default="pending", index=True)
    provider_message_id = Column(String(255), nullable=True, index=True)
    error_message = Column(Text, nullable=True)
    subject = Column(String(500), nullable=True)
    html_body = Column(Text, nullable=True)
    plain_body = Column(Text, nullable=True)
    reply_to = Column(String(255), nullable=True)
    attempts = Column(Integer, nullable=False, default=0)
    sent_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    contact_submission = relationship("ContactSubmission", back_populates="email_events")


class Asset(Base):
    __tablename__ = "assets"
    id = Column(Integer, primary_key=True)
    filename = Column(String(255), nullable=False, unique=True, index=True)
    storage_path = Column(String(500), nullable=False)
    mime_type = Column(String(100), nullable=False)
    file_size = Column(Integer, nullable=False)
    asset_type = Column(String(32), nullable=False, index=True)
    associated_project_id = Column(Integer, ForeignKey("projects.id", ondelete="SET NULL"), nullable=True, index=True)
    is_public = Column(Boolean, nullable=False, default=False, index=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)


class AdminUser(Base):
    __tablename__ = "admin_users"
    __table_args__ = (Index("ix_admin_users_email", "email"),)

    id = Column(Integer, primary_key=True)
    email = Column(String(255), nullable=False, unique=True)
    password_hash = Column(String(512), nullable=False)
    is_active = Column(Boolean, nullable=False, default=True, index=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)
    last_login_at = Column(DateTime(timezone=True), nullable=True)


class ContentVersion(Base):
    """Immutable audit snapshot for a versioned CMS record."""

    __tablename__ = "content_versions"
    __table_args__ = (UniqueConstraint("content_type", "content_id", "version", name="uq_content_version"),)

    id = Column(Integer, primary_key=True)
    content_type = Column(String(32), nullable=False, index=True)
    content_id = Column(String(100), nullable=False, index=True)
    version = Column(Integer, nullable=False)
    status = Column(String(32), nullable=False, default="draft", index=True)
    snapshot = Column(JSON, nullable=False)
    changed_by = Column(String(255), nullable=False, index=True)
    action = Column(String(32), nullable=False, index=True)
    changed_at = Column(DateTime(timezone=True), default=utc_now, nullable=False, index=True)
    published_at = Column(DateTime(timezone=True), nullable=True)
