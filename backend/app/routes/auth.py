"""Admin login endpoint."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import AdminUser
from app.schemas import LoginRequest, TokenResponse
from app.services.auth import create_access_token, verify_password
from app.utils.time import utc_now

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/login", response_model=TokenResponse)
async def login(credentials: LoginRequest, db: Session = Depends(get_db)):
    """Authenticate an active admin without revealing whether the email exists."""
    normalized_email = str(credentials.email).strip().lower()
    admin = db.query(AdminUser).filter(AdminUser.email == normalized_email).one_or_none()
    if admin is None or not verify_password(credentials.password, admin.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    if not admin.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin account is inactive")
    if not settings.jwt_secret_key:
        raise HTTPException(status_code=500, detail="JWT authentication is not configured")

    admin.last_login_at = utc_now()
    db.commit()
    return TokenResponse(
        access_token=create_access_token(admin),
        expires_in=settings.jwt_access_token_minutes * 60,
    )
