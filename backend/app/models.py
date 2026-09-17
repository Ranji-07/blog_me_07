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


class ContactSubmission(Base):
    __tablename__ = "contact_submissions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100))
    email = Column(String(255))
    message = Column(Text)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    is_read = Column(Boolean, default=False)


class VisitLog(Base):
    __tablename__ = "visit_logs"

    id = Column(Integer, primary_key=True, index=True)
    ip = Column(String(64), nullable=True)
    user_agent = Column(Text, nullable=True)
    visited_at = Column(DateTime(timezone=True), default=utc_now, index=True)
