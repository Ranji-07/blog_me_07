import json
import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import CONTENT_DIR
from app.utils.time import utc_now

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./portfolio_dev.db")

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def _load_section_file(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _load_portfolio_sections() -> list[tuple[str, dict]]:
    section_files = [
        ("about", CONTENT_DIR / "about.json"),
        ("projects", CONTENT_DIR / "projects.json"),
        ("experience", CONTENT_DIR / "experience.json"),
        ("contact", CONTENT_DIR / "contact.json"),
    ]

    missing = [str(path) for _, path in section_files if not path.exists()]
    if missing:
        raise FileNotFoundError(f"Missing content files: {', '.join(missing)}")

    return [(section, _load_section_file(path)) for section, path in section_files]


def init_database():
    """Initialize database with portfolio content files."""

    from app.database import Base
    from app.models import PortfolioData
    from app.services.content_service import is_content_active, normalize_content, validate_section_schema

    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    sections = _load_portfolio_sections()

    for section, raw_data in sections:
        data = normalize_content(raw_data)
        validate_section_schema(section, data)
        existing = db.query(PortfolioData).filter(PortfolioData.section == section).first()

        if not existing:
            portfolio_item = PortfolioData(
                section=section,
                content=json.dumps(data),
                is_active=is_content_active(data),
            )
            db.add(portfolio_item)
            print(f"[created] {section} section")
        else:
            existing.content = json.dumps(data)
            existing.is_active = is_content_active(data)
            existing.updated_at = utc_now()
            print(f"[updated] {section} section")

    db.commit()
    db.close()

    print("\nDatabase initialized successfully!")
    print("-" * 40)
    print("Sections created/updated:")
    for section, _ in sections:
        print(f"  - {section}")
    print("-" * 40)


if __name__ == "__main__":
    init_database()
