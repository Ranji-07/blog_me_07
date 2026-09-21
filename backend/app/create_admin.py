"""Create or update a local admin user without storing a plaintext password."""

import argparse
from getpass import getpass

from app.database import SessionLocal
from app.models import AdminUser
from app.services.auth import hash_password
from app.utils.time import utc_now


def create_admin(*, email: str, password: str, activate: bool = True) -> AdminUser:
    normalized_email = email.strip().lower()
    if len(password) < 12:
        raise ValueError("Admin passwords must contain at least 12 characters")
    db = SessionLocal()
    try:
        admin = db.query(AdminUser).filter(AdminUser.email == normalized_email).one_or_none()
        if admin is None:
            admin = AdminUser(email=normalized_email, password_hash=hash_password(password), is_active=activate)
            db.add(admin)
        else:
            admin.password_hash = hash_password(password)
            admin.is_active = activate
            admin.updated_at = utc_now()
        db.commit()
        db.refresh(admin)
        return admin
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create or reset a portfolio admin account.")
    parser.add_argument("--email", required=True, help="Admin email address")
    args = parser.parse_args()
    password = getpass("New password (12+ characters): ")
    confirmation = getpass("Confirm password: ")
    if password != confirmation:
        raise SystemExit("Passwords do not match")
    admin = create_admin(email=args.email, password=password)
    print(f"Admin account ready for {admin.email}.")
