"""JWT and password helpers for protected admin APIs."""

from datetime import timedelta

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerifyMismatchError
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import AdminUser
from app.utils.time import utc_now

_password_hasher = PasswordHasher()
_bearer_scheme = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    return _password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return _password_hasher.verify(password_hash, password)
    except (InvalidHashError, VerifyMismatchError):
        return False


def create_access_token(admin: AdminUser, *, expires_delta: timedelta | None = None) -> str:
    if not settings.jwt_secret_key:
        raise RuntimeError("JWT_SECRET_KEY is not configured")
    now = utc_now()
    expires_at = now + (expires_delta or timedelta(minutes=settings.jwt_access_token_minutes))
    return jwt.encode(
        {
            "sub": str(admin.id),
            "email": admin.email,
            "type": "admin",
            "iat": now,
            "exp": expires_at,
        },
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def _unauthorized(detail: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


def get_current_admin(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
    db: Session = Depends(get_db),
) -> AdminUser:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise _unauthorized("Authentication required")
    if not settings.jwt_secret_key:
        raise HTTPException(status_code=500, detail="JWT authentication is not configured")
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
    except jwt.ExpiredSignatureError as exc:
        raise _unauthorized("Authentication token has expired") from exc
    except jwt.InvalidTokenError as exc:
        raise _unauthorized("Invalid authentication token") from exc

    if payload.get("type") != "admin" or not str(payload.get("sub", "")).isdigit():
        raise _unauthorized("Invalid authentication token")
    admin = db.query(AdminUser).filter(AdminUser.id == int(payload["sub"])).one_or_none()
    if admin is None:
        raise _unauthorized("Invalid authentication token")
    if not admin.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin account is inactive")
    return admin
