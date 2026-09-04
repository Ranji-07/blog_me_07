from sqlalchemy import Boolean, Column, DateTime, Integer, String, Text

from app.database import Base
from app.utils.time import utc_now


class PortfolioData(Base):
    __tablename__ = "portfolio_data"

    id = Column(Integer, primary_key=True, index=True)
    section = Column(String(50), index=True, unique=True)
    content = Column(Text)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    is_active = Column(Boolean, default=True)


class EmailCommand(Base):
    __tablename__ = "email_commands"

    id = Column(Integer, primary_key=True, index=True)
    command_type = Column(String(50))
    email_from = Column(String(255))
    data = Column(Text)
    token = Column(String(64), unique=True, index=True)
    confirmed = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    expires_at = Column(DateTime(timezone=True))


class ContactSubmission(Base):
    __tablename__ = "contact_submissions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100))
    email = Column(String(255))
    contact = Column(String(50))
    message = Column(Text)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    is_read = Column(Boolean, default=False)


class VisitLog(Base):
    __tablename__ = "visit_logs"

    id = Column(Integer, primary_key=True, index=True)
    ip = Column(String(64), nullable=True)
    user_agent = Column(Text, nullable=True)
    visited_at = Column(DateTime(timezone=True), default=utc_now, index=True)


class PortfolioVersion(Base):
    __tablename__ = "portfolio_versions"

    id = Column(Integer, primary_key=True, index=True)
    section = Column(String(50), index=True)
    action = Column(String(50), index=True)
    actor_email = Column(String(255), index=True)
    target_id = Column(String(255), nullable=True)
    command_token = Column(String(64), nullable=True, index=True)
    snapshot_before = Column(Text, nullable=True)
    snapshot_after = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, index=True)
