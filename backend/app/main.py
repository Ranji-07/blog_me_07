import os
import logging
import re

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from app.database import BASE_DIR, Base, engine
from app.routes.admin import router as admin_router
from app.routes.public import router as public_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

Base.metadata.create_all(bind=engine)


def _allowed_origins() -> list[str]:
    raw_origins = os.getenv(
        "CORS_ALLOW_ORIGINS",
        "http://127.0.0.1:58115,http://localhost:58115",
    )
    if raw_origins.strip() == "*":
        raise RuntimeError("CORS_ALLOW_ORIGINS must list explicit origins")
    return [origin.strip() for origin in raw_origins.split(",") if origin.strip()]


def _allowed_origin_regex() -> str | None:
    # Flutter Web selects a new local port on each dev-server restart.
    return os.getenv(
        "CORS_ALLOW_ORIGIN_REGEX",
        r"^http://(localhost|127\.0\.0\.1):\d+$",
    ) or None

app = FastAPI(
    title="Portfolio API",
    description="Professional Portfolio Management System with Email Control",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins(),
    allow_origin_regex=_allowed_origin_regex(),
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(public_router)
app.include_router(admin_router)


@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    return response


@app.get("/images/{filename}", tags=["Assets"])
async def get_image(filename: str):
    if not re.fullmatch(r"[A-Za-z0-9_-]+\.(?:jpg|png|gif|webp)", filename):
        raise HTTPException(status_code=404, detail="Image not found")
    file_path = BASE_DIR / "uploaded_images" / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Image not found")
    return FileResponse(file_path)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host=os.getenv("API_HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", os.getenv("API_PORT", "8000"))),
    )
